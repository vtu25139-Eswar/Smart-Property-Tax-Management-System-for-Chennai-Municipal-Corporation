import { LightningElement, track } from 'lwc';
import calculateEstimate from '@salesforce/apex/PropertyTaxUIController.calculateEstimate';

export default class TaxAssessmentCalculator extends LightningElement {
    @track isLoading = false;
    @track result;

    zone = 'Zone 5 - Royapuram';
    propType = 'Residential';
    propUsage = 'Residential Individual';
    occupancy = 'Self-Occupied';
    area = 1200;
    finYear = '2025-2026';

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
        { label: 'Mixed-Use', value: 'Mixed-Use' }
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
        { label: 'Self-Occupied (10% Rebate)', value: 'Self-Occupied' },
        { label: 'Tenanted (No Rebate)', value: 'Tenanted' },
        { label: 'Vacant Land / Building', value: 'Vacant' },
        { label: 'Government / Exempt', value: 'Government/Exempt' }
    ];

    yearOptions = [
        { label: 'FY 2024-2025', value: '2024-2025' },
        { label: 'FY 2025-2026 (Current)', value: '2025-2026' },
        { label: 'FY 2026-2027 (Upcoming)', value: '2026-2027' }
    ];

    connectedCallback() {
        this.handleCompute();
    }

    handleZoneChange(e) { this.zone = e.target.value; this.handleCompute(); }
    handleTypeChange(e) { this.propType = e.target.value; this.handleCompute(); }
    handleUsageChange(e) { this.propUsage = e.target.value; this.handleCompute(); }
    handleOccupancyChange(e) { this.occupancy = e.target.value; this.handleCompute(); }
    handleAreaChange(e) { this.area = e.target.value; this.handleCompute(); }
    handleYearChange(e) { this.finYear = e.target.value; this.handleCompute(); }

    handleCompute() {
        if (!this.area || this.area <= 0) return;

        this.isLoading = true;
        calculateEstimate({
            area: parseFloat(this.area),
            zone: this.zone,
            propType: this.propType,
            propUsage: this.propUsage,
            occupancy: this.occupancy,
            financialYear: this.finYear
        })
        .then(data => {
            this.isLoading = false;
            this.result = data;
        })
        .catch(err => {
            this.isLoading = false;
        });
    }
}
