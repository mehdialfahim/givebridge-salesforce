public with sharing class GiftService {

    public class GiftRequest {
        public String webGiftId;
        public String donorEmail;
        public String donorFirstName;
        public String donorLastName;
        public Decimal originalAmount;
        public String originalCurrency;
        public Date giftDate;
    }

    public class GiftResult {
        public String webGiftId;
        public Id giftId;
        public Boolean created;
    }

    public class GiftServiceException extends Exception {}

    // Demo rates only. A real version would use live rates or store the rate on each gift.
    @TestVisible
    private static final Map<String, Decimal> USD_RATES = new Map<String, Decimal>{
        'USD' => 1.0, 'EUR' => 1.08, 'MAD' => 0.10
    };

    public static List<GiftResult> upsertGifts(List<GiftRequest> requests) {
        validate(requests);

        Set<String> emails = new Set<String>();
        Set<String> webGiftIds = new Set<String>();
        for (GiftRequest r : requests) {
            emails.add(r.donorEmail.toLowerCase());
            webGiftIds.add(r.webGiftId);
        }

        Map<String, Contact> contactsByEmail = ContactSelector.byEmail(emails);
        Map<String, Gift__c> existingGifts = GiftSelector.byWebGiftId(webGiftIds);

        List<Contact> newContacts = new List<Contact>();
        for (GiftRequest r : requests) {
            String key = r.donorEmail.toLowerCase();
            if (!contactsByEmail.containsKey(key)) {
                Contact c = new Contact(
                    FirstName = r.donorFirstName,
                    LastName = String.isBlank(r.donorLastName) ? r.donorEmail : r.donorLastName,
                    Email = r.donorEmail
                );
                contactsByEmail.put(key, c);
                newContacts.add(c);
            }
        }
        insert as user newContacts;

        List<Gift__c> gifts = new List<Gift__c>();
        for (GiftRequest r : requests) {
            gifts.add(new Gift__c(
                Web_Gift_Id__c = r.webGiftId,
                Donor__c = contactsByEmail.get(r.donorEmail.toLowerCase()).Id,
                Original_Amount__c = r.originalAmount,
                Original_Currency__c = r.originalCurrency,
                Amount_USD__c = (r.originalAmount * USD_RATES.get(r.originalCurrency)).setScale(2),
                Gift_Date__c = r.giftDate
            ));
        }
        upsert as user gifts Gift__c.Web_Gift_Id__c;

        List<GiftResult> results = new List<GiftResult>();
        for (Gift__c g : gifts) {
            GiftResult res = new GiftResult();
            res.webGiftId = g.Web_Gift_Id__c;
            res.giftId = g.Id;
            res.created = !existingGifts.containsKey(g.Web_Gift_Id__c);
            results.add(res);
        }
        return results;
    }

    private static void validate(List<GiftRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new GiftServiceException('At least one gift is required.');
        }
        Set<String> seen = new Set<String>();
        for (GiftRequest r : requests) {
            if (String.isBlank(r.webGiftId)) {
                throw new GiftServiceException('webGiftId is required.');
            }
            if (!seen.add(r.webGiftId)) {
                throw new GiftServiceException('Duplicate webGiftId in request: ' + r.webGiftId);
            }
            if (String.isBlank(r.donorEmail)) {
                throw new GiftServiceException('donorEmail is required for ' + r.webGiftId);
            }
            if (r.originalAmount == null || r.originalAmount <= 0) {
                throw new GiftServiceException('originalAmount must be positive for ' + r.webGiftId);
            }
            if (r.originalCurrency == null || !USD_RATES.containsKey(r.originalCurrency)) {
                throw new GiftServiceException('originalCurrency must be MAD, EUR or USD for ' + r.webGiftId);
            }
            if (r.giftDate == null || r.giftDate > Date.today()) {
                throw new GiftServiceException('giftDate is required and cannot be in the future for ' + r.webGiftId);
            }
        }
    }
}