@isTest
private class TaxCalculationServiceTest {

    @testSetup
    static void setupData() {
        TaxTestDataFactory.createTaxRates();
    }

    @isTest
    static void testSelfOccupiedResidentialCalculation() {
        Property__c prop = TaxTestDataFactory.createSampleProperty('CHN-TEST-001', 'Zone 5 - Royapuram', 'Residential', 1000, 'Self-Occupied');

        Test.startTest();
        TaxCalculationService.CalculationResult res = TaxCalculationService.calculateTax(prop, '2025-2026');
        Test.stopTest();

        System.assertNotEquals(null, res, 'Calculation result should not be null');
        System.assertEquals(1000, res.buildingArea, 'Assessed area should be 1000');
        System.assertEquals(15.00, res.appliedBaseRate, 'Base rate should be 15');
        System.assertEquals(15000.00, res.grossBaseTax, 'Gross base tax should be 1000 * 15 = 15000');
        System.assertEquals(1500.00, res.rebateAmount, 'Self-occupied 10% rebate should be 1500');
        System.assertEquals(13500.00, res.netBaseTax, 'Net tax base should be 13500');
        System.assertEquals(1350.00, res.libraryCess, 'Library cess 10% should be 1350');
        System.assertEquals(675.00, res.educationCess, 'Education cess 5% should be 675');
        System.assertEquals(15525.00, res.totalAssessedTax, 'Total tax should be 13500 + 1350 + 675 = 15525');
        System.assert(res.explanation.contains('GREATER CHENNAI CORPORATION'), 'Explanation should contain municipal header');
    }

    @isTest
    static void testTenantedResidentialCalculation() {
        Property__c prop = TaxTestDataFactory.createSampleProperty('CHN-TEST-002', 'Zone 5 - Royapuram', 'Residential', 1000, 'Tenanted');

        Test.startTest();
        TaxCalculationService.CalculationResult res = TaxCalculationService.calculateTax(prop, '2025-2026');
        Test.stopTest();

        System.assertEquals(0.00, res.rebateAmount, 'Tenanted property should have 0 rebate');
        System.assertEquals(15000.00, res.netBaseTax, 'Net tax base should equal gross 15000');
        System.assertEquals(1500.00, res.libraryCess, 'Library cess should be 1500');
        System.assertEquals(750.00, res.educationCess, 'Education cess should be 750');
        System.assertEquals(17250.00, res.totalAssessedTax, 'Total tax should be 17250');
    }

    @isTest
    static void testEstimatorOverload() {
        Test.startTest();
        TaxCalculationService.CalculationResult res = TaxCalculationService.calculateTaxEstimator(
            2000, 'Zone 8 - Annanagar', 'Commercial', 'Retail Commercial', 'Tenanted', '2025-2026'
        );
        Test.stopTest();

        System.assertNotEquals(null, res, 'Estimator should return valid result');
        System.assertEquals(35.00, res.appliedBaseRate, 'Should match commercial tax rate');
        System.assertEquals(70000.00, res.grossBaseTax, 'Gross base tax should be 2000 * 35 = 70000');
    }

    @isTest
    static void testNullPropertyThrowsException() {
        try {
            TaxCalculationService.calculateTax(null, '2025-2026');
            System.assert(false, 'Expected exception for null property');
        } catch (IllegalArgumentException ex) {
            System.assert(ex.getMessage().contains('cannot be null'), 'Expected error message');
        }
    }
}
