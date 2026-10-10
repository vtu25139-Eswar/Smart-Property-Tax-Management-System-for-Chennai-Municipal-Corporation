@isTest
private class PropertyVerificationScoreTest {

    @isTest
    static void testHighPriorityScoring() {
        Property__c prop = new Property__c(
            Property_Number__c = 'CHN-HIGH-001',
            Property_Owner_Name__c = 'Enterprise Holdings',
            Property_Type__c = 'Commercial',
            Property_Usage__c = 'Corporate Office',
            Building_Area_SqFt__c = 12000,
            Construction_Year__c = 1960,
            Outstanding_Dues__c = 75000,
            Verification_Status__c = 'Unverified'
            // Missing email and phone
        );

        Test.startTest();
        PropertyVerificationScoreService.ScoreDetail detail = PropertyVerificationScoreService.evaluateProperty(prop);
        Test.stopTest();

        System.assertNotEquals(null, detail, 'Score detail should not be null');
        System.assert(detail.score >= 65, 'High risk factors should produce score >= 65, actual: ' + detail.score);
        System.assertEquals('High', detail.level, 'Priority tier should be High');
        System.assert(detail.reasons.contains('Administrative Review Factors'), 'Reasons should contain itemized breakdown');
    }

    @isTest
    static void testLowPriorityScoring() {
        Property__c prop = new Property__c(
            Property_Number__c = 'CHN-LOW-001',
            Property_Owner_Name__c = 'Anand Kumar',
            Owner_Email__c = 'anand@example.com',
            Owner_Phone__c = '+91 98401 99999',
            Property_Address__c = 'No. 10, Anna Salai',
            Street_Name__c = 'Anna Salai',
            Property_Type__c = 'Residential',
            Building_Area_SqFt__c = 900,
            Construction_Year__c = 2020,
            Outstanding_Dues__c = 0,
            Verification_Status__c = 'Verified'
        );

        Test.startTest();
        PropertyVerificationScoreService.ScoreDetail detail = PropertyVerificationScoreService.evaluateProperty(prop);
        Test.stopTest();

        System.assert(detail.score < 30, 'Clean verified record should have low score < 30, actual: ' + detail.score);
        System.assertEquals('Low', detail.level, 'Priority tier should be Low');
    }

    @isTest
    static void testBulkScoreCalculation() {
        List<Property__c> properties = new List<Property__c>();
        for (Integer i = 0; i < 50; i++) {
            properties.add(new Property__c(
                Property_Number__c = 'CHN-BULK-' + i,
                Property_Owner_Name__c = 'Owner ' + i,
                Building_Area_SqFt__c = 1000 + (i * 100),
                Verification_Status__c = Math.mod(i, 2) == 0 ? 'Unverified' : 'Verified'
            ));
        }

        Test.startTest();
        PropertyVerificationScoreService.calculateScores(properties);
        Test.stopTest();

        for (Property__c p : properties) {
            System.assertNotEquals(null, p.Verification_Priority_Score__c, 'Score must be populated');
            System.assertNotEquals(null, p.Verification_Priority_Level__c, 'Level must be populated');
            System.assertNotEquals(null, p.Priority_Score_Reasons__c, 'Reasons must be populated');
        }
    }
}
