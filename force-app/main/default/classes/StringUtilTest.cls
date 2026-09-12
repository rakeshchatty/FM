@isTest
private class StringUtilTest {

	@isTest
	static void splitingBasedOnComma() {
		String text = 'avnuthjhgkjkjkkjncdjnjkdnkdnkdjdjdj, ghwhsvdhsdvbsbnsdvc, ddkdhkdhkd, sdfgvbvbdfghmmnbvjhfgvxccjasjsdjaDJJAdJHDGAFdabjabca jdfVBNBCNVBNVNBDVADBNAJDFJDFHFFJFJHhj, gjwhgdgjhdgjhedgjhdghjedjjdhgdgjd.';
		String delimiter = ',';
		Integer lineLength = 40;
		Integer count = 3;

		List<String> lines = StringUtil.split(text, delimiter, lineLength, count);

		Assert.areEqual(4, lines.size());
		Assert.areEqual('avnuthjhgkjkjkkjncdjnjkdnkdnkdjdjdj,', lines[0]);
		Assert.areEqual('ghwhsvdhsdvbsbnsdvc, ddkdhkdhkd,', lines[1]);
		Assert.areEqual('sdfgvbvbdfghmmnbvjhfgvxccjasjsdjaDJJAdJH', lines[2]);
		Assert.areEqual('DGAFdabjabca jdfVBNBCNVBNVNBDVADBNAJDFJDFHFFJFJHhj, gjwhgdgjhdgjhedgjhdghjedjjdhgdgjd.',  lines[3]);
	}

	@isTest
	static void splitingBasedOnSpace() {
		String text = 'Boxes filled with cardboard boxes/lids/packaging & Empty cardboard boxes & IT equipment such as one monitor, cables, computer box & The smaller boxes at the front are filled with books & A kickstep & Stationery/£165.';
		String delimiter = ' ';
		Integer lineLength = 25;
		Integer count = 4;

		List<String> lines = StringUtil.split(text, delimiter, lineLength, count);

		Assert.areEqual(5, lines.size());
		Assert.areEqual('Boxes filled with', lines[0]);
		Assert.areEqual('cardboard', lines[1]);
		Assert.areEqual('boxes/lids/packaging &', lines[2]);
		Assert.areEqual('Empty cardboard boxes &', lines[3]);
		Assert.areEqual('IT equipment such as one monitor, cables, computer box & The smaller boxes at the front are filled with books & A kickstep & Stationery/£165.', lines[4]);
	}

	@isTest
	static void toLowerTrim() {
		Assert.areEqual('boxes filled with cardboard', StringUtil.lower(StringUtil.trim('  Boxes Filled with Cardboard  ')));
	}

	@isTest
	static void splitTrim() {
		List<String> lines = StringUtil.splitTrim('  Boxes,Filled, with ,Cardboard , Pieces  ', ',');
		Assert.areEqual('Boxes', lines[0]);
		Assert.areEqual('Filled', lines[1]);
		Assert.areEqual('with', lines[2]);
		Assert.areEqual('Cardboard', lines[3]);
		Assert.areEqual('Pieces', lines[4]);
	}

	@isTest
	static void splitTrimStrip() {
		List<String> lines = StringUtil.splitTrimStrip('  "Boxes",Filled, "with" ,"Cardboard" , Pieces  ', ',', '"');
		Assert.areEqual('Boxes', lines[0]);
		Assert.areEqual('Filled', lines[1]);
		Assert.areEqual('with', lines[2]);
		Assert.areEqual('Cardboard', lines[3]);
		Assert.areEqual('Pieces', lines[4]);
	}
}