import { LightningElement, wire, api } from 'lwc';
import getRelevantPutOutTimes from '@salesforce/apex/PutOutTimeController.getRelevantPutOutTimes';

export default class PutOutTimes extends LightningElement {
    @api recordId; // To hold the Account Id
    putOutTimes;

    @wire(getRelevantPutOutTimes, { accountId: '$recordId' })
    wiredPutOutTimes({ error, data }) {
        if (data) {
            this.putOutTimes = data;
        } else if (error) {
            // Handle the error
            console.error(error);
        }
    }
}