/**
 * Created 16.9.2022..
 */

@IsTest
private class AccountMatcherTest {

    @IsTest
    static void testDuplicateRuleOn_tmp() {
        Account a1 = new Account();
        a1.FirstName = 'James';
        a1.LastName = 'McGill';
        a1.Date_of_Birth__c = Date.today();
        a1.PersonEmail = 'jm@hmm.com';

        insert a1;

        System.debug('inserted a1 with id: ' + a1.Id);

        Account a2 = new Account();
        a2.FirstName = 'Jimmy';
        a2.LastName = 'McGill';
        a2.Date_of_Birth__c = Date.today();
        a2.PersonEmail = 'jm@hmm.com';
        try {
            Database.SaveResult saveResult = Database.insert(a2, false);
            System.debug(saveResult);
            if (saveResult.errors != null && saveResult.errors.size() > 0) {
                for (Database.Error error : saveResult.errors) {
                    if (error instanceof Database.DuplicateError) {
                        List<Datacloud.MatchResult> dupes = ((Database.DuplicateError) error).getDuplicateResult().matchResults;
                        for (Datacloud.MatchResult dupe : dupes) {
                            System.debug('failed to insert, duplicate of: ' + JSON.serializePretty(dupe));
                        }
                    }
                }

            }
        }
        catch (DmlException e) {
            System.debug(e.getMessage());
            System.debug(e.getCause());
        }


    }

    @IsTest
    static void testNoMatch_and_Match() {

        Account a1 = new Account();
        a1.FirstName = 'James';
        a1.LastName = 'McGill';
        a1.Date_of_Birth__c = Date.today();
        a1.PersonEmail = 'jm@hmm.com';

        Account acc = AccountMatcher.findMatch(a1.FirstName, a1.LastName, a1.Date_of_Birth__c, a1.PersonEmail);
        System.assert(acc==null);

        insert a1;

        acc = AccountMatcher.findMatch(a1.FirstName, a1.LastName, a1.Date_of_Birth__c, a1.PersonEmail);
        System.assert(acc!=null);
        System.assert(acc.Id==a1.Id);
    }


}