/**
 * Parser is a utility class that contains constants and properties
 * designed to assist in the parsing of Strings and other forms of data.
 *
 * @author  Zoran Zunko based on idea by Marty Y. Chang
 * @version 1.0
 */
public class Parser {
    /**
     * Comma String as defined by IETF RFC 4180.
     */
    public static String COMMA =
           EnqixImportCSVParametersManager.getCsvParameters().Delimiter__c;

    /**
     * Carriage return String as defined by Salesforce documentation.
     *
     * Force.com IDE Library >
     * Apex Developer's Guide >
     * Language Constructs >
     * Data Types >
     * Primitive Data Types
     */
    public static String CR = '\r';

    /**
     * Double-quote String as defined by Salesforce documentation.
     *
     * Force.com IDE Library >
     * Apex Developer's Guide >
     * Language Constructs >
     * Data Types >
     * Primitive Data Types
     */
    public static String DQUOTE = '\"';

    /**
     * Line feed String as defined by Salesforce documentation.
     *
     * Force.com IDE Library >
     * Apex Developer's Guide >
     * Language Constructs >
     * Data Types >
     * Primitive Data Types
     */
    public static String LF = '\n';

    /**
     * Carriage return String followed by a line feed String.
     */
    public static String CRLF = EnqixImportCSVParametersManager.getCsvParameters().Line_break_UTF__c.unescapeUnicode();

    /**
     * Line feed String followed by a carriage return String.
     */
    public static String LFCR = LF + CR;

    /**
     * Escaped double-quotes per IETF RFC 4180.
     */
    public static String DQUOTEDQUOTE = DQUOTE + DQUOTE;
}