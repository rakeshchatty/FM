@isTest
private class SplitTextInvokeTest {

	@isTest
	static void split() {
		SplitTextInvoke.Input input = new SplitTextInvoke.Input();
		input.text = '  Boxes,Filled, with ,Cardboard , Pieces  ';
		input.delimiter = ',';

		List<String> lines = SplitTextInvoke.split(new List<SplitTextInvoke.Input>{input})[0];
		Assert.areEqual('Boxes', lines[0]);
		Assert.areEqual('Filled', lines[1]);
		Assert.areEqual('with', lines[2]);
		Assert.areEqual('Cardboard', lines[3]);
		Assert.areEqual('Pieces', lines[4]);

		input.delimiter = ';';
		lines = SplitTextInvoke.split(new List<SplitTextInvoke.Input>{input})[0];
		Assert.areEqual(input.text.trim(), lines[0]);
	}
}