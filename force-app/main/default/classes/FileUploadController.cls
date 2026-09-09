public without sharing class FileUploadController {

    @AuraEnabled
	public static List<FileUpload.Option> getOptions() {
		List<FileUpload.Option> options = new List<FileUpload.Option>();
		
		options.add(new DeliveryRouteFileUpload().getOption());
		options.add(new DeliveryOrderFileUpload().getOption());
		return options;
	}

	@AuraEnabled
	public static String getDelimiter(String fileReference) {
		return getInstance(fileReference).getDelimiter();
	}

	@AuraEnabled
	public static String preview(String fileReference, List<Object> objectData) {
		return getInstance(fileReference).preview(objectData);
	}

	@AuraEnabled
	public static void process(String fileReference, List<Object> objectData) {
		getInstance(fileReference).process(objectData);
	}

	private static FileUpload getInstance(String fileReference) {
		if (fileReference == DeliveryRouteFileUpload.FILE_REFERENCE) {
			return new DeliveryRouteFileUpload();
		} else if (fileReference == DeliveryOrderFileUpload.FILE_REFERENCE) {
			return new DeliveryOrderFileUpload();
		} else {
			return null;
		}
		
	}
}