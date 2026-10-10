/**
 * @description Administrative Scoring Service for Chennai Municipal Corporation.
 * Evaluates property data completeness, size, tax arrears, and inspection status
 * to calculate an objective 0-100 verification priority score with transparent explanations.
 */
public with sharing class PropertyVerificationScoreService {

    public class ScoreDetail {
        public Decimal score { get; set; }
        public String level { get; set; }
        public String reasons { get; set; }

        public ScoreDetail(Decimal score, String level, String reasons) {
            this.score = score;
            this.level = level;
            this.reasons = reasons;
        }
    }

    /**
     * @description Bulk score calculation for a list of Property records.
     * Updates the score, priority level, and explanation fields on the records.
     */
    public static void calculateScores(List<Property__c> properties) {
        if (properties == null || properties.isEmpty()) {
            return;
        }

        Integer currentYear = Date.today().year();

        for (Property__c prop : properties) {
            Decimal score = 0;
            List<String> factorList = new List<String>();

            // Factor 1: Verification Status
            if (String.isBlank(prop.Verification_Status__c) || 'Unverified'.equalsIgnoreCase(prop.Verification_Status__c)) {
                score += 25;
                factorList.add('+25: Initial registration pending physical/documentary verification.');
            } else if ('Discrepancy Flagged'.equalsIgnoreCase(prop.Verification_Status__c)) {
                score += 30;
                factorList.add('+30: Active discrepancy flagged during municipal inspection.');
            } else if ('Needs Re-Inspection'.equalsIgnoreCase(prop.Verification_Status__c)) {
                score += 20;
                factorList.add('+20: Property marked for municipal re-inspection.');
            }

            // Factor 2: Missing Contact / Address Information
            if (String.isBlank(prop.Owner_Email__c)) {
                score += 10;
                factorList.add('+10: Missing property owner email address.');
            }
            if (String.isBlank(prop.Owner_Phone__c)) {
                score += 10;
                factorList.add('+10: Missing property owner telephone contact.');
            }
            if (String.isBlank(prop.Street_Name__c) && String.isBlank(prop.Property_Address__c)) {
                score += 10;
                factorList.add('+10: Incomplete street / address specification.');
            }

            // Factor 3: High-Value Commercial / Large Plinth Area
            if (prop.Building_Area_SqFt__c != null && prop.Building_Area_SqFt__c >= 5000) {
                score += 15;
                factorList.add('+15: Large plinth area (' + prop.Building_Area_SqFt__c + ' sq ft) requires on-site audit.');
            }
            if ('Commercial'.equalsIgnoreCase(prop.Property_Type__c) || 'Industrial'.equalsIgnoreCase(prop.Property_Type__c)) {
                score += 15;
                factorList.add('+15: High-revenue commercial/industrial tax classification.');
            }

            // Factor 4: Significant Outstanding Arrears
            if (prop.Outstanding_Dues__c != null && prop.Outstanding_Dues__c >= 50000) {
                score += 20;
                factorList.add('+20: Substantial municipal tax arrears (>= ₹50,000).');
            } else if (prop.Outstanding_Dues__c != null && prop.Outstanding_Dues__c >= 10000) {
                score += 10;
                factorList.add('+10: Pending municipal tax arrears (>= ₹10,000).');
            }

            // Factor 5: Vintage / Structural Age Baseline
            if (prop.Construction_Year__c == null) {
                score += 10;
                factorList.add('+10: Construction year unrecorded.');
            } else if ((currentYear - prop.Construction_Year__c) >= 50) {
                score += 10;
                factorList.add('+10: Vintage heritage building (> 50 years structural age).');
            }

            // Cap maximum score at 100
            if (score > 100) {
                score = 100;
            }

            // Determine Priority Tier
            String level = 'Low';
            if (score >= 65) {
                level = 'High';
            } else if (score >= 30) {
                level = 'Medium';
            }

            String summaryText = 'Priority Score: ' + score + '/100 (' + level + ' Priority)\n' +
                'Administrative Review Factors:\n- ' + String.join(factorList, '\n- ') +
                '\n\nNotice: This score is an administrative prioritization aid, not proof of irregularity.';

            prop.Verification_Priority_Score__c = score;
            prop.Verification_Priority_Level__c = level;
            prop.Priority_Score_Reasons__c = summaryText;
        }
    }

    /**
     * @description Helper to evaluate a single property and return details without modifying.
     */
    public static ScoreDetail evaluateProperty(Property__c prop) {
        List<Property__c> tempList = new List<Property__c>{ prop.clone(true, true, true, true) };
        calculateScores(tempList);
        return new ScoreDetail(
            tempList[0].Verification_Priority_Score__c,
            tempList[0].Verification_Priority_Level__c,
            tempList[0].Priority_Score_Reasons__c
        );
    }
}
