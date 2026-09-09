global with sharing class CSVIterator implements Iterator<String>, Iterable<String> {

    private String m_CSVData;
    private String m_introValue;
    private Integer position;

    public CSVIterator(String fileData, String introValue) {

        System.debug('CSVIterator heap size: ' + Limits.getHeapSize());
        m_CSVData = fileData;
        if (!m_CSVData.endsWith(Parser.CRLF)) {
            m_CSVData += Parser.CRLF;
        }

        System.debug('CSVIterator heap size after file: ' + Limits.getHeapSize());
        position = 0;
        m_introValue = introValue;
    }
    global Boolean hasNext() {

        return m_CSVData.indexOf(m_introValue, position) > 1 ? true : false;
    }

    global String next() {

//        System.debug(LoggingLevel.FINE, 'm_CSVData.escapeUnicode(): ' + m_CSVData.escapeUnicode());
//        System.debug(LoggingLevel.FINE, m_CSVData.indexOf(m_introValue));
        System.debug(LoggingLevel.FINE, 'position: ' + position);
        Integer index = m_CSVData.indexOf(m_introValue, position);
        System.debug(LoggingLevel.FINE, 'index: ' + index);
        String row = m_CSVData.subString(position, index);
        System.debug('CSVIterator heap size after row: ' + Limits.getHeapSize());
        System.debug(LoggingLevel.FINE, 'row: ' + row);
//        m_CSVData = m_CSVData.subString(index + m_introValue.length(), m_CSVData.length());
        position = index + m_introValue.length();

        System.debug('CSVIterator heap size after substring: ' + Limits.getHeapSize());
        return row;
    }

    global Iterator<String> Iterator() {

        return this;
    }
}