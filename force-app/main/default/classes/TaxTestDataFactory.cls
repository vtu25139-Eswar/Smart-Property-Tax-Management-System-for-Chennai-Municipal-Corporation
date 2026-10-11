/**
 * @description Test Data Factory providing reusable test records across all test classes.
 */
@isTest
public class TaxTestDataFactory {

    public static List<Tax_Rate__c> createTaxRates() {
        List<Tax_Rate__c> rates = new List<Tax_Rate__c>{
            new Tax_Rate__c(
                Name = 'RATE-TEST-RES-ZN05',
                Zone__c = 'Zone 5 - Royapuram',
                Property_Type__c = 'Residential',
                Property_Usage__c = 'Residential Individual',
                Financial_Year__c = '2025-2026',
                Base_Rate_Per_SqFt__c = 15.00,
                Education_Cess_Percent__c = 5.00,
                Library_Cess_Percent__c = 10.00,
                Maintenance_Rebate_Percent__c = 10.00,
                Penalty_Rate_Percent__c = 2.00,
                Is_Active__c = true
            ),
            new Tax_Rate__c(
                Name = 'RATE-TEST-COMM-ALL',
                Zone__c = 'All Zones',
                Property_Type__c = 'Commercial',
                Property_Usage__c = 'Retail Commercial',
                Financial_Year__c = '2025-2026',
                Base_Rate_Per_SqFt__c = 35.00,
                Education_Cess_Percent__c = 5.00,
                Library_Cess_Percent__c = 10.00,
                Maintenance_Rebate_Percent__c = 0.00,
                Penalty_Rate_Percent__c = 5.00,
                Is_Active__c = true
            )
        };
        for (Tax_Rate__c r : rates) {
            r.Usage_Type__c = 'Residential, Commercial, Industrial, Mixed Use';
            r.Rate_Per_Sq_Ft__c = r.Base_Rate_Per_SqFt__c;
            r.Effective_From__c = Date.newInstance(2025, 4, 1);
            r.Active__c = true;
        }
        insert rates;
        return rates;
    }

    public static Property__c createSampleProperty(String propNumber, String zone, String propType, Decimal area, String occupancy) {
        Property__c p = new Property__c(
            Property_Number__c = propNumber,
            Property_Owner_Name__c = 'Karthik Subramanian',
            Owner_Email__c = 'karthik.subramanian@example.com',
            Owner_Phone__c = '+91 98401 23456',
            Property_Address__c = 'No. 42, Usman Road, T. Nagar, Chennai',
            Zone__c = String.isNotBlank(zone) ? zone : 'Zone 5 - Royapuram',
            Ward__c = 'Ward 114',
            Street_Name__c = 'Usman Road',
            Property_Type__c = String.isNotBlank(propType) ? propType : 'Residential',
            Building_Area_SqFt__c = area != null ? area : 1200,
            Number_of_Floors__c = 2,
            Construction_Year__c = 2018,
            Occupancy_Type__c = String.isNotBlank(occupancy) ? occupancy : 'Self-Occupied',
            Property_Usage__c = 'Residential Individual',
            Verification_Status__c = 'Unverified'
        );
        p.Area_in_Sq_Ft__c = p.Building_Area_SqFt__c;
        insert p;
        return p;
    }

    public static Tax_Assessment__c createAssessment(Id propId, Id taxRateId, Decimal taxAmount, String status) {
        Tax_Assessment__c a = new Tax_Assessment__c(
            Property__c = propId,
            Assessment_Year__c = '2025-2026',
            Assessment_Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(60),
            Assessed_Area_SqFt__c = 1200,
            Tax_Rate__c = taxRateId,
            Applied_Base_Rate__c = 15.00,
            Base_Property_Tax__c = 18000,
            Rebate_Concession_Amount__c = 1800,
            Education_Cess_Amount__c = 810,
            Library_Cess_Amount__c = 1620,
            Total_Assessed_Tax__c = taxAmount != null ? taxAmount : 18630,
            Status__c = String.isNotBlank(status) ? status : 'Submitted',
            Approval_Status__c = 'Pending Approval',
            Calculation_Explanation__c = 'Test assessment calculation explanation.'
        );
        insert a;
        return a;
    }

    public static Tax_Payment__c createPayment(Id assessmentId, Id propId, Decimal amount) {
        Tax_Payment__c pay = new Tax_Payment__c(
            Tax_Assessment__c = assessmentId,
            Property__c = propId,
            Payment_Reference__c = 'PAY-TEST-' + Math.abs(Crypto.getRandomInteger()),
            Amount_Paid__c = amount,
            Payment_Mode__c = 'Online - UPI',
            Payment_Status__c = 'Success',
            Payer_Name__c = 'Karthik Subramanian',
            Payer_Email__c = 'karthik.subramanian@example.com',
            Is_Simulated_Transaction__c = true
        );
        insert pay;
        return pay;
    }
}
