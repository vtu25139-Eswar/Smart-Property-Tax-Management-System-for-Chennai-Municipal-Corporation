@isTest
private class TaxAssessmentTriggerTest {

    @testSetup
    static void setup() {
        TaxTestDataFactory.createTaxRates();
    }

    @isTest
    static void testAssessmentBalanceCalculationAndSync() {
        Property__c prop = TaxTestDataFactory.createSampleProperty('CHN-ASM-001', 'Zone 5 - Royapuram', 'Residential', 1200, 'Self-Occupied');
        Tax_Rate__c rate = [SELECT Id FROM Tax_Rate__c LIMIT 1];

        Test.startTest();
        Tax_Assessment__c asm = new Tax_Assessment__c(
            Property__c = prop.Id,
            Assessment_Year__c = '2025-2026',
            Tax_Rate__c = rate.Id,
            Total_Assessed_Tax__c = 15500.00,
            Paid_Amount__c = 5000.00,
            Status__c = 'Submitted'
        );
        insert asm;
        Test.stopTest();

        Tax_Assessment__c queriedAsm = [SELECT Balance_Dues__c, Due_Date__c FROM Tax_Assessment__c WHERE Id = :asm.Id];
        System.assertEquals(10500.00, queriedAsm.Balance_Dues__c, 'Balance should be 15500 - 5000 = 10500');
        System.assertNotEquals(null, queriedAsm.Due_Date__c, 'Due date should default to +60 days');

        Property__c queriedProp = [SELECT Outstanding_Dues__c, Assessed_Annual_Tax__c FROM Property__c WHERE Id = :prop.Id];
        System.assertEquals(10500.00, queriedProp.Outstanding_Dues__c, 'Property outstanding dues should sync');
        System.assertEquals(15500.00, queriedProp.Assessed_Annual_Tax__c, 'Property annual tax should sync');
    }

    @isTest
    static void testApprovalValidationBlocksDiscrepantProperty() {
        Property__c prop = TaxTestDataFactory.createSampleProperty('CHN-DISC-001', 'Zone 5 - Royapuram', 'Residential', 1200, 'Self-Occupied');
        prop.Verification_Status__c = 'Discrepancy Flagged';
        update prop;

        Tax_Assessment__c asm = TaxTestDataFactory.createAssessment(prop.Id, null, 12000, 'Submitted');

        Test.startTest();
        asm.Status__c = 'Approved';
        try {
            update asm;
            System.assert(false, 'Expected approval to be blocked due to property discrepancy');
        } catch (DmlException ex) {
            System.assert(ex.getMessage().contains('discrepancies'), 'Error should mention unresolved discrepancies');
        }
        Test.stopTest();
    }

    @isTest
    static void testValidApprovalPopulatesAuditFields() {
        Property__c prop = TaxTestDataFactory.createSampleProperty('CHN-VALID-001', 'Zone 5 - Royapuram', 'Residential', 1200, 'Self-Occupied');
        prop.Verification_Status__c = 'Verified';
        update prop;

        Tax_Assessment__c asm = TaxTestDataFactory.createAssessment(prop.Id, null, 12000, 'Submitted');

        Test.startTest();
        asm.Status__c = 'Approved';
        update asm;
        Test.stopTest();

        Tax_Assessment__c updatedAsm = [SELECT Status__c, Approval_Status__c, Approved_By__c, Approval_Date__c FROM Tax_Assessment__c WHERE Id = :asm.Id];
        System.assertEquals('Approved', updatedAsm.Approval_Status__c, 'Approval status should be set');
        System.assertEquals(UserInfo.getUserId(), updatedAsm.Approved_By__c, 'Approved_By should be current user');
        System.assertEquals(Date.today(), updatedAsm.Approval_Date__c, 'Approval date should be today');
    }
}
