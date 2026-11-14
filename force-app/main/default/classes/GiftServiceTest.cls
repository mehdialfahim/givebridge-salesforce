@IsTest
private class GiftServiceTest {

    private static GiftService.GiftRequest buildRequest(
        String webGiftId, String email, Decimal amount, String currencyCode
    ) {
        GiftService.GiftRequest r = new GiftService.GiftRequest();
        r.webGiftId = webGiftId;
        r.donorEmail = email;
        r.donorFirstName = 'Amina';
        r.donorLastName = 'Benali';
        r.originalAmount = amount;
        r.originalCurrency = currencyCode;
        r.giftDate = Date.today().addDays(-1);
        return r;
    }

    @IsTest
    static void upsertGifts_newDonor_createsContactAndGift() {
        Test.startTest();
        List<GiftService.GiftResult> results = GiftService.upsertGifts(
            new List<GiftService.GiftRequest>{ buildRequest('T-1', 'amina@example.com', 500, 'MAD') }
        );
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'One result expected');
        Assert.isTrue(results[0].created, 'Gift should be reported as created');

        List<Contact> contacts = [SELECT Id, Total_Given__c FROM Contact WHERE Email = 'amina@example.com'];
        Assert.areEqual(1, contacts.size(), 'Donor should be created');
        Assert.areEqual(50.00, contacts[0].Total_Given__c, 'Roll-up should show 500 MAD as 50 USD');

        Gift__c gift = [SELECT Amount_USD__c, Donor__c FROM Gift__c WHERE Web_Gift_Id__c = 'T-1'];
        Assert.areEqual(50.00, gift.Amount_USD__c, 'MAD converts at 0.10');
        Assert.areEqual(contacts[0].Id, gift.Donor__c, 'Gift should belong to the donor');
    }

    @IsTest
    static void upsertGifts_existingDonor_reusesContact() {
        insert new Contact(FirstName = 'Amina', LastName = 'Benali', Email = 'amina@example.com');

        Test.startTest();
        GiftService.upsertGifts(
            new List<GiftService.GiftRequest>{ buildRequest('T-2', 'AMINA@example.com', 100, 'USD') }
        );
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM Contact WHERE Email = 'amina@example.com'],
            'No duplicate donor, even with different email casing');
    }

    @IsTest
    static void upsertGifts_sameWebGiftIdTwice_updatesInsteadOfDuplicating() {
        GiftService.upsertGifts(
            new List<GiftService.GiftRequest>{ buildRequest('T-3', 'amina@example.com', 100, 'USD') }
        );

        Test.startTest();
        List<GiftService.GiftResult> second = GiftService.upsertGifts(
            new List<GiftService.GiftRequest>{ buildRequest('T-3', 'amina@example.com', 200, 'USD') }
        );
        Test.stopTest();

        Assert.isFalse(second[0].created, 'Second call is an update');
        Assert.areEqual(1, [SELECT COUNT() FROM Gift__c WHERE Web_Gift_Id__c = 'T-3'], 'Still one gift');
        Assert.areEqual(200.00, [SELECT Amount_USD__c FROM Gift__c WHERE Web_Gift_Id__c = 'T-3'].Amount_USD__c,
            'Amount should be updated');
    }

    @IsTest
    static void upsertGifts_negativeAmount_throwsAndSavesNothing() {
        Boolean thrown = false;
        try {
            GiftService.upsertGifts(
                new List<GiftService.GiftRequest>{ buildRequest('T-4', 'amina@example.com', -5, 'USD') }
            );
        } catch (GiftService.GiftServiceException e) {
            thrown = true;
            Assert.isTrue(e.getMessage().contains('positive'), 'Message should explain the problem');
        }
        Assert.isTrue(thrown, 'A negative amount must be rejected');
        Assert.areEqual(0, [SELECT COUNT() FROM Gift__c], 'Nothing should be saved');
    }

    @IsTest
    static void upsertGifts_hundredGifts_staysWithinLimits() {
        List<GiftService.GiftRequest> requests = new List<GiftService.GiftRequest>();
        for (Integer i = 0; i < 100; i++) {
            requests.add(buildRequest('B-' + i, 'donor' + Math.mod(i, 20) + '@example.com', 10, 'EUR'));
        }

        Test.startTest();
        GiftService.upsertGifts(requests);
        Integer queries = Limits.getQueries();
        Test.stopTest();

        Assert.areEqual(100, [SELECT COUNT() FROM Gift__c], 'All gifts saved');
        Assert.areEqual(20, [SELECT COUNT() FROM Contact], 'One donor per distinct email');
        Assert.isTrue(queries <= 3, 'Bulk-safe: query count must not grow with the batch');
    }
}