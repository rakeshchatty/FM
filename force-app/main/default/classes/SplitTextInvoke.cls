public without sharing class SplitTextInvoke {

	@InvocableMethod(Label='Split Text')
	public static List<List<String>> split(List<Input> inputs) {
		List<List<String>> output = new List<List<String>>();
		for (Input input : inputs) {
			output.add(StringUtil.splitTrim(input.text, input.delimiter));
		}

		return output;
	}

	public class Input {
		@InvocableVariable(required=true)
		public String text;
		@InvocableVariable(required=true)
		public String delimiter;
	}
}