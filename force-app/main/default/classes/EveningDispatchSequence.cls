public without sharing class EveningDispatchSequence {

	@InvocableMethod(Label='Sequence Evening Dispatches')
	public static void sequence() {
		DispatchSequence.sequenceEveningDispatches();
	}
}