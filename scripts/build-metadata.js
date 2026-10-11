const fs = require('fs');
const path = require('path');

const baseDir = path.join(__dirname, '..', 'force-app', 'main', 'default', 'objects');

function ensureDir(dir) {
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
}

function writeObject(apiName, label, pluralLabel, nameField, sharingModel = 'ReadWrite') {
    const objDir = path.join(baseDir, apiName);
    ensureDir(objDir);
    ensureDir(path.join(objDir, 'fields'));
    ensureDir(path.join(objDir, 'validationRules'));

    let nameFieldXml = '';
    if (nameField.type === 'AutoNumber') {
        nameFieldXml = `    <nameField>
        <displayFormat>${nameField.displayFormat}</displayFormat>
        <label>${nameField.label}</label>
        <type>AutoNumber</type>
    </nameField>`;
    } else {
        nameFieldXml = `    <nameField>
        <label>${nameField.label}</label>
        <type>Text</type>
    </nameField>`;
    }

    const xml = `<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <actionOverrides>
        <actionName>Accept</actionName>
        <type>Default</type>
    </actionOverrides>
    <actionOverrides>
        <actionName>CancelEdit</actionName>
        <type>Default</type>
    </actionOverrides>
    <actionOverrides>
        <actionName>Clone</actionName>
        <type>Default</type>
    </actionOverrides>
    <actionOverrides>
        <actionName>Delete</actionName>
        <type>Default</type>
    </actionOverrides>
    <actionOverrides>
        <actionName>Edit</actionName>
        <type>Default</type>
    </actionOverrides>
    <actionOverrides>
        <actionName>List</actionName>
        <type>Default</type>
    </actionOverrides>
    <actionOverrides>
        <actionName>New</actionName>
        <type>Default</type>
    </actionOverrides>
    <actionOverrides>
        <actionName>SaveEdit</actionName>
        <type>Default</type>
    </actionOverrides>
    <actionOverrides>
        <actionName>Tab</actionName>
        <type>Default</type>
    </actionOverrides>
    <actionOverrides>
        <actionName>View</actionName>
        <type>Default</type>
    </actionOverrides>
    <allowInChatterGroups>false</allowInChatterGroups>
    <compactLayoutAssignment>SYSTEM</compactLayoutAssignment>
    <deploymentStatus>Deployed</deploymentStatus>
    <enableActivities>true</enableActivities>
    <enableBulkApi>true</enableBulkApi>
    <enableFeeds>false</enableFeeds>
    <enableHistory>true</enableHistory>
    <enableLicensing>false</enableLicensing>
    <enableReports>true</enableReports>
    <enableSearch>true</enableSearch>
    <enableSharing>true</enableSharing>
    <enableStreamingApi>true</enableStreamingApi>
    <label>${label}</label>
${nameFieldXml}
    <pluralLabel>${pluralLabel}</pluralLabel>
    <sharingModel>${sharingModel}</sharingModel>
    <visibility>Public</visibility>
</CustomObject>`;

    fs.writeFileSync(path.join(objDir, `${apiName}.object-meta.xml`), xml, 'utf8');
}

function writeField(objName, field) {
    const fieldsDir = path.join(baseDir, objName, 'fields');
    ensureDir(fieldsDir);

    let specificTags = '';
    if (field.type === 'Text') {
        specificTags = `    <length>${field.length || 255}</length>
    <required>${field.required || false}</required>
    <unique>${field.unique || false}</unique>
    <externalId>${field.externalId || false}</externalId>`;
    } else if (field.type === 'TextArea') {
        specificTags = `    <required>${field.required || false}</required>`;
    } else if (field.type === 'LongTextArea') {
        specificTags = `    <length>${field.length || 32768}</length>
    <visibleLines>${field.visibleLines || 3}</visibleLines>`;
    } else if (field.type === 'Number') {
        specificTags = `    <precision>${field.precision || 18}</precision>
    <scale>${field.scale || 0}</scale>
    <required>${field.required || false}</required>
    <unique>${field.unique || false}</unique>`;
    } else if (field.type === 'Currency') {
        specificTags = `    <precision>${field.precision || 18}</precision>
    <scale>${field.scale || 2}</scale>
    <required>${field.required || false}</required>`;
    } else if (field.type === 'Percent') {
        specificTags = `    <precision>${field.precision || 5}</precision>
    <scale>${field.scale || 2}</scale>
    <required>${field.required || false}</required>`;
    } else if (field.type === 'Checkbox') {
        specificTags = `    <defaultValue>${field.defaultValue || false}</defaultValue>`;
    } else if (field.type === 'Date' || field.type === 'DateTime') {
        specificTags = `    <required>${field.required || false}</required>`;
    } else if (field.type === 'Email' || field.type === 'Phone' || field.type === 'Url') {
        specificTags = `    <required>${field.required || false}</required>
    <unique>${field.unique || false}</unique>`;
    } else if (field.type === 'Picklist') {
        const escapeXml = (str) => String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
        const valSetValues = field.values.map(v => `            <value>
                <fullName>${escapeXml(v)}</fullName>
                <default>${v === field.defaultValue}</default>
                <label>${escapeXml(v)}</label>
            </value>`).join('\n');

        specificTags = `    <valueSet>
        <restricted>true</restricted>
        <valueSetDefinition>
            <sorted>false</sorted>
${valSetValues}
        </valueSetDefinition>
    </valueSet>`;
    } else if (field.type === 'Lookup') {
        specificTags = `    <deleteConstraint>SetNull</deleteConstraint>
    <referenceTo>${field.referenceTo}</referenceTo>
    <relationshipLabel>${field.relationshipLabel || field.label}</relationshipLabel>
    <relationshipName>${field.relationshipName}</relationshipName>
    <required>${field.required || false}</required>`;
    } else if (field.type === 'MasterDetail') {
        specificTags = `    <referenceTo>${field.referenceTo}</referenceTo>
    <relationshipLabel>${field.relationshipLabel || field.label}</relationshipLabel>
    <relationshipName>${field.relationshipName}</relationshipName>
    <relationshipOrder>0</relationshipOrder>
    <reparentableMasterDetail>false</reparentableMasterDetail>
    <trackTrending>false</trackTrending>
    <writeRequiresMasterRead>false</writeRequiresMasterRead>`;
    }

    const xml = `<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>${field.fullName}</fullName>
    <description>${field.description || field.label}</description>
    <label>${field.label}</label>
${specificTags}
    <type>${field.type}</type>
</CustomField>`;

    fs.writeFileSync(path.join(fieldsDir, `${field.fullName}.field-meta.xml`), xml, 'utf8');
}

function writeValidationRule(objName, rule) {
    const vrDir = path.join(baseDir, objName, 'validationRules');
    ensureDir(vrDir);

    const xml = `<?xml version="1.0" encoding="UTF-8"?>
<ValidationRule xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>${rule.fullName}</fullName>
    <active>${rule.active !== false}</active>
    <description>${rule.description}</description>
    <errorConditionFormula>${rule.formula}</errorConditionFormula>
    <errorMessage>${rule.message}</errorMessage>
</ValidationRule>`;

    fs.writeFileSync(path.join(vrDir, `${rule.fullName}.validationRule-meta.xml`), xml, 'utf8');
}

console.log('Generating Objects and Fields...');

// 1. Property__c
writeObject('Property__c', 'Property', 'Properties', { type: 'AutoNumber', displayFormat: 'PROP-{YYYY}-{0000}', label: 'Property Record ID' }, 'ReadWrite');

const propertyFields = [
    { fullName: 'Property_Number__c', label: 'Property Number', type: 'Text', length: 50, required: true, unique: true, externalId: true, description: 'Unique municipal property assessment number' },
    { fullName: 'Property_Owner_Name__c', label: 'Property Owner Name', type: 'Text', length: 100, required: true, description: 'Full legal name of the registered property owner' },
    { fullName: 'Owner_Email__c', label: 'Owner Email', type: 'Email', description: 'Primary email address for notices and receipts' },
    { fullName: 'Owner_Phone__c', label: 'Owner Phone Number', type: 'Phone', description: 'Contact phone number of property owner' },
    { fullName: 'Property_Address__c', label: 'Property Address', type: 'TextArea', description: 'Full street address of the property' },
    { fullName: 'Zone__c', label: 'Zone', type: 'Picklist', values: [
        'Zone 1 - Thiruvottiyur', 'Zone 2 - Manali', 'Zone 3 - Madhavaram', 'Zone 4 - Tondiarpet',
        'Zone 5 - Royapuram', 'Zone 6 - Thiru Vi Ka Nagar', 'Zone 7 - Ambattur', 'Zone 8 - Annanagar',
        'Zone 9 - Teynampet', 'Zone 10 - Kodambakkam', 'Zone 11 - Valasaravakkam', 'Zone 12 - Alandur',
        'Zone 13 - Adyar', 'Zone 14 - Perungudi', 'Zone 15 - Sholinganallur'
    ], defaultValue: 'Zone 5 - Royapuram', description: 'Chennai Municipal Corporation Zone' },
    { fullName: 'Ward__c', label: 'Ward', type: 'Text', length: 30, description: 'Municipal Ward number (e.g. Ward 114)' },
    { fullName: 'Street_Name__c', label: 'Street / Locality', type: 'Text', length: 100, description: 'Locality or street name' },
    { fullName: 'Property_Type__c', label: 'Property Type', type: 'Picklist', values: ['Residential', 'Commercial', 'Industrial', 'Mixed-Use', 'Vacant Land'], defaultValue: 'Residential', description: 'Category of property' },
    { fullName: 'Building_Area_SqFt__c', label: 'Building Area (Sq Ft)', type: 'Number', precision: 10, scale: 2, required: true, description: 'Total built-up plinth area in square feet' },
    { fullName: 'Number_of_Floors__c', label: 'Number of Floors', type: 'Number', precision: 3, scale: 0, description: 'Total number of floors including ground floor' },
    { fullName: 'Construction_Year__c', label: 'Construction Year', type: 'Number', precision: 4, scale: 0, description: 'Year of building construction / assessment baseline' },
    { fullName: 'Occupancy_Type__c', label: 'Occupancy Type', type: 'Picklist', values: ['Self-Occupied', 'Tenanted', 'Vacant', 'Government/Exempt'], defaultValue: 'Self-Occupied', description: 'Occupancy classification affecting rebates' },
    { fullName: 'Property_Usage__c', label: 'Property Usage', type: 'Picklist', values: ['Residential Individual', 'Apartment Complex', 'Retail Commercial', 'Corporate Office', 'Industrial Warehouse', 'Educational/Hospital'], defaultValue: 'Residential Individual', description: 'Detailed functional usage of the property' },
    { fullName: 'Verification_Status__c', label: 'Verification Status', type: 'Picklist', values: ['Unverified', 'Under Verification', 'Verified', 'Needs Re-Inspection', 'Discrepancy Flagged'], defaultValue: 'Unverified', description: 'Status of physical/documentary municipal verification' },
    { fullName: 'Verification_Priority_Score__c', label: 'Verification Priority Score', type: 'Number', precision: 5, scale: 2, description: 'Administrative verification priority score from 0 to 100' },
    { fullName: 'Verification_Priority_Level__c', label: 'Verification Priority Level', type: 'Picklist', values: ['Low', 'Medium', 'High'], defaultValue: 'Low', description: 'Administrative priority tier for municipal review' },
    { fullName: 'Priority_Score_Reasons__c', label: 'Priority Score Breakdown', type: 'LongTextArea', length: 2000, description: 'Itemized factors explaining the verification priority score' },
    { fullName: 'Assessed_Annual_Tax__c', label: 'Assessed Annual Tax', type: 'Currency', precision: 12, scale: 2, description: 'Most recent annual assessed tax in INR' },
    { fullName: 'Outstanding_Dues__c', label: 'Outstanding Dues', type: 'Currency', precision: 12, scale: 2, description: 'Total pending unpaid tax dues in INR' },
    { fullName: 'Current_Assessment_Status__c', label: 'Current Assessment Status', type: 'Picklist', values: ['Not Assessed', 'Pending Approval', 'Assessed & Active', 'Under Dispute', 'Exempt'], defaultValue: 'Not Assessed', description: 'Overall tax assessment lifecycle status' },
    { fullName: 'Latitude__c', label: 'Latitude', type: 'Number', precision: 8, scale: 5, description: 'GIS Latitude coordinate' },
    { fullName: 'Longitude__c', label: 'Longitude', type: 'Number', precision: 8, scale: 5, description: 'GIS Longitude coordinate' }
];

propertyFields.forEach(f => writeField('Property__c', f));

writeValidationRule('Property__c', {
    fullName: 'Building_Area_Must_Be_Positive',
    formula: 'Building_Area_SqFt__c &lt;= 0',
    message: 'Building Area in square feet must be greater than zero.',
    description: 'Ensures assessed area is strictly positive.'
});

writeValidationRule('Property__c', {
    fullName: 'Valid_Construction_Year',
    formula: 'AND(NOT(ISBLANK(Construction_Year__c)), OR(Construction_Year__c &lt; 1850, Construction_Year__c &gt; YEAR(TODAY())))',
    message: 'Construction year must be between 1850 and the current year.',
    description: 'Validates construction year bounds.'
});

// 2. Tax_Rate__c
writeObject('Tax_Rate__c', 'Tax Rate', 'Tax Rates', { type: 'Text', label: 'Tax Rate Code' }, 'ReadWrite');

const taxRateFields = [
    { fullName: 'Zone__c', label: 'Zone', type: 'Picklist', values: [
        'All Zones', 'Zone 1 - Thiruvottiyur', 'Zone 2 - Manali', 'Zone 3 - Madhavaram', 'Zone 4 - Tondiarpet',
        'Zone 5 - Royapuram', 'Zone 6 - Thiru Vi Ka Nagar', 'Zone 7 - Ambattur', 'Zone 8 - Annanagar',
        'Zone 9 - Teynampet', 'Zone 10 - Kodambakkam', 'Zone 11 - Valasaravakkam', 'Zone 12 - Alandur',
        'Zone 13 - Adyar', 'Zone 14 - Perungudi', 'Zone 15 - Sholinganallur'
    ], defaultValue: 'All Zones', description: 'Applicable municipal zone or All Zones' },
    { fullName: 'Property_Type__c', label: 'Property Type', type: 'Picklist', values: ['Residential', 'Commercial', 'Industrial', 'Mixed-Use', 'Vacant Land'], defaultValue: 'Residential', description: 'Property category' },
    { fullName: 'Property_Usage__c', label: 'Property Usage', type: 'Picklist', values: ['Residential Individual', 'Apartment Complex', 'Retail Commercial', 'Corporate Office', 'Industrial Warehouse', 'Educational/Hospital'], defaultValue: 'Residential Individual', description: 'Specific property usage' },
    { fullName: 'Financial_Year__c', label: 'Financial Year', type: 'Picklist', values: ['2024-2025', '2025-2026', '2026-2027'], defaultValue: '2025-2026', description: 'Financial assessment year' },
    { fullName: 'Base_Rate_Per_SqFt__c', label: 'Base Rate per Sq Ft (INR)', type: 'Currency', precision: 10, scale: 2, required: true, description: 'Annual base rate in INR per sq ft of plinth area' },
    { fullName: 'Education_Cess_Percent__c', label: 'Education Cess (%)', type: 'Percent', precision: 5, scale: 2, description: 'Education cess surcharge percentage' },
    { fullName: 'Library_Cess_Percent__c', label: 'Library Cess (%)', type: 'Percent', precision: 5, scale: 2, description: 'Tamil Nadu Library cess surcharge percentage' },
    { fullName: 'Maintenance_Rebate_Percent__c', label: 'Self-Occupied Rebate (%)', type: 'Percent', precision: 5, scale: 2, description: 'Rebate percentage for self-occupied residential buildings' },
    { fullName: 'Penalty_Rate_Percent__c', label: 'Late Payment Penalty (%)', type: 'Percent', precision: 5, scale: 2, description: 'Penalty surcharge for overdue payments' },
    { fullName: 'Is_Active__c', label: 'Active', type: 'Checkbox', defaultValue: true, description: 'Whether this tax rate schedule is currently active' },
    { fullName: 'Effective_Start_Date__c', label: 'Effective Start Date', type: 'Date', description: 'Date when this rate becomes effective' },
    { fullName: 'Effective_End_Date__c', label: 'Effective End Date', type: 'Date', description: 'Date when this rate expires' },
    { fullName: 'Description__c', label: 'Description', type: 'Text', length: 255, description: 'Notes on tax rule or government notification' }
];

taxRateFields.forEach(f => writeField('Tax_Rate__c', f));

// 3. Tax_Assessment__c
writeObject('Tax_Assessment__c', 'Tax Assessment', 'Tax Assessments', { type: 'AutoNumber', displayFormat: 'TAX-ASM-{YYYY}-{0000}', label: 'Assessment Number' }, 'ControlledByParent');

const assessmentFields = [
    { fullName: 'Property__c', label: 'Property', type: 'MasterDetail', referenceTo: 'Property__c', relationshipName: 'Tax_Assessments', relationshipLabel: 'Tax Assessments', description: 'Property being assessed' },
    { fullName: 'Assessment_Year__c', label: 'Assessment Year', type: 'Picklist', values: ['2024-2025', '2025-2026', '2026-2027'], defaultValue: '2025-2026', description: 'Financial year of assessment' },
    { fullName: 'Assessment_Date__c', label: 'Assessment Date', type: 'Date', description: 'Date assessment was calculated' },
    { fullName: 'Due_Date__c', label: 'Tax Due Date', type: 'Date', description: 'Final date for tax payment before penalty' },
    { fullName: 'Assessed_Area_SqFt__c', label: 'Assessed Area (Sq Ft)', type: 'Number', precision: 10, scale: 2, description: 'Area used in tax computation' },
    { fullName: 'Tax_Rate__c', label: 'Applied Tax Rate', type: 'Lookup', referenceTo: 'Tax_Rate__c', relationshipName: 'Tax_Assessments', relationshipLabel: 'Tax Assessments', description: 'Configured tax rate schedule used' },
    { fullName: 'Applied_Base_Rate__c', label: 'Applied Base Rate (INR/SqFt)', type: 'Currency', precision: 10, scale: 2, description: 'Base rate applied per sq ft' },
    { fullName: 'Base_Property_Tax__c', label: 'Base Property Tax (INR)', type: 'Currency', precision: 12, scale: 2, description: 'Unadjusted base tax amount' },
    { fullName: 'Rebate_Concession_Amount__c', label: 'Rebate / Concession (INR)', type: 'Currency', precision: 12, scale: 2, description: 'Deduction for self-occupied occupancy or concessions' },
    { fullName: 'Education_Cess_Amount__c', label: 'Education Cess (INR)', type: 'Currency', precision: 12, scale: 2, description: 'Education cess calculated' },
    { fullName: 'Library_Cess_Amount__c', label: 'Library Cess (INR)', type: 'Currency', precision: 12, scale: 2, description: 'Library cess calculated' },
    { fullName: 'Penalty_Late_Fee__c', label: 'Penalty / Late Fee (INR)', type: 'Currency', precision: 12, scale: 2, description: 'Late fee or arrears surcharge' },
    { fullName: 'Total_Assessed_Tax__c', label: 'Total Assessed Tax (INR)', type: 'Currency', precision: 12, scale: 2, description: 'Final payable annual tax' },
    { fullName: 'Paid_Amount__c', label: 'Paid Amount (INR)', type: 'Currency', precision: 12, scale: 2, description: 'Total amount settled by property owner' },
    { fullName: 'Balance_Dues__c', label: 'Balance Dues (INR)', type: 'Currency', precision: 12, scale: 2, description: 'Remaining unpaid tax balance' },
    { fullName: 'Status__c', label: 'Status', type: 'Picklist', values: ['Draft', 'Submitted', 'Under Review', 'Approved', 'Disputed', 'Overdue', 'Paid'], defaultValue: 'Draft', description: 'Lifecycle status of this assessment' },
    { fullName: 'Calculation_Explanation__c', label: 'Calculation Explanation', type: 'LongTextArea', length: 3000, description: 'Transparent mathematical breakdown of the tax computation' },
    { fullName: 'Approval_Status__c', label: 'Approval Status', type: 'Picklist', values: ['Not Submitted', 'Pending Approval', 'Approved', 'Rejected'], defaultValue: 'Not Submitted', description: 'Municipal officer approval status' },
    { fullName: 'Approved_By__c', label: 'Approved By', type: 'Lookup', referenceTo: 'User', relationshipName: 'Approved_Assessments', relationshipLabel: 'Approved Assessments', description: 'Municipal officer who approved the assessment' },
    { fullName: 'Approval_Date__c', label: 'Approval Date', type: 'Date', description: 'Date of municipal approval' },
    { fullName: 'Approval_Comments__c', label: 'Approval Comments', type: 'TextArea', description: 'Remarks entered during approval or rejection' }
];

assessmentFields.forEach(f => writeField('Tax_Assessment__c', f));

// 4. Tax_Payment__c
writeObject('Tax_Payment__c', 'Tax Payment', 'Tax Payments', { type: 'AutoNumber', displayFormat: 'RCPT-{YYYY}-{00000}', label: 'Receipt ID' }, 'ControlledByParent');

const paymentFields = [
    { fullName: 'Tax_Assessment__c', label: 'Tax Assessment', type: 'MasterDetail', referenceTo: 'Tax_Assessment__c', relationshipName: 'Tax_Payments', relationshipLabel: 'Tax Payments', description: 'Assessment being paid' },
    { fullName: 'Property__c', label: 'Property', type: 'Lookup', referenceTo: 'Property__c', relationshipName: 'Tax_Payments', relationshipLabel: 'Tax Payments', description: 'Associated property' },
    { fullName: 'Payment_Reference__c', label: 'Payment Reference', type: 'Text', length: 100, required: true, unique: true, externalId: true, description: 'Unique payment transaction identifier' },
    { fullName: 'Amount_Paid__c', label: 'Amount Paid (INR)', type: 'Currency', precision: 12, scale: 2, required: true, description: 'Transaction payment amount in INR' },
    { fullName: 'Payment_Date__c', label: 'Payment Date', type: 'DateTime', description: 'Timestamp of transaction completion' },
    { fullName: 'Payment_Mode__c', label: 'Payment Mode', type: 'Picklist', values: ['Online - UPI', 'Online - Net Banking', 'Credit/Debit Card', 'Municipal Counter - Cash', 'Municipal Counter - DD'], defaultValue: 'Online - UPI', description: 'Payment channel' },
    { fullName: 'Payment_Status__c', label: 'Payment Status', type: 'Picklist', values: ['Initiated', 'Success', 'Failed', 'Refunded'], defaultValue: 'Success', description: 'Gateway transaction status' },
    { fullName: 'Payer_Name__c', label: 'Payer Name', type: 'Text', length: 100, description: 'Name of person paying the tax' },
    { fullName: 'Payer_Email__c', label: 'Payer Email', type: 'Email', description: 'Email address where receipt is sent' },
    { fullName: 'Payer_Phone__c', label: 'Payer Phone', type: 'Phone', description: 'Contact phone of payer' },
    { fullName: 'Is_Simulated_Transaction__c', label: 'Simulated Sandbox Transaction', type: 'Checkbox', defaultValue: true, description: 'Flag marking simulated demo payment' },
    { fullName: 'Gateway_Transaction_Id__c', label: 'Gateway Transaction ID', type: 'Text', length: 100, description: 'Simulated payment gateway reference ID' },
    { fullName: 'Gateway_Response__c', label: 'Gateway Response', type: 'LongTextArea', length: 1500, description: 'Raw payload response from simulated payment gateway' },
    { fullName: 'Receipt_Number__c', label: 'Receipt Number', type: 'Text', length: 50, description: 'Municipal payment receipt number' }
];

paymentFields.forEach(f => writeField('Tax_Payment__c', f));

// 5. Verification_Request__c
writeObject('Verification_Request__c', 'Verification Request', 'Verification Requests', { type: 'AutoNumber', displayFormat: 'VER-REQ-{00000}', label: 'Verification Request ID' }, 'ControlledByParent');

const verificationFields = [
    { fullName: 'Property__c', label: 'Property', type: 'MasterDetail', referenceTo: 'Property__c', relationshipName: 'Verification_Requests', relationshipLabel: 'Verification Requests', description: 'Property under inspection' },
    { fullName: 'Request_Type__c', label: 'Request Type', type: 'Picklist', values: ['New Property Registration', 'Periodic Municipal Audit', 'Area Discrepancy Review', 'Dispute Field Verification'], defaultValue: 'New Property Registration', description: 'Inspection category' },
    { fullName: 'Priority_Score__c', label: 'Priority Score', type: 'Number', precision: 5, scale: 2, description: 'Calculated inspection urgency score' },
    { fullName: 'Priority_Level__c', label: 'Priority Level', type: 'Picklist', values: ['Low', 'Medium', 'High'], defaultValue: 'Low', description: 'Inspection priority tier' },
    { fullName: 'Status__c', label: 'Status', type: 'Picklist', values: ['Queued', 'In Progress', 'Verified - Match', 'Discrepancy Found', 'Cancelled'], defaultValue: 'Queued', description: 'Verification workflow status' },
    { fullName: 'Assigned_Officer__c', label: 'Assigned Officer', type: 'Lookup', referenceTo: 'User', relationshipName: 'Assigned_Verifications', relationshipLabel: 'Assigned Verifications', description: 'Municipal field officer assigned' },
    { fullName: 'Field_Inspection_Date__c', label: 'Field Inspection Date', type: 'Date', description: 'Date field audit was conducted' },
    { fullName: 'Physical_Area_Measured__c', label: 'Physical Area Measured (Sq Ft)', type: 'Number', precision: 10, scale: 2, description: 'Plinth area physically surveyed on-site' },
    { fullName: 'Area_Discrepancy_Percent__c', label: 'Area Discrepancy (%)', type: 'Percent', precision: 5, scale: 2, description: 'Percentage difference between declared and measured area' },
    { fullName: 'Inspector_Remarks__c', label: 'Inspector Remarks', type: 'LongTextArea', length: 2000, description: 'Notes recorded during site inspection' },
    { fullName: 'Inspection_Findings__c', label: 'Inspection Findings', type: 'Picklist', values: ['Area Verified Accurately', 'Minor Variation (&lt;5%)', 'Major Discrepancy (&gt;10%)', 'Unauthorized Construction', 'Change in Property Usage'], defaultValue: 'Area Verified Accurately', description: 'Classification of physical inspection result' }
];

verificationFields.forEach(f => writeField('Verification_Request__c', f));

// 6. Assessment_Dispute__c
writeObject('Assessment_Dispute__c', 'Assessment Dispute', 'Assessment Disputes', { type: 'AutoNumber', displayFormat: 'DISP-{YYYY}-{0000}', label: 'Dispute ID' }, 'ControlledByParent');

const disputeFields = [
    { fullName: 'Tax_Assessment__c', label: 'Tax Assessment', type: 'MasterDetail', referenceTo: 'Tax_Assessment__c', relationshipName: 'Assessment_Disputes', relationshipLabel: 'Assessment Disputes', description: 'Contested assessment' },
    { fullName: 'Property__c', label: 'Property', type: 'Lookup', referenceTo: 'Property__c', relationshipName: 'Assessment_Disputes', relationshipLabel: 'Assessment Disputes', description: 'Associated property' },
    { fullName: 'Dispute_Reason__c', label: 'Dispute Reason', type: 'Picklist', values: ['Incorrect Area Measurement', 'Wrong Rate Classification', 'Unapplied Concession/Rebate', 'Ownership Mismatch', 'Other'], defaultValue: 'Incorrect Area Measurement', description: 'Citizen dispute ground' },
    { fullName: 'Dispute_Description__c', label: 'Dispute Description', type: 'LongTextArea', length: 2000, description: 'Detailed justification submitted by property owner' },
    { fullName: 'Claimed_Area_SqFt__c', label: 'Claimed Area (Sq Ft)', type: 'Number', precision: 10, scale: 2, description: 'Corrected built area claimed by owner' },
    { fullName: 'Supporting_Document_URL__c', label: 'Supporting Document URL', type: 'Url', description: 'Link to deed, approved building plan, or survey document' },
    { fullName: 'Status__c', label: 'Status', type: 'Picklist', values: ['Filed', 'Under Verification', 'Hearing Scheduled', 'Accepted & Reassessed', 'Rejected'], defaultValue: 'Filed', description: 'Dispute resolution stage' },
    { fullName: 'Hearing_Date__c', label: 'Hearing Date', type: 'Date', description: 'Date scheduled for municipal grievance hearing' },
    { fullName: 'Resolution_Notes__c', label: 'Resolution Notes', type: 'LongTextArea', length: 2000, description: 'Hearing officer determination and rationale' },
    { fullName: 'Resolved_By__c', label: 'Resolved By', type: 'Lookup', referenceTo: 'User', relationshipName: 'Resolved_Disputes', relationshipLabel: 'Resolved Disputes', description: 'Municipal officer resolving dispute' },
    { fullName: 'Resolution_Date__c', label: 'Resolution Date', type: 'Date', description: 'Date dispute was officially closed' }
];

disputeFields.forEach(f => writeField('Assessment_Dispute__c', f));

console.log('All 6 Custom Objects, Fields, and Validation Rules generated successfully.');
