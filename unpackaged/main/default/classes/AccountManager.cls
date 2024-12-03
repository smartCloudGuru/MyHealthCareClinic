/**
 * Class stores all logic related to Accounts and Person Accounts
 *
 * @author Zoran Zunko
 *
 * @date 2/19/21
 */
public with sharing class AccountManager {

    public static final String RT_PERSON_ACCOUNT = 'Account.' + System.Label.Patient_RT_Developer_Name;

    public static RecordType getPatientRecordType() {
        RecordType personAccountRecordType = [SELECT Id FROM RecordType WHERE Name IN ('Person Account', 'Patient') AND SobjectType = 'Account' LIMIT 1];
        return personAccountRecordType;
    }

    @TestVisible
    private static String generateFriendReferralCode(String firstName, String lastName) {
        if (firstName == null) firstName = '';
        if (lastName == null) lastName = '';

        firstName = removeNonLatinCharacters(firstName).trim();
        lastName = removeNonLatinCharacters(lastName).trim();

        if (firstName.length() < 2) {
            firstName = firstName + getRandomLatinLetters(2 - firstName.length());
        }
        if (lastName.length() < 2) {
            lastName = lastName + getRandomLatinLetters(2 - lastName.length());
        }

        String accountCode = firstName.substring(0, 2) + lastName.substring(0, 2) + String.valueOf(Integer.valueOf(Math.floor(Math.random() * 900) + 100));

        return cleanUp(accountCode);
    }

    private static String cleanUp(String accountCode)
    {
        accountCode = accountCode.replaceAll('0', '1').toUpperCase(); // can not have 0 in the code, so it does not get confused with capital "O"

        //SELF-EXPLANATORY
        accountCode = accountCode.replace('ANAL','LAND');
        accountCode = accountCode.replace('ANUS','GOLD');
        accountCode = accountCode.replace('ARSE','ARCH');
        accountCode = accountCode.replace('CLIT','FOUR');
        accountCode = accountCode.replace('CRAP','PART');
        accountCode = accountCode.replace('CUNT','CARS');
        accountCode = accountCode.replace('DICK','KIDS');
        accountCode = accountCode.replace('DUMB','DORM');
        accountCode = accountCode.replace('DOOM','MUGS');
        accountCode = accountCode.replace('DYKE','FIVE');
        accountCode = accountCode.replace('FUCK','FUNK');
        accountCode = accountCode.replace('GOOK','GIVE');
        accountCode = accountCode.replace('HATE','BORN');
        accountCode = accountCode.replace('HOMO','MARK');
        accountCode = accountCode.replace('JERK','TYPE');
        accountCode = accountCode.replace('JISM','MOSS');
        accountCode = accountCode.replace('JUGS','ROOF');
        accountCode = accountCode.replace('KIKE','YEAR');
        accountCode = accountCode.replace('KILL','CORN');
        accountCode = accountCode.replace('PAKI','WORN');
        accountCode = accountCode.replace('PISS','SPAS');
        accountCode = accountCode.replace('SCUM','MUST');
        accountCode = accountCode.replace('SHAG','LARK');
        accountCode = accountCode.replace('SHIT','TILT');
        accountCode = accountCode.replace('SLAG','GARS');
        accountCode = accountCode.replace('SLUT','TURF');
        accountCode = accountCode.replace('SPIC','PICS');
        accountCode = accountCode.replace('SUCK','SUNS');
        accountCode = accountCode.replace('TURD','LINT');
        accountCode = accountCode.replace('TWAT','LAWN');
        accountCode = accountCode.replace('WANK','SILK');
        accountCode = accountCode.replace('BOOB','BOOK');
        accountCode = accountCode.replace('BUNG','BARN');
        accountCode = accountCode.replace('COON','NORM');
        accountCode = accountCode.replace('DAMN','MART');
        accountCode = accountCode.replace('DONG','JURY');
        accountCode = accountCode.replace('DUMP','PUMP');
        accountCode = accountCode.replace('HELL','HELM');
        accountCode = accountCode.replace('JEEZ','HERS');
        accountCode = accountCode.replace('KNOB','KNOW');
        accountCode = accountCode.replace('MILF','FILM');
        accountCode = accountCode.replace('MONG','MONK');
        accountCode = accountCode.replace('MUFF','SACK');
        accountCode = accountCode.replace('NADS','SAND');
        accountCode = accountCode.replace('NIPS','SPIN');
        accountCode = accountCode.replace('POON','POND');
        accountCode = accountCode.replace('POOP','FORT');
        accountCode = accountCode.replace('PUBE','BEST');
        accountCode = accountCode.replace('PUKE','KEEP');
        accountCode = accountCode.replace('PUSS','CATS');
        accountCode = accountCode.replace('TARD','CROP');
        accountCode = accountCode.replace('THOT','CROW');
        accountCode = accountCode.replace('TOSS','LOFT');
        accountCode = accountCode.replace('WANG','ANGE');
        accountCode = accountCode.replace('ASS','SAA');
        accountCode = accountCode.replace('CUM','TIN');
        accountCode = accountCode.replace('FAG','GAF');
        accountCode = accountCode.replace('GAY','YAG');
        accountCode = accountCode.replace('GOD','GAD');
        accountCode = accountCode.replace('JEW','TOM');
        accountCode = accountCode.replace('TIT','LIT');
        return accountCode;
    }

    @TestVisible
    private static String removeNonLatinCharacters(String str) {
        return str.toUpperCase().replaceAll('[^A-Z]', '');
    }

    @TestVisible
    private static String getRandomLatinLetters(Integer count) {
        String alphabet = 'ABCDEFGHJKLMNPQRSTUVWXXXYZ';
        String result = '';

        while (result.length() < count) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), alphabet.length());
            result += alphabet.substring(idx, idx + 1);
        }

        return result;
    }

    private static String generateUniqueFriendReferralCode(Account acc) {
        if (acc == null) return null;

        // Check if RefCode__c already exists
        if (String.isNotEmpty(acc.ReferFriendCode__c)) {
            return acc.ReferFriendCode__c;
        }

        return generateFriendReferralCode(acc.FirstName, acc.LastName);
    }


    public static void generateUniqueFriendReferralCodes(List<Account> accounts) {

        Set<Id> accIds = new Set<Id>();
        for (Account account : accounts) {
            if (account != null) accIds.add(account.Id);
        }

        List<Database.SaveResult> results = generateUniqueFriendReferralCodes(accIds);

        //retry eventual failed results
        accIds = new Set<Id>();

        for (Database.SaveResult failedResult : results) {
            accIds.add(failedResult.id);
        }

        if (accIds.size() > 0) results = generateUniqueFriendReferralCodes(accIds);
    }

    public static List<Database.SaveResult> generateUniqueFriendReferralCodes(Set<Id> accIds) {

        List<Account> accs = [SELECT Id, FirstName, LastName, ReferFriendCode__c, Patient_Id__c FROM Account WHERE Id IN :accIds];

        List<Account> accountsToUpdate = new List<Account>();
        String newCode = null;
        for (Account account : accs) {
            newCode = generateUniqueFriendReferralCode(account);
            if (newCode != account.ReferFriendCode__c) accountsToUpdate.add(new Account(Id = account.Id, ReferFriendCode__c = newCode));
        }

        return Database.update(accountsToUpdate, false);

    }
}