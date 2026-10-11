/**
 * @description Trigger Handler for Tax_Payment__c object.
 * Processes municipal payments (including simulated online/counter collections),
 * generates secure reference IDs, and updates assessment paid totals and balances.
 */
public with sharing class TaxPaymentTriggerHandler {

    private static Boolean isExecuting = false;

    public static void handleBeforeInsert(List<Tax_Payment__c> newRecords) {
        for (Tax_Payment__c pay : newRecords) {
            if (pay.Amount_Paid__c == null || pay.Amount_Paid__c <= 0) {
                pay.Amount_Paid__c.addError('Payment amount must be greater than zero.');
            }

            if (pay.Payment_Date__c == null) {
                pay.Payment_Date__c = DateTime.now();
            }

            if (String.isBlank(pay.Payment_Reference__c)) {
                String randSuffix = String.valueOf(Math.abs(Crypto.getRandomInteger())).substring(0, 6);
                pay.Payment_Reference__c = 'PAY-CHN-' + DateTime.now().format('yyyyMMdd') + '-' + randSuffix;
            }

            if (String.isBlank(pay.Receipt_Number__c)) {
                pay.Receipt_Number__c = pay.Payment_Reference__c;
            }

            if (String.isBlank(pay.Gateway_Transaction_Id__c)) {
                pay.Gateway_Transaction_Id__c = 'TXN-SIM-' + Crypto.getRandomLong();
            }

            if (String.isBlank(pay.Gateway_Response__c)) {
                pay.Gateway_Response__c = '{"status":"SUCCESS","gateway":"CHENNAI_MUNI_DEMO_SANDBOX","code":"200","message":"Simulated Tax Receipt Authorized"}';
            }
        }
    }

    public static void handleAfterInsert(List<Tax_Payment__c> newRecords) {
        if (isExecuting) return;
        isExecuting = true;

        Set<Id> assessmentIds = new Set<Id>();
        for (Tax_Payment__c pay : newRecords) {
            if (pay.Tax_Assessment__c != null && 'Success'.equalsIgnoreCase(pay.Payment_Status__c)) {
                assessmentIds.add(pay.Tax_Assessment__c);
            }
        }

        if (assessmentIds.isEmpty()) {
            isExecuting = false;
            return;
        }

        List<Tax_Assessment__c> assessments = [
            SELECT Id, Total_Assessed_Tax__c, Paid_Amount__c, Balance_Dues__c, Status__c, Property__c,
                   (SELECT Amount_Paid__c FROM Tax_Payments__r WHERE Payment_Status__c = 'Success')
            FROM Tax_Assessment__c
            WHERE Id IN :assessmentIds
        ];

        List<Tax_Assessment__c> assessmentsToUpdate = new List<Tax_Assessment__c>();
        for (Tax_Assessment__c a : assessments) {
            Decimal totalPaid = 0;
            for (Tax_Payment__c p : a.Tax_Payments__r) {
                if (p.Amount_Paid__c != null) {
                    totalPaid += p.Amount_Paid__c;
                }
            }

            a.Paid_Amount__c = totalPaid;
            Decimal balance = (a.Total_Assessed_Tax__c != null ? a.Total_Assessed_Tax__c : 0) - totalPaid;
            a.Balance_Dues__c = balance > 0 ? balance : 0;

            if (a.Balance_Dues__c == 0 && a.Status__c != 'Disputed') {
                a.Status__c = 'Paid';
            }

            assessmentsToUpdate.add(a);
        }

        if (!assessmentsToUpdate.isEmpty() && Schema.sObjectType.Tax_Assessment__c.isUpdateable()) {
            update assessmentsToUpdate;
        }

        isExecuting = false;
    }
}
