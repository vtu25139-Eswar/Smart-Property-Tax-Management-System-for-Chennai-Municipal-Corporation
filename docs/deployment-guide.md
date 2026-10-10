# Deployment Guide: Smart Property Tax Management System
## Target Org: `property-tax-org` (`vakanani2006@brave-panda-9mfmin.com`)

### 1. Prerequisites Checklist
- [x] Node.js v20+ and npm installed
- [x] Git configured with repository remote
- [x] Salesforce CLI (`@salesforce/cli`) installed
- [x] Target Developer Edition Org credentials: `vakanani2006@brave-panda-9mfmin.com`

---

### 2. Salesforce Authentication (Interactive Browser Login)

To authenticate your Salesforce CLI against the target Developer Edition org:

```powershell
# Authenticate using the official interactive browser login
sf org login web --alias property-tax-org --set-default
```

*Note: Antigravity will never ask for your password, security token, or private credentials in chat. Complete the login directly in your secure web browser.*

Once authenticated, verify that the authenticated username matches your Developer Edition username:

```powershell
# Verify authenticated org and username
sf org display --target-org property-tax-org
```

Output should show:
- **Alias**: `property-tax-org`
- **Username**: `vakanani2006@brave-panda-9mfmin.com`
- **Connected Status**: `Connected`

---

### 3. Deploy Metadata to Salesforce

Deploy all objects, fields, Apex classes, triggers, flows, permission sets, tabs, and Lightning Web Components:

```powershell
# Deploy all source metadata
sf project deploy start --target-org property-tax-org
```

To validate without deploying (dry run):
```powershell
# Dry-run validation check
sf project deploy start --target-org property-tax-org --dry-run
```

---

### 4. Assign Permission Sets

Assign the Municipal Administrator permission set to your admin user to unlock full system access:

```powershell
# Assign Administrator Permission Set
sf org assign permset --name Property_Tax_Municipal_Admin --target-org property-tax-org
```

To assign operational permission sets to other users:
```powershell
# Citizen User
sf org assign permset --name Property_Tax_Citizen --target-org property-tax-org

# Verification Officer
sf org assign permset --name Property_Tax_Verification_Officer --target-org property-tax-org

# Tax Assessor
sf org assign permset --name Property_Tax_Assessor --target-org property-tax-org

# Zonal Head
sf org assign permset --name Property_Tax_Zonal_Head --target-org property-tax-org
```

---

### 5. Seed Demonstration Data

Execute the automated Apex seed data script to populate Chennai zones, tax rate schedules, realistic properties, calculated assessments, and simulated payment records:

```powershell
# Execute seed script in target org
sf apex run --file scripts/apex/sample-data.apex --target-org property-tax-org
```

---

### 6. Run Apex Test Suite

Validate that all business logic, validation rules, triggers, and REST endpoints pass with >= 85% test coverage:

```powershell
# Run all Apex unit tests with coverage reporting
sf apex run test --test-level RunLocalTests --target-org property-tax-org --code-coverage --result-format human
```

---

### 7. Access the Application in Salesforce

1. Log into your Salesforce Developer Edition org in your browser.
2. Click the **App Launcher (9 dots)** in the top left corner.
3. Search for **Smart Property Tax Management**.
4. Open the app to view:
   - **Properties Tab**
   - **Tax Assessments Tab**
   - **Tax Payments Tab**
   - **Verification Requests Tab**
   - **Assessment Disputes Tab**
   - **Tax Rates Tab**
   - **Municipal Admin Dashboard**
