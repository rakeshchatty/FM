public without sharing class DeliveryPackage {

	public static final String STATUS_NEW = 'New';
	public static final String STATUS_ERROR = 'Error';
	public static final String STATUS_RETRY = 'Retry';
	public static final String STATUS_ADVISED = 'Advised';
	public static final String STATUS_LABELLED = 'Labelled';
	public static final String STATUS_LOCK = 'Lock';
    public static final String STATUS_PACKAGED = 'Packaged';
	public static final String STATUS_CANCEL_REQUEST = 'Request Cancellation';
	public static final String STATUS_CANCELLED = 'Cancelled';

	public static final String CARRIER_PARCELFORCE = 'Parcelforce';
	public static final String CARRIER_ROYAL_MAIL = 'Royal Mail';
	public static final String CARRIER_FIRST_MILE = 'First Mile';

	public static final String SIZE_REGULAR = 'Regular';
	public static final String SIZE_LARGE = 'Large';
}