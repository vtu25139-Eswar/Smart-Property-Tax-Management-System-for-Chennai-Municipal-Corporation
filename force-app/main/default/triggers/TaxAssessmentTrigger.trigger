trigger TaxAssessmentTrigger on Tax_Assessment__c (before insert, before update, after insert, after update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        TaxAssessmentTriggerHandler.handleBeforeInsert(Trigger.new);
    } else if (Trigger.isBefore && Trigger.isUpdate) {
        TaxAssessmentTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    } else if (Trigger.isAfter && Trigger.isInsert) {
        TaxAssessmentTriggerHandler.handleAfterInsert(Trigger.new);
    } else if (Trigger.isAfter && Trigger.isUpdate) {
        TaxAssessmentTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}
