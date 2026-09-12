public class StringUtil {

	public static String lower(String text) {
		return String.isBlank(text) ? '' : text.toLowerCase();
	}

	public static String trim(String text) {
		return String.isBlank(text) ? '' : text.trim();
	}

	public static List<String> splitTrim(String text, String delimiter) {
		List<String> timmedLines = new List<String>();

		if (String.isBlank(text)) {
			return timmedLines;
		}

		List<String> lines = text.split(delimiter);
		for (String line : lines) {
			timmedLines.add(line.trim());
		}

		return timmedLines;
	}

	public static List<String> splitTrimStrip(String text, String delimiter, String strip) {
		List<String> strippedLines = new List<String>();
		for (String line : splitTrim(text, delimiter)) {
			strippedLines.add(line.removeStart(strip).removeEnd(strip));
		}

		return strippedLines;
	}

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

	public static string abbreviate(String text, Integer maxLimit) {
		return String.isBlank(text) ? '' : text.left(maxLimit);
	}
}