public with sharing class GiftSelector {
    public static Map<String, Gift__c> byWebGiftId(Set<String> webGiftIds) {
        Map<String, Gift__c> result = new Map<String, Gift__c>();
        for (Gift__c g : [
            SELECT Id, Web_Gift_Id__c, Donor__c, Amount_USD__c
            FROM Gift__c
            WHERE Web_Gift_Id__c IN :webGiftIds
            WITH USER_MODE
        ]) {
            result.put(g.Web_Gift_Id__c, g);
        }
        return result;
    }
        public static List<Gift__c> recentByDonor(Id donorId, Integer limitSize) {
        return [
            SELECT Id, Name, Amount_USD__c, Original_Amount__c, Original_Currency__c, Gift_Date__c
            FROM Gift__c
            WHERE Donor__c = :donorId
            WITH USER_MODE
            ORDER BY Gift_Date__c DESC
            LIMIT :limitSize
        ];
    }
}