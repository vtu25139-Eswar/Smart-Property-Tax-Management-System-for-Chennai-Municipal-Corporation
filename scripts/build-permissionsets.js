const fs = require('fs');
const path = require('path');

const permDir = path.join(__dirname, '..', 'force-app', 'main', 'default', 'permissionsets');
if (!fs.existsSync(permDir)) {
    fs.mkdirSync(permDir, { recursive: true });
}

const objects = ['Property__c', 'Tax_Rate__c', 'Tax_Assessment__c', 'Tax_Payment__c', 'Verification_Request__c', 'Assessment_Dispute__c'];
const classes = [
    'TaxCalculationService',
    'PropertyVerificationScoreService',
    'PropertyTriggerHandler',
    'TaxAssessmentTriggerHandler',
    'TaxPaymentTriggerHandler',
    'TaxReassessmentBatch',
    'TaxOverdueScheduler',
    'PropertyTaxNotificationQueueable',
    'PropertyTaxRestService',
    'PropertyTaxUIController'
];

function generatePermSet(name, label, desc, objConfig) {
    let objXml = '';
    for (const obj of objects) {
        const cfg = objConfig[obj] || { r: true, c: false, e: false, d: false, v: false, m: false };
        objXml += `    <objectPermissions>
        <allowCreate>${cfg.c}</allowCreate>
        <allowDelete>${cfg.d}</allowDelete>
        <allowEdit>${cfg.e}</allowEdit>
        <allowRead>${cfg.r}</allowRead>
        <modifyAllRecords>${cfg.m}</modifyAllRecords>
        <object>${obj}</object>
        <viewAllRecords>${cfg.v}</viewAllRecords>
    </objectPermissions>\n`;
    }

    let classXml = '';
    for (const cls of classes) {
        classXml += `    <classAccesses>
        <apexClass>${cls}</apexClass>
        <enabled>true</enabled>
    </classAccesses>\n`;
    }

    const xml = `<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <description>${desc}</description>
    <hasActivationRequired>false</hasActivationRequired>
    <label>${label}</label>
${classXml}${objXml}</PermissionSet>`;

    fs.writeFileSync(path.join(permDir, `${name}.permissionset-meta.xml`), xml, 'utf8');
}

// 1. Citizen: Read own property, create property, create dispute, read assessments and payments
generatePermSet(
    'Property_Tax_Citizen',
    'Property Tax Citizen User',
    'Allows citizens to register properties, view assessments, make payments, and file disputes.',
    {
        'Property__c': { r: true, c: true, e: false, d: false, v: false, m: false },
        'Tax_Rate__c': { r: true, c: false, e: false, d: false, v: false, m: false },
        'Tax_Assessment__c': { r: true, c: false, e: false, d: false, v: false, m: false },
        'Tax_Payment__c': { r: true, c: true, e: false, d: false, v: false, m: false },
        'Verification_Request__c': { r: true, c: false, e: false, d: false, v: false, m: false },
        'Assessment_Dispute__c': { r: true, c: true, e: false, d: false, v: false, m: false }
    }
);

// 2. Verification Officer: Field inspections, read properties, edit verification status
generatePermSet(
    'Property_Tax_Verification_Officer',
    'Property Tax Verification Officer',
    'Field inspectors conducting site visits, measuring built areas, and updating verification statuses.',
    {
        'Property__c': { r: true, c: false, e: true, d: false, v: true, m: false },
        'Tax_Rate__c': { r: true, c: false, e: false, d: false, v: false, m: false },
        'Tax_Assessment__c': { r: true, c: false, e: false, d: false, v: true, m: false },
        'Tax_Payment__c': { r: true, c: false, e: false, d: false, v: true, m: false },
        'Verification_Request__c': { r: true, c: true, e: true, d: false, v: true, m: false },
        'Assessment_Dispute__c': { r: true, c: false, e: true, d: false, v: true, m: false }
    }
);

// 3. Tax Assessor: Compute taxes, create assessments, evaluate rates
generatePermSet(
    'Property_Tax_Assessor',
    'Property Tax Assessor',
    'Municipal assessment officers calculating tax schedules, reviewing areas, and submitting assessments for approval.',
    {
        'Property__c': { r: true, c: true, e: true, d: false, v: true, m: false },
        'Tax_Rate__c': { r: true, c: true, e: true, d: false, v: true, m: false },
        'Tax_Assessment__c': { r: true, c: true, e: true, d: false, v: true, m: false },
        'Tax_Payment__c': { r: true, c: true, e: false, d: false, v: true, m: false },
        'Verification_Request__c': { r: true, c: false, e: false, d: false, v: true, m: false },
        'Assessment_Dispute__c': { r: true, c: false, e: true, d: false, v: true, m: false }
    }
);

// 4. Zonal Head: Approve assessments, resolve disputes, zonal reports
generatePermSet(
    'Property_Tax_Zonal_Head',
    'Property Tax Zonal Head',
    'Zonal commissioners with authority to approve assessments, resolve citizen disputes, and review zonal performance.',
    {
        'Property__c': { r: true, c: true, e: true, d: false, v: true, m: false },
        'Tax_Rate__c': { r: true, c: true, e: true, d: false, v: true, m: false },
        'Tax_Assessment__c': { r: true, c: true, e: true, d: false, v: true, m: false },
        'Tax_Payment__c': { r: true, c: true, e: false, d: false, v: true, m: false },
        'Verification_Request__c': { r: true, c: true, e: true, d: false, v: true, m: false },
        'Assessment_Dispute__c': { r: true, c: true, e: true, d: false, v: true, m: false }
    }
);

// 5. Municipal Admin: Full CRUD & Modify All
generatePermSet(
    'Property_Tax_Municipal_Admin',
    'Property Tax Municipal Administrator',
    'Full administrative control over all property tax management entities, configurations, and batches.',
    {
        'Property__c': { r: true, c: true, e: true, d: true, v: true, m: true },
        'Tax_Rate__c': { r: true, c: true, e: true, d: true, v: true, m: true },
        'Tax_Assessment__c': { r: true, c: true, e: true, d: true, v: true, m: true },
        'Tax_Payment__c': { r: true, c: true, e: true, d: true, v: true, m: true },
        'Verification_Request__c': { r: true, c: true, e: true, d: true, v: true, m: true },
        'Assessment_Dispute__c': { r: true, c: true, e: true, d: true, v: true, m: true }
    }
);

console.log('Generated 5 Permission Sets successfully.');
