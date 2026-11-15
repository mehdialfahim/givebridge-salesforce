@IsTest
private class DonorSummaryControllerTest {

    @IsTest
    static void getRecentGifts_donorWithSixGifts_returnsFiveNewestFirst() {
        Contact donor = new Contact(LastName = 'Benali', Email = 'amina@example.com');
        insert donor;

        List<Gift__c> gifts = new List<Gift__c>();
        for (Integer i = 0; i < 6; i++) {
            gifts.add(new Gift__c(
                Donor__c = donor.Id,
                Original_Amount__c = 10,
                Original_Currency__c = 'USD',
                Amount_USD__c = 10,
                Gift_Date__c = Date.today().addDays(-i),
                Web_Gift_Id__c = 'D-' + i
            ));
        }
        insert gifts;

        Test.startTest();
        List<Gift__c> result = DonorSummaryController.getRecentGifts(donor.Id);
        Test.stopTest();

        Assert.areEqual(5, result.size(), 'Only the 5 newest gifts are returned');
        Assert.areEqual(Date.today(), result[0].Gift_Date__c, 'Newest gift comes first');
        Assert.areEqual(Date.today().addDays(-4), result[4].Gift_Date__c, 'Fifth gift is the oldest returned');
    }

    @IsTest
    static void getRecentGifts_donorWithNoGifts_returnsEmptyList() {
        Contact donor = new Contact(LastName = 'Benali', Email = 'amina@example.com');
        insert donor;

        Test.startTest();
        List<Gift__c> result = DonorSummaryController.getRecentGifts(donor.Id);
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'No gifts means an empty list');
    }
}