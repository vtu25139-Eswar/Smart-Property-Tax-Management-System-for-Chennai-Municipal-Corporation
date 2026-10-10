/**
 * @description Trigger Handler for Property__c object.
 * Manages priority score calculation, duplicate validation, and auto-creation of verification work items.
 */
public with sharing class PropertyTriggerHandler {

    private static Boolean isExecuting = false;

    public static void handleBeforeInsert(List<Property__c> newRecords) {
        formatAndValidatePropertyNumbers(newRecords);
        PropertyVerificationScoreService.calculateScores(newRecords);
    }

    public static void handleBeforeUpdate(List<Property__c> newRecords, Map<Id, Property__c> oldMap) {
        List<Property__c> changedProperties = new List<Property__c>();
        for (Property__c p : newRecords) {
            Property__c oldP = oldMap.get(p.Id);
            if (p.Building_Area_SqFt__c != oldP.Building_Area_SqFt__c ||
                p.Property_Type__c != oldP.Property_Type__c ||
                p.Verification_Status__c != oldP.Verification_Status__c ||
                p.Outstanding_Dues__c != oldP.Outstanding_Dues__c ||
                p.Owner_Email__c != oldP.Owner_Email__c ||
                p.Owner_Phone__c != oldP.Owner_Phone__c ||
                p.Property_Address__c != oldP.Property_Address__c) {
                changedProperties.add(p);
            }
        }

        if (!changedProperties.isEmpty()) {
            PropertyVerificationScoreService.calculateScores(changedProperties);
        }
    }

    public static void handleAfterInsert(List<Property__c> newRecords) {
        if (isExecuting) {
            return;
        }
        isExecuting = true;

        List<Verification_Request__c> verificationsToInsert = new List<Verification_Request__c>();

        for (Property__c p : newRecords) {
            // Automatically queue initial municipal verification request
            Verification_Request__c vReq = new Verification_Request__c();
            vReq.Property__c = p.Id;
            vReq.Request_Type__c = 'New Property Registration';
            vReq.Status__c = 'Queued';
            vReq.Priority_Score__c = p.Verification_Priority_Score__c;
            vReq.Priority_Level__c = p.Verification_Priority_Level__c;
            vReq.Inspector_Remarks__c = 'Auto-generated verification task for registered property ' + p.Property_Number__c;
            verificationsToInsert.add(vReq);
        }

        if (!verificationsToInsert.isEmpty() && Schema.sObjectType.Verification_Request__c.isCreateable()) {
            insert verificationsToInsert;
        }

        isExecuting = false;
    }

    private static void formatAndValidatePropertyNumbers(List<Property__c> records) {
        Set<String> incomingNumbers = new Set<String>();

        for (Property__c p : records) {
            if (String.isNotBlank(p.Property_Number__c)) {
                p.Property_Number__c = p.Property_Number__c.trim().toUpperCase();

                if (incomingNumbers.contains(p.Property_Number__c)) {
                    p.Property_Number__c.addError('Duplicate Property Number detected within the batch: ' + p.Property_Number__c);
                } else {
                    incomingNumbers.add(p.Property_Number__c);
                }
            } else {
                p.Property_Number__c.addError('Property Number is required.');
            }
        }
    }
}
