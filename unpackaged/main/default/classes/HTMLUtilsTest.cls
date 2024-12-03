/**
 * Created 17.6.2024..
 */

@IsTest
private class HTMLUtilsTest {
    @IsTest static void testConvertToPlainTextEmptyString() {
        // Setup
        String htmlText = '';

        // Exercise
        String result = HTMLUtils.convertToPlainText(htmlText);

        // Verify
        System.assertEquals('', result, 'The returned value is not as expected.');
    }

    @IsTest static void testConvertToPlainTextHtml() {
        // Setup
        String htmlText = '<h1>Hello, World!&amp;</h1>';

        // Exercise
        String result = HTMLUtils.convertToPlainText(htmlText);

        // Verify
        System.assertEquals('Hello, World!&', result, 'The returned value is not as expected.');
    }

    @IsTest static void testConvertToPlainTextWithNewLines() {
        // Setup
        String htmlText = 'Hello,&#13;&#10;World!';

        // Exercise
        String result = HTMLUtils.convertToPlainText(htmlText);

        // Verify
        System.assertEquals('Hello,\nWorld!', result, 'The returned value is not as expected.');
    }

    @IsTest static void testDecodeHtmlEntitiesEmptyString() {
        // Setup
        String text = '';

        // Exercise
        String result = HTMLUtils.decodeHtmlEntities(text);

        // Verify
        System.assertEquals('', result, 'The returned value is not as expected.');
    }

    @IsTest static void testDecodeHtmlEntitiesWithEntities() {
        // Setup
        String text = 'Hello,&nbsp;World!';

        // Exercise
        String result = HTMLUtils.decodeHtmlEntities(text);

        // Verify
        System.assertEquals('Hello, World!', result, 'The returned value is not as expected.');
    }
}