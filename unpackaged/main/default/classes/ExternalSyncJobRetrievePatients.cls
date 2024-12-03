/**
 * Created 13.12.2021..
 */

global class ExternalSyncJobRetrievePatients implements Database.AllowsCallouts {

    @TestVisible
    private static IntegrationErrorReporter logger = new IntegrationErrorReporter('ExtSync-J-RetPat');

    public static final Id PERSON_ACCOUNT_RECORD_TYPE_ID = Cache.recordTypeId(AccountManager.RT_PERSON_ACCOUNT);


    @Future(Callout=true)
    public static void scheduleGetPatients() {
        getPatients();
    }

    @InvocableMethod(Category='Patient' Label='External Sync - retrieve recently updated Patients' Description='Retrieve recently updated Patients' Callout=true)
    public static void getPatients() {

        doGetAndOptionallyWrite(true, null);

    }

    public static SyncResult doGetAndOptionallyWrite(Boolean doWrite, Datetime fromDateTime) {
        //        logger.addLog(LoggingLevel.INFO, null, 'Starting getPatients()');

        SyncResult ret = new SyncResult();

        try {
            //HEYDOC
            HeyDocService.Pagination pagination = new HeyDocService.Pagination();
            pagination.page = 0;
            pagination.pageSize = 200;

            HeyDocService.QueryOptions queryOptions = new HeyDocService.QueryOptions();
            queryOptions.updatedAt = new HeyDocService.DateRange();

            if (fromDateTime != null) {
                queryOptions.updatedAt.start = fromDateTime;
            }
            else {
                queryOptions.updatedAt.start = Datetime.now().addHours(-8);
            }

            queryOptions.updatedAt.end_jsonsafe = Datetime.now().addHours(4);

            Boolean hasMore = true;
            List<HeyDocService.Patient> heyDocPatients = new List<HeyDocService.Patient>();
            HeyDocService.PatientData patientData = null;
            //            logger.addLog(LoggingLevel.INFO, null, 'getPatients(): before callout');
            while (hasMore) {
                pagination.page++;
                if (pagination.page >= 99) {
                    logger.addLog(LoggingLevel.ERROR, null, 'Too many patients to sync from HEYDOC!');
                    break;
                }
                hasMore = false;
                //                logger.addLog(LoggingLevel.INFO, null, 'getPatients(): callout at page ' + pagination.page);
                patientData = HeyDocService.searchPatients(null, pagination, queryOptions);
                if (patientData != null) {
                    heyDocPatients.addAll(patientData.data);
                    hasMore = (patientData.pageInfo?.hasMore != null && patientData.pageInfo?.hasMore);
                }
            }
            //            logger.addLog(LoggingLevel.INFO, null, 'retrieved HD patients:' + heyDocPatients.size());

            if (heyDocPatients.size() > 0) {

                /*
                    split retrieved patients to
                    1) those we have (by external Id) and those that might be new
                    2) new ones
                      - matched
                      - unmatched
                */

                //get all patients by external Ids
                Map<String, HeyDocService.Patient> map_retrievedHeyDocPatients = new Map<String, HeyDocService.Patient>();
                Map<String, HeyDocService.Patient> map_retrievedHeyDocPatientsToCreateOrMap = new Map<String, HeyDocService.Patient>();
                for (HeyDocService.Patient p : heyDocPatients) {
                    if (p.dob != null) p.dob = p.dob.addHours(3); //move the dob midday because HD ignores timezones
                    map_retrievedHeyDocPatients.put(p.id, p);
                }

                List<Account> ourPatientsWithIds = [
                        SELECT Id,
                                HeyDoc_Id__c,
                                FirstName,
                                LastName,
                                Date_of_Birth__c,
                                PersonEmail,
                                Gender__c,
                                BillingStreet,
                                BillingCity,
                                BillingCountry,
                                BillingPostalCode,
                                BillingState,
                                PersonMobilePhone
                        FROM Account
                        WHERE HeyDoc_Id__c IN :map_retrievedHeyDocPatients.keySet()
                        AND RecordTypeId = :PERSON_ACCOUNT_RECORD_TYPE_ID
                        FOR UPDATE
                ];
                Map<String, Account> map_existingKnownAccounts = new Map<String, Account>();
                for (Account acc : ourPatientsWithIds) {
                    map_existingKnownAccounts.put(acc.HeyDoc_Id__c, acc);
                }
                System.debug('patients with matching HDID on SF side: ' + ourPatientsWithIds.size());

                List<Account> knownPatientsToUpdate = new List<Account>();
                List<Account> patientsToInsert = new List<Account>();
                Boolean changed = false;

                //for each patient retrieved from HeyDoc
                for (HeyDocService.Patient hp : heyDocPatients) {
                    Account acc = map_existingKnownAccounts.get(hp.id);
                    if (acc != null) // if we have a patient with this heydoc id
                    {
                        //detect changes
                        changed = isDifferent(acc.FirstName, hp.firstName)
                                || isDifferent(acc.LastName, hp.lastName)
                                || (acc.Date_of_Birth__c != hp.dob?.date())
                                || isDifferent(acc.PersonEmail, hp.email)
                                || isDifferent(acc.Gender__c, ExternalSyncPatients.mapFromHeyDocGender(hp.gender))
                                || isDifferent(acc.BillingStreet, hp.address?.address)
                                || isDifferent(acc.BillingCity, hp.address?.city)
                                || isDifferent(acc.BillingCountry, ExternalSyncPatients.mapToCountry(hp.address?.country))
                                || isDifferent(acc.BillingPostalCode, hp.address?.postcode)
                                || isDifferent(acc.PersonMobilePhone, hp.getMobilePhone());

                        if (changed) {
                            System.debug(' - patient ' + acc.Id + ' has changed data on HD side');
                            acc.FirstName = hp.firstName;
                            acc.LastName = hp.lastName;
                            acc.Date_of_Birth__c = hp.dob?.date();
                            acc.PersonEmail = hp.email;
                            acc.Gender__c = ExternalSyncPatients.mapFromHeyDocGender(hp.gender);
                            acc.BillingStreet = hp.address?.address;
                            acc.BillingCity = hp.address?.city;
                            acc.BillingCountry = ExternalSyncPatients.mapToCountry(hp.address?.country);
                            acc.BillingPostalCode = hp.address?.postcode;
                            acc.PersonMobilePhone = hp.getMobilePhone();
                            acc.HeyDoc_Fingerprint__c = ExternalSyncPatients.calcFingerprint(acc);
                            knownPatientsToUpdate.add(acc);
                        }
                        else {
                            System.debug(' - patient ' + acc.Id + ' has NO changes on HD side');
                        }
                    }
                    else {
                        // ELSE
                        // if we got a patient but we do not have an account with this HDID, we need to either
                        // - create
                        // - or update an account with the same name, last name, dob
                        map_retrievedHeyDocPatientsToCreateOrMap.put(hp.id, hp);
                    }
                }


                System.debug('retrieved num patients to create or map: ' + map_retrievedHeyDocPatientsToCreateOrMap.size());
                // list date of births from all the remaining patients
                Set<Date> remainDOBs = new Set<Date>();
                Set<String> remainEmails = new Set<String>();
                for (HeyDocService.Patient hp : map_retrievedHeyDocPatientsToCreateOrMap.values()) {
                    if (hp.dob != null) remainDOBs.add(hp.dob.date());
                    if (hp.email != null) remainEmails.add(hp.email);
                }
                //                //get patients with these dobs
                //                List <Account> candidateAccounts = getAccountsForDOBs(remainDOBs);

                //get patients with these emails
                List <Account> candidateAccounts = getAccountsForEmails(remainEmails);

                //for each remaining HD patient
                Boolean candidateFound = false;
                for (HeyDocService.Patient hp : map_retrievedHeyDocPatientsToCreateOrMap.values()) {
                    //for each candidate account
                    candidateFound = false;
                    for (Account acc : candidateAccounts) {
                        if (
                                (acc.PersonEmail != null)
                                        && (acc.PersonEmail.equalsIgnoreCase(hp.email))
                                        && (acc.Date_of_Birth__c != null)
                                        && (hp.dob != null)
                                        && (acc.Date_of_Birth__c == hp.dob.date())) {
                            if (acc.HeyDoc_Id__c!=hp.id) {
                                System.debug(' - patient ' + acc.Id + ' is now mapped to HD id ' + hp.id);
                                acc.HeyDoc_Id__c = hp.id;
                                acc.FirstName = hp.firstName;
                                acc.LastName = hp.lastName;
                                acc.Date_of_Birth__c = hp.dob?.date();
                                acc.PersonEmail = hp.email;
                                acc.Gender__c = ExternalSyncPatients.mapFromHeyDocGender(hp.gender);
                                acc.BillingStreet = hp.address?.address;
                                acc.BillingCity = hp.address?.city;
                                acc.BillingCountry = ExternalSyncPatients.mapToCountry(hp.address?.country);
                                acc.BillingPostalCode = hp.address?.postcode;
                                acc.PersonMobilePhone = hp.getMobilePhone();
                                acc.HeyDoc_Fingerprint__c = ExternalSyncPatients.calcFingerprint(acc);
                                knownPatientsToUpdate.add(acc);
                                candidateFound = true;
                                break;
                            }
                        }
                    }

                    //if no candidate is hound for this HD patient, then we need to create this account
                    if (!candidateFound) {
                        Account accNew = newAccountFromPatient(hp);
                        patientsToInsert.add(accNew);
                    }
                }

                ret.knownPatientsToUpdate = knownPatientsToUpdate;
                ret.patientsToInsert = patientsToInsert;
                ret.map_retrievedHeyDocPatientsToCreateOrMap = map_retrievedHeyDocPatientsToCreateOrMap;
                ret.map_retrievedHeyDocPatients = map_retrievedHeyDocPatients;

                System.debug('=> HD patients to update: ' + knownPatientsToUpdate.size());
                System.debug('=> HD patients to insert: ' + patientsToInsert.size());

                /*
                for (Account account : patientsToInsert) {
                    //logger.addLog(LoggingLevel.INFO, account.Id, 'creating patient due to new on HD', null, account.HeyDoc_Id__c);
                }


                for (Account account : knownPatientsToUpdate) {
                    //logger.addLog(LoggingLevel.INFO, account.Id, 'updating patient due to change on HD', null, account.HeyDoc_Id__c);
                }
                */

                if (doWrite) {
                    List<Database.SaveResult> updateResult = Database.update(knownPatientsToUpdate, false);
                    for (Database.SaveResult ures : updateResult) {
                        if (!ures.isSuccess()) {
                            logger.addLog(LoggingLevel.ERROR, ures.getId(), 'unable to update Account', null, JSON.serialize(ures.getErrors()));
                        }
                    }

                    for (Account account : patientsToInsert) {
                        //logger.addLog(LoggingLevel.INFO, account.Id, 'inserting patient due to change on HD', null, account.HeyDoc_Id__c);
                    }
                    List<Database.SaveResult> insertResult = Database.insert(patientsToInsert, false);
                    for (Database.SaveResult ires : insertResult) {
                        if (!ires.isSuccess()) {
                            logger.addLog(LoggingLevel.ERROR, null, 'unable to insert Account for external patient', null, JSON.serialize(ires.getErrors()));
                        }
                    }
                }
            }
        }
        catch (Exception e) {
            logger.addLog(LoggingLevel.ERROR, null, 'unable to do getPatients() ' + e.getMessage() + e.getTypeName(), e.getStackTraceString(), null);
        }

        if (doWrite) logger.persistLogs();

        return ret;
    }

    /**
     * Returns if there is a change in the provided strings, but ignores changes if both are isBlank
     *
     * @param a
     * @param b
     *
     * @return
     */
    public static Boolean isDifferent(String a, String b) {
        if (String.isBlank(a) && String.isBlank(b)) return false;
        return a != b;
    }

    /**
     * Returns if there is a change in the provided strings, but ignores changes if both are isBlank
     *
     * @param a
     * @param b
     *
     * @return
     */
    public static Boolean isSameIgnoreCase(String a, String b) {
        if (String.isBlank(a) && String.isBlank(b)) return true;
        if (String.isBlank(a)) return false;
        if (String.isBlank(b)) return false;
        String aIC = '' + a;
        String bIC = '' + b;
        if (a != null) aIC = a.toLowerCase();
        if (b != null) bIC = b.toLowerCase();
        return aIC.equalsIgnoreCase(bIC);
    }

    public static Account newAccountFromPatient(HeyDocService.Patient hp) {
        Account accNew = new Account();
        accNew.HeyDoc_Id__c = hp.id;
        accNew.FirstName = hp.firstName;
        accNew.LastName = hp.lastName;
        accNew.Date_of_Birth__c = hp.dob?.date();
        accNew.PersonEmail = hp.email;
        accNew.Gender__c = ExternalSyncPatients.mapFromHeyDocGender(hp.gender);
        accNew.BillingStreet = hp.address?.address;
        accNew.BillingCity = hp.address?.city;
        accNew.BillingCountry = ExternalSyncPatients.mapToCountry(hp.address?.country);
        accNew.BillingPostalCode = hp.address?.postcode;
        accNew.PersonMobilePhone = hp.getMobilePhone();
        accNew.HeyDoc_Fingerprint__c = ExternalSyncPatients.calcFingerprint(accNew);
        return accNew;
    }


    public static List<Account> getAccountsForEmails(Set<String> emails) {
        List <Account> candidateAccounts = [
                SELECT Id,
                        HeyDoc_Id__c,
                        FirstName,
                        LastName,
                        Date_of_Birth__c,
                        PersonEmail,
                        Gender__c,
                        BillingStreet,
                        BillingCity,
                        BillingCountry,
                        BillingPostalCode,
                        BillingState,
                        PersonMobilePhone
                FROM Account
                WHERE
                        PersonEmail IN :emails
                        AND RecordTypeId = :PERSON_ACCOUNT_RECORD_TYPE_ID
        ]; //AND HeyDoc_Id__c = NULL

        return candidateAccounts;
    }

    public class SyncResult {
        public List<Account> knownPatientsToUpdate;
        public List<Account> patientsToInsert;
        public Map<String, HeyDocService.Patient> map_retrievedHeyDocPatients;
        public Map<String, HeyDocService.Patient> map_retrievedHeyDocPatientsToCreateOrMap;

    }
}