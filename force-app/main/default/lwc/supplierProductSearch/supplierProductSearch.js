import { LightningElement, api, track } from 'lwc';
import searchProducts from '@salesforce/apex/SupplierProductSearchController.searchProducts';
import getSuppliersWithProduct from '@salesforce/apex/SupplierProductSearchController.getSuppliersWithProduct';

export default class SupplierProductSearch extends LightningElement {
    @api recordId; // Postcode (Region__c) ID
    @track searchKey = '';
    @track products = [];
    @track productOptions = [];
    @track selectedProductId = '';
    @track results;
    @track error;

    handleSearchKeyChange(event) {
        this.searchKey = event.target.value;
        if (this.searchKey.length >= 2) {
            searchProducts({ searchKey: this.searchKey })
                .then(data => {
                    this.products = data;
                    this.productOptions = data.map(prod => ({
                        label: prod.Name,
                        value: prod.Id
                    }));
                    this.error = undefined;
                })
                .catch(() => {
                    this.error = 'Error fetching products';
                    this.products = [];
                    this.productOptions = [];
                });
        }
    }

    handleProductSelect(event) {
        this.selectedProductId = event.detail.value;

        getSuppliersWithProduct({
            postcodeId: this.recordId,
            productId: this.selectedProductId
        })
            .then(data => {
                this.results = data;
                this.error = undefined;
            })
            .catch(error => {
                this.error = error.body.message || 'Error fetching supplier info';
                this.results = undefined;
            });
    }
}