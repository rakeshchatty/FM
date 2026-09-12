public without sharing class DeliveryPackageCreationSchedular implements Schedulable {

	private RoyalMailSetting__c royalMailSetting;

	private Date nextWeekDay;

	private Decimal maxOrderAmount;
	private Integer minOrdersPerDayLondon;
	private Integer maxOrdersPerDayLondon;
	private Integer maxOrdersPerDayNonLondon;
	private Integer bagsPerParcel;
	private String carrier;

	Integer packageCount;

	private void initalizeSettings() {
		royalMailSetting = RoyalMailSetting__c.getOrgDefaults();

		if (royalMailSetting.IsActive__c) {
			carrier = DeliveryPackage.CARRIER_ROYAL_MAIL;
			maxOrderAmount = royalMailSetting.MaximumOrderAmount__c;
			minOrdersPerDayLondon = Integer.valueOf(royalMailSetting.MinimumOrdersPerDayLondon__c);
			maxOrdersPerDayLondon = Integer.valueOf(royalMailSetting.MaximumOrdersPerDayLondon__c);
			maxOrdersPerDayNonLondon = Integer.valueOf(royalMailSetting.MaximumOrdersPerDayNonLondon__c);
			bagsPerParcel = Integer.valueOf(royalMailSetting.BagsPerParcel__c);
		} else {
			carrier = DeliveryPackage.CARRIER_PARCELFORCE;
			ParcelforceSetting__c parcelforceSetting = ParcelforceSetting__c.getOrgDefaults();
			maxOrderAmount = parcelforceSetting.MaximumOrderAmount__c;
			minOrdersPerDayLondon = Integer.valueOf(parcelforceSetting.MinimumOrdersPerDayLondon__c);
			maxOrdersPerDayLondon = Integer.valueOf(parcelforceSetting.MaximumOrdersPerDayLondon__c);
			maxOrdersPerDayNonLondon = Integer.valueOf(parcelforceSetting.MaximumOrdersPerDayNonLondon__c);
			bagsPerParcel = Integer.valueOf(parcelforceSetting.BagsPerParcel__c);
		}
	}

	public void execute(SchedulableContext SC) {
		initalizeSettings();
		nextWeekDay = DateUtil.getNextWeekday(System.today());

		List<DeliveryPackage__c> deliveryPackages = new List<DeliveryPackage__c>();

		packageCount = getDeliveryPackageCount(true);
		if (packageCount < maxOrdersPerDayLondon) {
			deliveryPackages.addAll(createDeliveryPackages(getOrdersToProcess(true, false), maxOrdersPerDayLondon));
			deliveryPackages.addAll(createDeliveryPackages(getOrdersToProcess(true, true), maxOrdersPerDayLondon));
		}

		packageCount = getDeliveryPackageCount(false);
		if (packageCount < maxOrdersPerDayNonLondon) {
			deliveryPackages.addAll(createDeliveryPackages(getOrdersToProcess(false, false), maxOrdersPerDayNonLondon));
		}

		if (!royalMailSetting.IsActive__c) {
			deliveryPackages.addAll(createCollectionPackages(getCollectionOrdersToProcess()));
		}

		if (!deliveryPackages.isEmpty()) {
			INSERT deliveryPackages;
		}
	}

	private List<DeliveryPackage__c> createDeliveryPackages(List<Order> orders, Integer dayLimit) {
		List<DeliveryPackage__c> deliveryPackages = new List<DeliveryPackage__c>();
		DeliveryPackage__c pkg;

		for (Order order : orders) {
			if (packageCount >= dayLimit) {
				break;
			}

			if (!order.DeliveryPackages__r.isEmpty()) {
				continue;
			}

			Decimal packageBoxCount = 0;
			Decimal bagsQuantity = 0;
			for (OrderItem orderItem : order.OrderItems) {
				if (orderItem.Product2.PackageBoxCount__c == null) {
					bagsQuantity += orderItem.Quantity;
				} else {
					packageBoxCount += (orderItem.Quantity * orderItem.Product2.PackageBoxCount__c);
				}
			}

			Long boxCount = (packageBoxCount + (bagsQuantity / bagsPerParcel)).round(System.RoundingMode.CEILING);
			pkg = new DeliveryPackage__c(Carrier__c = carrier, Order__c = order.Id, RequestedDeliveryDate__c = nextWeekDay, Count__c = boxCount);
			if (order.IsIncludeInDeliveryPacking__c) {
				pkg.Carrier__c = DeliveryPackage.CARRIER_FIRST_MILE;
			}
			if (order.RecycleIdProducts__c > 0) {
				pkg.Size__c = DeliveryPackage.SIZE_LARGE;
			}			
			deliveryPackages.add(pkg);
			packageCount++;
		}

		return deliveryPackages;
	}

	private List<DeliveryPackage__c> createCollectionPackages(List<Order> orders) {
		List<DeliveryPackage__c> collectionPackages = new List<DeliveryPackage__c>();

		for (Order order : orders) {
			if (!order.DeliveryPackages__r.isEmpty()) {
				continue;
			}

			collectionPackages.add(new DeliveryPackage__c(Carrier__c = carrier, Order__c = order.Id, RequestedDeliveryDate__c = order.Requested_Delivery_Date__c, Count__c = order.Quantity__c,
				IsCollection__c = true, CollectionDepot__c = order.OrderItems[0].Product2.CollectionDepot__c));
		}

		return collectionPackages;
	}

	private List<Order> getOrdersToProcess(Boolean isLondonLocation, Boolean isCentralLondonLocation) {
		List<Order> ordersToProcess = [SELECT Requested_Delivery_Date__c, IsIncludeInDeliveryPacking__c, RecycleIdProducts__c,
				(SELECT Id FROM DeliveryPackages__r WHERE Status__c = :DeliveryPackage.STATUS_CANCELLED AND IsRequestedDeliveryDateSameAsOrder__c = true),
				(SELECT Quantity, Product2.PackageBoxCount__c FROM OrderItems)
				FROM Order WHERE IsDeliveryPackageToBeCreated__c = true AND TotalAmount <= :maxOrderAmount
				AND IsLondonLocation__c = :isLondonLocation AND IsCentralLondonLocation__c = :isCentralLondonLocation ORDER BY CreatedDate];
		return isCentralLondonLocation ? getNonBikeOrders(ordersToProcess) : ordersToProcess;
	}

	private List<Order> getCollectionOrdersToProcess() {
		List<Order> ordersToProcess = [SELECT Requested_Delivery_Date__c, Quantity__c,
				(SELECT Id FROM DeliveryPackages__r WHERE Status__c = :DeliveryPackage.STATUS_CANCELLED AND IsRequestedDeliveryDateSameAsOrder__c = true),
				(SELECT Product2.CollectionDepot__c FROM OrderItems LIMIT 1)
				FROM Order WHERE IsCollectionByExternalCarrier__c = true ORDER BY CreatedDate];
		return ordersToProcess;
	}

	private List<Order> getNonBikeOrders(List<Order> ordersToProcess) {
		if (ordersToProcess.size() <= minOrdersPerDayLondon) {
			return new List<Order>();
		}
		for (Integer i=0; i<minOrdersPerDayLondon; i++) {
			ordersToProcess.remove(0);
		}
		return ordersToProcess;
	}

	private Integer getDeliveryPackageCount(Boolean isLondonLocation) {
		List<AggregateResult> aggregatedPackages = [SELECT COUNT(Id) PackageCount FROM DeliveryPackage__c WHERE IsCollection__c = false AND RequestedDeliveryDate__c = :nextWeekDay AND Order__r.IsLondonLocation__c = :isLondonLocation];
		return (Integer)aggregatedPackages[0].get('PackageCount');
	}
}