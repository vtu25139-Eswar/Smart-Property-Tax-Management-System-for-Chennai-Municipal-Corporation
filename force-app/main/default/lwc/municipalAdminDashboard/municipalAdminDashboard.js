import { LightningElement, track } from 'lwc';
import getMunicipalAdminMetrics from '@salesforce/apex/PropertyTaxUIController.getMunicipalAdminMetrics';

export default class MunicipalAdminDashboard extends LightningElement {
    @track isLoading = false;
    @track metrics = {
        totalProperties: 0,
        unverifiedCount: 0,
        verifiedCount: 0,
        highPriorityCount: 0,
        totalAssessedTax: 0,
        totalTaxCollected: 0,
        outstandingTaxDues: 0,
        collectionEfficiency: 0,
        zoneBreakdown: []
    };

    connectedCallback() {
        this.loadMetrics();
    }

    loadMetrics() {
        this.isLoading = true;
        getMunicipalAdminMetrics()
            .then(data => {
                this.isLoading = false;
                if (data) {
                    this.metrics = data;
                }
            })
            .catch(err => {
                this.isLoading = false;
            });
    }

    handleRefresh() {
        this.loadMetrics();
    }

    get formattedAssessedTax() {
        return Number(this.metrics.totalAssessedTax || 0).toLocaleString('en-IN', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        });
    }

    get formattedCollectedTax() {
        return Number(this.metrics.totalTaxCollected || 0).toLocaleString('en-IN', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        });
    }

    get formattedDues() {
        return Number(this.metrics.outstandingTaxDues || 0).toLocaleString('en-IN', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        });
    }
}
