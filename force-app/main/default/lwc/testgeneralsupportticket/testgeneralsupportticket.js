import { LightningElement, track, api} from 'lwc';
import AAT_LOGO from '@salesforce/resourceUrl/AskAcctLogoSR';
import parentPage from './testgeneralsupportticket.html';
import childPage from './testgeneralsupportticketsub.html';

export default class App extends LightningElement {

    @api recordId;

    aatlogo = AAT_LOGO;
    @track parentPage = true;
    @track tickettypevalue;
    @track tickettypelabel;
    @track accounttypevalue;
    @track ticketurgent = false;
    @track currentRecordId;

    get tickettypeoptions() {
        return [
                { label: 'Contract Balance', value: 'ContractBalance' },
                { label: 'Invoice Request', value: 'InvoiceRequest' },
                { label: 'Contact Pro/Payment', value: 'ContactProPayment' },
                { label: 'Contact Pro/Billing Questions', value: 'ContactProBillingQuestions' },
                { label: 'Bad Debt Owed', value: 'BadDebtOwed' },
                { label: 'Payment Status', value: 'PaymentStatus' },
                { label: 'Credit/Make Good Request', value: 'CreditMakeGoodRequest' },
                { label: 'W9 Request', value: 'W9Request' },
                { label: 'Vendor Form Request', value: 'VendorFormRequest' },
                { label: 'Contract Cancellation', value: 'ContractCancellation' },
                { label: 'Recontracting Questions', value: 'RecontractingQuestions' },
                { label: 'CA-ETM Questions', value: 'CAETMQuestions' },
                { label: 'Other', value: 'Other' },
            ];
    }

    get accounttypeoptions() {
        return [
                { label: 'TKWW Account', value: 'TKWWAccount' },
                { label: 'Legacy TK Account', value: 'LegacyTKAccount' },
                { label: 'Legacy WW Account', value: 'LegacyWWAccount' },
            ];
    }

    tickettypedropdownHandler(event) {
        this.tickettypevalue = event.detail.value;
        this.tickettypelabel = event.target.options.find(opt => opt.value === event.detail.value).label;
    }

    accounttypedropdownHandler(event) {
        this.accounttypevalue = event.detail.value;
        this.accounttypelabel = event.target.options.find(opt => opt.value === event.detail.value).label;
    }

    urgenthandler(event) {
        this.ticketurgent = event.target.checked;
    }

    uploadfilehandler(event){
        this.currentRecordId = this.recordId;
        const uploadfile = event.detail.files;
    }

    render() {
        return this.parentPage ? parentPage : childPage;
    }
    nextHandler(){
        if(this.tickettypevalue == null){
            alert("You must select a ticket type!")
        }
        else{
            this.parentPage = this.parentPage === true ? false : true; 
        }
    }

    submitHandler(){
        alert("Submit!")
    }

 
}