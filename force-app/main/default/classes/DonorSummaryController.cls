public with sharing class DonorSummaryController {

    @AuraEnabled(cacheable=true)
    public static List<Gift__c> getRecentGifts(Id contactId) {
        return GiftSelector.recentByDonor(contactId, 5);
    }
}