import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getRecentGifts from '@salesforce/apex/DonorSummaryController.getRecentGifts';

import TOTAL_GIVEN from '@salesforce/schema/Contact.Total_Given__c';
import GIFT_COUNT from '@salesforce/schema/Contact.Gift_Count__c';
import DONOR_LEVEL from '@salesforce/schema/Contact.Donor_Level__c';
import LAST_GIFT_DATE from '@salesforce/schema/Contact.Last_Gift_Date__c';

export default class DonorSummary extends LightningElement {
    @api recordId;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [TOTAL_GIVEN, GIFT_COUNT, DONOR_LEVEL, LAST_GIFT_DATE]
    })
    contact;

    @wire(getRecentGifts, { contactId: '$recordId' })
    gifts;

    get totalGiven() {
        return getFieldValue(this.contact.data, TOTAL_GIVEN);
    }
    get giftCount() {
        return getFieldValue(this.contact.data, GIFT_COUNT);
    }
    get donorLevel() {
        return getFieldValue(this.contact.data, DONOR_LEVEL);
    }
    get lastGiftDate() {
        return getFieldValue(this.contact.data, LAST_GIFT_DATE);
    }
    get hasGifts() {
        return this.gifts.data && this.gifts.data.length > 0;
    }
    get hasError() {
        return Boolean(this.contact.error || this.gifts.error);
    }
}