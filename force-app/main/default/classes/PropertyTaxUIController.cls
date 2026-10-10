/**
 * @description Lightning Controller supporting all Property Tax Lightning Web Components.
 * Exposes methods for property registration, instant tax estimation, simulated payment processing,
 * and real-time municipal dashboard KPI rollups.
 */
public with sharing class PropertyTaxUIController {

    @AuraEnabled(cacheable=true)
    public static Property__c getPropertyDetails(Id propertyId) {
        if (propertyId == null) {
            return null;
        }
        return [
            SELECT Id, Name, Property_Number__c, Property_Owner_Name__c, Owner_Email__c, Owner_Phone__c,
                   Property_Address__c, Zone__c, Ward__c, Street_Name__c, Property_Type__c,
                   Building_Area_SqFt__c, Number_of_Floors__c, Construction_Year__c, Occupancy_Type__c,
                   Property_Usage__c, Verification_Status__c, Verification_Priority_Score__c,
                   Verification_Priority_Level__c, Priority_Score_Reasons__c, Assessed_Annual_Tax__c,
                   Outstanding_Dues__c, Current_Assessment_Status__c
            FROM Property__c
            WHERE Id = :propertyId
            LIMIT 1
        ];
    }

    @AuraEnabled
    public static Id registerProperty(Property__c property) {
        if (property == null) {
            throw new AuraHandledException('Property details are required.');
        }

        try {
            if (Schema.sObjectType.Property__c.isCreateable()) {
                insert property;
                return property.Id;
            } else {
                throw new AuraHandledException('Insufficient permissions to register properties.');
            }
        } catch (Exception ex) {
            throw new AuraHandledException('Registration Error: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static TaxCalculationService.CalculationResult calculateEstimate(
        Decimal area,
        String zone,
        String propType,
        String propUsage,
        String occupancy,
        String financialYear
    ) {
        try {
            return TaxCalculationService.calculateTaxEstimator(
                area, zone, propType, propUsage, occupancy, financialYear
            );
        } catch (Exception ex) {
            throw new AuraHandledException('Calculation Error: ' + ex.getMessage());
        }
    }

    @AuraEnabled
    public static Tax_Payment__c processSimulatedPayment(
        Id assessmentId,
        Id propertyId,
        Decimal amount,
        String paymentMode,
        String payerName,
        String payerEmail
    ) {
        if (assessmentId == null || amount == null || amount <= 0) {
            throw new AuraHandledException('Assessment ID and positive payment amount are required.');
        }

        try {
            Tax_Payment__c pay = new Tax_Payment__c();
            pay.Tax_Assessment__c = assessmentId;
            pay.Property__c = propertyId;
            pay.Amount_Paid__c = amount;
            pay.Payment_Mode__c = String.isNotBlank(paymentMode) ? paymentMode : 'Online - UPI';
            pay.Payment_Status__c = 'Success';
            pay.Payer_Name__c = payerName;
            pay.Payer_Email__c = payerEmail;
            pay.Is_Simulated_Transaction__c = true;
            pay.Gateway_Transaction_Id__c = 'LWC-SIM-' + Crypto.getRandomLong();

            insert pay;

            return [
                SELECT Id, Name, Payment_Reference__c, Amount_Paid__c, Payment_Date__c,
                       Payment_Mode__c, Payment_Status__c, Receipt_Number__c, Is_Simulated_Transaction__c
                FROM Tax_Payment__c
                WHERE Id = :pay.Id
            ];
        } catch (Exception ex) {
            throw new AuraHandledException('Payment Error: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getMunicipalAdminMetrics() {
        Map<String, Object> metrics = new Map<String, Object>();

        // Total registered properties
        Integer totalProps = [SELECT count() FROM Property__c];
        metrics.put('totalProperties', totalProps);

        // Verification status breakdown
        Integer unverifiedCount = [SELECT count() FROM Property__c WHERE Verification_Status__c = 'Unverified'];
        Integer verifiedCount = [SELECT count() FROM Property__c WHERE Verification_Status__c = 'Verified'];
        Integer highPriorityCount = [SELECT count() FROM Property__c WHERE Verification_Priority_Level__c = 'High'];
        metrics.put('unverifiedCount', unverifiedCount);
        metrics.put('verifiedCount', verifiedCount);
        metrics.put('highPriorityCount', highPriorityCount);

        // Aggregate financial totals
        AggregateResult[] finTotals = [
            SELECT SUM(Total_Assessed_Tax__c) totalAssessed,
                   SUM(Paid_Amount__c) totalPaid,
                   SUM(Balance_Dues__c) totalDues
            FROM Tax_Assessment__c
        ];

        Decimal totalAssessed = (finTotals.size() > 0 && finTotals[0].get('totalAssessed') != null) ? (Decimal)finTotals[0].get('totalAssessed') : 0;
        Decimal totalCollected = (finTotals.size() > 0 && finTotals[0].get('totalPaid') != null) ? (Decimal)finTotals[0].get('totalPaid') : 0;
        Decimal totalDues = (finTotals.size() > 0 && finTotals[0].get('totalDues') != null) ? (Decimal)finTotals[0].get('totalDues') : 0;

        metrics.put('totalAssessedTax', totalAssessed);
        metrics.put('totalTaxCollected', totalCollected);
        metrics.put('outstandingTaxDues', totalDues);

        // Calculate collection efficiency percentage
        Decimal collectionEfficiency = totalAssessed > 0 ? ((totalCollected / totalAssessed) * 100).setScale(1) : 0;
        metrics.put('collectionEfficiency', collectionEfficiency);

        // Zone-wise distribution
        List<Map<String, Object>> zoneBreakdown = new List<Map<String, Object>>();
        AggregateResult[] zoneAggr = [
            SELECT Zone__c zone, count(Id) propCount, SUM(Outstanding_Dues__c) zoneDues
            FROM Property__c
            WHERE Zone__c != null
            GROUP BY Zone__c
            ORDER BY count(Id) DESC
            LIMIT 15
        ];

        for (AggregateResult ar : zoneAggr) {
            zoneBreakdown.add(new Map<String, Object>{
                'zone' => (String)ar.get('zone'),
                'count' => (Integer)ar.get('propCount'),
                'dues' => ar.get('zoneDues') != null ? (Decimal)ar.get('zoneDues') : 0
            });
        }
        metrics.put('zoneBreakdown', zoneBreakdown);

        return metrics;
    }

    @AuraEnabled
    public static Id submitDispute(
        Id assessmentId,
        Id propertyId,
        String reason,
        String description,
        Decimal claimedArea
    ) {
        if (assessmentId == null || String.isBlank(description)) {
            throw new AuraHandledException('Assessment ID and dispute description are required.');
        }

        try {
            Assessment_Dispute__c disp = new Assessment_Dispute__c();
            disp.Tax_Assessment__c = assessmentId;
            disp.Property__c = propertyId;
            disp.Dispute_Reason__c = String.isNotBlank(reason) ? reason : 'Incorrect Area Measurement';
            disp.Dispute_Description__c = description;
            disp.Claimed_Area_SqFt__c = claimedArea;
            disp.Status__c = 'Filed';

            insert disp;

            // Mark assessment as disputed
            Tax_Assessment__c a = new Tax_Assessment__c(Id = assessmentId, Status__c = 'Disputed');
            update a;

            return disp.Id;
        } catch (Exception ex) {
            throw new AuraHandledException('Dispute Filing Error: ' + ex.getMessage());
        }
    }
}
