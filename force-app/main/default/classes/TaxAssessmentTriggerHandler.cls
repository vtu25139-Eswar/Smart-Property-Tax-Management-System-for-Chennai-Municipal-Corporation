/**
 * @description Trigger Handler for Tax_Assessment__c object.
 * Enforces business validation, prevents approval of disputed/discrepancy properties,
 * calculates net balance dues, and syncs totals to the parent Property.
 */
public with sharing class TaxAssessmentTriggerHandler {

    private static Boolean isExecuting = false;

    public static void handleBeforeInsert(List<Tax_Assessment__c> newRecords) {
        populateDefaultsAndBalance(newRecords);
    }

    public static void handleBeforeUpdate(List<Tax_Assessment__c> newRecords, Map<Id, Tax_Assessment__c> oldMap) {
        validateApprovalRules(newRecords, oldMap);
        populateDefaultsAndBalance(newRecords);
    }

    public static void handleAfterInsert(List<Tax_Assessment__c> newRecords) {
        if (isExecuting) return;
        isExecuting = true;
        syncTotalsToProperty(newRecords);
        isExecuting = false;
    }

    public static void handleAfterUpdate(List<Tax_Assessment__c> newRecords, Map<Id, Tax_Assessment__c> oldMap) {
        if (isExecuting) return;
        isExecuting = true;
        syncTotalsToProperty(newRecords);
        isExecuting = false;
    }

    private static void populateDefaultsAndBalance(List<Tax_Assessment__c> records) {
        for (Tax_Assessment__c a : records) {
            if (a.Assessment_Date__c == null) {
                a.Assessment_Date__c = Date.today();
            }
            if (a.Due_Date__c == null) {
                a.Due_Date__c = Date.today().addDays(60);
            }
            if (a.Paid_Amount__c == null) {
                a.Paid_Amount__c = 0;
            }
            if (a.Total_Assessed_Tax__c == null) {
                a.Total_Assessed_Tax__c = 0;
            }

            // Calculate balance dues
            Decimal balance = a.Total_Assessed_Tax__c - a.Paid_Amount__c;
            a.Balance_Dues__c = balance > 0 ? balance : 0;

            // If fully paid, mark status
            if (a.Balance_Dues__c == 0 && a.Paid_Amount__c > 0 && a.Status__c != 'Disputed') {
                a.Status__c = 'Paid';
            }
        }
    }

    private static void validateApprovalRules(List<Tax_Assessment__c> records, Map<Id, Tax_Assessment__c> oldMap) {
        Set<Id> propIdsToCheck = new Set<Id>();

        for (Tax_Assessment__c a : records) {
            Tax_Assessment__c oldA = oldMap.get(a.Id);
            if (a.Status__c == 'Approved' && oldA.Status__c != 'Approved') {
                propIdsToCheck.add(a.Property__c);
            }
        }

        if (propIdsToCheck.isEmpty()) {
            return;
        }

        Map<Id, Property__c> propMap = new Map<Id, Property__c>([
            SELECT Id, Property_Number__c, Verification_Status__c
            FROM Property__c
            WHERE Id IN :propIdsToCheck
        ]);

        for (Tax_Assessment__c a : records) {
            Tax_Assessment__c oldA = oldMap.get(a.Id);
            if (a.Status__c == 'Approved' && oldA.Status__c != 'Approved') {
                Property__c parentProp = propMap.get(a.Property__c);
                if (parentProp != null && parentProp.Verification_Status__c == 'Discrepancy Flagged') {
                    a.addError('Cannot approve assessment for Property ' + parentProp.Property_Number__c +
                               ': Physical verification has flagged unresolved area or usage discrepancies.');
                }

                // Record audit fields
                if (a.Approved_By__c == null) {
                    a.Approved_By__c = UserInfo.getUserId();
                }
                if (a.Approval_Date__c == null) {
                    a.Approval_Date__c = Date.today();
                }
                a.Approval_Status__c = 'Approved';
            }
        }
    }

    private static void syncTotalsToProperty(List<Tax_Assessment__c> records) {
        Set<Id> propIds = new Set<Id>();
        for (Tax_Assessment__c a : records) {
            if (a.Property__c != null) {
                propIds.add(a.Property__c);
            }
        }

        if (propIds.isEmpty()) return;

        List<Tax_Assessment__c> allAssessments = [
            SELECT Id, Property__c, Total_Assessed_Tax__c, Balance_Dues__c, Status__c, CreatedDate
            FROM Tax_Assessment__c
            WHERE Property__c IN :propIds
            ORDER BY CreatedDate DESC
        ];

        Map<Id, Decimal> propOutstandingMap = new Map<Id, Decimal>();
        Map<Id, Decimal> propLatestTaxMap = new Map<Id, Decimal>();
        Map<Id, String> propLatestStatusMap = new Map<Id, String>();

        for (Tax_Assessment__c a : allAssessments) {
            // Sum total outstanding dues
            Decimal curOutstanding = propOutstandingMap.containsKey(a.Property__c) ? propOutstandingMap.get(a.Property__c) : 0;
            propOutstandingMap.put(a.Property__c, curOutstanding + (a.Balance_Dues__c != null ? a.Balance_Dues__c : 0));

            // Keep latest annual tax and assessment status
            if (!propLatestTaxMap.containsKey(a.Property__c)) {
                propLatestTaxMap.put(a.Property__c, a.Total_Assessed_Tax__c != null ? a.Total_Assessed_Tax__c : 0);
                propLatestStatusMap.put(a.Property__c, a.Status__c == 'Approved' ? 'Assessed & Active' :
                                                        (a.Status__c == 'Disputed' ? 'Under Dispute' : 'Pending Approval'));
            }
        }

        List<Property__c> propertiesToUpdate = new List<Property__c>();
        for (Id propId : propIds) {
            Property__c p = new Property__c(Id = propId);
            p.Outstanding_Dues__c = propOutstandingMap.containsKey(propId) ? propOutstandingMap.get(propId) : 0;
            if (propLatestTaxMap.containsKey(propId)) {
                p.Assessed_Annual_Tax__c = propLatestTaxMap.get(propId);
            }
            if (propLatestStatusMap.containsKey(propId)) {
                p.Current_Assessment_Status__c = propLatestStatusMap.get(propId);
            }
            propertiesToUpdate.add(p);
        }

        if (!propertiesToUpdate.isEmpty() && Schema.sObjectType.Property__c.isUpdateable()) {
            update propertiesToUpdate;
        }
    }
}
