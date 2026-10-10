# Testing & Quality Assurance Guide
## Smart Property Tax Management System

### 1. Test Architecture & Coverage Summary

The system is tested by comprehensive Apex test classes targeting all business logic, bulk processing, triggers, asynchronous batches, schedulers, and REST API endpoints.

| Test Class | Target Component | Scenarios Tested |
| :--- | :--- | :--- |
| `TaxCalculationServiceTest` | `TaxCalculationService.cls` | Self-occupied 10% rebate, tenanted calculations, library/education cess math, commercial rate lookup, edge cases & null input handling |
| `PropertyVerificationScoreTest`| `PropertyVerificationScoreService.cls`| High priority score (>=65), Low priority (<30), bulk scoring of 50+ records, factor itemization |
| `PropertyTriggerTest` | `PropertyTrigger`, `PropertyTriggerHandler` | Before insert property number formatting, auto-creation of verification work item, score recalculation on field update, duplicate prevention, 100+ bulk insert |
| `TaxAssessmentTriggerTest` | `TaxAssessmentTrigger`, `Handler` | Balance dues calculation, default due date, blocking approval when property has flagged discrepancy, valid approval audit fields, rollup sync |
| `TaxPaymentTriggerTest` | `TaxPaymentTrigger`, `Handler` | Unique payment reference generation, simulated transaction flag, validation of positive amount, assessment balance settlement, status change to 'Paid' |
| `TaxReassessmentBatchTest` | `TaxReassessmentBatch`, `Scheduler` | Batch execution across properties, generation of new annual assessments, scheduling batch and overdue auditor jobs |
| `PropertyTaxRestServiceTest` | `PropertyTaxRestService.cls` | GET property by number (200, 404), POST payment simulation (201), POST on-the-fly tax estimate (200), bad request handling (400, 404) |
| `PropertyTaxUIControllerTest` | `PropertyTaxUIController.cls` | LWC controller methods: `getPropertyDetails`, `registerProperty`, `calculateEstimate`, `processSimulatedPayment`, `getMunicipalAdminMetrics`, `submitDispute` |

---

### 2. Executing Apex Tests via Salesforce CLI

#### Run All Local Tests with Code Coverage:
```powershell
sf apex run test --test-level RunLocalTests --target-org property-tax-org --code-coverage --result-format human
```

#### Run Specific Test Class:
```powershell
sf apex run test --class-names TaxCalculationServiceTest --target-org property-tax-org --result-format human
```

---

### 3. REST API Testing Guide

#### A. GET Property Details
**Request:**
```bash
curl -X GET "https://<INSTANCE_URL>/services/apexrest/v1/property-tax/properties/CHN-ZN05-W052-1001" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -H "Content-Type: application/json"
```

**Expected Response (HTTP 200):**
```json
{
  "success": true,
  "message": "Property record retrieved successfully",
  "data": {
    "Property_Number__c": "CHN-ZN05-W052-1001",
    "Property_Owner_Name__c": "Karthik Subramanian",
    "Zone__c": "Zone 5 - Royapuram",
    "Building_Area_SqFt__c": 1200.0,
    "Verification_Status__c": "Verified",
    "Assessed_Annual_Tax__c": 15525.0,
    "Outstanding_Dues__c": 0.0
  },
  "timestamp": "2026-10-10 10:30:00"
}
```

---

#### B. POST On-the-Fly Tax Estimation
**Request:**
```bash
curl -X POST "https://<INSTANCE_URL>/services/apexrest/v1/property-tax/assess" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -H "Content-Type: application/json" \
     -d '{
       "buildingArea": 1500,
       "zone": "Zone 5 - Royapuram",
       "propertyType": "Residential",
       "propertyUsage": "Residential Individual",
       "occupancyType": "Self-Occupied",
       "financialYear": "2025-2026"
     }'
```

**Expected Response (HTTP 200):**
```json
{
  "success": true,
  "message": "Tax estimate calculated successfully",
  "data": {
    "buildingArea": 1500.00,
    "appliedBaseRate": 12.00,
    "grossBaseTax": 18000.00,
    "rebateAmount": 1800.00,
    "netBaseTax": 16200.00,
    "libraryCess": 1620.00,
    "educationCess": 810.00,
    "totalAssessedTax": 18630.00,
    "explanation": "=== GREATER CHENNAI CORPORATION TAX ASSESSMENT (2025-2026) ===\n1. Assessed Plinth Area: 1500.00 sq ft..."
  }
}
```

---

#### C. POST Simulated Citizen Tax Payment
**Request:**
```bash
curl -X POST "https://<INSTANCE_URL>/services/apexrest/v1/property-tax/payments" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -H "Content-Type: application/json" \
     -d '{
       "propertyNumber": "CHN-ZN05-W052-1001",
       "amountPaid": 5000.00,
       "paymentMode": "Online - UPI",
       "payerName": "Karthik Subramanian",
       "payerEmail": "karthik.subramanian@example.com"
     }'
```

**Expected Response (HTTP 201 Created):**
```json
{
  "success": true,
  "message": "Payment recorded successfully",
  "data": {
    "paymentReference": "PAY-CHN-20261010-829104",
    "receiptNumber": "RCPT-2025-00042",
    "amountPaid": 5000.0,
    "paymentMode": "Online - UPI",
    "isSimulated": true,
    "municipalNotice": "DEMO RECEIPT: This transaction was processed in the Greater Chennai Corporation Sandbox environment."
  }
}
```
