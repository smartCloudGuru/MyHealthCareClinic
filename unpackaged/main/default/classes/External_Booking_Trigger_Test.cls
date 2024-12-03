/**
 * Created by Matija on 12.9.2023..
 */

@IsTest
private class External_Booking_Trigger_Test {


    @IsTest
    static void testBehavior() {
        Account acc = new Account(
                FirstName = 'Test FName',
                LastName = 'Test LName',
                Gender__c = 'Male',
                Patient_Type__c = 'New'
        );
        insert acc;

        External_Booking__c externalBooking = new External_Booking__c();
        externalBooking.External_System__c = 'Aerona';
        externalBooking.Account__c = acc.Id;
        externalBooking.Business_Unit__c = 'GP';
        externalBooking.Status__c = 'Arrived';
        externalBooking.External_Id__c = 'wersdvw4t4';
        externalBooking.Appointment_Time__c = Datetime.now();

        insert externalBooking;

        System.debug('Inserted EXB1 ' + externalBooking.Id);

        acc = [SELECT Id, Existing_GP_Patient__c, Patient_Type__c FROM Account WHERE Id = :acc.Id];

        System.assert(acc.Existing_GP_Patient__c == true);
        System.assert(acc.Patient_Type__c == 'Registered');


        List<Patient_Business_Unit__c> pbus = [
                SELECT
                        Id,
                        Account__c,
                        Composite_Key__c,
                        Business_Unit__c,
                        First_Opportunity__c,
                        Latest_Opportunity__c,
                        First_Historical_Record__c,
                        Latest_Historical_Record__c,
                        Won__c
                FROM Patient_Business_Unit__c
                WHERE Account__c = :acc.Id
        ];

        System.debug(JSON.serialize(pbus));

        System.assert(pbus.size() == 1);
        System.assert(pbus[0].First_Historical_Record__c == externalBooking.Id);
        System.assert(pbus[0].Latest_Historical_Record__c == externalBooking.Id);

        External_Booking__c externalBooking2 = new External_Booking__c();
        externalBooking2.External_System__c = 'Aerona';
        externalBooking2.Account__c = acc.Id;
        externalBooking2.Business_Unit__c = 'GP';
        externalBooking2.Status__c = 'Arrived';
        externalBooking2.External_Id__c = '2222222';
        externalBooking2.Appointment_Time__c = Datetime.now().addDays(1);

        insert externalBooking2;

        System.debug('Inserted EXB2 ' + externalBooking2.Id);

        pbus = [
                SELECT
                        Id,
                        Account__c,
                        Composite_Key__c,
                        Business_Unit__c,
                        First_Opportunity__c,
                        Latest_Opportunity__c,
                        First_Historical_Record__c,
                        Latest_Historical_Record__c,
                        Won__c
                FROM Patient_Business_Unit__c
                WHERE Account__c = :acc.Id
        ];

        System.debug(JSON.serialize(pbus));

        System.assert(pbus.size()==1);
        System.assert(pbus[0].First_Historical_Record__c == externalBooking.Id);
        System.assert(pbus[0].Latest_Historical_Record__c == externalBooking2.Id);

    }
}