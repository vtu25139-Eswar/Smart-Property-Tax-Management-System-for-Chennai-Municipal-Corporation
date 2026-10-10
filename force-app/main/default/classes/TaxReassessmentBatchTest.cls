@isTest
private class TaxReassessmentBatchTest {

    @testSetup
    static void setup() {
        TaxTestDataFactory.createTaxRates();
        List<Property__c> props = new List<Property__c>();
        for (Integer i = 0; i < 10; i++) {
            props.add(new Property__c(
                Property_Number__c = 'CHN-BATCH-' + i,
                Property_Owner_Name__c = 'Batch Owner ' + i,
                Building_Area_SqFt__c = 1000 + (i * 100),
                Zone__c = 'Zone 5 - Royapuram',
                Property_Type__c = 'Residential',
                Occupancy_Type__c = 'Self-Occupied'
            ));
        }
        insert props;
    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();
        TaxReassessmentBatch batch = new TaxReassessmentBatch('2025-2026', 'Zone 5 - Royapuram');
        Database.executeBatch(batch, 10);
        Test.stopTest();

        List<Tax_Assessment__c> createdAssessments = [
            SELECT Id, Assessment_Year__c, Total_Assessed_Tax__c
            FROM Tax_Assessment__c
            WHERE Assessment_Year__c = '2025-2026'
        ];
        System.assertEquals(10, createdAssessments.size(), 'Batch should create assessments for all 10 properties');
        for (Tax_Assessment__c a : createdAssessments) {
            System.assert(a.Total_Assessed_Tax__c > 0, 'Assessed tax should be greater than zero');
        }
    }

    @isTest
    static void testSchedulers() {
        Test.startTest();
        // Schedule batch
        String cronExpBatch = '0 0 1 * * ?';
        String jobId1 = System.schedule('Test Tax Reassessment Job', cronExpBatch, new TaxReassessmentBatch());
        System.assertNotEquals(null, jobId1, 'Batch schedule job ID should not be null');

        // Schedule overdue auditor
        String cronExpOverdue = '0 0 2 * * ?';
        String jobId2 = System.schedule('Test Tax Overdue Auditor', cronExpOverdue, new TaxOverdueScheduler());
        System.assertNotEquals(null, jobId2, 'Overdue scheduler job ID should not be null');
        Test.stopTest();
    }
}
