/**
 * Created 17.6.2024..
 */

public with sharing class HTMLUtils {

    public static String convertToPlainText(String htmlText) {
        if (String.isEmpty(htmlText)) {
            return '';
        }

        // Remove HTML tags
        String plainText = htmlText.replaceAll('<[^>]*>', '');

        // Decode HTML entities
        plainText = decodeHtmlEntities(plainText);

        // Preserve newline characters
        plainText = plainText.replaceAll('&#13;&#10;|&#10;|&#13;', '\n');

        return plainText;
    }

    @TestVisible
    private static String decodeHtmlEntities(String text) {
        if (String.isEmpty(text)) {
            return '';
        }

        // List of common HTML entities
        Map<String, String> htmlEntities = new Map<String, String>{
                '&amp;' => '&',
                '&lt;' => '<',
                '&gt;' => '>',
                '&quot;' => '"',
                '&#39;' => '\'',
                '&#x2F;' => '/',
                '&#96;' => '`',
                '&#x5C;' => '\\',
                '&#x2A;' => '*',
                '&nbsp;' => ' ',
                '&ndash;' => '-'
        };

        // Replace HTML entities with corresponding characters
        for (String entity : htmlEntities.keySet()) {
            text = text.replaceAll(entity, htmlEntities.get(entity));
        }

        return text;
    }
}