/**
 * Created 1.8.2022..
 */

public without sharing class OnlPasswordChangeInvocable {

    @InvocableMethod (Category='Online Booking' Label='Send Password Change LInk' Description='Send Password Change Link')
    public static void sendEmail(List<Account> accounts) {

        List<Id> ids = new List<Id>();
        for (Account account : accounts) {
            ids.add(account.Id);
        }

        accounts = [SELECT Id, PersonEmail FROM Account WHERE Id IN :ids];
        for (Account account : accounts) {
            OnlBookUI.queuePassChange(account.PersonEmail);
        }

    }
}