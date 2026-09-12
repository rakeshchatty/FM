public without sharing class FileUploadController {

	private static List<FileUploader> fileUploaders = new List<FileUploader> {
		new DeliveryRouteFileUploader(),
		new DeliveryOrderFileUploader()
	};

	@AuraEnabled
	public static List<FileUploader.Option> getOptions() {
		List<FileUploader.Option> options = new List<FileUploader.Option>();
		for (FileUploader fileUploader : fileUploaders) {
			options.add(fileUploader.getOption());
		}
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

	private static FileUploader getInstance(String fileReference) {
		for (FileUploader fileUploader : fileUploaders) {
			if (fileReference == fileUploader.getFileReference()) {
				return fileUploader;
			}
		}
		return null;
	}
}