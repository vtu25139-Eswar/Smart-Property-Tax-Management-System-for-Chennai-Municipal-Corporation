import { LightningElement, api, wire, track } from 'lwc';
import getPropertyDetails from '@salesforce/apex/PropertyTaxUIController.getPropertyDetails';

export default class VerificationPriorityBadge extends LightningElement {
    @api recordId;
    @track isModalOpen = false;

    @track property;

    @wire(getPropertyDetails, { propertyId: '$recordId' })
    wiredProperty({ error, data }) {
        if (data) {
            this.property = data;
        }
    }

    get priorityScore() {
        return this.property && this.property.Verification_Priority_Score__c != null
            ? this.property.Verification_Priority_Score__c
            : 0;
    }

    get priorityLevel() {
        return this.property && this.property.Verification_Priority_Level__c
            ? this.property.Verification_Priority_Level__c
            : 'Low';
    }

    get priorityReasons() {
        return this.property && this.property.Priority_Score_Reasons__c
            ? this.property.Priority_Score_Reasons__c
            : 'No breakdown available.';
    }

    get priorityBadgeClass() {
        if (this.priorityLevel === 'High') return 'slds-badge slds-theme_error';
        if (this.priorityLevel === 'Medium') return 'slds-badge slds-theme_warning';
        return 'slds-badge slds-theme_success';
    }

    get priorityIcon() {
        if (this.priorityLevel === 'High') return 'utility:warning';
        if (this.priorityLevel === 'Medium') return 'utility:priority';
        return 'utility:check';
    }

    get iconVariant() {
        if (this.priorityLevel === 'High') return 'error';
        if (this.priorityLevel === 'Medium') return 'warning';
        return 'success';
    }

    handleOpenModal() {
        this.isModalOpen = true;
    }

    handleCloseModal() {
        this.isModalOpen = false;
    }
}
