/**
 * @description Transparent Tax Calculation Service for Chennai Municipal Corporation.
 * Computes base tax, self-occupied concessions, library cess, education cess, and penalties
 * using configurable Tax_Rate__c records with full mathematical explainability.
 */
public with sharing class TaxCalculationService {

    public class CalculationResult {
        @AuraEnabled public Decimal buildingArea { get; set; }
        @AuraEnabled public Decimal appliedBaseRate { get; set; }
        @AuraEnabled public Decimal grossBaseTax { get; set; }
        @AuraEnabled public Decimal rebateAmount { get; set; }
        @AuraEnabled public Decimal netBaseTax { get; set; }
        @AuraEnabled public Decimal educationCess { get; set; }
        @AuraEnabled public Decimal libraryCess { get; set; }
        @AuraEnabled public Decimal penaltyAmount { get; set; }
        @AuraEnabled public Decimal totalAssessedTax { get; set; }
        @AuraEnabled public Id taxRateId { get; set; }
        @AuraEnabled public String explanation { get; set; }

        public CalculationResult() {
            this.buildingArea = 0;
            this.appliedBaseRate = 0;
            this.grossBaseTax = 0;
            this.rebateAmount = 0;
            this.netBaseTax = 0;
            this.educationCess = 0;
            this.libraryCess = 0;
            this.penaltyAmount = 0;
            this.totalAssessedTax = 0;
            this.explanation = '';
        }
    }

    /**
     * @description Calculates tax for a given property record and financial year.
     */
    public static CalculationResult calculateTax(Property__c property, String financialYear) {
        if (property == null) {
            throw new IllegalArgumentException('Property record cannot be null for tax calculation.');
        }

        String finYear = String.isNotBlank(financialYear) ? financialYear : '2025-2026';
        Decimal area = property.Building_Area_SqFt__c != null ? property.Building_Area_SqFt__c : 0;
        String zone = property.Zone__c;
        String propType = property.Property_Type__c;
        String propUsage = property.Property_Usage__c;
        String occupancy = property.Occupancy_Type__c;

        Tax_Rate__c rate = getMatchingTaxRate(zone, propType, propUsage, finYear);
        return performCalculation(area, occupancy, rate, finYear);
    }

    /**
     * @description On-the-fly calculation overload for calculator LWC or REST API
     */
    public static CalculationResult calculateTaxEstimator(
        Decimal area,
        String zone,
        String propType,
        String propUsage,
        String occupancy,
        String financialYear
    ) {
        String finYear = String.isNotBlank(financialYear) ? financialYear : '2025-2026';
        Tax_Rate__c rate = getMatchingTaxRate(zone, propType, propUsage, finYear);
        return performCalculation(area, occupancy, rate, finYear);
    }

    /**
     * @description Performs calculation with mathematical breakdown
     */
    private static CalculationResult performCalculation(
        Decimal area,
        String occupancy,
        Tax_Rate__c rate,
        String financialYear
    ) {
        CalculationResult res = new CalculationResult();
        res.buildingArea = area != null ? area.setScale(2) : 0;

        Decimal baseRate = (rate != null && rate.Base_Rate_Per_SqFt__c != null) ? rate.Base_Rate_Per_SqFt__c : 15.00;
        Decimal eduCessPct = (rate != null && rate.Education_Cess_Percent__c != null) ? rate.Education_Cess_Percent__c : 5.00;
        Decimal libCessPct = (rate != null && rate.Library_Cess_Percent__c != null) ? rate.Library_Cess_Percent__c : 10.00;
        Decimal rebatePct = (rate != null && rate.Maintenance_Rebate_Percent__c != null) ? rate.Maintenance_Rebate_Percent__c : 10.00;

        res.taxRateId = rate != null ? rate.Id : null;
        res.appliedBaseRate = baseRate.setScale(2);

        // 1. Gross Base Tax = Area * Rate
        Decimal gross = (res.buildingArea * res.appliedBaseRate).setScale(2, RoundingMode.HALF_UP);
        res.grossBaseTax = gross;

        // 2. Occupancy Rebate (e.g. 10% concession for Self-Occupied residential units)
        Decimal rebate = 0;
        if ('Self-Occupied'.equalsIgnoreCase(occupancy)) {
            rebate = (gross * (rebatePct / 100.0)).setScale(2, RoundingMode.HALF_UP);
        }
        res.rebateAmount = rebate;

        // 3. Net Base Tax
        Decimal net = gross - rebate;
        res.netBaseTax = net.setScale(2);

        // 4. Tamil Nadu Statutory Cesses
        Decimal libCess = (net * (libCessPct / 100.0)).setScale(2, RoundingMode.HALF_UP);
        Decimal eduCess = (net * (eduCessPct / 100.0)).setScale(2, RoundingMode.HALF_UP);
        res.libraryCess = libCess;
        res.educationCess = eduCess;

        // 5. Total Annual Tax
        Decimal total = (net + libCess + eduCess).setScale(2, RoundingMode.HALF_UP);
        res.totalAssessedTax = total;

        // Explanation narrative
        List<String> steps = new List<String>();
        steps.add('=== GREATER CHENNAI CORPORATION TAX ASSESSMENT (' + financialYear + ') ===');
        steps.add('1. Assessed Plinth Area: ' + res.buildingArea + ' sq ft');
        steps.add('2. Applied Base Unit Rate: ₹' + res.appliedBaseRate + ' per sq ft');
        steps.add('3. Gross Base Annual Value: ₹' + res.grossBaseTax + ' (Area × Base Rate)');
        if (rebate > 0) {
            steps.add('4. Self-Occupied Rebate (' + rebatePct + '%): -₹' + res.rebateAmount);
        } else {
            steps.add('4. Concession / Rebate: ₹0.00 (Occupancy: ' + occupancy + ')');
        }
        steps.add('5. Net Taxable Base: ₹' + res.netBaseTax);
        steps.add('6. Library Cess (' + libCessPct + '% TN Public Libraries Act): ₹' + res.libraryCess);
        steps.add('7. Education Cess (' + eduCessPct + '% Municipal Surcharge): ₹' + res.educationCess);
        steps.add('8. Total Payable Annual Tax: ₹' + res.totalAssessedTax);
        steps.add('--------------------------------------------------');
        steps.add('Disclaimer: Configured demo rates for Chennai Municipal Corporation demonstration.');

        res.explanation = String.join(steps, '\n');
        return res;
    }

    /**
     * @description Matches Tax_Rate__c by zone, type, usage, and financial year.
     * Falls back to general rate if exact zone record is not found.
     */
    public static Tax_Rate__c getMatchingTaxRate(String zone, String propType, String propUsage, String finYear) {
        List<Tax_Rate__c> rates = [
            SELECT Id, Name, Zone__c, Property_Type__c, Property_Usage__c, Financial_Year__c,
                   Base_Rate_Per_SqFt__c, Education_Cess_Percent__c, Library_Cess_Percent__c,
                   Maintenance_Rebate_Percent__c, Penalty_Rate_Percent__c, Is_Active__c
            FROM Tax_Rate__c
            WHERE Is_Active__c = true
              AND Financial_Year__c = :finYear
              AND Property_Type__c = :propType
            ORDER BY Zone__c ASC, CreatedDate DESC
            LIMIT 50
        ];

        if (rates.isEmpty()) {
            return null;
        }

        // 1. Exact zone and exact usage match
        for (Tax_Rate__c r : rates) {
            if (r.Zone__c == zone && r.Property_Usage__c == propUsage) {
                return r;
            }
        }

        // 2. Exact zone match
        for (Tax_Rate__c r : rates) {
            if (r.Zone__c == zone) {
                return r;
            }
        }

        // 3. 'All Zones' fallback match
        for (Tax_Rate__c r : rates) {
            if (r.Zone__c == 'All Zones' && r.Property_Usage__c == propUsage) {
                return r;
            }
        }

        for (Tax_Rate__c r : rates) {
            if (r.Zone__c == 'All Zones') {
                return r;
            }
        }

        return rates[0];
    }
}
