/**
 * @description Batch and Schedulable Apex for bulk municipal property reassessment.
 * Iterates across properties in Chennai Municipal Corporation zones,
 * generates new tax assessments for the financial year, and recalculates dues.
 */
public with sharing class TaxReassessmentBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    private String targetFinancialYear;
    private String zoneFilter;
    public Integer recordsProcessed = 0;
    public Decimal totalTaxAssessed = 0;

    public TaxReassessmentBatch() {
        this('2025-2026', null);
    }

    public TaxReassessmentBatch(String financialYear, String zone) {
        this.targetFinancialYear = String.isNotBlank(financialYear) ? financialYear : '2025-2026';
        this.zoneFilter = zone;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Property_Number__c, Property_Owner_Name__c, Owner_Email__c, ' +
                       'Zone__c, Property_Type__c, Property_Usage__c, Occupancy_Type__c, ' +
                       'Building_Area_SqFt__c, Verification_Status__c, Outstanding_Dues__c ' +
                       'FROM Property__c WHERE Building_Area_SqFt__c > 0';

        if (String.isNotBlank(this.zoneFilter)) {
            query += ' AND Zone__c = :zoneFilter';
        }

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Property__c> scope) {
        Set<Id> propIds = new Map<Id, Property__c>(scope).keySet();

        // Check which properties already have an assessment for this year
        Map<Id, Tax_Assessment__c> existingAssessments = new Map<Id, Tax_Assessment__c>();
        for (Tax_Assessment__c a : [
            SELECT Id, Property__c, Status__c, Assessment_Year__c
            FROM Tax_Assessment__c
            WHERE Property__c IN :propIds AND Assessment_Year__c = :targetFinancialYear
        ]) {
            existingAssessments.put(a.Property__c, a);
        }

        List<Tax_Assessment__c> assessmentsToUpsert = new List<Tax_Assessment__c>();

        for (Property__c prop : scope) {
            TaxCalculationService.CalculationResult calc = TaxCalculationService.calculateTax(prop, targetFinancialYear);

            Tax_Assessment__c asm;
            if (existingAssessments.containsKey(prop.Id)) {
                asm = existingAssessments.get(prop.Id);
            } else {
                asm = new Tax_Assessment__c();
                asm.Property__c = prop.Id;
                asm.Assessment_Year__c = targetFinancialYear;
                asm.Status__c = 'Submitted';
                asm.Approval_Status__c = 'Pending Approval';
            }

            asm.Assessment_Date__c = Date.today();
            asm.Due_Date__c = Date.today().addDays(60);
            asm.Assessed_Area_SqFt__c = calc.buildingArea;
            asm.Tax_Rate__c = calc.taxRateId;
            asm.Applied_Base_Rate__c = calc.appliedBaseRate;
            asm.Base_Property_Tax__c = calc.grossBaseTax;
            asm.Rebate_Concession_Amount__c = calc.rebateAmount;
            asm.Education_Cess_Amount__c = calc.educationCess;
            asm.Library_Cess_Amount__c = calc.libraryCess;
            asm.Total_Assessed_Tax__c = calc.totalAssessedTax;
            asm.Calculation_Explanation__c = calc.explanation;

            assessmentsToUpsert.add(asm);
            recordsProcessed++;
            totalTaxAssessed += calc.totalAssessedTax;
        }

        if (!assessmentsToUpsert.isEmpty() && Schema.sObjectType.Tax_Assessment__c.isCreateable() && Schema.sObjectType.Tax_Assessment__c.isUpdateable()) {
            upsert assessmentsToUpsert;
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO, 'TaxReassessmentBatch completed. Processed: ' + recordsProcessed +
                                         ', Total Tax Assessed: ₹' + totalTaxAssessed);

        // Chain queueable for post-batch notifications
        if (!Test.isRunningTest()) {
            System.enqueueJob(new PropertyTaxNotificationQueueable(recordsProcessed, totalTaxAssessed));
        }
    }

    // Schedulable execute method
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new TaxReassessmentBatch(), 100);
    }
}
