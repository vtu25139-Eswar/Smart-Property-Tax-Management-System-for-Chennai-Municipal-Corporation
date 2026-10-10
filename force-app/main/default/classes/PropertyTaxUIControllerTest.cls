@isTest
private class PropertyTaxUIControllerTest {

    @testSetup
    static void setup() {
        TaxTestDataFactory.createTaxRates();
        Property__c prop = TaxTestDataFactory.createSampleProperty('CHN-UI-001', 'Zone 5 - Royapuram', 'Residential', 1200, 'Self-Occupied');
        TaxTestDataFactory.createAssessment(prop.Id, null, 18000, 'Submitted');
    }

    @isTest
    static void testGetPropertyDetails() {
        Property__c prop = [SELECT Id FROM Property__c LIMIT 1];

        Test.startTest();
        Property__c details = PropertyTaxUIController.getPropertyDetails(prop.Id);
        Test.stopTest();

        System.assertNotEquals(null, details, 'Property details should be returned');
        System.assertEquals('CHN-UI-001', details.Property_Number__c, 'Property number should match');
    }

    @isTest
    static void testRegisterProperty() {
        Property__c newProp = new Property__c(
            Property_Number__c = 'CHN-REG-999',
            Property_Owner_Name__c = 'Meenakshi Sundaram',
            Building_Area_SqFt__c = 1400,
            Zone__c = 'Zone 13 - Adyar',
            Property_Type__c = 'Residential',
            Occupancy_Type__c = 'Self-Occupied'
        );

        Test.startTest();
        Id propId = PropertyTaxUIController.registerProperty(newProp);
        Test.stopTest();

        System.assertNotEquals(null, propId, 'Registered property ID should not be null');
        Property__c registered = [SELECT Id, Property_Number__c FROM Property__c WHERE Id = :propId];
        System.assertEquals('CHN-REG-999', registered.Property_Number__c, 'Property number should match');
    }

    @isTest
    static void testCalculateEstimate() {
        Test.startTest();
        TaxCalculationService.CalculationResult res = PropertyTaxUIController.calculateEstimate(
            1500, 'Zone 5 - Royapuram', 'Residential', 'Residential Individual', 'Self-Occupied', '2025-2026'
        );
        Test.stopTest();

        System.assertNotEquals(null, res, 'Calculation result should not be null');
        System.assert(res.totalAssessedTax > 0, 'Total tax should be calculated');
    }

    @isTest
    static void testProcessSimulatedPayment() {
        Tax_Assessment__c asm = [SELECT Id, Property__c FROM Tax_Assessment__c LIMIT 1];

        Test.startTest();
        Tax_Payment__c pay = PropertyTaxUIController.processSimulatedPayment(
            asm.Id, asm.Property__c, 5000, 'Online - UPI', 'Meenakshi', 'meenakshi@example.com'
        );
        Test.stopTest();

        System.assertNotEquals(null, pay, 'Payment record should be returned');
        System.assertEquals(5000, pay.Amount_Paid__c, 'Amount paid should match');
        System.assert(pay.Is_Simulated_Transaction__c, 'Should be flagged as simulated');
    }

    @isTest
    static void testGetMunicipalAdminMetrics() {
        Test.startTest();
        Map<String, Object> metrics = PropertyTaxUIController.getMunicipalAdminMetrics();
        Test.stopTest();

        System.assertNotEquals(null, metrics, 'Metrics map should not be null');
        System.assert(metrics.containsKey('totalProperties'), 'Should contain totalProperties');
        System.assert(metrics.containsKey('totalAssessedTax'), 'Should contain totalAssessedTax');
        System.assert(metrics.containsKey('zoneBreakdown'), 'Should contain zoneBreakdown');
    }

    @isTest
    static void testSubmitDispute() {
        Tax_Assessment__c asm = [SELECT Id, Property__c FROM Tax_Assessment__c LIMIT 1];

        Test.startTest();
        Id dispId = PropertyTaxUIController.submitDispute(
            asm.Id, asm.Property__c, 'Incorrect Area Measurement', 'Plinth area is only 1000 sq ft according to approved plan.', 1000
        );
        Test.stopTest();

        System.assertNotEquals(null, dispId, 'Dispute ID should not be null');
        Tax_Assessment__c updatedAsm = [SELECT Status__c FROM Tax_Assessment__c WHERE Id = :asm.Id];
        System.assertEquals('Disputed', updatedAsm.Status__c, 'Assessment status should update to Disputed');
    }
}
