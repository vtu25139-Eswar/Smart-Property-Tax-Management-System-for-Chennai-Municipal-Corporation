import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import registerProperty from '@salesforce/apex/PropertyTaxUIController.registerProperty';
import calculateEstimate from '@salesforce/apex/PropertyTaxUIController.calculateEstimate';

export default class PropertyRegistrationForm extends NavigationMixin(LightningElement) {
    @track isLoading = false;

    // Form inputs
    propertyNumber = '';
    selectedZone = 'Zone 5 - Royapuram';
    ward = '';
    street = '';
    address = '';
    selectedType = 'Residential';
    selectedUsage = 'Residential Individual';
    selectedOccupancy = 'Self-Occupied';
    buildingArea = 1200;
    constructionYear = 2020;
    ownerName = '';
    ownerEmail = '';
    ownerPhone = '';

    // Estimated Tax Preview
    previewTaxAmount = '18,630.00';

    zoneOptions = [
        { label: 'Zone 1 - Thiruvottiyur', value: 'Zone 1 - Thiruvottiyur' },
        { label: 'Zone 2 - Manali', value: 'Zone 2 - Manali' },
        { label: 'Zone 3 - Madhavaram', value: 'Zone 3 - Madhavaram' },
        { label: 'Zone 4 - Tondiarpet', value: 'Zone 4 - Tondiarpet' },
        { label: 'Zone 5 - Royapuram', value: 'Zone 5 - Royapuram' },
        { label: 'Zone 6 - Thiru Vi Ka Nagar', value: 'Zone 6 - Thiru Vi Ka Nagar' },
        { label: 'Zone 7 - Ambattur', value: 'Zone 7 - Ambattur' },
        { label: 'Zone 8 - Annanagar', value: 'Zone 8 - Annanagar' },
        { label: 'Zone 9 - Teynampet', value: 'Zone 9 - Teynampet' },
        { label: 'Zone 10 - Kodambakkam', value: 'Zone 10 - Kodambakkam' },
        { label: 'Zone 11 - Valasaravakkam', value: 'Zone 11 - Valasaravakkam' },
        { label: 'Zone 12 - Alandur', value: 'Zone 12 - Alandur' },
        { label: 'Zone 13 - Adyar', value: 'Zone 13 - Adyar' },
        { label: 'Zone 14 - Perungudi', value: 'Zone 14 - Perungudi' },
        { label: 'Zone 15 - Sholinganallur', value: 'Zone 15 - Sholinganallur' }
    ];

    typeOptions = [
        { label: 'Residential', value: 'Residential' },
        { label: 'Commercial', value: 'Commercial' },
        { label: 'Industrial', value: 'Industrial' },
        { label: 'Mixed-Use', value: 'Mixed-Use' },
        { label: 'Vacant Land', value: 'Vacant Land' }
    ];

    usageOptions = [
        { label: 'Residential Individual', value: 'Residential Individual' },
        { label: 'Apartment Complex', value: 'Apartment Complex' },
        { label: 'Retail Commercial', value: 'Retail Commercial' },
        { label: 'Corporate Office', value: 'Corporate Office' },
        { label: 'Industrial Warehouse', value: 'Industrial Warehouse' },
        { label: 'Educational/Hospital', value: 'Educational/Hospital' }
    ];

    occupancyOptions = [
        { label: 'Self-Occupied', value: 'Self-Occupied' },
        { label: 'Tenanted', value: 'Tenanted' },
        { label: 'Vacant', value: 'Vacant' },
        { label: 'Government/Exempt', value: 'Government/Exempt' }
    ];

    connectedCallback() {
        this.fetchPreviewEstimate();
    }

    handlePropNumberChange(e) { this.propertyNumber = e.target.value; }
    handleZoneChange(e) { this.selectedZone = e.target.value; this.fetchPreviewEstimate(); }
    handleWardChange(e) { this.ward = e.target.value; }
    handleStreetChange(e) { this.street = e.target.value; }
    handleAddressChange(e) { this.address = e.target.value; }
    handleTypeChange(e) { this.selectedType = e.target.value; this.fetchPreviewEstimate(); }
    handleUsageChange(e) { this.selectedUsage = e.target.value; this.fetchPreviewEstimate(); }
    handleOccupancyChange(e) { this.selectedOccupancy = e.target.value; this.fetchPreviewEstimate(); }
    handleAreaChange(e) { this.buildingArea = e.target.value; this.fetchPreviewEstimate(); }
    handleYearChange(e) { this.constructionYear = e.target.value; }
    handleOwnerNameChange(e) { this.ownerName = e.target.value; }
    handleOwnerEmailChange(e) { this.ownerEmail = e.target.value; }
    handleOwnerPhoneChange(e) { this.ownerPhone = e.target.value; }

    fetchPreviewEstimate() {
        if (!this.buildingArea || this.buildingArea <= 0) return;

        calculateEstimate({
            area: parseFloat(this.buildingArea),
            zone: this.selectedZone,
            propType: this.selectedType,
            propUsage: this.selectedUsage,
            occupancy: this.selectedOccupancy,
            financialYear: '2025-2026'
        })
        .then(result => {
            if (result && result.totalAssessedTax) {
                this.previewTaxAmount = Number(result.totalAssessedTax).toLocaleString('en-IN', {
                    minimumFractionDigits: 2,
                    maximumFractionDigits: 2
                });
            }
        })
        .catch(err => {
            // Ignore preview calculation errors in background
        });
    }

    handleRegister() {
        if (!this.propertyNumber || !this.ownerName || !this.buildingArea) {
            this.showToast('Validation Error', 'Please complete all required fields.', 'error');
            return;
        }

        this.isLoading = true;

        const propertyRecord = {
            Property_Number__c: this.propertyNumber,
            Property_Owner_Name__c: this.ownerName,
            Owner_Email__c: this.ownerEmail,
            Owner_Phone__c: this.ownerPhone,
            Property_Address__c: this.address,
            Zone__c: this.selectedZone,
            Ward__c: this.ward,
            Street_Name__c: this.street,
            Property_Type__c: this.selectedType,
            Property_Usage__c: this.selectedUsage,
            Occupancy_Type__c: this.selectedOccupancy,
            Building_Area_SqFt__c: parseFloat(this.buildingArea),
            Construction_Year__c: this.constructionYear ? parseInt(this.constructionYear, 10) : null,
            Verification_Status__c: 'Unverified'
        };

        registerProperty({ property: propertyRecord })
            .then(recordId => {
                this.isLoading = false;
                this.showToast(
                    'Success',
                    `Property registered successfully! Initial verification request has been queued.`,
                    'success'
                );

                // Navigate to newly created record
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: recordId,
                        objectApiName: 'Property__c',
                        actionName: 'view'
                    }
                });
            })
            .catch(error => {
                this.isLoading = false;
                const msg = error.body && error.body.message ? error.body.message : error.message;
                this.showToast('Registration Error', msg, 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
