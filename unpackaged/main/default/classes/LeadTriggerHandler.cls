/**
 * Created by Matija on 28.8.2023..
 */

public without sharing class LeadTriggerHandler {

    public static void handle() {

        if (Trigger.isBefore) {
            try {

                List<Lead> newLeads = Trigger.new;

                // find potential existing patients by email and date of birth
                Set<String> leadEmails = new Set<String>();

                for (Lead ld : newLeads) {
                    //System.debug('::Lead_tgr:ld:' + ld);
                    if (Trigger.isInsert) System.debug('::Lead_tgr:insert');
                    if (Trigger.isUpdate) System.debug('::Lead_tgr:update');
                    if (String.isNotBlank(ld.Email)) leadEmails.add(ld.Email);
                }

                //System.debug('::Lead_tgr:emails:' + leadEmails);

                List<Account> existingAccounts = [
                        SELECT
                                Id, CreatedDate, PersonEmail, Date_of_Birth__c
                        FROM Account
                        WHERE PersonEmail IN :leadEmails
                        ORDER BY Number_of_Opps__c ASC
                ];

                //System.debug('::Lead_tgr:existingAccounts:' + existingAccounts);

                Account potentialAccount = null;
                Set<Id> potentialPatients = new Set<Id>();
                for (Lead ld : newLeads) {

                    if (String.isBlank(ld.Email)) continue;

                    // if lead does not already have an Existing Patient set, try to guess which is it
                    if (String.isBlank(ld.Existing_Patient__c)) {
                        potentialAccount = null;

                        for (Account account : existingAccounts) {
                            if (account.PersonEmail.equalsIgnoreCase(ld.Email)) {
                                potentialAccount = account;
                                if (ld.Date_of_birth__c != null) {
                                    if (account.Date_of_Birth__c == ld.Date_of_birth__c) break; // matched email AND dob
                                }
                            }
                        }


                        if (potentialAccount == null || potentialAccount.CreatedDate > ld.CreatedDate) {
                            ld.Existing_Patient__c = null;
                            System.debug('::Lead_tgr:setting New Patient for ' + ld.Email);
                            ld.Reporting_Category__c = 'New Patient'; // no patients found at all
                        }
                        else {
                            ld.Existing_Patient__c = potentialAccount.Id;
                            if (String.isNotBlank(ld.Business_Unit__c)) ld.Reporting_Category__c = 'New Business Unit';
                            System.debug('::Lead_tgr:setting New Business Unit for ' + ld.Email);
                            potentialPatients.add(potentialAccount.Id);
                        }
                    }
                    else {
                        potentialPatients.add(ld.Existing_Patient__c);
                    }

                }

                // search for Patient Business Units for these accounts
                if (potentialPatients.size() > 0) {
                    List<Patient_Business_Unit__c> pbus = [
                            SELECT Id, CreatedDate, First_Lead__c, Account__c, New_Patient__c, Effective_Date__c, Business_Unit__c
                            FROM Patient_Business_Unit__c
                            WHERE Won__c = TRUE
                            AND Account__c IN :potentialPatients
                    ];

                    System.debug('::Lead_tgr: pbus found ' + pbus);

                    Datetime fromLeadCreation = Datetime.now();

                    Boolean found_at_least_one_pbu = false;
                    for (Lead ld : newLeads) {

                        fromLeadCreation = Datetime.now();
                        if (ld.CreatedDate != null) fromLeadCreation = ld.CreatedDate;
                        if (String.isBlank(ld.Email) || String.isBlank(ld.Business_Unit__c) || ld.Existing_Patient__c == null) continue;

                        if (!String.isBlank(ld.Email)) System.debug('::Lead_tgr: processing for ' + ld.Email);

                        found_at_least_one_pbu = false;
                        for (Patient_Business_Unit__c pbu : pbus) {

                            if ((pbu.Account__c == ld.Existing_Patient__c) && (pbu.Effective_Date__c <= fromLeadCreation)) {
                                found_at_least_one_pbu = true;
                                //if such PBU exists
                                if (ld.Business_Unit__c == pbu.Business_Unit__c) {

                                    //default to repeat booking
                                    System.debug('::Lead_tgr: "repeat booking" because existing pbu found  ' + ld.Email);
                                    ld.Reporting_Category__c = 'Repeat Booking'; // if there's a pbu record and it's earlier than lead, this is a repeat booking

                                    if ((pbu.First_Lead__c == ld.Id || pbu.First_Lead__c == null) && (pbu.Effective_Date__c != null) && (pbu.Effective_Date__c == ld.CreatedDate.date())) {
                                        if (pbu.New_Patient__c) {
                                            ld.Reporting_Category__c = 'New Patient';
                                            System.debug('::Lead_tgr: "new patient" because pbu found and lead is first on a "NewPatient" PBU ' + ld.Email);
                                            break;
                                        }
                                    }

                                    if ((pbu.Effective_Date__c != null) && (pbu.Effective_Date__c == ld.CreatedDate.date())) {
                                        ld.Reporting_Category__c = 'New Business Unit';
                                        System.debug('::Lead_tgr: (2) "New Business Unit" because pbu found and lead is first on non-"NewPatient" PBU ' + ld.Email);
                                        break;
                                    }

                                    break;
                                }
                            }
                        }
                        if (!found_at_least_one_pbu) {
                            System.debug('::Lead_tgr: "New Patient " because no existing pbu found  ' + ld.Email);
                            ld.Reporting_Category__c = 'New Patient';
                        }


                    }
                }
            }
            catch (Exception ex) {
                System.debug(LoggingLevel.ERROR, ex);
            }
        }

        if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {

            if (Trigger.isBefore) System.debug('::TGR:Lead: isBefore');
            if (Trigger.isAfter) System.debug('::TGR:Lead: isAfter');
            if (Trigger.isInsert) System.debug('::TGR:Lead: isInsert');
            if (Trigger.isUpdate) System.debug('::TGR:Lead: isUpdate');

            // get all accounts now so there's no SOQL in loop
            Set<Id> accountIds = new Set<Id>();
            Map<Id, Account> map_accId_acc = new Map<Id, Account>();
            List<Lead> newLeadsOrig = Trigger.new;
            List<Lead> newLeads = new List<Lead>();

            //consider only recent closed won opps with business units
            for (Lead ld : newLeadsOrig) {
                if (String.isNotBlank(ld.Business_Unit__c) && ld.ConvertedAccountId != null) {
                    newLeads.add(ld);
                    accountIds.add(ld.ConvertedAccountId);
                }
            }

            if (newLeads.isEmpty()) return; // LEAVE IF NO converted leads with a BU

            List<Patient_Business_Unit__c> pbusToUpsert = new List<Patient_Business_Unit__c>();

            //get these accounts to search from
            List<Patient_Business_Unit__c> pbus = [
                    SELECT
                            Id,
                            Account__c,
                            Composite_Key__c,
                            Business_Unit__c,
                            First_Lead__c,
                            First_Lead__r.CreatedDate,
                            First_Lead__r.ConvertedDate,
                            Latest_Lead__c,
                            Latest_Lead__r.CreatedDate,
                            Latest_Lead__r.ConvertedDate,
                            Won__c
                    FROM Patient_Business_Unit__c
                    WHERE Account__c IN :accountIds
                    FOR UPDATE
            ];

            // find accounts that are not new patients
            Map<String, Patient_Business_Unit__c> map_composite_existingPatientsBu = new Map<String, Patient_Business_Unit__c>();
            for (Patient_Business_Unit__c patientBusinessUnit : pbus) {
                map_composite_existingPatientsBu.put(patientBusinessUnit.Composite_Key__c, patientBusinessUnit);
            }

            // now build PBU records

            for (Lead ld : newLeads) {

                String compositeKey = ld.ConvertedAccountId + '@' + ld.Business_Unit__c;

                Patient_Business_Unit__c pbu = map_composite_existingPatientsBu.get(compositeKey);
                if (pbu == null) pbu = new Patient_Business_Unit__c(
                        Account__c = ld.ConvertedAccountId,
                        Business_Unit__c = ld.Business_Unit__c,
                        New_Patient__c = false, // new leads do not count as new patients (for a completely new PBU record)
                        First_Lead__c = ld.Id,
                        Latest_Lead__c = ld.Id);

                if (pbu.Latest_Lead__c == null || (pbu.Latest_Lead__c != null && pbu.Latest_Lead__r.CreatedDate != null && pbu.Latest_Lead__r.CreatedDate < ld.CreatedDate)) pbu.Latest_Lead__c = ld.Id;
                if (pbu.First_Lead__c == null || (pbu.First_Lead__c != null && pbu.First_Lead__r.CreatedDate != null && pbu.First_Lead__r.CreatedDate > ld.CreatedDate)) pbu.First_Lead__c = ld.Id;

                pbu.Composite_Key__c = compositeKey;
                map_composite_existingPatientsBu.put(pbu.Composite_Key__c, pbu);

                pbusToUpsert.add(pbu);

            }

            if (!pbusToUpsert.isEmpty()) {

                Map<String, Patient_Business_Unit__c> uniquePbus = new Map<String, Patient_Business_Unit__c>();
                for (Patient_Business_Unit__c patientBusinessUnit : pbusToUpsert) {
                    uniquePbus.put(patientBusinessUnit.Composite_Key__c, patientBusinessUnit);
                }
                Database.upsert(uniquePbus.values(), Patient_Business_Unit__c.Composite_Key__c, false);
            }


        }


    }

}