public without sharing class RoyalMailDelivery {

	public class CreateRequest {
		public ShipmentInformation ShipmentInformation = new ShipmentInformation();
		public Shipper Shipper = new Shipper();
		public Destination Destination = new Destination();
		public List<RequestPackage> Packages = new List<RequestPackage>();
	}

	public class ShipmentInformation {
		public String ContentType = 'NDX';	// Non Documents
		public string ServiceCode;
		public string DescriptionOfGoods;
		public String ShipmentDate;
	}

	public class Shipper {
		public String ShippingAccountId;
		public String ShippingLocationId;
		public String Reference1;
	}

	public class Destination {
		public Address Address = new Address();
	}

	public class Address {
		public String CompanyName;
		public String ContactEmail;
		public String ContactPhone;
		public String Line1;
		public String Line2;
		public String Line3;
		public String Town;
		public String Postcode;
		public String CountryCode;
	}

	public class RequestPackage {
		public String PackageType = 'Parcel';
		public Decimal DeclaredWeight;
		public Integer PackageOccurrence;

		public RequestPackage(Decimal weight, Integer IncrementalCount) {
			DeclaredWeight = weight;
			PackageOccurrence = IncrementalCount;
		}
	}

	public class CreateResponse {
		public String Labels;
		public String LabelFormat;
		public List<ResponsePackage> Packages;
		public List<Error> Errors;
	}

	public class ResponsePackage {
		public CarrierDetails CarrierDetails;
		public String ShipmentId;
		public Integer PackageOccurrence;
		public String TrackingNumber;
		public String CarrierTrackingUrl;
	}

	public class CarrierDetails {
		public String UniqueId;
	}

	public class Error {
		public String Message;
	}

	public class CancelRequest {
		public String Status = 'Cancel';
		public String Reason = 'Order Cancelled';
		public List<String> ShipmentIds;

		public CancelRequest(List<String> shipmentIds) {
			this.ShipmentIds = shipmentIds;
		}
	}

	public class CancelResponse {
		public List<Error> Errors;
	}

	public class PickedRequest {
		public String Status = 'Picked';
		public String Reason = 'Packaged';
		public List<String> ShipmentIds;

		public PickedRequest(List<String> shipmentIds) {
			this.ShipmentIds = shipmentIds;
		}
	}

	public class PickedResponse {
		public List<Error> Errors;
	}

	public class ManifestRequest {
		public String Status = 'Picked';
		public String Async = 'false';
		public String ShippingLocationId;
	}

	public class ManifestResponse {
        public String Message;
		public List<Error> Errors;
	}

	public class RequestException extends Exception {}
}