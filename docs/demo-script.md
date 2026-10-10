# HR & Technical Interview Demonstration Script
## Smart Property Tax Management System (Greater Chennai Corporation)

### Presentation Overview (Target Duration: 15–20 minutes)
This script guides you through demonstrating the project to Hackathon evaluators, HR interviewers, or Salesforce architects.

---

### Phase 1: Context & Problem Statement (2 Minutes)
- **Speaker:** *"Good morning/afternoon. Today I am presenting the Smart Property Tax Management System developed for the Greater Chennai Corporation (GCC). In large municipal corporations like Chennai, property tax is the single largest source of local civic revenue. However, manual assessments suffer from three critical bottlenecks: opaque calculations that trigger resident disputes, unprioritized inspection queues that waste surveyor hours, and fragmented revenue reporting."*
- **Action:** Open the **Smart Property Tax Management** app in Salesforce Lightning.
- **Key Message:** *"Our solution leverages Salesforce Lightning Web Components, configurable Apex calculation engines, automated scoring algorithms, and secure REST APIs to create an end-to-end transparent municipal tax lifecycle."*

---

### Phase 2: Citizen Registration & Real-Time Estimation (3 Minutes)
- **Speaker:** *"Let's begin from the citizen's perspective. When a resident registers a property, they need clarity on their expected assessment before submission."*
- **Action:** Open the **Property Registration Form LWC**.
  1. Enter Property Assessment Number: `CHN-ZN08-W104-5555`.
  2. Select Zone: `Zone 8 - Annanagar`.
  3. Enter Plinth Area: `1,500 sq ft`.
  4. Select Property Type: `Residential` | Usage: `Residential Individual` | Occupancy: `Self-Occupied`.
  5. Point to the **Instant Estimation Preview card**: *"Notice how as soon as I enter the area and occupancy, our reactive LWC calls the Apex calculation engine in the background. The citizen immediately sees ₹18,630.00 estimated tax."*
  6. Fill in Owner particulars and click **Register Property**.
- **Result:** Toast notification confirms registration and automatically navigates to the newly created record.

---

### Phase 3: Automated Verification Scoring & Field Queue (3 Minutes)
- **Speaker:** *"Now let's step into the shoes of the Municipal Verification Officer. When a property is registered, our `PropertyTrigger` immediately computes an objective Verification Priority Score."*
- **Action:** View the Property Record page and highlight the **Verification Priority Badge LWC**.
  1. Click **Audit Breakdown** on the badge.
  2. Explain the modal: *"Notice how the system itemizes every factor: +25 for initial unverified status, +15 for area, etc. This ensures administrative decisions are completely transparent, objective, and auditable."*
  3. Show the related **Verification Requests** list: *"Our trigger automatically created a queued field inspection task, ensuring no registered property slips through municipal cracks."*

---

### Phase 4: Transparent Tax Assessment & Separation of Duties (4 Minutes)
- **Speaker:** *"Next, let's examine the Assessment Phase. Most tax disputes arise because property owners cannot understand how their tax was computed."*
- **Action:** Open the **Tax Assessment** record.
  1. Highlight the financial breakdown: Gross Base Tax, 10% Self-Occupied Rebate, Tamil Nadu Library Cess (10%), and Education Surcharge (5%).
  2. Scroll to the **Calculation Explanation** field: *"Here is our transparent mathematical audit trail. It explains every single multiplication and deduction step."*
  3. Show Approval Workflow: Attempt to approve a record whose parent property has a flagged discrepancy. Show the custom Apex trigger blocking invalid approvals to enforce separation of duties.

---

### Phase 5: Simulated Citizen Payment & Official Receipt (3 Minutes)
- **Speaker:** *"Once assessed, the citizen can settle their dues online or at municipal counters."*
- **Action:** On the Property page, click **Simulate Payment** on the **Property Tax Summary Card LWC**.
  1. Select Payment Channel: `Online - UPI`.
  2. Enter Amount: `₹5,000.00`.
  3. Point to the yellow badge: *"Note that our system clearly marks this as a sandbox demonstration workflow, ensuring zero ambiguity about real banking transfers."*
  4. Click **Authorize Simulated Payment**.
  5. Show the generated **Municipal Tax Receipt** with unique Reference ID `PAY-CHN-XXXXXX`.
  6. Point out how the **Outstanding Dues** immediately decrease from ₹15,525 to ₹10,525 in real time!

---

### Phase 6: Municipal Commissioner Command Center (3 Minutes)
- **Speaker:** *"Finally, let's look at the Municipal Admin Dashboard designed for Zonal Commissioners and the Revenue Secretary."*
- **Action:** Open the **Municipal Admin Dashboard LWC**.
  1. Highlight KPI metric tiles: Total Registered Properties, Assessed Revenue Base, Collections Realized, Outstanding Municipal Arrears, and Collection Efficiency %.
  2. Highlight the **Verification Queue Backlog** and **High-Priority Target bars**.
  3. Show the **Zone-wise Distribution Table** comparing Royapuram, Anna Nagar, T. Nagar, and Adyar.

---

### Phase 7: Technical Architecture & Code Highlights (2 Minutes)
- **Speaker:** *"To summarize the technical architecture:
  - 6 Custom Objects with master-detail rollups and validation rules.
  - 10 Production-grade Apex classes and trigger handlers written with strict sharing and bulk safety.
  - Comprehensive unit tests covering positive, negative, and bulk limits with high code coverage.
  - 5 responsive Lightning Web Components following SLDS design guidelines.
  - Secure REST API endpoint enabling external mobile and kiosk integrations.
  - 5 tailored Permission Sets enforcing least-privilege security."*
- **Closing:** *"Thank you! I am now happy to take any technical questions on Apex design, bulkification, or data model architecture."*
