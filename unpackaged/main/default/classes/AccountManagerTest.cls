/**
 * Created 25.6.2024..
 */

@IsTest
private class AccountManagerTest {
    @IsTest
    static void testBehavior() {
        String friendReferralCode = AccountManager.generateFriendReferralCode('John', 'Doe');
        System.debug('T0:' + friendReferralCode);
        System.assert(friendReferralCode.length() == 7, 'Length should be 7');
        System.assert(friendReferralCode.startsWith('JODO'), 'Code should start with first two letters of names');
        System.assert(friendReferralCode == friendReferralCode.toUpperCase(), 'Code should be all uppercase');
    }

    @IsTest static void testWithEmptyNames() {
        String friendReferralCode = AccountManager.generateFriendReferralCode('', '');
        System.debug('T1:' + friendReferralCode);
        System.assert(friendReferralCode.length() == 7, 'Length should be 7');
        System.assert(matchesRegex(friendReferralCode, '^[A-Z]{4}[0-9]{3}$'), 'Code should only contain uppercase Latin letters');
    }

    @IsTest static void testWithNullNames() {
        String friendReferralCode = AccountManager.generateFriendReferralCode(null, null);
        System.debug('T2:' + friendReferralCode);
        System.assert(friendReferralCode.length() == 7, 'Length should be 7');
        System.assert(matchesRegex(friendReferralCode, '^[A-Z]{4}[0-9]{3}$'), 'Code should only contain uppercase Latin letters');
    }

    @IsTest static void testWithNonLatinNames() {
        String friendReferralCode = AccountManager.generateFriendReferralCode('Čččč', 'Ćććž');
        System.debug('T3:' + friendReferralCode);
        System.assert(friendReferralCode.length() == 7, 'Length should be 7');
        System.assert(friendReferralCode == friendReferralCode.toUpperCase(), 'Code should be all uppercase');
        System.assert(matchesRegex(friendReferralCode, '^[A-Z]{4}[0-9]{3}$'), 'Code should only contain uppercase Latin letters');
    }

    private static Boolean matchesRegex(String content, String regexPattern) {
        Pattern pattern = Pattern.compile(regexPattern);

        Matcher matcher = pattern.matcher(content);

        // Check if the string matches the regex
        return matcher.matches();
    }

    @IsTest
    static void testGenerateUniqueFriendReferralCodes_AllSuccesses() {
        // Generate mock accounts
        List<Account> accounts = TestDataFactory.createPersonAccounts(4, true);

        Test.startTest();
        AccountManager.generateUniqueFriendReferralCodes(accounts);
        Test.stopTest();

        System.assertEquals([SELECT COUNT() FROM Account WHERE ReferFriendCode__c = null], 0,
                'Accounts not created properly 1');
        System.assertEquals([SELECT COUNT() FROM Account WHERE ReferFriendCode__c != null], accounts.size(),
                'Accounts not created properly 1');
    }

    @IsTest
    static void testLetterCount() {
        Integer count = 10;
        String randomLatinLetters = AccountManager.getRandomLatinLetters(count);
        System.assertEquals(count, randomLatinLetters.length());
    }

    @IsTest
    static void testContainedInAlphabet() {
        Integer count = 10;
        String randomLatinLetters = AccountManager.getRandomLatinLetters(count);
        String alphabet = 'ABCDEFGHJKLMNPQRSTUVWXXXYZ';
        for (Integer i = 0; i < randomLatinLetters.length(); i++) {
            System.assert(alphabet.contains(randomLatinLetters.substring(i, i + 1)));
        }
    }

}