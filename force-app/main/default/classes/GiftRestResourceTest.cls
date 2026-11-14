@IsTest
private class GiftRestResourceTest {

    private static void callEndpoint(String jsonBody) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/gifts';
        req.httpMethod = 'POST';
        if (jsonBody != null) {
            req.requestBody = Blob.valueOf(jsonBody);
        }
        RestContext.request = req;
        RestContext.response = new RestResponse();
        GiftRestResource.doPost();
    }

    private static String giftJson(String webGiftId, Decimal amount) {
        return '[{"webGiftId":"' + webGiftId + '",'
            + '"donorEmail":"amina@example.com",'
            + '"donorFirstName":"Amina","donorLastName":"Benali",'
            + '"originalAmount":' + amount + ','
            + '"originalCurrency":"MAD",'
            + '"giftDate":"' + String.valueOf(Date.today().addDays(-1)) + '"}]';
    }

    @IsTest
    static void doPost_newGift_returns201() {
        Test.startTest();
        callEndpoint(giftJson('R-1', 500));
        Test.stopTest();

        Assert.areEqual(201, RestContext.response.statusCode, 'New gift should return 201');
        Assert.isTrue(RestContext.response.responseBody.toString().contains('"created":true'));
        Assert.areEqual(1, [SELECT COUNT() FROM Gift__c WHERE Web_Gift_Id__c = 'R-1']);
    }

    @IsTest
    static void doPost_sameGiftTwice_returns200() {
        callEndpoint(giftJson('R-2', 500));

        Test.startTest();
        callEndpoint(giftJson('R-2', 500));
        Test.stopTest();

        Assert.areEqual(200, RestContext.response.statusCode, 'Repeat should return 200');
        Assert.isTrue(RestContext.response.responseBody.toString().contains('"created":false'));
        Assert.areEqual(1, [SELECT COUNT() FROM Gift__c WHERE Web_Gift_Id__c = 'R-2'], 'No duplicate');
    }

    @IsTest
    static void doPost_negativeAmount_returns400() {
        Test.startTest();
        callEndpoint(giftJson('R-3', -5));
        Test.stopTest();

        Assert.areEqual(400, RestContext.response.statusCode, 'Bad amount should return 400');
        Assert.isTrue(RestContext.response.responseBody.toString().contains('positive'));
        Assert.areEqual(0, [SELECT COUNT() FROM Gift__c], 'Nothing saved');
    }

    @IsTest
    static void doPost_invalidJson_returns400() {
        Test.startTest();
        callEndpoint('{this is not json');
        Test.stopTest();

        Assert.areEqual(400, RestContext.response.statusCode, 'Broken JSON should return 400');
    }

    @IsTest
    static void doPost_emptyBody_returns400() {
        Test.startTest();
        callEndpoint(null);
        Test.stopTest();

        Assert.areEqual(400, RestContext.response.statusCode, 'Empty body should return 400');
    }
}