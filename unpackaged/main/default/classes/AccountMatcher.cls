/**
 * Created 16.9.2022..
 */

public without sharing class AccountMatcher {

    public static Account findMatch(String firstName, String lastName, Date dateOfBirth, String email) {
        System.debug('::findMatch ' + firstName + ' ' + lastName + ' ' + dateOfBirth + ' '+ email);

        List<Account> candidates2 = new List<Account>();

        // do not match without email,
        if (String.isBlank(email))
        {
            System.debug('::findMatch returning null due to no email for matching');
            return null;
        }

        List<Account> candidates = [SELECT Id, Member_Status__c, Patient_Type__c, FirstName, LastName, Date_of_Birth__c, PersonEmail FROM Account WHERE PersonEmail = :email];

        System.debug('::findMatch candidates: ' + candidates);

        //no accounts with the same email
        if (candidates.isEmpty()) return null;

        //if there are many, find the ones with the same birthdate
        for (Account account : candidates) {
            if (account.Date_of_Birth__c == dateOfBirth) candidates2.add(account);
        }

        //no accounts with the same email and date of births
        if (candidates2.isEmpty()) return null;

        //exactly 1 account with the same email and dob
        if (candidates2.size() == 1) return candidates2[0];

        throw new MatchException ('Multiple accounts already with same email and date of birth');
    }

    public virtual class MatchException extends Exception {
    }
}