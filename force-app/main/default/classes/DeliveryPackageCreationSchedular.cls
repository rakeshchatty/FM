public without sharing class DeliveryPackageCreationSchedular implements Schedulable {

	private Date nextWeekDay;

	private Integer minOrdersPerDayLondon;
	private Integer maxOrdersPerDayLondon;
	private Integer maxOrdersPerDayNonLondon;
	private Integer bagsPerParcel;

	Integer packageCount;

	public void execute(SchedulableContext SC) {
		ParcelforceSetting__c parcelforceSetting = ParcelforceSetting__c.getOrgDefaults();
		minOrdersPerDayLondon = Integer.valueOf(parcelforceSetting.MinimumOrdersPerDayLondon__c);
		maxOrdersPerDayLondon = Integer.valueOf(parcelforceSetting.MaximumOrdersPerDayLondon__c);
		maxOrdersPerDayNonLondon = Integer.valueOf(parcelforceSetting.MaximumOrdersPerDayNonLondon__c);
		bagsPerParcel = Integer.valueOf(parcelforceSetting.BagsPerParcel__c);

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

		if (!deliveryPackages.isEmpty()) {
			INSERT deliveryPackages;
		}
	}

	private List<DeliveryPackage__c> createDeliveryPackages(List<Order> orders, Integer dayLimit) {
		List<DeliveryPackage__c> deliveryPackages = new List<DeliveryPackage__c>();

		for (Order order : orders) {
			if (packageCount >= dayLimit) {
				break;
			}

			if (!order.DeliveryPackages__r.isEmpty()) {
				continue;
			}

			Long boxCount = (order.BagsQuantity__c / bagsPerParcel).round(System.RoundingMode.CEILING);
			deliveryPackages.add(new DeliveryPackage__c(Order__c = order.Id, RequestedDeliveryDate__c = nextWeekDay, Count__c = boxCount));
			packageCount++;
		}

		return deliveryPackages;
	}

	private List<Order> getOrdersToProcess(Boolean isLondonLocation, Boolean isCentralLondonLocation) {
		List<Order> ordersToProcess = [SELECT Requested_Delivery_Date__c, BagsQuantity__c,
				(SELECT Id FROM DeliveryPackages__r WHERE Status__c = :DeliveryPackage.STATUS_CANCELLED AND IsRequestedDeliveryDateSameAsOrder__c = true)
				FROM Order WHERE IsDeliveryByExternalCarrier__c = true AND IsLondonLocation__c = :isLondonLocation AND IsCentralLondonLocation__c = :isCentralLondonLocation ORDER BY CreatedDate];
		return isCentralLondonLocation ? getNonBikeOrders(ordersToProcess) : ordersToProcess;
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
		List<AggregateResult> aggregatedPackages = [SELECT COUNT(Id) PackageCount FROM DeliveryPackage__c WHERE RequestedDeliveryDate__c = :nextWeekDay AND Order__r.IsLondonLocation__c = :isLondonLocation];
		return (Integer)aggregatedPackages[0].get('PackageCount');
	}
}