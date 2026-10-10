@isTest
private class PropertyTaxRestServiceTest {

    @testSetup
    static void setup() {
        TaxTestDataFactory.createTaxRates();
        Property__c prop = TaxTestDataFactory.createSampleProperty('CHN-REST-001', 'Zone 5 - Royapuram', 'Residential', 1200, 'Self-Occupied');
        TaxTestDataFactory.createAssessment(prop.Id, null, 15000, 'Submitted');
    }

    @isTest
    static void testGetPropertySuccess() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/v1/property-tax/properties/CHN-REST-001';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        PropertyTaxRestService.handleGet();
        Test.stopTest();

        System.assertEquals(200, res.statusCode, 'Should return HTTP 200');
        System.assert(res.responseBody.toString().contains('CHN-REST-001'), 'Response should include property number');
    }

    @isTest
    static void testGetPropertyNotFound() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/v1/property-tax/properties/NON-EXISTENT-999';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        PropertyTaxRestService.handleGet();
        Test.stopTest();

        System.assertEquals(404, res.statusCode, 'Should return HTTP 404');
    }

    @isTest
    static void testPostPaymentSuccess() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/v1/property-tax/payments';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"propertyNumber":"CHN-REST-001","amountPaid":5000,"paymentMode":"Online - UPI","payerName":"Karthik"}');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        PropertyTaxRestService.handlePost();
        Test.stopTest();

        System.assertEquals(201, res.statusCode, 'Payment should return HTTP 201');
        System.assert(res.responseBody.toString().contains('PAY-CHN-'), 'Receipt should include payment reference');
        System.assert(res.responseBody.toString().contains('DEMO RECEIPT'), 'Should contain sandbox demo disclaimer');
    }

    @isTest
    static void testPostTaxEstimateSuccess() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/v1/property-tax/assess';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"buildingArea":1500,"zone":"Zone 5 - Royapuram","propertyType":"Residential","propertyUsage":"Residential Individual","occupancyType":"Self-Occupied","financialYear":"2025-2026"}');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        PropertyTaxRestService.handlePost();
        Test.stopTest();

        System.assertEquals(200, res.statusCode, 'Estimate should return HTTP 200');
        System.assert(res.responseBody.toString().contains('totalAssessedTax'), 'Should include computed tax');
    }

    @isTest
    static void testPostInvalidEndpoint() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/v1/property-tax/unknown';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        PropertyTaxRestService.handlePost();
        Test.stopTest();

        System.assertEquals(404, res.statusCode, 'Unknown POST endpoint should return 404');
    }
}
