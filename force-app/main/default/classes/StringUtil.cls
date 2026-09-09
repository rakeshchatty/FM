public class StringUtil {

	public static List<String> split(String text, String delimiter, Integer lineLength, Integer count) {
		List<String> lines = new List<String>();
		Integer remainingLength = text != null ? text.length() : 0;

		while (remainingLength > 0 && lines.size() < count) {
			String line = text.substring(0, Math.min(lineLength, remainingLength));
			Integer lastDelimiterIndex = line.lastIndexOf(delimiter);
			if (lastDelimiterIndex != -1) {
				line = line.substring(0, lastDelimiterIndex + 1).trim();
			}

			lines.add(line);
			text = text.substring(line.length()).trim();
			remainingLength = text.length();
		}
		if (remainingLength > 0) {
			lines.add(text);
		}

		return lines;
	}
}