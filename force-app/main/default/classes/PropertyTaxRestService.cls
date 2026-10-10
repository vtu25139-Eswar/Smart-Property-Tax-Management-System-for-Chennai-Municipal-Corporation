/**
 * @description Secure REST API Endpoint for Chennai Municipal Corporation.
 * Exposes endpoints for citizen mobile apps, payment kiosks, and external municipal systems:
 * - GET  /v1/property-tax/properties/{propertyNumber}
 * - POST /v1/property-tax/payments
 * - POST /v1/property-tax/assess
 */
@RestResource(urlMapping='/v1/property-tax/*')
global with sharing class PropertyTaxRestService {

    global class ApiResponse {
        global Boolean success;
        global String message;
        global Object data;
        global String timestamp;

        global ApiResponse(Boolean success, String message, Object data) {
            this.success = success;
            this.message = message;
            this.data = data;
            this.timestamp = String.valueOf(DateTime.now());
        }
    }

    global class PaymentRequest {
        global String propertyNumber;
        global String assessmentId;
        global Decimal amountPaid;
        global String paymentMode;
        global String payerName;
        global String payerEmail;
        global String payerPhone;
    }

    global class EstimateRequest {
        global Decimal buildingArea;
        global String zone;
        global String propertyType;
        global String propertyUsage;
        global String occupancyType;
        global String financialYear;
    }

    /**
     * @description GET endpoint to look up property and assessment details by property number
     */
    @HttpGet
    global static void handleGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        String path = req.requestURI;
        String propertyNumber = path.substring(path.lastIndexOf('/') + 1);

        if (String.isBlank(propertyNumber) || propertyNumber.equalsIgnoreCase('property-tax')) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf(JSON.serialize(new ApiResponse(false, 'Missing property number in URL path. Format: /v1/property-tax/properties/{propertyNumber}', null)));
            return;
        }

        List<Property__c> properties = [
            SELECT Id, Property_Number__c, Property_Owner_Name__c, Owner_Email__c, Owner_Phone__c,
                   Property_Address__c, Zone__c, Ward__c, Street_Name__c, Property_Type__c,
                   Building_Area_SqFt__c, Occupancy_Type__c, Property_Usage__c, Verification_Status__c,
                   Verification_Priority_Level__c, Assessed_Annual_Tax__c, Outstanding_Dues__c,
                   Current_Assessment_Status__c,
                   (SELECT Id, Name, Assessment_Year__c, Assessment_Date__c, Due_Date__c,
                           Total_Assessed_Tax__c, Paid_Amount__c, Balance_Dues__c, Status__c
                    FROM Tax_Assessments__r ORDER BY CreatedDate DESC LIMIT 5),
                   (SELECT Id, Name, Payment_Reference__c, Amount_Paid__c, Payment_Date__c,
                           Payment_Mode__c, Payment_Status__c, Receipt_Number__c
                    FROM Tax_Payments__r ORDER BY CreatedDate DESC LIMIT 5)
            FROM Property__c
            WHERE Property_Number__c = :propertyNumber.trim().toUpperCase()
            LIMIT 1
        ];

        if (properties.isEmpty()) {
            res.statusCode = 404;
            res.responseBody = Blob.valueOf(JSON.serialize(new ApiResponse(false, 'No property found with number: ' + propertyNumber, null)));
            return;
        }

        res.statusCode = 200;
        res.responseBody = Blob.valueOf(JSON.serialize(new ApiResponse(true, 'Property record retrieved successfully', properties[0])));
    }

    /**
     * @description POST endpoint to process simulated payments or calculate tax estimates
     */
    @HttpPost
    global static void handlePost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        String path = req.requestURI;
        String body = req.requestBody != null ? req.requestBody.toString() : '';

        try {
            if (path.endsWith('/payments')) {
                processPayment(body, res);
            } else if (path.endsWith('/assess')) {
                processEstimate(body, res);
            } else {
                res.statusCode = 404;
                res.responseBody = Blob.valueOf(JSON.serialize(new ApiResponse(false, 'Invalid POST endpoint path. Supported: /payments, /assess', null)));
            }
        } catch (Exception ex) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(new ApiResponse(false, 'Server Error: ' + ex.getMessage(), null)));
        }
    }

    private static void processPayment(String jsonBody, RestResponse res) {
        if (String.isBlank(jsonBody)) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf(JSON.serialize(new ApiResponse(false, 'Request body cannot be empty', null)));
            return;
        }

        PaymentRequest pReq = (PaymentRequest) JSON.deserialize(jsonBody, PaymentRequest.class);

        if (String.isBlank(pReq.propertyNumber) || pReq.amountPaid == null || pReq.amountPaid <= 0) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf(JSON.serialize(new ApiResponse(false, 'Property number and positive amountPaid are required', null)));
            return;
        }

        List<Property__c> props = [
            SELECT Id, Property_Number__c, Property_Owner_Name__c, Owner_Email__c, Outstanding_Dues__c
            FROM Property__c
            WHERE Property_Number__c = :pReq.propertyNumber.trim().toUpperCase()
            LIMIT 1
        ];

        if (props.isEmpty()) {
            res.statusCode = 404;
            res.responseBody = Blob.valueOf(JSON.serialize(new ApiResponse(false, 'Property number not registered: ' + pReq.propertyNumber, null)));
            return;
        }

        Property__c prop = props[0];

        // Locate pending assessment
        Tax_Assessment__c targetAssessment;
        if (String.isNotBlank(pReq.assessmentId)) {
            List<Tax_Assessment__c> asms = [
                SELECT Id, Total_Assessed_Tax__c, Paid_Amount__c, Balance_Dues__c, Status__c, Property__c
                FROM Tax_Assessment__c
                WHERE Id = :pReq.assessmentId AND Property__c = :prop.Id
                LIMIT 1
            ];
            if (!asms.isEmpty()) {
                targetAssessment = asms[0];
            }
        }

        if (targetAssessment == null) {
            List<Tax_Assessment__c> asms = [
                SELECT Id, Total_Assessed_Tax__c, Paid_Amount__c, Balance_Dues__c, Status__c, Property__c
                FROM Tax_Assessment__c
                WHERE Property__c = :prop.Id AND Balance_Dues__c > 0
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            if (!asms.isEmpty()) {
                targetAssessment = asms[0];
            }
        }

        if (targetAssessment == null) {
            // Find most recent assessment even if fully paid
            List<Tax_Assessment__c> asms = [
                SELECT Id, Total_Assessed_Tax__c, Paid_Amount__c, Balance_Dues__c, Status__c, Property__c
                FROM Tax_Assessment__c
                WHERE Property__c = :prop.Id
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            if (!asms.isEmpty()) {
                targetAssessment = asms[0];
            } else {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf(JSON.serialize(new ApiResponse(false, 'No tax assessment exists for this property to apply payment.', null)));
                return;
            }
        }

        Tax_Payment__c pay = new Tax_Payment__c();
        pay.Tax_Assessment__c = targetAssessment.Id;
        pay.Property__c = prop.Id;
        pay.Amount_Paid__c = pReq.amountPaid;
        pay.Payment_Mode__c = String.isNotBlank(pReq.paymentMode) ? pReq.paymentMode : 'Online - UPI';
        pay.Payment_Status__c = 'Success';
        pay.Payer_Name__c = String.isNotBlank(pReq.payerName) ? pReq.payerName : prop.Property_Owner_Name__c;
        pay.Payer_Email__c = String.isNotBlank(pReq.payerEmail) ? pReq.payerEmail : prop.Owner_Email__c;
        pay.Is_Simulated_Transaction__c = true;
        pay.Gateway_Transaction_Id__c = 'REST-SIM-' + Crypto.getRandomLong();

        insert pay;

        // Query created record for receipt details
        Tax_Payment__c insertedPay = [
            SELECT Id, Name, Payment_Reference__c, Amount_Paid__c, Payment_Date__c,
                   Payment_Mode__c, Payment_Status__c, Gateway_Transaction_Id__c,
                   Is_Simulated_Transaction__c
            FROM Tax_Payment__c
            WHERE Id = :pay.Id
        ];

        Map<String, Object> receiptData = new Map<String, Object>{
            'receiptNumber' => insertedPay.Name,
            'paymentReference' => insertedPay.Payment_Reference__c,
            'amountPaid' => insertedPay.Amount_Paid__c,
            'paymentMode' => insertedPay.Payment_Mode__c,
            'propertyNumber' => prop.Property_Number__c,
            'assessmentId' => targetAssessment.Id,
            'isSimulated' => true,
            'municipalNotice' => 'DEMO RECEIPT: This transaction was processed in the Greater Chennai Corporation Sandbox environment.'
        };

        res.statusCode = 201;
        res.responseBody = Blob.valueOf(JSON.serialize(new ApiResponse(true, 'Payment recorded successfully', receiptData)));
    }

    private static void processEstimate(String jsonBody, RestResponse res) {
        if (String.isBlank(jsonBody)) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf(JSON.serialize(new ApiResponse(false, 'Request body cannot be empty', null)));
            return;
        }

        EstimateRequest eReq = (EstimateRequest) JSON.deserialize(jsonBody, EstimateRequest.class);

        if (eReq.buildingArea == null || eReq.buildingArea <= 0) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf(JSON.serialize(new ApiResponse(false, 'Valid buildingArea (> 0) is required', null)));
            return;
        }

        TaxCalculationService.CalculationResult result = TaxCalculationService.calculateTaxEstimator(
            eReq.buildingArea,
            eReq.zone,
            eReq.propertyType,
            eReq.propertyUsage,
            eReq.occupancyType,
            eReq.financialYear
        );

        res.statusCode = 200;
        res.responseBody = Blob.valueOf(JSON.serialize(new ApiResponse(true, 'Tax estimate calculated successfully', result)));
    }
}
