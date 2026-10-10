# System Architecture: Smart Property Tax Management System
## Greater Chennai Corporation (GCC)

### 1. Architectural Overview

The **Smart Property Tax Management System** is built natively on the Salesforce Lightning Platform to modernize municipal tax operations for the Greater Chennai Corporation. The platform digitizes property registration, physical verification prioritization, explainable tax calculation, multi-level approvals, payment reconciliation, and citizen grievances.

```mermaid
flowchart TD
    subgraph Citizens & External Channels
        CitizenUI[Citizen Self-Service / LWC Portal]
        MobileAPI[Mobile App & Citizen Kiosks via REST API]
    end

    subgraph Salesforce Lightning Platform
        subgraph Presentation Layer
            LWC1[Property Registration Form LWC]
            LWC2[Tax Assessment Calculator LWC]
            LWC3[Property Tax Summary Card LWC]
            LWC4[Verification Priority Badge LWC]
            LWC5[Municipal Admin Dashboard LWC]
        end

        subgraph Business Logic & Apex Services
            TaxCalc[TaxCalculationService.cls]
            ScoreSvc[PropertyVerificationScoreService.cls]
            UIController[PropertyTaxUIController.cls]
            RestAPI[PropertyTaxRestService.cls @RestResource]
        end

        subgraph Event Handlers & Automation
            PropTrig[PropertyTrigger / Handler]
            AsmTrig[TaxAssessmentTrigger / Handler]
            PayTrig[TaxPaymentTrigger / Handler]
            StatusFlow[Property Assessment Status Sync Flow]
            EscFlow[Property Verification Escalation Flow]
        end

        subgraph Asynchronous Processing Layer
            BatchJob[TaxReassessmentBatch.cls - Batchable]
            Scheduler[TaxOverdueScheduler.cls - Schedulable]
            QueueableJob[PropertyTaxNotificationQueueable.cls]
        end

        subgraph Enterprise Data Layer
            PropObj[(Property__c)]
            RateObj[(Tax_Rate__c)]
            AsmObj[(Tax_Assessment__c)]
            PayObj[(Tax_Payment__c)]
            VerObj[(Verification_Request__c)]
            DispObj[(Assessment_Dispute__c)]
        end
    end

    CitizenUI --> Presentation Layer
    MobileAPI --> RestAPI
    Presentation Layer --> UIController
    UIController --> TaxCalc
    UIController --> ScoreSvc
    UIController --> Enterprise Data Layer
    RestAPI --> TaxCalc
    RestAPI --> Enterprise Data Layer

    Enterprise Data Layer --> PropTrig
    Enterprise Data Layer --> AsmTrig
    Enterprise Data Layer --> PayTrig
    PropTrig --> ScoreSvc
    AsmTrig --> TaxCalc
    AsmTrig --> StatusFlow
    PropTrig --> EscFlow

    Scheduler --> BatchJob
    BatchJob --> TaxCalc
    BatchJob --> QueueableJob
    BatchJob --> Enterprise Data Layer
```

---

### 2. Core Architectural Pillars

#### A. Explainable Computation Engine (`TaxCalculationService.cls`)
Unlike opaque "black box" tax calculators, the calculation service evaluates configurable `Tax_Rate__c` records based on:
1. **Municipal Zone** (Zones 1 to 15, or fallback to 'All Zones')
2. **Property Type & Usage** (Residential Individual, Apartment, Retail Commercial, Corporate Office)
3. **Plinth Built-Up Area** (in square feet)
4. **Occupancy Classification** (Self-Occupied vs. Tenanted vs. Vacant)
5. **Statutory Tamil Nadu Cesses**:
   - **Tamil Nadu Public Libraries Act**: 10% Library Cess on net property tax.
   - **Municipal Surcharge / Education Cess**: 5% on net property tax.
   - **Self-Occupied Concession**: 10% maintenance rebate for self-occupied residential dwellings.

Every calculation returns a comprehensive mathematical explanation string explaining each multiplication and deduction step.

#### B. Objective Administrative Scoring Engine (`PropertyVerificationScoreService.cls`)
Prioritizes physical inspection workloads without biased human discretion. Evaluates:
- Initial registration / unverified baseline (+25 pts)
- Missing owner telephone or email (+10 pts each)
- High-value commercial / large plinth area >= 5,000 sq ft (+15 pts each)
- Heavy municipal arrears >= ₹50,000 (+20 pts)
- Structural building age >= 50 years (+10 pts)
- Unresolved discrepancy status (+30 pts)

Scores are tiered into **Low (<30)**, **Medium (30-65)**, and **High (>65)** priority tiers with full audit explanations.

#### C. Separation of Duties & Multi-Stage Approval
- Assessors calculate and propose assessments (`Status__c = 'Submitted'`).
- The trigger blocks approval if the property is currently marked with a **Discrepancy Flagged** verification status.
- Only authorized officers (Zonal Head / Municipal Admin) can approve assessments, recording `Approved_By__c` and `Approval_Date__c`.

#### D. Batch & Asynchronous Operations
- **`TaxReassessmentBatch`**: Bulkifies processing of thousands of municipal properties per zone.
- **`TaxOverdueScheduler`**: Audits overdue assessments nightly and applies statutory 2% late payment fees.
- **`PropertyTaxNotificationQueueable`**: Decouples receipt generation and communication dispatches from synchronous UI transactions.

#### E. REST API Integration Architecture
- Endpoint: `@RestResource(urlMapping='/v1/property-tax/*')`
- Exposes GET property lookup, POST tax estimation, and POST simulated payment execution.
- Includes rate limiting protection, parameter validation, and explicit simulation watermarks.
