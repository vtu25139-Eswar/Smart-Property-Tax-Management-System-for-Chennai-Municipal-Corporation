trigger TaxPaymentTrigger on Tax_Payment__c (before insert, after insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        TaxPaymentTriggerHandler.handleBeforeInsert(Trigger.new);
    } else if (Trigger.isAfter && Trigger.isInsert) {
        TaxPaymentTriggerHandler.handleAfterInsert(Trigger.new);
    }
}
