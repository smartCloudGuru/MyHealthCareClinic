/**
 * Created 17.5.2024..
 */

public without sharing class AeronaTreatmentPlansCtrl {

    public static void onTreatment(Map<String, Object> reqMap) {

        String patientId = '' + reqMap.get('patientId');

        if (String.isEmpty(patientId)) return;

        refreshAllTreatmentPlansForPatient(patientId);
    }

    public static void refreshAllTreatmentPlansForPatient(String aeronaPatientId) {

        if (aeronaPatientId == '0') return;

        //todo get local patient, process if we don't have them or there are multiples
        List<Account> accounts = [SELECT Id, Name, Aerona_Id__c FROM Account WHERE Aerona_Id__c = :aeronaPatientId];

        if (accounts.isEmpty()) {
            //todo fetch and create when needed
            System.debug('No such Aerona Patient by ID: ' + aeronaPatientId + ' !');
            return;
        }

        Account acc = accounts[0];

        // get all treatments for that patient
        List<AeronaServiceOASApi.OASAPITreatment> treatments = AeronaService.getTreatmentsForPatient(Long.valueOf(aeronaPatientId));

        // get treatment plan descriptions for that patient
        Map<String, AeronaServiceOASApi.OASAPITreatmentPlan> map_atpId_atplan = new Map<String, AeronaServiceOASApi.OASAPITreatmentPlan>();
        List<AeronaServiceOASApi.OASAPITreatmentPlan> atps = AeronaService.getTreatmentPlansForPatient(Long.valueOf(acc.Aerona_Id__c));
        if (atps != null) {
            for (AeronaServiceOASApi.OASAPITreatmentPlan oasapiTreatmentPlan : atps) {
                map_atpId_atplan.put(String.valueOf(oasapiTreatmentPlan.treatmentPlanId), oasapiTreatmentPlan);
            }
        }

        //process all treatments
        processAllPatientTreatmentsWithTID(acc, treatments, map_atpId_atplan);

    }

    //    /**
    //     * Processing all Aerona treatments linked to a given account.
    //     * It checks whether there are existing opportunities(treatmentPlans) and treatments, and creates or updates them as necessary.
    //     * The Opportunities are linked to their respective treatments. The procedure also camputes and calculates treatment amounts and
    //     * Retained Charges of the Opportunity.
    //     *
    //     * @param acc The Account which the treatments are tied to.
    //     * @param treatments A list of all treatments linked to the Account to be processed.
    //     */
    //    public static void processAllPatientTreatments(Account acc, List<AeronaServiceOASApi.OASAPITreatment> treatments) {
    //        if (treatments == null || treatments.size() == 0) return;
    //
    //        Map<String, String> clinicianNames = getClinicianNames();
    //
    //        //extract list of treatmentPlan names
    //        Map<String, Opportunity> opsMap = new Map<String, Opportunity>();
    //
    //        for (AeronaServiceOASApi.OASAPITreatment treatment : treatments) {
    //            if (String.isEmpty(treatment.treatmentPlanDescription)) continue;
    //
    //            opsMap.put(temporaryNameId(treatment), null);
    //            if (Test.isRunningTest()) System.debug('::processing treatment:' + JSON.serialize(treatment));
    //        }
    //
    //        //get any existing ones and put them to map
    //        List<Opportunity> existingOpps = [
    //                SELECT
    //                        Id, Aerona_Treatment_Plan_Name__c, Amount, StageName, Retained_Charges__c, CreatedDate, CloseDate, Probability, Treatment_Clinician__c
    //                FROM Opportunity
    //                WHERE Aerona_Treatment_Plan_Name__c IN :opsMap.keySet()
    //        ];
    //        for (Opportunity opportunity : existingOpps) {
    //            opsMap.put(opportunity.Aerona_Treatment_Plan_Name__c, opportunity);
    //        }
    //        if (Test.isRunningTest()) System.debug('::existingOpps:' + JSON.serialize(existingOpps));
    //
    //        //get any existing treatmentIds for the patient (so that we know if we need to set Created Date for new ones or not)
    //        List<Aerona_Treatment__c> existingTreatments = [SELECT Id, External_Id__c FROM Aerona_Treatment__c WHERE Patient_Id__c = :acc.Aerona_Id__c];
    //        Set<String> existingTreatmentExtIds = new Set<String>();
    //        for (Aerona_Treatment__c etr : existingTreatments) {
    //            existingTreatmentExtIds.add(etr.External_Id__c);
    //        }
    //        if (Test.isRunningTest()) System.debug('::existingTreatmentExtIds:' + JSON.serialize(existingTreatmentExtIds));
    //
    //        List<Aerona_Treatment__c> ae_treatments_to_upsert = new List<Aerona_Treatment__c>();
    //        List<Aerona_Treatment__c> ae_treatments_to_delete = new List<Aerona_Treatment__c>();
    //
    //        for (AeronaServiceOASApi.OASAPITreatment treatment : treatments) {
    //            if (String.isEmpty(treatment.treatmentPlanDescription)) continue;
    //
    //            String temporaryIdByPlanName = temporaryNameId(treatment);
    //            Opportunity opp = opsMap.get(temporaryIdByPlanName);
    //
    //            if (Test.isRunningTest()) System.debug('::gen/match Opp for treatment:' + JSON.serialize(treatment));
    //
    //            //add each to a list of treatment to upsert
    //            Aerona_Treatment__c aeronaTreatment = toAeronaTreatment(existingTreatmentExtIds, treatment);
    //            if (treatment.userId != null) {
    //                if (clinicianNames.get(String.valueOf(treatment.userId)) != null) aeronaTreatment.Treatment_Clinician__c = clinicianNames.get(String.valueOf(treatment.userId));
    //            }
    //
    //            if (!aeronaTreatment.Deleted_Ind__c) {
    //                ae_treatments_to_upsert.add(aeronaTreatment);
    //                if ((String.isEmpty(treatment.treatmentPlanDescription)) && existingTreatmentExtIds.contains(aeronaTreatment.External_Id__c)) ae_treatments_to_delete.add(aeronaTreatment);
    //
    //            }
    //            else // do not include deleted treatments
    //            {
    //                if (existingTreatmentExtIds.contains(aeronaTreatment.External_Id__c)) ae_treatments_to_delete.add(aeronaTreatment);
    //            }
    //
    //            if (Test.isRunningTest()) System.debug('::mapped to AT_C:' + JSON.serialize(aeronaTreatment));
    //
    //            if (opp == null) {
    //                //new needed
    //                opp = new Opportunity();
    //                opp.Mode__c = 'Dental Treatment Plan';
    //                opp.AccountId = acc?.Id;
    //                opp.Name = acc.Name + ' [DTP] ' + treatment.treatmentPlanDescription;
    //                opp.StageName = 'Qualification';
    //                opp.Probability = 10;
    //                opp.CloseDate = Date.today();
    //                opp.Amount = 0;
    //                opp.Aerona_Treatment_Plan_Name__c = temporaryIdByPlanName;
    //                if (Test.isRunningTest()) System.debug('::new opp to be created:' + opp.Aerona_Treatment_Plan_Name__c);
    //
    //                //fields that are required on forms
    //                opp.LeadSource = 'Did Not Obtain';
    //                opp.Call_Back__c = 'Not a call back';
    //                opp.Site__c = 'None specified';
    //                //opp.Business_Unit__c = 'Dentist';
    //                opp.Retained_Charges__c = 0;
    //                opp.CreatedDate = Datetime.now();
    //                opp.Exclude_From_Reporting__c = true;
    //            }
    //
    //            if (opp.Treatment_Clinician__c == null && treatment.userId != null) {
    //                if (clinicianNames.get(String.valueOf(treatment.userId)) != null) opp.Treatment_Clinician__c = clinicianNames.get(String.valueOf(treatment.userId));
    //            }
    //
    //            opp.RecordTypeId = OpportunityManager.getDental_TreatmentPlan_RT_Id();
    //            opsMap.put(temporaryIdByPlanName, opp);
    //        }
    //
    //        System.debug('upsert:' + ae_treatments_to_upsert.size());
    //
    //
    //        //now recalculate all opportunity amounts
    //        for (Opportunity opportunity : opsMap.values()) {
    //            opportunity.Amount = 0;
    //            opportunity.Retained_Charges__c = 0;
    //        }
    //
    //        for (AeronaServiceOASApi.OASAPITreatment treatment : treatments) {
    //
    //            if (treatment.deleteInd == true) continue;
    //
    //            if (String.isEmpty(treatment.treatmentPlanDescription)) continue; //treatment.treatmentPlanDescription = '---';
    //
    //            Opportunity opp = opsMap.get(temporaryNameId(treatment));
    //
    //            if (opp != null) {
    //                opp.Amount += util_zeroOrDoubleValue(treatment.totalNetPrice);
    //                opp.Retained_Charges__c += util_zeroOrDoubleValue(treatment.amountPaid);
    //
    //                if (opp.Id == null) {
    //                    //set createddate for any new opportunity to the earliest known treatment
    //                    if (treatment.dateCreated != null && treatment.dateCreated < opp.CreatedDate) {
    //                        opp.CreatedDate = treatment.dateCreated;
    //                        opp.CloseDate = treatment.dateCreated.date();
    //                    }
    //                }
    //
    //                if (treatment.dateCompleted != null && (treatment.dateCompleted > opp.CloseDate)) opp.CloseDate = treatment.dateCompleted.date();
    //
    //            }
    //        }
    //
    //        //close or reopen opportunities based on remaining values, and set default probabilities
    //        for (Opportunity opp : opsMap.values()) {
    //            if (opp.Amount == opp.Retained_Charges__c) {
    //                opp.StageName = 'Closed Won';
    //                opp.Probability = 100;
    //            }
    //            if (opp.Amount != opp.Retained_Charges__c && opp.StageName == 'Closed Won') {
    //                opp.Probability = 50;
    //                opp.StageName = 'Qualification';
    //            }
    //            if (opp.Amount != opp.Retained_Charges__c) {
    //                if (opp.Amount != null && opp.Retained_Charges__c != null && opp.Amount > 0 && (opp.Retained_Charges__c < opp.Amount)) opp.Probability = Math.floor(opp.Retained_Charges__c / opp.Amount);
    //            }
    //            if (opp.StageName == 'Qualification' && opp.Probability < 10) {
    //                opp.Probability = 10;
    //            }
    //
    //        }
    //
    //        upsert opsMap.values();
    //
    //        // LINK treatments to opportunities by plan name
    //        Map<String, Id> map_planName_oppId = new Map<String, Id>(); // create map of oppid and opp name for these inserted and updated
    //        for (Opportunity opportunity : opsMap.values()) {
    //            map_planName_oppId.put(opportunity.Aerona_Treatment_Plan_Name__c, opportunity.Id);
    //        }
    //
    //        //iterate over ae_treatments_to_upsert, and link them to appropriate opportunity
    //        for (Aerona_Treatment__c aeronaTreatment : ae_treatments_to_upsert) {
    //            aeronaTreatment.Opportunity__c = map_planName_oppId.get(temporaryNameId(aeronaTreatment));
    //        }
    //
    //        Database.upsert(ae_treatments_to_upsert, Aerona_Treatment__c.External_Id__c, false);
    //
    //        //delete those that have eventually been deleted in aerona
    //        Database.delete(ae_treatments_to_delete, false);
    //
    //        //at the end, if we have an opportunity with no aerona treatments, mark them as lost
    //        //        List<Opportunity> opsForPatient = [
    //        //                SELECT
    //        //                        Id, Amount, StageName, Reason_for_non_conversion__c, (SELECT Id FROM Aerona_Treatments__r)
    //        //                FROM Opportunity
    //        //                WHERE AccountId = :acc.Id
    //        //                AND Mode__c = 'Dental Treatment Plan'
    //        //        ];
    //
    //        //        List<Opportunity> opsToMarkAsLost = new List<Opportunity>();
    //        //        for (Opportunity opportunity : opsForPatient) {
    //        //            if (opportunity.Aerona_Treatments__r.isEmpty()) {
    //        //                opportunity.Amount = 0;
    //        //                opportunity.Retained_Charges__c = 0;
    //        //                opportunity.StageName = 'Closed Lost';
    //        //                opportunity.Reason_for_non_conversion__c = 'Price - expensive';
    //        //                opsToMarkAsLost.add(opportunity);
    //        //            }
    //        //        }
    //        //
    //        //        Database.update(opsToMarkAsLost, false);
    //
    //    }


    /**
     * Processing all Aerona treatments linked to a given account.
     * It checks whether there are existing opportunities(treatmentPlans) and treatments, and creates or updates them as necessary.
     * The Opportunities are linked to their respective treatments. The procedure also camputes and calculates treatment amounts and
     * Retained Charges of the Opportunity.
     *
     * @param acc The Account which the treatments are tied to.
     * @param treatments
     * @param map_atpId_atplan
     */
    public static void processAllPatientTreatmentsWithTID(Account acc, List<AeronaServiceOASApi.OASAPITreatment> treatments, Map<String, AeronaServiceOASApi.OASAPITreatmentPlan> map_atpId_atplan) {
        if (treatments == null || treatments.size() == 0) return;

        Map<String, String> clinicianNames = getClinicianNames();

        //extract list of treatmentPlan names
        Set<String> aeronaPlanNames = new Set<String>();
        Set<String> aeronaTreatmentIds = new Set<String>();
        Map<String, String> map_planName_planId = new Map<String, String>();
        Map<String, Opportunity> opsMap = new Map<String, Opportunity>();

        for (AeronaServiceOASApi.OASAPITreatment treatment : treatments) {
            if (treatment.treatmentPlanId > 0) {
                aeronaPlanNames.add(temporaryNameId(treatment));
                aeronaTreatmentIds.add(String.valueOf(treatment.treatmentPlanId));
                map_planName_planId.put(temporaryNameId(treatment), String.valueOf(treatment.treatmentPlanId));
            }
        }

        if (Test.isRunningTest()) System.debug('::aeronaPlanNames:' + JSON.serialize(aeronaPlanNames));
        if (Test.isRunningTest()) System.debug('::aeronaTreatmentIds:' + JSON.serialize(aeronaTreatmentIds));

        // due to transition from plan names to treatment plan IDs, first gat any without a treatmentID, then update their treatmentPlanIds
        //get any existing ones by plan name, where we don't have the treatmentId
        List<Opportunity> existingOppsByPlanName = [
                SELECT
                        Id, Aerona_Treatment_Plan_Name__c, Aerona_Treatment_Plan_Id__c
                FROM Opportunity
                WHERE Aerona_Treatment_Plan_Name__c IN :aeronaPlanNames
                AND Aerona_Treatment_Plan_Id__c = NULL
        ];

        //update their ID to the new treatmentPlanId
        for (Opportunity opportunity : existingOppsByPlanName) {
            opportunity.Aerona_Treatment_Plan_Id__c = map_planName_planId.get(opportunity.Aerona_Treatment_Plan_Id__c);
        }
        update existingOppsByPlanName;


        //get any existing ones and put them to map
        List<Opportunity> existingOppsByTreatmentId = [
                SELECT
                        Id, Aerona_Treatment_Plan_Name__c, Aerona_Treatment_Plan_Id__c, Amount, StageName, Retained_Charges__c, CreatedDate, CloseDate, Probability, Treatment_Clinician__c
                FROM Opportunity
                WHERE Aerona_Treatment_Plan_Id__c IN :aeronaTreatmentIds
        ];

        for (Opportunity opportunity : existingOppsByTreatmentId) {
            opsMap.put(opportunity.Aerona_Treatment_Plan_Id__c, opportunity);
        }
        if (Test.isRunningTest()) System.debug('::existingOpps:' + JSON.serialize(existingOppsByTreatmentId));

        //get any existing treatmentIds for the patient (so that we know if we need to set Created Date for new ones or not)
        List<Aerona_Treatment__c> existingTreatments = [SELECT Id, External_Id__c FROM Aerona_Treatment__c WHERE Patient_Id__c = :acc.Aerona_Id__c];
        Set<String> existingTreatmentExtIds = new Set<String>();
        for (Aerona_Treatment__c etr : existingTreatments) {
            existingTreatmentExtIds.add(etr.External_Id__c);
        }
        if (Test.isRunningTest()) System.debug('::existingTreatmentExtIds:' + JSON.serialize(existingTreatmentExtIds));

        List<Aerona_Treatment__c> ae_treatments_to_upsert = new List<Aerona_Treatment__c>();
        List<Aerona_Treatment__c> ae_treatments_to_delete = new List<Aerona_Treatment__c>();

        for (AeronaServiceOASApi.OASAPITreatment treatment : treatments) {
            if (treatment.treatmentPlanId == 0) continue;
            if (String.isEmpty(treatment.treatmentPlanDescription)) treatment.treatmentPlanDescription = '---';

            Opportunity opp = opsMap.get(String.valueOf(treatment.treatmentPlanId));

            if (Test.isRunningTest()) System.debug('::gen/match Opp for treatment:' + JSON.serialize(treatment));

            //add each to a list of treatment to upsert
            Aerona_Treatment__c aeronaTreatment = toAeronaTreatment(existingTreatmentExtIds, treatment);

            if (treatment.userId != null) {
                if (clinicianNames.get(String.valueOf(treatment.userId)) != null) aeronaTreatment.Clinician__c = clinicianNames.get(String.valueOf(treatment.userId));
            }

            if (!aeronaTreatment.Deleted_Ind__c) {
                ae_treatments_to_upsert.add(aeronaTreatment);
                // do not include treatments outside plans
                if ((aeronaTreatment.Plan_Id__c == '0') && existingTreatmentExtIds.contains(aeronaTreatment.External_Id__c)) ae_treatments_to_delete.add(aeronaTreatment);
            }
            else // do not include deleted treatments
            {
                if (existingTreatmentExtIds.contains(aeronaTreatment.External_Id__c)) ae_treatments_to_delete.add(aeronaTreatment);
            }

            if (Test.isRunningTest()) System.debug('::mapped to AT_C:' + JSON.serialize(aeronaTreatment));

            if (opp == null) {
                //new needed
                opp = new Opportunity();
                opp.Mode__c = 'Dental Treatment Plan';
                opp.AccountId = acc?.Id;
                opp.Name = acc.Name + ' [DTP] ' + treatment.treatmentPlanDescription;
                opp.StageName = 'Qualification';
                opp.Probability = 10;
                opp.CloseDate = Date.today();
                opp.Amount = 0;
                opp.Aerona_Treatment_Plan_Name__c = temporaryNameId(treatment);
                opp.Aerona_Treatment_Plan_Id__c = String.valueOf(treatment.treatmentPlanId);

                if (Test.isRunningTest()) System.debug('::new opp to be created:' + opp.Aerona_Treatment_Plan_Name__c);

                //fields that are required on forms
                opp.LeadSource = 'Did Not Obtain';
                opp.Call_Back__c = 'Not a call back';
                opp.Site__c = 'None specified';
                //opp.Business_Unit__c = 'Dentist';
                opp.Retained_Charges__c = 0;
                opp.CreatedDate = Datetime.now();
                opp.Exclude_From_Reporting__c = true;
            }
            else {
                opp.Aerona_Treatment_Plan_Name__c = temporaryNameId(treatment);
                opp.Aerona_Treatment_Plan_Id__c = String.valueOf(treatment.treatmentPlanId);
            }

            if (opp.Treatment_Clinician__c == null && treatment.userId != null) {
                if (clinicianNames.get(String.valueOf(treatment.userId)) != null) opp.Treatment_Clinician__c = clinicianNames.get(String.valueOf(treatment.userId));
            }

            opp.RecordTypeId = OpportunityManager.getDental_TreatmentPlan_RT_Id();
            if (opp.Aerona_Treatment_Plan_Id__c != null && map_atpId_atplan.get(opp.Aerona_Treatment_Plan_Id__c) != null) {
                opp.Description = HTMLUtils.convertToPlainText(map_atpId_atplan.get(opp.Aerona_Treatment_Plan_Id__c).treatmentPlanComment);
            }
            opsMap.put(opp.Aerona_Treatment_Plan_Id__c, opp);
        }

        System.debug('upsert:' + ae_treatments_to_upsert.size());


        //now recalculate all opportunity amounts
        for (Opportunity opportunity : opsMap.values()) {
            opportunity.Amount = 0;
            opportunity.Retained_Charges__c = 0;
        }

        for (AeronaServiceOASApi.OASAPITreatment treatment : treatments) {

            if (treatment.treatmentPlanId <= 0) continue;
            if (treatment.deleteInd == true) continue;

            if (String.isEmpty(treatment.treatmentPlanDescription)) treatment.treatmentPlanDescription = '---';

            Opportunity opp = opsMap.get(String.valueOf(treatment.treatmentPlanId));

            if (opp != null) {
                opp.Amount += util_zeroOrDoubleValue(treatment.totalNetPrice);
                opp.Retained_Charges__c += util_zeroOrDoubleValue(treatment.amountPaid);

                if (opp.Id == null) {
                    //set createddate for any new opportunity to the earliest known treatment
                    if (treatment.dateCreated != null && treatment.dateCreated < opp.CreatedDate) {
                        opp.CreatedDate = treatment.dateCreated;
                        opp.CloseDate = treatment.dateCreated.date();
                    }
                }

                if (treatment.dateCompleted != null && (treatment.dateCompleted > opp.CloseDate)) opp.CloseDate = treatment.dateCompleted.date();

            }
        }

        //close or reopen opportunities based on remaining values, and set default probabilities
        for (Opportunity opp : opsMap.values()) {
            if (opp.Amount == opp.Retained_Charges__c) {
                opp.StageName = 'Closed Won';
                opp.Probability = 100;
            }
            if (opp.Amount != opp.Retained_Charges__c && opp.StageName == 'Closed Won') {
                opp.Probability = 50;
                opp.StageName = 'Qualification';
            }
            if (opp.Amount != opp.Retained_Charges__c) {
                if (opp.Amount != null && opp.Retained_Charges__c != null && opp.Amount > 0 && (opp.Retained_Charges__c < opp.Amount)) opp.Probability = Math.floor(opp.Retained_Charges__c / opp.Amount);
            }
            if (opp.StageName == 'Qualification' && opp.Probability < 10) {
                opp.Probability = 10;
            }

        }

        upsert opsMap.values();

        // LINK treatments to opportunities by treatment plan id
        Map<String, Id> map_planId_oppId = new Map<String, Id>(); // create map of oppid and opp name for these inserted and updated
        for (Opportunity opportunity : opsMap.values()) {
            map_planId_oppId.put(opportunity.Aerona_Treatment_Plan_Id__c, opportunity.Id);
        }

        //iterate over ae_treatments_to_upsert, and link them to appropriate opportunity
        for (Aerona_Treatment__c aeronaTreatment : ae_treatments_to_upsert) {
            aeronaTreatment.Opportunity__c = map_planId_oppId.get(aeronaTreatment.Plan_Id__c);
        }

        System.debug(':: treatments to upsert: ' + ae_treatments_to_upsert.size());
        Database.upsert(ae_treatments_to_upsert, Aerona_Treatment__c.External_Id__c, false);

        //delete those that have eventually been deleted in aerona
        System.debug(':: treatments to delete: ' + ae_treatments_to_delete.size());
        Database.delete(ae_treatments_to_delete, false);

    }


    private static String temporaryNameId(AeronaServiceOASApi.OASAPITreatment treatment) {
        if (String.isEmpty(treatment.treatmentPlanDescription)) treatment.treatmentPlanDescription = '---';
        return (treatment.patientId + ':ATP:' + treatment.treatmentPlanDescription).trim();
    }

    private static String temporaryNameId(Aerona_Treatment__c treatment) {
        if (String.isEmpty(treatment.Plan_Name__c)) treatment.Plan_Name__c = '---';
        return (treatment.Patient_Id__c + ':ATP:' + treatment.Plan_Name__c).trim();
    }

    public static Aerona_Treatment__c toAeronaTreatment(Set <String> existingTreatmentIds, AeronaServiceOASApi.OASAPITreatment treatment) {
        Aerona_Treatment__c ret = new Aerona_Treatment__c();

        //set created name only for new Treatments
        if (!existingTreatmentIds.contains('' + treatment.treatmentId)) ret.CreatedDate = treatment.dateCreated;

        ret.External_Id__c = '' + treatment.treatmentId;
        ret.Patient_Id__c = '' + treatment.patientId;
        ret.Appointment_Time__c = treatment.appointmentTime;
        ret.Status__c = mapToStatusPicklist(treatment.statusId);
        ret.Date_Completed__c = treatment.dateCompleted;
        ret.Plan_Name__c = treatment.treatmentPlanDescription;
        ret.Plan_Id__c = String.valueOf(treatment.treatmentPlanId);
        ret.Deleted_Ind__c = treatment.deleteInd;
        ret.Sale_Item_Text__c = treatment.saleItemText;
        ret.Outstanding_Insurance_Amount__c = util_zeroOrDoubleValue (treatment.outstandingInsuranceAmount) ;
        ret.Amount_Paid__c = util_zeroOrDoubleValue(treatment.amountPaid);
        ret.Amount_Refunded__c = util_zeroOrDoubleValue(treatment.amountRefunded);
        ret.Quantity__c = util_zeroOrDoubleValue(treatment.quantity);
        ret.Unit_Price__c = util_zeroOrDoubleValue(treatment.unitNetPrice);
        ret.Total_Net_Price__c = util_zeroOrDoubleValue(treatment.totalNetPrice);
        ret.Total_Discount__c = util_zeroOrDoubleValue(treatment.totalDiscount);
        ret.Total_Price__c = util_zeroOrDoubleValue(treatment.totalPrice);
        ret.Vat_Rate__c = treatment.vatRate;


        return ret;
    }

    @AuraEnabled(Cacheable=true)
    public static String aura_getDentalTreatmentPlansForOpportunity(String oppId) {

        String accountId = [SELECT Id, AccountId FROM Opportunity WHERE Id = :oppId].AccountId;
        return JSON.serialize(getDentalTreatmentPlansForAccountId(accountId));
    }

    @AuraEnabled(Cacheable=true)
    public static String aura_getDentalTreatmentPlansForAccount(String accountId) {
        return JSON.serialize(getDentalTreatmentPlansForAccountId(accountId));
    }

    private static List<Opportunity> getDentalTreatmentPlansForAccountId(String accountId) {
        return [
                SELECT
                        (SELECT Id, Total_Net_Price__c, Amount_Paid__c, Status__c, Sale_Item_Text__c FROM Aerona_Treatments__r),
                        Id,
                        CreatedDate,
                        Name,
                        Business_Unit__c,
                        Probability,
                        Amount,
                        Outstanding_Amount__c,
                        Retained_Charges__c,
                        StageName,
                        Parent_Opportunity__c
                FROM Opportunity
                WHERE AccountId = :accountId AND Mode__c = 'Dental Treatment Plan'
                AND (NOT Name LIKE '%---%')
                ORDER BY CreatedDate DESC
        ];
    }

    @AuraEnabled(Cacheable=false)
    public static void aura_updateBusinessUnit(String oppId, String businessUnit) {
        Opportunity opp = new Opportunity(Id = oppId, Business_Unit__c = businessUnit);
        Database.update (opp, false);
    }

    @AuraEnabled(Cacheable=false)
    public static void aura_updateProbability(String oppId, Integer probability) {
        Opportunity opp = new Opportunity(Id = oppId, Probability = probability);
        Database.update (opp, false);
    }

    @AuraEnabled(Cacheable=false)
    public static void aura_updatePaymentMethod(String oppId, String paymentMethod) {
        Opportunity opp = new Opportunity(Id = oppId, DT_Payment_Method__c = paymentMethod);
        Database.update (opp, false);
    }

    @AuraEnabled(Cacheable=false)
    public static void aura_updateParent(String oppId, String parentOppId, String businessUnit, Integer probability, String paymentMethod) {
        Opportunity opp = new Opportunity(Id = oppId, Business_Unit__c = businessUnit, Probability = probability, DT_Payment_Method__c = paymentMethod);
        opp.Parent_Opportunity__c = parentOppId;
        update opp;
    }

    private static Map<String, String> getClinicianNames() {
        List<ServiceTerritoryMember> stms = [SELECT Id, ServiceResource.Name, Aerona_Clinician_Id__c FROM ServiceTerritoryMember WHERE Aerona_Clinician_Id__c != NULL];

        Map<String, String> ret = new Map<String, String>();
        for (ServiceTerritoryMember serviceTerritoryMember : stms) {
            ret.put(serviceTerritoryMember.Aerona_Clinician_Id__c, serviceTerritoryMember.ServiceResource.Name);
        }

        return ret;
    }

    private static Double util_zeroOrDoubleValue(String value) {
        if (String.isEmpty(value)) return 0;
        return Double.valueOf(value);
    }

    private static String mapToStatusPicklist(String statusId) {

        switch on statusId {
            when '1' {
                return 'Complete';
            }
            when '2' {
                return 'Planned';
            }
            when '3' {
                return 'Option';
            }
            when '4' {
                return 'Historic';
            }
            when '6' {
                return 'Sent for Approval';
            }
            when '7' {
                return 'Declined';
            }
            when else {
                return statusId;
            }
        }
    }


}