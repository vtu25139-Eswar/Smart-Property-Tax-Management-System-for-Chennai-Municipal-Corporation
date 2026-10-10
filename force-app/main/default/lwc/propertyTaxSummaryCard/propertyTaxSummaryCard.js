import { LightningElement, api, wire, track } from 'lwc';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPropertyDetails from '@salesforce/apex/PropertyTaxUIController.getPropertyDetails';
import processSimulatedPayment from '@salesforce/apex/PropertyTaxUIController.processSimulatedPayment';
import submitDispute from '@salesforce/apex/PropertyTaxUIController.submitDispute';

export default class PropertyTaxSummaryCard extends LightningElement {
    @api recordId;
    @track property;
    @track isLoading = false;

    // Modals
    @track isDisputeModalOpen = false;
    @track isPaymentModalOpen = false;

    // Payment fields
    paymentAmount = 0;
    paymentMode = 'Online - UPI';
    payerName = '';
    payerEmail = '';
    @track receipt;

    // Dispute fields
    disputeReason = 'Incorrect Area Measurement';
    claimedArea = 0;
    disputeDescription = '';

    paymentModeOptions = [
        { label: 'Online - UPI (GPay / PhonePe / Paytm)', value: 'Online - UPI' },
        { label: 'Online - Net Banking', value: 'Online - Net Banking' },
        { label: 'Credit / Debit Card', value: 'Credit/Debit Card' },
        { label: 'Municipal Counter - Cash', value: 'Municipal Counter - Cash' },
        { label: 'Municipal Counter - DD', value: 'Municipal Counter - DD' }
    ];

    disputeReasonOptions = [
        { label: 'Incorrect Area Measurement', value: 'Incorrect Area Measurement' },
        { label: 'Wrong Rate Classification', value: 'Wrong Rate Classification' },
        { label: 'Unapplied Concession/Rebate', value: 'Unapplied Concession/Rebate' },
        { label: 'Ownership Mismatch', value: 'Ownership Mismatch' },
        { label: 'Other', value: 'Other' }
    ];

    connectedCallback() {
        this.loadPropertyData();
    }

    loadPropertyData() {
        if (!this.recordId) return;
        this.isLoading = true;
        getPropertyDetails({ propertyId: this.recordId })
            .then(data => {
                this.isLoading = false;
                this.property = data;
                if (data) {
                    this.paymentAmount = data.Outstanding_Dues__c > 0 ? data.Outstanding_Dues__c : (data.Assessed_Annual_Tax__c || 0);
                    this.payerName = data.Property_Owner_Name__c;
                    this.payerEmail = data.Owner_Email__c;
                    this.claimedArea = data.Building_Area_SqFt__c;
                }
            })
            .catch(err => {
                this.isLoading = false;
            });
    }

    get formattedDues() {
        return (this.property && this.property.Outstanding_Dues__c != null)
            ? Number(this.property.Outstanding_Dues__c).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
            : '0.00';
    }

    get formattedTax() {
        return (this.property && this.property.Assessed_Annual_Tax__c != null)
            ? Number(this.property.Assessed_Annual_Tax__c).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
            : '0.00';
    }

    get verificationBadgeClass() {
        const st = this.property ? this.property.Verification_Status__c : '';
        if (st === 'Verified') return 'slds-badge slds-theme_success';
        if (st === 'Discrepancy Flagged') return 'slds-badge slds-theme_error';
        if (st === 'Needs Re-Inspection') return 'slds-badge slds-theme_warning';
        return 'slds-badge';
    }

    get priorityBadgeClass() {
        const lvl = this.property ? this.property.Verification_Priority_Level__c : 'Low';
        if (lvl === 'High') return 'slds-badge slds-theme_error';
        if (lvl === 'Medium') return 'slds-badge slds-theme_warning';
        return 'slds-badge slds-theme_success';
    }

    handleOpenPaymentModal() { this.receipt = null; this.isPaymentModalOpen = true; }
    handleClosePaymentModal() { this.isPaymentModalOpen = false; }
    handlePaymentAmountChange(e) { this.paymentAmount = e.target.value; }
    handlePaymentModeChange(e) { this.paymentMode = e.target.value; }
    handlePayerNameChange(e) { this.payerName = e.target.value; }
    handlePayerEmailChange(e) { this.payerEmail = e.target.value; }

    handleExecutePayment() {
        if (!this.paymentAmount || this.paymentAmount <= 0) {
            this.showToast('Validation Error', 'Payment amount must be greater than zero.', 'error');
            return;
        }

        this.isLoading = true;
        // Find assessment if available or let controller resolve
        processSimulatedPayment({
            assessmentId: null, // UI controller queries open assessment
            propertyId: this.recordId,
            amount: parseFloat(this.paymentAmount),
            paymentMode: this.paymentMode,
            payerName: this.payerName,
            payerEmail: this.payerEmail
        })
        .then(receiptRecord => {
            this.isLoading = false;
            this.receipt = receiptRecord;
            this.showToast('Payment Successful', `Simulated receipt generated: ${receiptRecord.Payment_Reference__c}`, 'success');
            getRecordNotifyChange([{ recordId: this.recordId }]);
            this.loadPropertyData();
        })
        .catch(err => {
            this.isLoading = false;
            const msg = err.body && err.body.message ? err.body.message : err.message;
            this.showToast('Payment Error', msg, 'error');
        });
    }

    handleOpenDisputeModal() { this.isDisputeModalOpen = true; }
    handleCloseDisputeModal() { this.isDisputeModalOpen = false; }
    handleDisputeReasonChange(e) { this.disputeReason = e.target.value; }
    handleClaimedAreaChange(e) { this.claimedArea = e.target.value; }
    handleDisputeDescChange(e) { this.disputeDescription = e.target.value; }

    handleSubmitDispute() {
        if (!this.disputeDescription) {
            this.showToast('Validation Error', 'Please specify grievance details.', 'error');
            return;
        }

        this.isLoading = true;
        submitDispute({
            assessmentId: null,
            propertyId: this.recordId,
            reason: this.disputeReason,
            description: this.disputeDescription,
            claimedArea: parseFloat(this.claimedArea)
        })
        .then(() => {
            this.isLoading = false;
            this.isDisputeModalOpen = false;
            this.showToast('Grievance Filed', 'Dispute ticket registered and assigned for hearing.', 'warning');
            getRecordNotifyChange([{ recordId: this.recordId }]);
            this.loadPropertyData();
        })
        .catch(err => {
            this.isLoading = false;
            const msg = err.body && err.body.message ? err.body.message : err.message;
            this.showToast('Error', msg, 'error');
        });
    }

    handleOpenPriorityModal() {
        if (this.property && this.property.Priority_Score_Reasons__c) {
            alert(this.property.Priority_Score_Reasons__c);
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
