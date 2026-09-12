public without sharing class RoyalMailDeliveryCreateBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {

	private final RoyalMailSetting__c royalMailSetting = RoyalMailSetting__c.getOrgDefaults();
	private final String ACCOUNT_ID = royalMailSetting.ShippingAccountId__c;
	private final String LOCATION_ID = royalMailSetting.ShippingLocationId__c;
	private final String SERVICE_CODE = royalMailSetting.ServiceCode__c;
	private final String DESCRIPTION_OF_GOODS = royalMailSetting.DescriptionOfGoods__c;
	private final Decimal DECLARED_WEIGHT = royalMailSetting.DeclaredWeight__c;
	private final String shipmentDate;

	private Set<Id> packageIds = new Set<Id>();

	public RoyalMailDeliveryCreateBatch(Set<Id> packageIds) {
		this.packageIds = packageIds;

		Time lastCollection;
		try {
			lastCollection = Convert.toTime(royalMailSetting.LastCollection__c);
		} catch (Exception e) {
			lastCollection = Time.newInstance(23, 59, 59, 0);
		}

		DateTime NOW = System.now();
		shipmentDate = Convert.toString(NOW.time() <= lastCollection ? NOW.date() : DateUtil.getNextWeekday(NOW.date()), 'yyyy-MM-dd');
	}

	public Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator([SELECT Order__r.Account.Name, Order__r.OrderNumber, Count__c,
			Order__r.ShippingStreetLineSingle__c, Order__r.ShippingCity, Order__r.ShippingPostalCode, Order__r.ShippingCountryCode
			FROM DeliveryPackage__c
			WHERE Id IN :packageIds AND Status__c IN (:DeliveryPackage.STATUS_NEW, :DeliveryPackage.STATUS_RETRY) AND IsCollection__c = false]);
	}

	public void execute(Database.BatchableContext BC, List<DeliveryPackage__c> scope) {
		List<Attachment> attachments = new List<Attachment>();

		for (DeliveryPackage__c pkg : scope) {
			try {
				attachments.add(process(pkg));
			} catch (Exception e) {
				pkg.Status__c = DeliveryPackage.STATUS_ERROR;
				pkg.Message__c = e.getMessage();
			}
		}

		INSERT attachments;
		UPDATE scope;
	}

	public void finish(Database.BatchableContext BC) {}

	private Attachment process(DeliveryPackage__c pkg) {
		RoyalMailDelivery.CreateResponse response = post(createRequest(pkg));
		pkg.Message__c = '';	// Clear any previous error message
		pkg.Status__c = DeliveryPackage.STATUS_LABELLED;
		pkg.TrackingId__c = response.Packages[0].TrackingNumber;

		List<String> trackingIds = new List<String>();
		for (RoyalMailDelivery.ResponsePackage responsePackage : response.Packages) {
			trackingIds.add(responsePackage.TrackingNumber);
		}
		pkg.TrackingIds__c = String.join(trackingIds, ', ');

		return addAttachment(pkg, response);
	}

	private RoyalMailDelivery.CreateRequest createRequest(DeliveryPackage__c pkg) {
		RoyalMailDelivery.CreateRequest request = new RoyalMailDelivery.CreateRequest();

		request.ShipmentInformation.ServiceCode = SERVICE_CODE;
		request.ShipmentInformation.DescriptionOfGoods = DESCRIPTION_OF_GOODS;
		request.ShipmentInformation.ShipmentDate = shipmentDate;

		request.Shipper.ShippingAccountId = ACCOUNT_ID;
		request.Shipper.ShippingLocationId = LOCATION_ID;
		request.Shipper.Reference1 = pkg.Order__r.OrderNumber;

		request.Destination.Address.CompanyName = pkg.Order__r.Account.Name.left(40);
		List<String> shippingStreet = StringUtil.split(pkg.Order__r.ShippingStreetLineSingle__c, ',', 40, 3);
		request.Destination.Address.Line1 = shippingStreet.size() >= 1 ? shippingStreet[0] : null;
		request.Destination.Address.Line2 = shippingStreet.size() >= 2 ? shippingStreet[1] : null;
		request.Destination.Address.Line3 = shippingStreet.size() >= 3 ? shippingStreet[2] : null;
		request.Destination.Address.Town = pkg.Order__r.ShippingCity;
		request.Destination.Address.Postcode = pkg.Order__r.ShippingPostalCode;
		request.Destination.Address.CountryCode = pkg.Order__r.ShippingCountryCode;

		Integer numberOfParcels = Integer.valueOf(pkg.Count__c);
		Integer counter = 1;
		while (counter <= numberOfParcels) {
			request.Packages.add(new RoyalMailDelivery.RequestPackage(DECLARED_WEIGHT, counter++));
		}

		return request;
	}

	private RoyalMailDelivery.CreateResponse post(RoyalMailDelivery.CreateRequest shipmentRequest) {
		HttpRequest request = new HttpRequest();
		request.setEndpoint('callout:RoyalMail/shipments/rm');
		request.setMethod('POST');
		request.setHeader('Content-Type', 'application/json');
		request.setBody(JSON.serialize(shipmentRequest));

		HttpResponse response = new Http().send(request);
		RoyalMailDelivery.CreateResponse shipmentResponse = (RoyalMailDelivery.CreateResponse)JSON.deserialize(response.getBody(), RoyalMailDelivery.CreateResponse.class);
		if (response.getStatusCode() == 200) {
			return shipmentResponse;
		} else {
			String errorMessage = '';
			for (RoyalMailDelivery.Error error : shipmentResponse.Errors) {
				errorMessage += error.Message + ' ';
			}
			throw new RoyalMailDelivery.RequestException(errorMessage.trim());
		}
	}

	private Attachment addAttachment(DeliveryPackage__c pkg, RoyalMailDelivery.CreateResponse response) {
		Attachment attachment = new Attachment();
		attachment.ParentId = pkg.Id;
		attachment.Name = 'RoyalMail Label - ' + response.Packages[0].TrackingNumber + '.pdf';
		attachment.Body = EncodingUtil.base64Decode(response.Labels);
		return attachment;
	}
}