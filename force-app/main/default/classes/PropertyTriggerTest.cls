@isTest
private class PropertyTriggerTest {

    @isTest
    static void testPropertyInsertAndAutoVerificationQueue() {
        Test.startTest();
        Property__c prop = new Property__c(
            Property_Number__c = 'chn-prop-1001 ',
            Property_Owner_Name__c = 'Ramesh Kumar',
            Building_Area_SqFt__c = 1500,
            Zone__c = 'Zone 5 - Royapuram',
            Property_Type__c = 'Residential',
            Occupancy_Type__c = 'Self-Occupied'
        );
        insert prop;
        Test.stopTest();

        Property__c queried = [
            SELECT Id, Property_Number__c, Verification_Priority_Score__c, Verification_Priority_Level__c
            FROM Property__c
            WHERE Id = :prop.Id
        ];

        System.assertEquals('CHN-PROP-1001', queried.Property_Number__c, 'Should trim and uppercase property number');
        System.assertNotEquals(null, queried.Verification_Priority_Score__c, 'Priority score should be computed');

        List<Verification_Request__c> vReqs = [
            SELECT Id, Property__c, Status__c, Request_Type__c
            FROM Verification_Request__c
            WHERE Property__c = :prop.Id
        ];
        System.assertEquals(1, vReqs.size(), 'Should automatically queue an initial verification request');
        System.assertEquals('Queued', vReqs[0].Status__c, 'Verification request should be queued');
    }

    @isTest
    static void testPropertyUpdateRecalculatesScore() {
        Property__c prop = TaxTestDataFactory.createSampleProperty('CHN-UPD-001', 'Zone 5 - Royapuram', 'Residential', 800, 'Self-Occupied');

        Decimal initialScore = [SELECT Verification_Priority_Score__c FROM Property__c WHERE Id = :prop.Id].Verification_Priority_Score__c;

        Test.startTest();
        // Change to high-value commercial with arrears
        prop.Property_Type__c = 'Commercial';
        prop.Building_Area_SqFt__c = 8500;
        prop.Outstanding_Dues__c = 65000;
        update prop;
        Test.stopTest();

        Property__c updatedProp = [SELECT Verification_Priority_Score__c, Verification_Priority_Level__c FROM Property__c WHERE Id = :prop.Id];
        System.assert(updatedProp.Verification_Priority_Score__c > initialScore, 'Score should increase after updating to commercial with dues');
    }

    @isTest
    static void testDuplicatePropertyNumberInBatch() {
        List<Property__c> batchProps = new List<Property__c>{
            new Property__c(Property_Number__c = 'CHN-DUP-001', Property_Owner_Name__c = 'A', Building_Area_SqFt__c = 1000),
            new Property__c(Property_Number__c = 'chn-dup-001', Property_Owner_Name__c = 'B', Building_Area_SqFt__c = 1200)
        };

        Test.startTest();
        try {
            insert batchProps;
            System.assert(false, 'Expected duplicate error');
        } catch (DmlException ex) {
            System.assert(ex.getMessage().contains('Duplicate Property Number'), 'Expected duplicate error message');
        }
        Test.stopTest();
    }

    @isTest
    static void testBulkInsert() {
        List<Property__c> bulkProps = new List<Property__c>();
        for (Integer i = 0; i < 100; i++) {
            bulkProps.add(new Property__c(
                Property_Number__c = 'CHN-BULK-PROP-' + i,
                Property_Owner_Name__c = 'Bulk Owner ' + i,
                Building_Area_SqFt__c = 1000 + i,
                Zone__c = 'Zone 5 - Royapuram',
                Property_Type__c = 'Residential',
                Occupancy_Type__c = 'Self-Occupied'
            ));
        }

        Test.startTest();
        insert bulkProps;
        Test.stopTest();

        Integer count = [SELECT count() FROM Property__c WHERE Property_Number__c LIKE 'CHN-BULK-PROP-%'];
        System.assertEquals(100, count, 'All 100 records should be inserted');
    }
}
