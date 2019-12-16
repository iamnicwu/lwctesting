import { LightningElement, api } from 'lwc';

export default class RecordComponent extends LightningElement {
    @api recordId

    handleConsoleLogClick(event) {
        console.log(this.recordId);
    }
}