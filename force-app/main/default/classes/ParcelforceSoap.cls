public without sharing class ParcelforceSoap {

	public class ShipServicePort {
		private String[] ns_map_type_info = new String[]{'http://www.parcelforce.net/ws/ship/v14', 'ParcelforceSoap'};

		private Authentication getCredentials() {
			Authentication auth = new Authentication();
			auth.UserName = '{!$Credential.Username}';
			auth.Password = '{!$Credential.Password}';
			return auth;
		}

		public CreateShipmentReply createShipment(RequestedShipment requestedShipment) {
			CreateShipmentRequest request = new CreateShipmentRequest();
			request.Authentication = getCredentials();
			request.RequestedShipment = requestedShipment;

			Map<String, CreateShipmentReply> responseMap = new Map<String, CreateShipmentReply>{'response_x' => null};
			WebServiceCallout.invoke(
				this,
				request,
				responseMap,
				new String[]{'callout:Parcelforce',
					'createShipment',
					'http://www.parcelforce.net/ws/ship/v14',
					'CreateShipmentRequest',
					'http://www.parcelforce.net/ws/ship/v14',
					'CreateShipmentReply',
					'ParcelforceSoap.CreateShipmentReply'}
			);
			return responseMap.get('response_x');
		}

		public PrintLabelReply printLabel(String shipmentNumber) {
			PrintLabelRequest request = new PrintLabelRequest();
			request.Authentication = getCredentials();
			request.ShipmentNumber = shipmentNumber;

			Map<String, PrintLabelReply> responseMap = new Map<String, PrintLabelReply>{'response_x' => null};
			WebServiceCallout.invoke(
				this,
				request,
				responseMap,
				new String[]{'callout:Parcelforce',
					'printLabel',
					'http://www.parcelforce.net/ws/ship/v14',
					'PrintLabelRequest',
					'http://www.parcelforce.net/ws/ship/v14',
					'PrintLabelReply',
					'ParcelforceSoap.PrintLabelReply'}
			);
			return responseMap.get('response_x');
		}

		public CancelShipmentReply cancelShipment(String shipmentNumber) {
			CancelShipmentRequest request = new CancelShipmentRequest();
			request.Authentication = getCredentials();
			request.ShipmentNumber = shipmentNumber;

			Map<String, CancelShipmentReply> responseMap = new Map<String, CancelShipmentReply>{'response_x' => null};
			WebServiceCallout.invoke(
				this,
				request,
				responseMap,
				new String[]{'callout:Parcelforce',
				'cancelShipment',
				'http://www.parcelforce.net/ws/ship/v14',
				'CancelShipmentRequest',
				'http://www.parcelforce.net/ws/ship/v14',
				'CancelShipmentReply',
				'ParcelforceSoap.CancelShipmentReply'}
			);
			return responseMap.get('response_x');
		}
	}

	public class Authentication {
		public String UserName;
		public String Password;
		private String[] UserName_type_info = new String[]{'UserName','http://www.parcelforce.net/ws/ship/v14',null,'1','1','false'};
		private String[] Password_type_info = new String[]{'Password','http://www.parcelforce.net/ws/ship/v14',null,'1','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://www.parcelforce.net/ws/ship/v14','true','false'};
		private String[] field_order_type_info = new String[]{'UserName','Password'};
	}

	public class CreateShipmentRequest {
		public Authentication Authentication;
		public RequestedShipment RequestedShipment;
		private String[] Authentication_type_info = new String[]{'Authentication','http://www.parcelforce.net/ws/ship/v14',null,'1','1','false'};
		private String[] RequestedShipment_type_info = new String[]{'RequestedShipment','http://www.parcelforce.net/ws/ship/v14',null,'1','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://www.parcelforce.net/ws/ship/v14','true','false'};
		private String[] field_order_type_info = new String[]{'Authentication', 'RequestedShipment'};
	}

	public class RequestedShipment {
		public String ShipmentType;
		public String ContractNumber;
		public String ServiceCode;
		public Date ShippingDate;
		public Contact RecipientContact = new Contact();
		public Address RecipientAddress = new Address();
		public Integer TotalNumberOfParcels;
		public Enhancement Enhancement = new Enhancement();
		public String ReferenceNumber1;
		public String SpecialInstructions1;
		public String SpecialInstructions2;
		public String SpecialInstructions3;
		public String SpecialInstructions4;
		private String[] ShipmentType_type_info = new String[]{'ShipmentType','http://www.parcelforce.net/ws/ship/v14',null,'1','1','false'};
		private String[] ContractNumber_type_info = new String[]{'ContractNumber','http://www.parcelforce.net/ws/ship/v14',null,'1','1','false'};
		private String[] ServiceCode_type_info = new String[]{'ServiceCode','http://www.parcelforce.net/ws/ship/v14',null,'1','1','false'};
		private String[] ShippingDate_type_info = new String[]{'ShippingDate','http://www.parcelforce.net/ws/ship/v14',null,'0','1','false'};
		private String[] RecipientContact_type_info = new String[]{'RecipientContact','http://www.parcelforce.net/ws/ship/v14',null,'1','1','false'};
		private String[] RecipientAddress_type_info = new String[]{'RecipientAddress','http://www.parcelforce.net/ws/ship/v14',null,'1','1','false'};
		private String[] TotalNumberOfParcels_type_info = new String[]{'TotalNumberOfParcels','http://www.parcelforce.net/ws/ship/v14',null,'0','1','false'};
		private String[] Enhancement_type_info = new String[]{'Enhancement','http://www.parcelforce.net/ws/ship/v14',null,'0','1','false'};
		private String[] ReferenceNumber1_type_info = new String[]{'ReferenceNumber1','http://www.parcelforce.net/ws/ship/v14',null,'0','1','false'};
		private String[] SpecialInstructions1_type_info = new String[]{'SpecialInstructions1','http://www.parcelforce.net/ws/ship/v14',null,'0','1','false'};
		private String[] SpecialInstructions2_type_info = new String[]{'SpecialInstructions2','http://www.parcelforce.net/ws/ship/v14',null,'0','1','false'};
		private String[] SpecialInstructions3_type_info = new String[]{'SpecialInstructions3','http://www.parcelforce.net/ws/ship/v14',null,'0','1','false'};
		private String[] SpecialInstructions4_type_info = new String[]{'SpecialInstructions4','http://www.parcelforce.net/ws/ship/v14',null,'0','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://www.parcelforce.net/ws/ship/v14','true','false'};
		private String[] field_order_type_info = new String[]{'ShipmentType','ContractNumber','ServiceCode','ShippingDate','RecipientContact','RecipientAddress','TotalNumberOfParcels','Enhancement','ReferenceNumber1','SpecialInstructions1','SpecialInstructions2','SpecialInstructions3','SpecialInstructions4'};
	}

	public class Contact {
		public String BusinessName;
		private String[] BusinessName_type_info = new String[]{'BusinessName','http://www.parcelforce.net/ws/ship/v14',null,'1','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://www.parcelforce.net/ws/ship/v14','true','false'};
		private String[] field_order_type_info = new String[]{'BusinessName'};
	}

	public class Address {
		public String AddressLine1;
		public String AddressLine2;
		public String AddressLine3;
		public String Town;
		public String Postcode;
		public String Country;
		private String[] AddressLine1_type_info = new String[]{'AddressLine1','http://www.parcelforce.net/ws/ship/v14',null,'1','1','false'};
		private String[] AddressLine2_type_info = new String[]{'AddressLine2','http://www.parcelforce.net/ws/ship/v14',null,'0','1','false'};
		private String[] AddressLine3_type_info = new String[]{'AddressLine3','http://www.parcelforce.net/ws/ship/v14',null,'0','1','false'};
		private String[] Town_type_info = new String[]{'Town','http://www.parcelforce.net/ws/ship/v14',null,'0','1','false'};
		private String[] Postcode_type_info = new String[]{'Postcode','http://www.parcelforce.net/ws/ship/v14',null,'0','1','false'};
		private String[] Country_type_info = new String[]{'Country','http://www.parcelforce.net/ws/ship/v14',null,'1','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://www.parcelforce.net/ws/ship/v14','true','false'};
		private String[] field_order_type_info = new String[]{'AddressLine1','AddressLine2','AddressLine3','Town','Postcode','Country'};
	}

	public class Enhancement {
		public Boolean SaturdayDeliveryRequired;
		private String[] SaturdayDeliveryRequired_type_info = new String[]{'SaturdayDeliveryRequired','http://www.parcelforce.net/ws/ship/v14',null,'0','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://www.parcelforce.net/ws/ship/v14','true','false'};
		private String[] field_order_type_info = new String[]{'SaturdayDeliveryRequired'};
	}

	public class CreateShipmentReply {
		public CompletedShipmentInfo CompletedShipmentInfo;
		public Alerts Alerts;
		private String[] CompletedShipmentInfo_type_info = new String[]{'CompletedShipmentInfo','http://www.parcelforce.net/ws/ship/v14',null,'0','1','false'};
		private String[] Alerts_type_info = new String[]{'Alerts','http://www.parcelforce.net/ws/ship/v14',null,'0','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://www.parcelforce.net/ws/ship/v14','true','false'};
		private String[] field_order_type_info = new String[]{'CompletedShipmentInfo', 'Alerts'};
	}

	public class CompletedShipmentInfo {
		public String Status;
		public CompletedShipments CompletedShipments;
		public RequestedShipment RequestedShipment;
		private String[] Status_type_info = new String[]{'Status','http://www.parcelforce.net/ws/ship/v14',null,'1','1','false'};
		private String[] CompletedShipments_type_info = new String[]{'CompletedShipments','http://www.parcelforce.net/ws/ship/v14',null,'1','1','false'};
		private String[] RequestedShipment_type_info = new String[]{'RequestedShipment','http://www.parcelforce.net/ws/ship/v14',null,'1','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://www.parcelforce.net/ws/ship/v14','true','false'};
		private String[] field_order_type_info = new String[]{'Status','CompletedShipments','RequestedShipment'};
	}

	public class CompletedShipments {
		public CompletedShipment[] CompletedShipment;
		private String[] CompletedShipment_type_info = new String[]{'CompletedShipment','http://www.parcelforce.net/ws/ship/v14',null,'1','-1','false'};
		private String[] apex_schema_type_info = new String[]{'http://www.parcelforce.net/ws/ship/v14','true','false'};
		private String[] field_order_type_info = new String[]{'CompletedShipment'};
	}

	public class CompletedShipment {
		public String ShipmentNumber;
		private String[] ShipmentNumber_type_info = new String[]{'ShipmentNumber','http://www.parcelforce.net/ws/ship/v14',null,'0','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://www.parcelforce.net/ws/ship/v14','true','false'};
		private String[] field_order_type_info = new String[]{'ShipmentNumber'};
	}

	public class PrintLabelRequest {
		public Authentication Authentication;
		public String ShipmentNumber;
		private String[] Authentication_type_info = new String[]{'Authentication','http://www.parcelforce.net/ws/ship/v14',null,'1','1','false'};
		private String[] ShipmentNumber_type_info = new String[]{'ShipmentNumber','http://www.parcelforce.net/ws/ship/v14',null,'1','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://www.parcelforce.net/ws/ship/v14','true','false'};
		private String[] field_order_type_info = new String[]{'Authentication','ShipmentNumber'};
	}

	public class PrintLabelReply {
		public Document Label;
		public Alerts Alerts;
		private String[] Label_type_info = new String[]{'Label','http://www.parcelforce.net/ws/ship/v14',null,'0','1','false'};
		private String[] Alerts_type_info = new String[]{'Alerts','http://www.parcelforce.net/ws/ship/v14',null,'0','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://www.parcelforce.net/ws/ship/v14','true','false'};
		private String[] field_order_type_info = new String[]{'Label', 'Alerts'};
	}

	public class Document {
		public String Data;
		private String[] Data_type_info = new String[]{'Data','http://www.parcelforce.net/ws/ship/v14',null,'1','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://www.parcelforce.net/ws/ship/v14','true','false'};
		private String[] field_order_type_info = new String[]{'Data'};
	}

	public class CancelShipmentRequest {
		public Authentication Authentication;
		public String ShipmentNumber;
		private String[] Authentication_type_info = new String[]{'Authentication','http://www.parcelforce.net/ws/ship/v14',null,'1','1','false'};
		private String[] ShipmentNumber_type_info = new String[]{'ShipmentNumber','http://www.parcelforce.net/ws/ship/v14',null,'1','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://www.parcelforce.net/ws/ship/v14','true','false'};
		private String[] field_order_type_info = new String[]{'Authentication', 'ShipmentNumber'};
	}

	public class CancelShipmentReply {
		public CompletedCancel CompletedCancel;
		public Alerts Alerts;
		private String[] CompletedCancel_type_info = new String[]{'CompletedCancel','http://www.parcelforce.net/ws/ship/v14',null,'0','1','false'};
		private String[] Alerts_type_info = new String[]{'Alerts','http://www.parcelforce.net/ws/ship/v14',null,'0','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://www.parcelforce.net/ws/ship/v14','true','false'};
		private String[] field_order_type_info = new String[]{'CompletedCancel', 'Alerts'};
	}

	public class CompletedCancel {
		public CompletedCancelInfo CompletedCancelInfo;
		private String[] CompletedCancelInfo_type_info = new String[]{'CompletedCancelInfo','http://www.parcelforce.net/ws/ship/v14',null,'0','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://www.parcelforce.net/ws/ship/v14','true','false'};
		private String[] field_order_type_info = new String[]{'CompletedCancelInfo'};
	}

	public class CompletedCancelInfo {
		public String Status;
		public String ShipmentNumber;
		private String[] Status_type_info = new String[]{'Status','http://www.parcelforce.net/ws/ship/v14',null,'0','1','false'};
		private String[] ShipmentNumber_type_info = new String[]{'ShipmentNumber','http://www.parcelforce.net/ws/ship/v14',null,'0','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://www.parcelforce.net/ws/ship/v14','true','false'};
		private String[] field_order_type_info = new String[]{'Status','ShipmentNumber'};
	}

	public class Alerts {
		public Alert[] Alert;
		private String[] Alert_type_info = new String[]{'Alert','http://www.parcelforce.net/ws/ship/v14',null,'1','-1','false'};
		private String[] apex_schema_type_info = new String[]{'http://www.parcelforce.net/ws/ship/v14','true','false'};
		private String[] field_order_type_info = new String[]{'Alert'};
	}

	public class Alert {
		public Integer Code;
		public String Message;
		public String Type;
		private String[] Code_type_info = new String[]{'Code','http://www.parcelforce.net/ws/ship/v14',null,'1','1','false'};
		private String[] Message_type_info = new String[]{'Message','http://www.parcelforce.net/ws/ship/v14',null,'1','1','false'};
		private String[] Type_type_info = new String[]{'Type','http://www.parcelforce.net/ws/ship/v14',null,'1','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://www.parcelforce.net/ws/ship/v14','true','false'};
		private String[] field_order_type_info = new String[]{'Code','Message','Type'};
	}

	public class ShipmentSuccessMock implements WebServiceMock {
		private Boolean randomShipmentNumber = false;

		public ShipmentSuccessMock() {}

		public ShipmentSuccessMock(Boolean randomShipmentNumber) {
			this.randomShipmentNumber = randomShipmentNumber;
		}

		public void doInvoke(Object stub, Object request, Map<String, Object> response, String endpoint, String soapAction, String requestName, String responseNS, String responseName, String responseType) {
			if (requestName == 'CreateShipmentRequest') {
				ParcelforceSoap.CreateShipmentReply createShipmentResponse = new ParcelforceSoap.CreateShipmentReply();
				createShipmentResponse.CompletedShipmentInfo = new ParcelforceSoap.CompletedShipmentInfo();
				createShipmentResponse.CompletedShipmentInfo.Status = 'ALLOCATED';
				createShipmentResponse.CompletedShipmentInfo.CompletedShipments = new ParcelforceSoap.CompletedShipments();
				createShipmentResponse.CompletedShipmentInfo.CompletedShipments.CompletedShipment = new List<ParcelforceSoap.CompletedShipment>();
				ParcelforceSoap.CompletedShipment completedShipment = new ParcelforceSoap.CompletedShipment();
				completedShipment.ShipmentNumber = !randomShipmentNumber ? '12345678' : String.valueOf(Integer.valueof((Math.random() * 1234567890)));
				createShipmentResponse.CompletedShipmentInfo.CompletedShipments.CompletedShipment.add(completedShipment);
				response.put('response_x', createShipmentResponse);
			} else if (requestName == 'PrintLabelRequest') {
				ParcelforceSoap.PrintLabelReply printLabelResponse = new ParcelforceSoap.PrintLabelReply();
				printLabelResponse.Label = new ParcelforceSoap.Document();
				printLabelResponse.Label.Data = 'Mock label data';
				response.put('response_x', printLabelResponse);
			}
		}
	}

	public class ShipmentErrorMock implements WebServiceMock {

		public void doInvoke(Object stub, Object request, Map<String, Object> response, String endpoint, String soapAction, String requestName, String responseNS, String responseName, String responseType) {
			if (requestName == 'CreateShipmentRequest') {
				ParcelforceSoap.CreateShipmentReply createShipmentResponse = new ParcelforceSoap.CreateShipmentReply();
				createShipmentResponse.Alerts = new ParcelforceSoap.Alerts();
				createShipmentResponse.Alerts.Alert = new List<ParcelforceSoap.Alert>();
				ParcelforceSoap.Alert alert = new ParcelforceSoap.Alert();
				alert.Type = 'ERROR';
				alert.Code = 011026101;
				alert.Message = 'ShippingDate is in the past';
				createShipmentResponse.Alerts.Alert.add(alert);
				response.put('response_x', createShipmentResponse);
			}
		}
	}

	public class LabelErrorMock implements WebServiceMock {

		public void doInvoke(Object stub, Object request, Map<String, Object> response, String endpoint, String soapAction, String requestName, String responseNS, String responseName, String responseType) {
			if (requestName == 'CreateShipmentRequest') {
				ParcelforceSoap.CreateShipmentReply createShipmentResponse = new ParcelforceSoap.CreateShipmentReply();
				createShipmentResponse.CompletedShipmentInfo = new ParcelforceSoap.CompletedShipmentInfo();
				createShipmentResponse.CompletedShipmentInfo.Status = 'ALLOCATED';
				createShipmentResponse.CompletedShipmentInfo.CompletedShipments = new ParcelforceSoap.CompletedShipments();
				createShipmentResponse.CompletedShipmentInfo.CompletedShipments.CompletedShipment = new List<ParcelforceSoap.CompletedShipment>();
				ParcelforceSoap.CompletedShipment completedShipment = new ParcelforceSoap.CompletedShipment();
				completedShipment.ShipmentNumber = '12345678';
				createShipmentResponse.CompletedShipmentInfo.CompletedShipments.CompletedShipment.add(completedShipment);
				response.put('response_x', createShipmentResponse);
			} else if (requestName == 'PrintLabelRequest') {
				ParcelforceSoap.PrintLabelReply printLabelResponse = new ParcelforceSoap.PrintLabelReply();
				printLabelResponse.Alerts = new ParcelforceSoap.Alerts();
				printLabelResponse.Alerts.Alert = new List<ParcelforceSoap.Alert>();
				ParcelforceSoap.Alert alert = new ParcelforceSoap.Alert();
				alert.Type = 'ERROR';
				alert.Code = 021000001;
				alert.Message = 'Shipment number ER80145001 not found';
				printLabelResponse.Alerts.Alert.add(alert);
				response.put('response_x', printLabelResponse);
			}
		}
	}

	public class CancellationSuccessMock implements WebServiceMock {

		public void doInvoke(Object stub, Object request, Map<String, Object> response, String endpoint, String soapAction, String requestName, String responseNS, String responseName, String responseType) {
			if (requestName == 'CancelShipmentRequest') {
				ParcelforceSoap.CancelShipmentReply cancelShipmentResponse = new ParcelforceSoap.CancelShipmentReply();
				cancelShipmentResponse.CompletedCancel = new ParcelforceSoap.CompletedCancel();
				cancelShipmentResponse.CompletedCancel.CompletedCancelInfo = new ParcelforceSoap.CompletedCancelInfo();
				cancelShipmentResponse.CompletedCancel.CompletedCancelInfo.Status = 'CANCELLED';
				response.put('response_x', cancelShipmentResponse);
			}
		}
	}

	public class CancellationErrorMock implements WebServiceMock {

		public void doInvoke(Object stub, Object request, Map<String, Object> response, String endpoint, String soapAction, String requestName, String responseNS, String responseName, String responseType) {
			if (requestName == 'CancelShipmentRequest') {
				ParcelforceSoap.CancelShipmentReply cancelShipmentResponse = new ParcelforceSoap.CancelShipmentReply();
				cancelShipmentResponse.Alerts = new ParcelforceSoap.Alerts();
				cancelShipmentResponse.Alerts.Alert = new List<ParcelforceSoap.Alert>();
				ParcelforceSoap.Alert alert = new ParcelforceSoap.Alert();
				alert.Type = 'ERROR';
				alert.Code = 231000001;
				alert.Message = 'Cancel Shipment ER825368 not valid';
				cancelShipmentResponse.Alerts.Alert.add(alert);
				response.put('response_x', cancelShipmentResponse);
			}
		}
	}
}