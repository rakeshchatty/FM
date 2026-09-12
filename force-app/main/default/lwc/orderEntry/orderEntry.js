import { LightningElement, track, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import init from '@salesforce/apex/OrderController.init';
import modal from "@salesforce/resourceUrl/orderEntryCss";
import { loadStyle } from "lightning/platformResourceLoader";
import addProductsToCart from '@salesforce/apex/OrderController.addProductsToCart';
import calculateTotals from '@salesforce/apex/OrderController.calculateTotals';
import addAdditionalCharges from '@salesforce/apex/OrderController.addAdditionalCharges';
import saveOrder from '@salesforce/apex/OrderController.saveOrder';
import getAvailableProducts from '@salesforce/apex/OrderController.getAvailableProducts';
import USER_ID from '@salesforce/user/Id';
import PROFILE_NAME from '@salesforce/schema/User.Profile.Name';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

export default class OrderEntry extends NavigationMixin(LightningElement) {
	locationId;

	@api
	get recordId() {
		return this.locationId;
	}

	set recordId(value) {
		if (value != this.locationId) {
			this.locationId = value;
			this.initializePage();
		}
	}

	userId = USER_ID;

	@track selectedSupplierId;

	@track page = 1;
	@track isLoading = true;
	@track errorMessage = '';

	@track orderData = {};
	@track accountDetails = {};
	@track shoppingCart = [];
	@track orderTypes = [];
	@track contactOptions = [];
	@track mostOrderedProducts = [];
	@track subscribedProducts = [];
	@track availableProducts = [];
	@track overLimit = false;

	@track orderType = 'Regular';
	@track selectedContactId;
	@track poNumber = '';
	@track requestedDeliveryDate;
	@track deliveryNotes = '';
	@track searchString = '';

	@track showConfirmationModal = false;
	@track confirmationMessage = '';
	@track confirmedPayment = false;
	@track isSaving = false;

	searchTimer;
	searchWaitTime = 1000;

	currencySign = '';

	productColumns = [
		{ label: 'Name', fieldName: 'productName', type: 'text' },
		{ label: 'List Price', fieldName: 'listPrice', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'currencyCode' } } },
		{ label: 'Category', fieldName: 'productCategory', type: 'text' },
		{
			type: 'button',
			fixedWidth: 150,
			typeAttributes: {
				label: 'Select',
				name: 'select',
				variant: 'brand'
			}
		}
	];

	mostProductColumns = [
		{ label: 'Name', fieldName: 'productName', type: 'text' },
		{ label: 'List Price', fieldName: 'listPrice', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'currencyCode' } } },
		{ label: 'Supplier', fieldName: 'supplierName', type: 'text' },
		{ label: 'Category', fieldName: 'productCategory', type: 'text' },
		{
			type: 'button',
			fixedWidth: 150,
			typeAttributes: {
				label: 'Select',
				name: 'select',
				variant: 'brand'
			}
		}
	];

	subscribedProductColumns = [
		{ label: 'Name', fieldName: 'productName', type: 'text' },
		{ label: 'List Price', fieldName: 'listPrice', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'currencyCode' } } },
		{ label: 'Supplier', fieldName: 'supplierName', type: 'text' },
		{ label: 'Quantity Remaining', fieldName: 'quantityRemaining', type: 'number' },
		{ label: 'Quantity Limit', fieldName: 'locationLimitQuantity', type: 'number' },
		{ label: 'Category', fieldName: 'productCategory', type: 'text' },
		{
			type: 'button',
			fixedWidth: 150,
			typeAttributes: {
				label: 'Select',
				name: 'select',
				variant: 'brand'
			}
		}
	];

	searchTimer;
	searchWaitTime = 1000;

	get isPage1() {
		return this.page === 1;
	}

	get isPage2() {
		return this.page === 2;
	}

	get isPage3() {
		return this.page === 3;
	}

	get showAccountDeadMessage() {
		return this.accountDetails.id && !this.accountDetails.priceBookId;
	}

	get isDisabled() {
		if (this.accountDetails.isAccountDead || !this.accountDetails.isPriceBookActive ||
			this.accountDetails.isServiceSuspended || !this.accountDetails.priceBookId) return true;
		if (this.accountDetails && this.accountDetails.isPORequired && !this.poNumber) return true;
		if (!this.selectedContactId) return true;
	}

	get isPriceBookInactive() {
		return this.accountDetails && !this.accountDetails.isPriceBookActive;
	}

	get accountName() {
		return this.accountDetails && this.accountDetails.id ? this.accountDetails.name : '';
	}

	get isSaveDisabled() {
		return this.isSaving || !this.canSave || this.isDisabled;
	}

	get hasDeliveryDays() {
		return this.accountDetails && this.accountDetails.deliveryDays;
	}

	get isNationalAccount() {
		return this.accountDetails && this.accountDetails.isNational;
	}

	get isServiceSuspended() {
		return this.accountDetails && this.accountDetails.isServiceSuspended;
	}

	get isAccountDead() {
		return this.accountDetails && this.accountDetails.isAccountDead;
	}

	get showPORequired() {
		return this.accountDetails && this.accountDetails.isPORequired;
	}

	get discountOptions() {
		let discountOptions = [
			{ label: 'Account', value: 'Account' },
			{ label: 'Partner', value: 'Partner' }
		];
		return discountOptions;
	}

	get canSave() {
		if (!this.shoppingCart || this.shoppingCart.length === 0) return false;
		if (this.accountDetails && this.accountDetails.isPORequired && !this.poNumber) return false;
		if (!this.selectedContactId) return false;

		const hasZeroQuantity = this.shoppingCart.some(item =>
			!item.quantity || item.quantity <= 0
		);

		return !hasZeroQuantity;
	}

	@wire(getRecord, {recordId: '$userId', fields: [PROFILE_NAME]})
    userRecord;

    get isSupplierPriceEditable() {
		let profileName = getFieldValue(this.userRecord.data, PROFILE_NAME);
        if (profileName == 'System Administrator' || profileName == 'Super User') {
			return true;
		} else {
			return false;
		}
	}

	connectedCallback() {
		loadStyle(this, modal);
	}

	async initializePage() {
		try {
			this.isLoading = true;
			const result = await init({ locationId: this.recordId });

			if (result.location) {
				this.accountDetails = result.location;
				this.currencySign = (this.accountDetails.effectiveCurrencyCode == 'GBP') ? '£' : (this.accountDetails.effectiveCurrencyCode == 'EUR') ? '€' : '';
			}

			if (result.requestedDeliveryDate) {
				this.requestedDeliveryDate = result.requestedDeliveryDate;
			}

			if (result.orderTypes) {
				this.orderTypes = result.orderTypes;
			}

			if (result.contacts) {
				this.contactOptions = result.contacts.map(contact => ({
					label: contact.Name,
					value: contact.Id
				}));
			}

			if (result.mostOrderedProducts) {
				this.mostOrderedProducts = result.mostOrderedProducts;
			}

			if (result.subscribedProducts) {
				this.subscribedProducts = result.subscribedProducts;
			}

			if (result.availableProducts) {
				this.availableProducts = result.availableProducts;
				if (result.availableProducts.length > 30) {
					this.overLimit = true;
					this.availableProducts.pop();
				}
			}

			this.isLoading = false;

		} catch (error) {
			this.showError('Error initializing page: ' + error.body?.message || error.message);
			this.isLoading = false;
		}
	}

	goToPage1() {
		this.page = 1;
	}

	goToPage2() {
		this.orderData = {
			locationId: this.accountDetails.id,
			type: this.orderType,
			contactId: this.selectedContactId,
			poNumber: this.poNumber,
			requestedDeliveryDate: this.requestedDeliveryDate,
			deliveryNotes: this.deliveryNotes,
			isPaymentConfirmed: this.confirmedPayment,
			priceBookId : this.accountDetails.priceBookId,
			orderItems : []
		};

		this.page = 2;
	}

	handleOrderTypeChange(event) {
		this.orderType = event.detail.value;
	}

	handleContactChange(event) {
		this.selectedContactId = event.detail.value;
	}

	handlePONumberChange(event) {
		this.poNumber = event.detail.value;
	}

	handleDeliveryDateChange(event) {
		this.requestedDeliveryDate = event.detail.value;
	}

	handleDeliveryNotesChange(event) {
		this.deliveryNotes = event.detail.value;
	}

	handleSupplierChange(event) {
		this.selectedSupplierId = event.detail.recordId || null;

	}

	handleSearchChange(event) {
		this.searchString = event.detail.value;
		if (this.searchTimer) {
			clearTimeout(this.searchTimer);
		}
		this.searchTimer = setTimeout(() => {
			if (this.searchString.length === 0 || this.searchString.length > 2) {
				this.loadAvailableProducts();
			}
		}, this.searchWaitTime);
	}

	async increase(event) {
		event.stopPropagation();

		const itemId = event.currentTarget.dataset.id;
		const item = this.shoppingCart.find(i => i.rowKey === itemId || i.Id === itemId);

		const newQuantity = item.quantity + item.quantitySoldIn;

		const updatedCart = this.shoppingCart.map(cartItem => {
				if (cartItem.rowKey === itemId || cartItem.Id === itemId) {
					return {
						...cartItem,
						quantity: newQuantity
					};
				}
				return cartItem;
			});

		this.shoppingCart = updatedCart;
	}

	async decrease(event) {
		event.stopPropagation();

		const itemId = event.currentTarget.dataset.id;
		const item = this.shoppingCart.find(i => i.rowKey === itemId || i.Id === itemId);

		if (item.quantity > item.quantitySoldIn) {
			const newQuantity = item.quantity - item.quantitySoldIn;

			const updatedCart = this.shoppingCart.map(cartItem => {
				if (cartItem.rowKey === itemId || cartItem.Id === itemId) {
					return {
						...cartItem,
						quantity: newQuantity
					};
				}
				return cartItem;
			});

			this.shoppingCart = updatedCart;
		}
	}

	async handleProductNameChange(event) {
		event.stopPropagation();
		const itemId = event.currentTarget.dataset.id;
		const productName = event.detail.value;

		const updatedCart = this.shoppingCart.map(cartItem => {
			if (cartItem.rowKey === itemId || cartItem.Id === itemId) {
				return { ...cartItem, manualProductName: productName};
			}
			return cartItem;
		});

		this.shoppingCart = updatedCart;
	}

	async handleDiscountToApplyChange(event) {
		event.stopPropagation();
		const itemId = event.currentTarget.dataset.id;
		const selectedDiscToApply = event.detail.value;

		const item = this.shoppingCart.find(i => i.rowKey === itemId || i.Id === itemId);
		if (selectedDiscToApply == 'Partner') {
			const updatedCart = this.shoppingCart.map(cartItem => {
				if (cartItem.rowKey === itemId || cartItem.Id === itemId) {
					return { ...cartItem,
						discountToApply: selectedDiscToApply,
						discount: item.partnerDiscount,
						unitPrice: item.listPrice - item.partnerDiscount
					};
				}
				return cartItem;
			});
			this.shoppingCart = updatedCart;
		} else {
			const updatedCart = this.shoppingCart.map(cartItem => {
				if (cartItem.rowKey === itemId || cartItem.Id === itemId) {
					return { ...cartItem,
						discountToApply: selectedDiscToApply,
						discount: item.parentDiscount,
						unitPrice: item.listPrice - item.parentDiscount
					};
				}
				return cartItem;
			});
			this.shoppingCart = updatedCart;
		}
	}

	async handleListPriceChange(event) {
		event.stopPropagation();
		const itemId = event.currentTarget.dataset.id;
		const listPrice = parseFloat(event.detail.value) || 0;
		const item = this.shoppingCart.find(i => i.rowKey === itemId || i.Id === itemId);

		const updatedCart = this.shoppingCart.map(cartItem => {
			if (cartItem.rowKey === itemId || cartItem.Id === itemId) {
				return { ...cartItem,
					listPrice: listPrice,
					unitPrice: listPrice,
					discount : 0,
					discountToApply : '',
					showDiscountDropdown : false,
					discountLabel: '-'
				};
			}
			return cartItem;
		});

		this.shoppingCart = updatedCart;
	}

	async handleSupplierUnitPriceChange(event) {
		event.stopPropagation();
		const itemId = event.currentTarget.dataset.id;
		const supplierUnitPrice = parseFloat(event.detail.value) || 0;
		const item = this.shoppingCart.find(i => i.rowKey === itemId || i.Id === itemId);

		const updatedCart = this.shoppingCart.map(cartItem => {
			if (cartItem.rowKey === itemId || cartItem.Id === itemId) {
				return { ...cartItem,
					supplierUnitPrice: supplierUnitPrice
				};
			}
			return cartItem;
		});

		this.shoppingCart = updatedCart;
	}

	async handleMostOrderedSelection(event) {
		event.stopPropagation();
		const row = event.detail.row;
		await this.addProductToCart(row, 'most');
	}

	async handleSubscribedSelection(event) {
		event.stopPropagation();
		const row = event.detail.row;
		await this.addProductToCart(row, 'bid');
	}

	async handleRowAction(event) {
		event.stopPropagation();
		const row = event.detail.row;
		await this.addProductToCart(row, 'available');
	}

	async addProductToCart(product, source) {
		try {
			if (this.shoppingCart.some(item => item.pricebookEntryId === product.pricebookEntryId)) {
				return;
			}

			const result = await addProductsToCart({
					product: product,
					source: source,
					selectedSupplierId: this.selectedSupplierId,
					location: this.accountDetails
				});

			const cartItem = {...result, showDiscountDropdown : result.parentDiscountId != null && result.partnerDiscountId != null,
				discountLabel : result.discountToApply != null ? result.discountToApply : '-'};

			this.shoppingCart = [...this.shoppingCart, cartItem];
		} catch (error) {
			this.showError('Error adding product: ' + error.body?.message || error.message);
		}
	}

	async handleRemoveItem(event) {
		event.stopPropagation();
		const itemId = event.currentTarget.dataset.id;

		this.shoppingCart = this.shoppingCart.filter(item =>
			item.rowKey !== itemId && item.Id !== itemId
		);
	}

	async loadAvailableProducts() {
		try {
			if (!this.accountDetails || !this.accountDetails.priceBookId) return;
			this.overLimit = false;

			const result = await getAvailableProducts({
				location: this.accountDetails,
				searchKey: this.searchString
			});

			this.availableProducts = [...result];
			if (this.availableProducts.length > 30) {
				this.overLimit = true;
				this.availableProducts.pop();
			}
		} catch (error) {
			const avalProductsError = `Error loading available products: ${error}`;
			this.showError(avalProductsError);
		}
	}

	async handleProcessOrder() {
		for (const item of this.shoppingCart) {
			if (item.quantity > item.quantityRemaining) {
				const quantityLimitError = `Order quantity exceeds for: ${item.manualProductName}`;
				this.showError(quantityLimitError);
				throw new Error(quantityLimitError);
			}
		}

		const orderOutput = {
			locationId: this.accountDetails.id,
			orderItems: this.shoppingCart
		}

		let additionalCharges = await addAdditionalCharges({orderData: orderOutput});

		this.orderData.orderItems = [...this.shoppingCart, ...additionalCharges];

		this.orderData = await calculateTotals({orderData: this.orderData});

		this.page = 3;
	}

	async handleSave() {
		if (this.isSaving) return;
		try {
			const needsConfirmation = await this.checkConfirmationNeeded();

			if (needsConfirmation) {
				this.confirmationMessage = needsConfirmation;
				this.showConfirmationModal = true;
				return;
			}

			await this.saveOrderData();

		} catch (error) {
			const saveError = `Error saving order: ${error.body?.message || error.message}`;
			this.showError(saveError);
		}
	}

	async checkConfirmationNeeded() {
		if ((this.accountDetails.parentPaymentMethod === 'Normal' || !this.accountDetails.parentPaymentMethod) &&
			this.orderData.totalPriceIncludingVat < 1000 && this.orderData.totalPriceIncludingVat !== 0 && !this.confirmedPayment) {
			return 'Order amount is less then £1000, don\'t forget to take payment on the next screen.';
		}

		if (this.accountDetails.parentPaymentMethod === 'Credit Card Only' && !this.confirmedPayment && this.orderData.totalPrice !== 0) {
			return 'Account payment method is card, don\'t forget to take payment on the next screen.';
		}

		return null;
	}

	async saveOrderData() {
		try {
			this.isSaving = true;

			let orderId = await saveOrder({orderData: this.orderData});

			this.showSuccess('Order saved successfully!');

			this.navigateToRecord(orderId);

		} catch (error) {
			throw error;
		}
	}

	handleConfirmPayment() {
		this.confirmedPayment = true;
		this.showConfirmationModal = false;
		this.handleSave();
	}

	handleCloseModal() {
		this.showConfirmationModal = false;
		this.isSaving = false;
	}

	handleCancel() {
		this.navigateToRecord(this.accountDetails.id);
	}

	formatDate(dateString) {
		if (!dateString) return '';
		const date = new Date(dateString);
		return date.toISOString().split('T')[0];
	}

	navigateToRecord(recordId) {
		if (!recordId) {
			this.showError('No record ID available for navigation');
			return;
		}

		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: recordId,
				objectApiName: recordId.startsWith('801') ? 'Order' : 'Account',
				actionName: 'view'
			}
		});
	}

	showSuccess(message) {
		this.dispatchEvent(
			new ShowToastEvent({
				title: 'Success',
				message: message,
				variant: 'success'
			})
		);
	}

	showError(message) {
		this.dispatchEvent(
			new ShowToastEvent({
				title: 'Error',
				message: message,
				variant: 'error'
			})
		);
		this.errorMessage = message;
	}
}