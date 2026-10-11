const fs = require('fs');
const path = require('path');

const objectsDir = path.join(__dirname, '..', 'force-app', 'main', 'default', 'objects');
const objs = fs.readdirSync(objectsDir);
const eligibleFields = [];

for (const obj of objs) {
    const fieldsDir = path.join(objectsDir, obj, 'fields');
    if (!fs.existsSync(fieldsDir)) continue;
    const fieldFiles = fs.readdirSync(fieldsDir);
    for (const f of fieldFiles) {
        if (!f.endsWith('.field-meta.xml')) continue;
        const fieldName = f.replace('.field-meta.xml', '');
        const content = fs.readFileSync(path.join(fieldsDir, f), 'utf8');
        if (content.includes('<type>MasterDetail</type>') || content.includes('<required>true</required>')) {
            continue;
        }
        eligibleFields.push(obj + '.' + fieldName);
    }
}
eligibleFields.sort();

const fieldPermXml = eligibleFields.map(f => 
    '    <fieldPermissions>\n' +
    '        <editable>true</editable>\n' +
    '        <field>' + f + '</field>\n' +
    '        <readable>true</readable>\n' +
    '    </fieldPermissions>'
).join('\n');

const permSetPath = path.join(__dirname, '..', 'force-app', 'main', 'default', 'permissionsets', 'Property_Tax_Municipal_Admin.permissionset-meta.xml');
let content = fs.readFileSync(permSetPath, 'utf8');

// Replace or insert fieldPermissions before objectPermissions
content = content.replace('    <objectPermissions>', fieldPermXml + '\n    <objectPermissions>');
fs.writeFileSync(permSetPath, content, 'utf8');
console.log('Successfully updated Property_Tax_Municipal_Admin with ' + eligibleFields.length + ' field permissions.');
