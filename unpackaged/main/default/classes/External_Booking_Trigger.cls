/**
 * Created by Matija on 12.9.2023..
 */

public without sharing class External_Booking_Trigger {

    public static void handle() {

        //        if (Trigger.isBefore) {
        //            List<External_Booking__c> newBookingsOrig1 = Trigger.new;
        //
        //            //on inserts and update set the effective date to earlier of (created, appointment time)
        //            for (External_Booking__c externalBooking : newBookingsOrig1) {
        //                externalBooking.Effective_Date__c = externalBooking.CreatedDate?.date();
        //                if (externalBooking.CreatedDate != null && externalBooking.Appointment_Time__c != null) {
        //                    if (externalBooking.Appointment_Time__c.date() < externalBooking.CreatedDate) externalBooking.Effective_Date__c = externalBooking.Appointment_Time__c.date();
        //                }
        //            }
        //        }

        if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {


            if (Trigger.isBefore) System.debug('::TGR:EXB: isBefore');
            if (Trigger.isAfter) System.debug('::TGR:EXB: isAfter');
            if (Trigger.isInsert) System.debug('::TGR:EXB: isInsert');
            if (Trigger.isUpdate) System.debug('::TGR:EXB: isUpdate');

            // get all accounts now so there's no SOQL in loop
            Set<Id> accountIds = new Set<Id>();
            Map<Id, Account> map_accId_acc = new Map<Id, Account>();
            List<External_Booking__c> newBookingsOrig = Trigger.new;
            List<External_Booking__c> newBookings = new List<External_Booking__c>();

            for (External_Booking__c externalBooking : newBookingsOrig) {
                if (isEBWon (externalBooking) && externalBooking.Account__c != null) {
                    accountIds.add(externalBooking.Account__c);
                    newBookings.add(externalBooking);
                }
            }

            try {
                //put accounts to map
                List<Account> accounts = [
                        SELECT Id,
                                Patient_Type__c,
                                Existing_Dental_Patient__c,
                                Existing_GP_Patient__c
                        FROM Account
                        WHERE Id IN :accountIds
                        FOR UPDATE
                ];
                for (Account account : accounts) {
                    if (account != null && account.Id != null) map_accId_acc.put(account.Id, account);
                }


                // update account to Registered if opp is closed Won
                // TODO refactor later to WORK TYPE lookups

                System.debug('::TGR:EXB:calculating existing patient flags');

                Map<Id, Account> map_accountToUpdate = new Map<Id, Account>();

                Set<Id> wonBookingsAccounts = new Set<Id>();

                Boolean accNeedsUpdating = false;
                for (External_Booking__c eb : newBookings) {

                    Account acc = map_accId_acc.get(eb.Account__c);
                    accNeedsUpdating = false;
                    if (acc != null) {
                        if (TH_Opportunity_ExistingPatientFlags.map_bu_service.get(eb.Category__c) == 'Dental') {
                            if (acc.Existing_Dental_Patient__c == false) accNeedsUpdating = true;
                            acc.Existing_Dental_Patient__c = true;
                        }
                        else if (TH_Opportunity_ExistingPatientFlags.map_bu_service.get(eb.Category__c) == 'Medical') {
                            if (acc.Existing_GP_Patient__c == false) accNeedsUpdating = true;
                            acc.Existing_GP_Patient__c = true;
                        }

                        if (acc.Patient_Type__c == 'New' && (acc.Existing_Dental_Patient__c || acc.Existing_GP_Patient__c)) {
                            accNeedsUpdating = true;
                            acc.Patient_Type__c = 'Registered';
                        }
                        if (accNeedsUpdating) map_accountToUpdate.put(acc.Id, acc);
                    }
                }

                Database.update(map_accountToUpdate.values(), false);

            }
            catch (Exception e) {
            }

            Set<Id> wonBookingsAccounts = new Set<Id>();

            for (External_Booking__c eb : newBookings) {
                wonBookingsAccounts.add(eb.Account__c);
            }

            //we have won bookings opportunities to process
            if (!wonBookingsAccounts.isEmpty()) {

                List<Patient_Business_Unit__c> pbusToUpsert = new List<Patient_Business_Unit__c>();

                //get these accounts to search from
                List<Patient_Business_Unit__c> pbus = [
                        SELECT
                                Id,
                                Account__c,
                                Composite_Key__c,
                                Business_Unit__c,
                                First_Historical_Record__c,
                                First_Historical_Record__r.Status__c,
                                First_Historical_Record__r.CreatedDate,
                                First_Historical_Record__r.Appointment_Time__c,
                                Latest_Historical_Record__c,
                                Latest_Historical_Record__r.Status__c,
                                Latest_Historical_Record__r.CreatedDate,
                                Latest_Historical_Record__r.Appointment_Time__c,
                                Won__c
                        FROM Patient_Business_Unit__c
                        WHERE Account__c IN :wonBookingsAccounts
                        FOR UPDATE
                ];

                // find accounts that are not new patients
                Set<Id> existingPatients = new Set<Id>();
                Map<String, Patient_Business_Unit__c> map_composite_existingPatientsBu = new Map<String, Patient_Business_Unit__c>();
                for (Patient_Business_Unit__c patientBusinessUnit : pbus) {
                    if (patientBusinessUnit.Won__c) {
                        existingPatients.add(patientBusinessUnit.Account__c);
                    }
                    map_composite_existingPatientsBu.put(patientBusinessUnit.Composite_Key__c, patientBusinessUnit);
                }

                Set<Id> usedNewPatients = new Set<Id>(); //prevents multiple New records for a patient

                // now build PBU records
                Boolean newPatientFlag = false;

                for (External_Booking__c eb : newBookings) {

                    String compositeKey = eb.Account__c + '@' + eb.Category__c;

                    if (String.isNotBlank(eb.Category__c) && eb.Account__c != null && isEBWon(eb)) {
                        newPatientFlag = !existingPatients.contains(eb.Account__c) && !usedNewPatients.contains(eb.Account__c);
                        if (newPatientFlag) {
                            System.debug('::TGR:EXB:new patient flag for ' + compositeKey);
                            usedNewPatients.add(eb.Account__c);
                        }

                        Patient_Business_Unit__c pbu = map_composite_existingPatientsBu.get(compositeKey);
                        if (pbu == null) pbu = new Patient_Business_Unit__c(
                                Account__c = eb.Account__c,
                                Business_Unit__c = eb.Category__c,
                                New_Patient__c = newPatientFlag,
                                First_Historical_Record__c = eb.Id,
                                Latest_Historical_Record__c = eb.Id
                        );

                        if (!isEBWon(pbu.First_Historical_Record__r)) pbu.First_Historical_Record__c = eb.Id;
                        if (!isEBWon(pbu.Latest_Historical_Record__r)) pbu.Latest_Historical_Record__c = eb.Id;

                        //prioritize appointment time when sorting first and last, otherwise created date
                        if (eb.Appointment_Time__c != null && pbu.First_Historical_Record__c != null && pbu.First_Historical_Record__r.Appointment_Time__c != null) {
                            if (pbu.First_Historical_Record__r.Appointment_Time__c > eb.Appointment_Time__c) pbu.First_Historical_Record__c = eb.Id;
                        }
                        else {
                            if (pbu.First_Historical_Record__c == null || (pbu.First_Historical_Record__c != null && pbu.First_Historical_Record__r.CreatedDate != null && pbu.First_Historical_Record__r.CreatedDate > eb.CreatedDate)) pbu.First_Historical_Record__c = eb.Id;
                        }

                        if (eb.Appointment_Time__c != null && pbu.Latest_Historical_Record__c != null && pbu.Latest_Historical_Record__r.Appointment_Time__c != null) {
                            if (pbu.Latest_Historical_Record__r.Appointment_Time__c < eb.Appointment_Time__c) pbu.Latest_Historical_Record__c = eb.Id;
                        }
                        else {
                            if (pbu.Latest_Historical_Record__c == null || (pbu.Latest_Historical_Record__c != null && pbu.Latest_Historical_Record__r.CreatedDate != null && pbu.Latest_Historical_Record__r.CreatedDate < eb.CreatedDate)) pbu.Latest_Historical_Record__c = eb.Id;
                        }

                        if (newPatientFlag) pbu.New_Patient__c = true;

                        pbu.Composite_Key__c = compositeKey;

                        map_composite_existingPatientsBu.put(pbu.Composite_Key__c, pbu);

                        pbusToUpsert.add(pbu);
                    }
                }

                if (!pbusToUpsert.isEmpty()) {

                    Map<String, Patient_Business_Unit__c> uniquePbus = new Map<String, Patient_Business_Unit__c>();
                    for (Patient_Business_Unit__c patientBusinessUnit : pbusToUpsert) {
                        uniquePbus.put(patientBusinessUnit.Composite_Key__c, patientBusinessUnit);
                    }
                    System.debug('::EBTgr:writing PBUS:' + JSON.serialize(uniquePbus.values()));
                    List<Database.UpsertResult> upsertresults = Database.upsert(uniquePbus.values(), Patient_Business_Unit__c.Composite_Key__c, false);
                    for (Database.UpsertResult upsertResult : upsertresults) {
                        System.debug(' - Upsert Result: ' + JSON.serialize(upsertResult));
                    }
                }

            }

        }


    }

    private static Boolean isEBWon(External_Booking__c externalBooking) {
        return externalBooking != null && externalBooking.Status__c != 'Canceled' && externalBooking.Status__c != 'Did Not Arrive';
    }
}