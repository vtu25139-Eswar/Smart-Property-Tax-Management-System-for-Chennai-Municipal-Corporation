@isTest
private class TaxPaymentTriggerTest {

    @testSetup
    static void setup() {
        TaxTestDataFactory.createTaxRates();
    }

    @isTest
    static void testPaymentUpdatesAssessmentAndRollsUp() {
        Property__c prop = TaxTestDataFactory.createSampleProperty('CHN-PAY-001', 'Zone 5 - Royapuram', 'Residential', 1000, 'Self-Occupied');
        Tax_Assessment__c asm = TaxTestDataFactory.createAssessment(prop.Id, null, 10000, 'Approved');

        Test.startTest();
        Tax_Payment__c pay1 = new Tax_Payment__c(
            Tax_Assessment__c = asm.Id,
            Property__c = prop.Id,
            Amount_Paid__c = 6000,
            Payment_Mode__c = 'Online - UPI',
            Payment_Status__c = 'Success'
        );
        insert pay1;
        Test.stopTest();

        Tax_Payment__c queriedPay = [
            SELECT Id, Payment_Reference__c, Gateway_Transaction_Id__c, Is_Simulated_Transaction__c
            FROM Tax_Payment__c
            WHERE Id = :pay1.Id
        ];
        System.assert(queriedPay.Payment_Reference__c.startsWith('PAY-CHN-'), 'Payment reference format should match');
        System.assert(queriedPay.Is_Simulated_Transaction__c, 'Should be flagged as simulated');

        Tax_Assessment__c updatedAsm = [
            SELECT Paid_Amount__c, Balance_Dues__c, Status__c
            FROM Tax_Assessment__c
            WHERE Id = :asm.Id
        ];
        System.assertEquals(6000, updatedAsm.Paid_Amount__c, 'Paid amount should be 6000');
        System.assertEquals(4000, updatedAsm.Balance_Dues__c, 'Balance dues should be 4000');
        System.assertNotEquals('Paid', updatedAsm.Status__c, 'Partial payment should not mark as Paid');
    }

    @isTest
    static void testFullPaymentMarksAssessmentPaid() {
        Property__c prop = TaxTestDataFactory.createSampleProperty('CHN-PAY-002', 'Zone 5 - Royapuram', 'Residential', 1000, 'Self-Occupied');
        Tax_Assessment__c asm = TaxTestDataFactory.createAssessment(prop.Id, null, 5000, 'Approved');

        Test.startTest();
        Tax_Payment__c pay = new Tax_Payment__c(
            Tax_Assessment__c = asm.Id,
            Property__c = prop.Id,
            Amount_Paid__c = 5000,
            Payment_Mode__c = 'Credit/Debit Card',
            Payment_Status__c = 'Success'
        );
        insert pay;
        Test.stopTest();

        Tax_Assessment__c updatedAsm = [
            SELECT Paid_Amount__c, Balance_Dues__c, Status__c
            FROM Tax_Assessment__c
            WHERE Id = :asm.Id
        ];
        System.assertEquals(5000, updatedAsm.Paid_Amount__c, 'Paid amount should be 5000');
        System.assertEquals(0, updatedAsm.Balance_Dues__c, 'Balance dues should be 0');
        System.assertEquals('Paid', updatedAsm.Status__c, 'Assessment should be marked Paid');
    }

    @isTest
    static void testInvalidPaymentAmountThrowsError() {
        Property__c prop = TaxTestDataFactory.createSampleProperty('CHN-PAY-003', 'Zone 5 - Royapuram', 'Residential', 1000, 'Self-Occupied');
        Tax_Assessment__c asm = TaxTestDataFactory.createAssessment(prop.Id, null, 5000, 'Approved');

        Test.startTest();
        try {
            Tax_Payment__c pay = new Tax_Payment__c(
                Tax_Assessment__c = asm.Id,
                Property__c = prop.Id,
                Amount_Paid__c = -100
            );
            insert pay;
            System.assert(false, 'Expected negative payment to fail');
        } catch (DmlException ex) {
            System.assert(ex.getMessage().contains('greater than zero'), 'Should reject non-positive payment');
        }
        Test.stopTest();
    }
}
