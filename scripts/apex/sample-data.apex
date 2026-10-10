/**
 * Greater Chennai Corporation - Property Tax Management System
 * Comprehensive Seed Data Generation Script for Demonstration
 * Execute via Developer Console Anonymous Apex or `sf apex run -f scripts/apex/sample-data.apex`
 */

System.debug('=== INITIATING CHENNAI PROPERTY TAX SEED DATA ===');

// 1. Clean existing demo data safely
delete [SELECT Id FROM Assessment_Dispute__c LIMIT 200];
delete [SELECT Id FROM Tax_Payment__c LIMIT 200];
delete [SELECT Id FROM Tax_Assessment__c LIMIT 200];
delete [SELECT Id FROM Verification_Request__c LIMIT 200];
delete [SELECT Id FROM Property__c WHERE Property_Number__c LIKE 'CHN-%' LIMIT 200];
delete [SELECT Id FROM Tax_Rate__c WHERE Name LIKE 'RATE-2025-%' LIMIT 200];

// 2. Insert Illustrative Municipal Tax Rates
List<Tax_Rate__c> rateList = new List<Tax_Rate__c>{
    new Tax_Rate__c(
        Name = 'RATE-2025-RES-ZN05',
        Zone__c = 'Zone 5 - Royapuram',
        Property_Type__c = 'Residential',
        Property_Usage__c = 'Residential Individual',
        Financial_Year__c = '2025-2026',
        Base_Rate_Per_SqFt__c = 12.00,
        Education_Cess_Percent__c = 5.00,
        Library_Cess_Percent__c = 10.00,
        Maintenance_Rebate_Percent__c = 10.00,
        Penalty_Rate_Percent__c = 2.00,
        Is_Active__c = true,
        Description__c = 'Royapuram Zone Residential Schedule (GCC Gazetted Notification)'
    ),
    new Tax_Rate__c(
        Name = 'RATE-2025-RES-ZN08',
        Zone__c = 'Zone 8 - Annanagar',
        Property_Type__c = 'Residential',
        Property_Usage__c = 'Residential Individual',
        Financial_Year__c = '2025-2026',
        Base_Rate_Per_SqFt__c = 18.00,
        Education_Cess_Percent__c = 5.00,
        Library_Cess_Percent__c = 10.00,
        Maintenance_Rebate_Percent__c = 10.00,
        Penalty_Rate_Percent__c = 2.00,
        Is_Active__c = true,
        Description__c = 'Anna Nagar Prime Residential Schedule'
    ),
    new Tax_Rate__c(
        Name = 'RATE-2025-COMM-ZN10',
        Zone__c = 'Zone 10 - Kodambakkam',
        Property_Type__c = 'Commercial',
        Property_Usage__c = 'Retail Commercial',
        Financial_Year__c = '2025-2026',
        Base_Rate_Per_SqFt__c = 40.00,
        Education_Cess_Percent__c = 5.00,
        Library_Cess_Percent__c = 10.00,
        Maintenance_Rebate_Percent__c = 0.00,
        Penalty_Rate_Percent__c = 5.00,
        Is_Active__c = true,
        Description__c = 'T. Nagar Commercial & Retail Hub Schedule'
    ),
    new Tax_Rate__c(
        Name = 'RATE-2025-COMM-ZN15',
        Zone__c = 'Zone 15 - Sholinganallur',
        Property_Type__c = 'Commercial',
        Property_Usage__c = 'Corporate Office',
        Financial_Year__c = '2025-2026',
        Base_Rate_Per_SqFt__c = 32.00,
        Education_Cess_Percent__c = 5.00,
        Library_Cess_Percent__c = 10.00,
        Maintenance_Rebate_Percent__c = 0.00,
        Penalty_Rate_Percent__c = 4.00,
        Is_Active__c = true,
        Description__c = 'OMR IT Corridor Corporate Office Schedule'
    ),
    new Tax_Rate__c(
        Name = 'RATE-2025-RES-ALL',
        Zone__c = 'All Zones',
        Property_Type__c = 'Residential',
        Property_Usage__c = 'Residential Individual',
        Financial_Year__c = '2025-2026',
        Base_Rate_Per_SqFt__c = 15.00,
        Education_Cess_Percent__c = 5.00,
        Library_Cess_Percent__c = 10.00,
        Maintenance_Rebate_Percent__c = 10.00,
        Penalty_Rate_Percent__c = 2.00,
        Is_Active__c = true,
        Description__c = 'GCC Standard Baseline Rate across Chennai'
    )
};
insert rateList;
System.debug('Inserted ' + rateList.size() + ' tax rate records.');

// 3. Insert Sample Properties across Chennai
List<Property__c> sampleProps = new List<Property__c>{
    new Property__c(
        Property_Number__c = 'CHN-ZN05-W052-1001',
        Property_Owner_Name__c = 'Karthik Subramanian',
        Owner_Email__c = 'karthik.subramanian@example.com',
        Owner_Phone__c = '+91 98401 11222',
        Property_Address__c = 'No. 14, Mannarsamy Koil Street, Royapuram, Chennai - 600013',
        Zone__c = 'Zone 5 - Royapuram',
        Ward__c = 'Ward 52',
        Street_Name__c = 'Mannarsamy Koil Street',
        Property_Type__c = 'Residential',
        Property_Usage__c = 'Residential Individual',
        Occupancy_Type__c = 'Self-Occupied',
        Building_Area_SqFt__c = 1200,
        Number_of_Floors__c = 2,
        Construction_Year__c = 2016,
        Verification_Status__c = 'Verified'
    ),
    new Property__c(
        Property_Number__c = 'CHN-ZN08-W102-2002',
        Property_Owner_Name__c = 'S. Meenakshi Sundaram',
        Owner_Email__c = 'meenakshi.sundaram@example.com',
        Owner_Phone__c = '+91 98412 33445',
        Property_Address__c = 'Plot 412, 2nd Avenue, Anna Nagar West, Chennai - 600040',
        Zone__c = 'Zone 8 - Annanagar',
        Ward__c = 'Ward 102',
        Street_Name__c = '2nd Avenue',
        Property_Type__c = 'Residential',
        Property_Usage__c = 'Apartment Complex',
        Occupancy_Type__c = 'Self-Occupied',
        Building_Area_SqFt__c = 2200,
        Number_of_Floors__c = 3,
        Construction_Year__c = 2019,
        Verification_Status__c = 'Verified'
    ),
    new Property__c(
        Property_Number__c = 'CHN-ZN10-W141-3003',
        Property_Owner_Name__c = 'Chennai Silks Commercial Holdings',
        Owner_Email__c = 'accounts@chennaicommercial.example.com',
        Owner_Phone__c = '+91 44 2434 5678',
        Property_Address__c = 'No. 88, Usman Road, T. Nagar, Chennai - 600017',
        Zone__c = 'Zone 10 - Kodambakkam',
        Ward__c = 'Ward 141',
        Street_Name__c = 'Usman Road',
        Property_Type__c = 'Commercial',
        Property_Usage__c = 'Retail Commercial',
        Occupancy_Type__c = 'Tenanted',
        Building_Area_SqFt__c = 8500,
        Number_of_Floors__c = 4,
        Construction_Year__c = 2012,
        Verification_Status__c = 'Under Verification'
    ),
    new Property__c(
        Property_Number__c = 'CHN-ZN15-W198-4004',
        Property_Owner_Name__c = 'Infotech Realty Corporation',
        Owner_Email__c = 'compliance@infotechrealty.example.com',
        Owner_Phone__c = '+91 44 4567 8900',
        Property_Address__c = 'Tower B, Rajiv Gandhi Salai (OMR), Sholinganallur, Chennai - 600119',
        Zone__c = 'Zone 15 - Sholinganallur',
        Ward__c = 'Ward 198',
        Street_Name__c = 'Rajiv Gandhi Salai',
        Property_Type__c = 'Commercial',
        Property_Usage__c = 'Corporate Office',
        Occupancy_Type__c = 'Tenanted',
        Building_Area_SqFt__c = 15000,
        Number_of_Floors__c = 6,
        Construction_Year__c = 2021,
        Verification_Status__c = 'Unverified'
    ),
    new Property__c(
        Property_Number__c = 'CHN-ZN13-W175-5005',
        Property_Owner_Name__c = 'R. Soundararajan',
        Owner_Email__c = 'soundar.rajan@example.com',
        Owner_Phone__c = '+91 97890 55667',
        Property_Address__c = 'Old No. 5, Gandhi Nagar 1st Cross, Adyar, Chennai - 600020',
        Zone__c = 'Zone 13 - Adyar',
        Ward__c = 'Ward 175',
        Street_Name__c = 'Gandhi Nagar',
        Property_Type__c = 'Residential',
        Property_Usage__c = 'Residential Individual',
        Occupancy_Type__c = 'Tenanted',
        Building_Area_SqFt__c = 1800,
        Number_of_Floors__c = 2,
        Construction_Year__c = 2005,
        Verification_Status__c = 'Verified'
    )
};
insert sampleProps;
System.debug('Inserted ' + sampleProps.size() + ' properties.');

// 4. Generate and Approve Assessments
List<Tax_Assessment__c> asms = new List<Tax_Assessment__c>();
for (Property__c p : sampleProps) {
    TaxCalculationService.CalculationResult calc = TaxCalculationService.calculateTax(p, '2025-2026');

    Tax_Assessment__c a = new Tax_Assessment__c();
    a.Property__c = p.Id;
    a.Assessment_Year__c = '2025-2026';
    a.Assessment_Date__c = Date.today().addDays(-30);
    a.Due_Date__c = Date.today().addDays(30);
    a.Assessed_Area_SqFt__c = calc.buildingArea;
    a.Tax_Rate__c = calc.taxRateId;
    a.Applied_Base_Rate__c = calc.appliedBaseRate;
    a.Base_Property_Tax__c = calc.grossBaseTax;
    a.Rebate_Concession_Amount__c = calc.rebateAmount;
    a.Education_Cess_Amount__c = calc.educationCess;
    a.Library_Cess_Amount__c = calc.libraryCess;
    a.Total_Assessed_Tax__c = calc.totalAssessedTax;
    a.Status__c = 'Approved';
    a.Approval_Status__c = 'Approved';
    a.Approved_By__c = UserInfo.getUserId();
    a.Approval_Date__c = Date.today().addDays(-20);
    a.Calculation_Explanation__c = calc.explanation;
    asms.add(a);
}
insert asms;
System.debug('Inserted ' + asms.size() + ' tax assessments.');

// 5. Insert Simulated Payments for Demonstration
List<Tax_Payment__c> demoPayments = new List<Tax_Payment__c>{
    new Tax_Payment__c(
        Tax_Assessment__c = asms[0].Id,
        Property__c = sampleProps[0].Id,
        Amount_Paid__c = asms[0].Total_Assessed_Tax__c,
        Payment_Mode__c = 'Online - UPI',
        Payment_Status__c = 'Success',
        Payer_Name__c = 'Karthik Subramanian',
        Payer_Email__c = 'karthik.subramanian@example.com',
        Is_Simulated_Transaction__c = true
    ),
    new Tax_Payment__c(
        Tax_Assessment__c = asms[1].Id,
        Property__c = sampleProps[1].Id,
        Amount_Paid__c = (asms[1].Total_Assessed_Tax__c / 2).setScale(2, RoundingMode.HALF_UP),
        Payment_Mode__c = 'Online - Net Banking',
        Payment_Status__c = 'Success',
        Payer_Name__c = 'S. Meenakshi Sundaram',
        Payer_Email__c = 'meenakshi.sundaram@example.com',
        Is_Simulated_Transaction__c = true
    )
};
insert demoPayments;
System.debug('Inserted ' + demoPayments.size() + ' simulated demo payments.');

// 6. Insert a Demonstration Dispute
Assessment_Dispute__c disp = new Assessment_Dispute__c(
    Tax_Assessment__c = asms[2].Id,
    Property__c = sampleProps[2].Id,
    Dispute_Reason__c = 'Incorrect Area Measurement',
    Dispute_Description__c = 'The physical carpet area measured is only 7,800 sq ft, whereas 8,500 sq ft was billed. Request municipal re-inspection.',
    Claimed_Area_SqFt__c = 7800,
    Status__c = 'Filed'
);
insert disp;

System.debug('=== CHENNAI PROPERTY TAX SEED DATA GENERATION COMPLETE ===');
