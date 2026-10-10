trigger PropertyTrigger on Property__c (before insert, before update, after insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        PropertyTriggerHandler.handleBeforeInsert(Trigger.new);
    } else if (Trigger.isBefore && Trigger.isUpdate) {
        PropertyTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    } else if (Trigger.isAfter && Trigger.isInsert) {
        PropertyTriggerHandler.handleAfterInsert(Trigger.new);
    }
}
