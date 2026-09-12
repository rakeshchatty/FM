public without sharing class BambooEmployeeDirectoryQueueable implements Queueable, Database.AllowsCallouts {

	private Integer page;

	public BambooEmployeeDirectoryQueueable() {
		this(1);
	}

	public BambooEmployeeDirectoryQueueable(Integer page) {
		this.page = page;
	}

	public void execute(QueueableContext context) {
		Response response = fetchEmployeeDirectory();
		if (response == null) {
			return;
		}

		List<Driver__c> driversToUpsert = new List<Driver__c>();
		for (Employee employee : response.data) {
			if (employee.customField4416 != 'Drivers') {
				continue;
			}

			Driver__c driver = new Driver__c();
			driver.Id_Ba__c  = Integer.valueOf(employee.eeid);
			driver.External_Id__c = employee.employeeNumber;
			driver.Active_Driver__c = employee.status == 'Active';
			driver.First_Name__c = employee.firstName;
			driver.Last_Name__c = employee.lastName;
			driver.Name = employee.firstNameLastName;
			driver.Job_Title__c = employee.jobInformationJobTitle;
			driversToUpsert.add(driver);
		}

		if (!driversToUpsert.isEmpty()) {
			Database.UpsertResult[] results = Database.upsert(driversToUpsert, Driver__c.Id_Ba__c, false);
			LogRegister.createLogsUpsert(results, driversToUpsert, 'Upsert Bamboo Employee Directory', 'Upsert', 'Driver__c', null);
		}

		if (response.pagination.next_page != null) {
			System.enqueueJob(new BambooEmployeeDirectoryQueueable(response.pagination.current_page + 1));
		}
	}

	private Response fetchEmployeeDirectory() {
		HttpRequest request = new HttpRequest();
		request.setEndpoint('callout:Bamboo/v1/datasets/employee?page_size=500&page=' + page);
		request.setMethod('POST');
		request.setBody('{"fields": ["eeid","employeeNumber","firstName","lastName","firstNameLastName","jobInformationJobTitle","status","customField4416"]}');

		HttpResponse response = new Http().send(request);
		if (response.getStatusCode() != 200) {
			return null;
		}

		return (Response)JSON.deserialize(response.getBody(), Response.class);
	}

	private class Response {
		private List<Employee> data;
		private Pagination pagination;
	}

	private class Employee {
		private String eeid;
		private string employeeNumber;
		private string status;
		private String firstName;
		private String lastName;
		private String firstNameLastName;
		private String jobInformationJobTitle;
		private String customField4416;
	}

	private class Pagination {
		private String next_page;
		private Integer current_page;
	}
}