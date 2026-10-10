/**
 * @description Schedulable Apex job to periodically audit and flag overdue municipal tax assessments.
 * Identifies unpaid assessments past their due date and updates them to Overdue status.
 */
public with sharing class TaxOverdueScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        List<Tax_Assessment__c> overdueAssessments = [
            SELECT Id, Due_Date__c, Balance_Dues__c, Status__c, Penalty_Late_Fee__c, Total_Assessed_Tax__c
            FROM Tax_Assessment__c
            WHERE Due_Date__c < :Date.today()
              AND Balance_Dues__c > 0
              AND Status__c NOT IN ('Overdue', 'Disputed')
            LIMIT 200
        ];

        for (Tax_Assessment__c a : overdueAssessments) {
            a.Status__c = 'Overdue';
            if (a.Penalty_Late_Fee__c == null || a.Penalty_Late_Fee__c == 0) {
                // Apply standard 2% administrative late interest on balance
                Decimal lateFee = (a.Balance_Dues__c * 0.02).setScale(2, RoundingMode.HALF_UP);
                a.Penalty_Late_Fee__c = lateFee;
                a.Total_Assessed_Tax__c += lateFee;
                a.Balance_Dues__c += lateFee;
            }
        }

        if (!overdueAssessments.isEmpty() && Schema.sObjectType.Tax_Assessment__c.isUpdateable()) {
            update overdueAssessments;
        }
    }
}
