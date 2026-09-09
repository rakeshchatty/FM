public class DeliveryPackageShipmentBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {

	private ParcelforceSetting__c parcelforceSetting = ParcelforceSetting__c.getOrgDefaults();
	private final String SHIPMENT_TYPE = parcelforceSetting.ShipmentType__c;
	private final String CONTRACT_NUMBER = parcelforceSetting.ContractNumber__c;
	private final String SERVICE_CODE = parcelforceSetting.ServiceCode__c;
	private final DateTime NOW = System.now();
	private Time lastCollection; 

	private static final String SUCCESS_STATUS = 'ALLOCATED';
	private List<DeliveryPackage__c> pkgs = new List<DeliveryPackage__c>();

	private Set<Id> packageIds = new Set<Id>();

	public DeliveryPackageShipmentBatch(Set<Id> packageIds) {
		this.packageIds = packageIds;
	}

	public Database.QueryLocator start(Database.BatchableContext BC) {
		try {
			lastCollection = Time.newInstance(Integer.valueOf(parcelforceSetting.LastCollection__c.substringBefore(':')), Integer.valueOf(parcelforceSetting.LastCollection__c.substringAfter(':')), 0, 0);
		} catch (Exception e) {
			lastCollection = Time.newInstance(23, 59, 59, 0);
		}

		return Database.getQueryLocator([SELECT Order__r.Account.Name, Order__r.OrderNumber, RequestedDeliveryDate__c, Count__c,IsSaturdayDelivery__c,
			Order__r.ShippingCity, Order__r.ShippingPostalCode, Order__r.ShippingCountryCode, Order__r.ShippingStreetLineSingle__c, Order__r.Account.Enqix_Dly_ExtraInfo__c
			FROM DeliveryPackage__c
			WHERE Id IN :packageIds AND Status__c IN (:DeliveryPackage.STATUS_NEW, :DeliveryPackage.STATUS_RETRY)]);
	}

	public void execute(Database.BatchableContext BC, List<DeliveryPackage__c> scope) {
		for (DeliveryPackage__c pkg : scope) {
			pkg.Message__c = '';
			ParcelforceSoap.CreateShipmentReply response;
			try {
				response = new ParcelforceSoap.ShipServicePort().createShipment(createRequest(pkg));
				if (response.CompletedShipmentInfo != null && response.CompletedShipmentInfo.Status == SUCCESS_STATUS) {
					pkg.Status__c = DeliveryPackage.STATUS_ADVISED;
					pkg.TrackingId__c = response.CompletedShipmentInfo.CompletedShipments.CompletedShipment[0].ShipmentNumber;
				} else {
					pkg.Status__c = DeliveryPackage.STATUS_ERROR;
					ParcelforceSoap.Alerts alerts = response.Alerts;
					for (ParcelforceSoap.Alert alert : alerts.Alert) {
						pkg.Message__c += alert.Message + ('\n');
					}
				}
			} catch (Exception e) {
				pkg.Status__c = DeliveryPackage.STATUS_ERROR;
				pkg.Message__c = e.getMessage();
			}
			pkgs.add(pkg);
		}
	}

	private ParcelforceSoap.RequestedShipment createRequest(DeliveryPackage__c pkg) {
		List<String> shippingStreet = StringUtil.split(pkg.Order__r.ShippingStreetLineSingle__c, ',', 40, 3);
		List<String> deliveryNotes = StringUtil.split(pkg.Order__r.Account.Enqix_Dly_ExtraInfo__c, ' ', 25, 4);
		ParcelforceSoap.RequestedShipment request = new ParcelforceSoap.RequestedShipment();
		request.ShipmentType = SHIPMENT_TYPE;
		request.ContractNumber = CONTRACT_NUMBER;
		request.ServiceCode = SERVICE_CODE;
		request.ShippingDate = NOW.time() <= lastCollection ? NOW.date() : Dateutil.getNextWeekday(NOW.date());
		request.RecipientContact.BusinessName = pkg.Order__r.Account.Name.left(40);
		request.RecipientAddress.AddressLine1 = shippingStreet.size() >= 1 ? shippingStreet[0] : null;
		request.RecipientAddress.AddressLine2 = shippingStreet.size() >= 2 ? shippingStreet[1] : null;
		request.RecipientAddress.AddressLine3 = shippingStreet.size() >= 3 ? shippingStreet[2] : null;
		request.RecipientAddress.Town = pkg.Order__r.ShippingCity;
		request.RecipientAddress.Postcode = pkg.Order__r.ShippingPostalCode;
		request.RecipientAddress.Country = pkg.Order__r.ShippingCountryCode ;
		request.TotalNumberOfParcels = Integer.valueOf(pkg.Count__c);
		request.Enhancement.SaturdayDeliveryRequired = pkg.IsSaturdayDelivery__c;
		request.ReferenceNumber1 = pkg.Order__r.OrderNumber;
		request.SpecialInstructions1 = deliveryNotes.size() >= 1 ? deliveryNotes[0] : null;
		request.SpecialInstructions2 = deliveryNotes.size() >= 2 ? deliveryNotes[1] : null;
		request.SpecialInstructions3 = deliveryNotes.size() >= 3 ? deliveryNotes[2] : null;
		request.SpecialInstructions4 = deliveryNotes.size() >= 4 ? deliveryNotes[3] : null;
		return request;
	}

	public void finish(Database.BatchableContext BC) {
		UPDATE pkgs;
	}
}