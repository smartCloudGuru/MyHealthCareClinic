/**
 * Created by Matija on 18.9.2023..
 */

public with sharing class TH_Opportunity_UpsertPatientBusinessUnit extends AnthologyTriggerHandler.DelegateBase {

    private Map<Id, Account> map_accounts = new Map<Id, Account>();
    private List<Patient_Business_Unit__c> pbusToUpsert = new List<Patient_Business_Unit__c>();
    private Set<Id> existingPatients = new Set<Id>();
    private Map<String, Patient_Business_Unit__c> map_composite_existingPatientsBu = new Map<String, Patient_Business_Unit__c>();
    private Set<Id> usedNewPatients = new Set<Id>();
    private List<Opportunity> oppsToProcess = new List<Opportunity>();
    private Set<Id> oppsToProcessIds = new Set<Id>();

    public TH_Opportunity_UpsertPatientBusinessUnit(AnthologyTriggerHandler.AnthologyTriggerContext anthTriggerContext) {
        this.anthTriggerContext = anthTriggerContext;
        name = 'TH_Opportunity_UpsertPatientBusinessUnit';
    }

    // build maps to use while calculating and to update on finish
    public override void prepareBefore() {

        map_accounts = new Map<Id, Account>();
        pbusToUpsert = new List<Patient_Business_Unit__c>();
        oppsToProcess = new List<Opportunity>();

        //put accounts to map
        Set<Id> accountIds = new Set<Id>();

        List<Opportunity> newOppsOrig = anthTriggerContext.newList;

        //consider only recent closed won opps with business units
        if (newOppsOrig==null) {
            System.debug('::TH_OPP_PBU: no opps to process');
            return; // LEAVE IF NO CLOSED OPS WITH BU
        }
        for (Opportunity op : newOppsOrig) {
            if (op!=null && String.isNotBlank(op.Business_Unit__c)
                    && op.AccountId != null
                    && op.StageName == 'Closed Won'
                    //&& op.CloseDate >= Date.today().addDays(-1)
            ){
                oppsToProcess.add(op);
                oppsToProcessIds.add(op.Id);
                accountIds.add(op.AccountId);
            }
        }

        if (oppsToProcess.isEmpty()) {
            System.debug('::TH_OPP_PBU: no opps to process');
            return; // LEAVE IF NO CLOSED OPS WITH BU
        }

        // TODO refactor later to WORK TYPE lookups
        //we have closed opportunities to process

        List<Patient_Business_Unit__c> pbus = [
                SELECT
                        Id,
                        Account__c,
                        Composite_Key__c,
                        Business_Unit__c,
                        First_Opportunity__c,
                        First_Opportunity__r.CreatedDate,
                        First_Opportunity__r.CloseDate,
                        Latest_Opportunity__c,
                        Latest_Opportunity__r.CreatedDate,
                        Latest_Opportunity__r.CloseDate,
                        Won__c
                FROM Patient_Business_Unit__c
                WHERE Account__c IN :accountIds
                FOR UPDATE
        ];

        // find accounts that are not new patients
        existingPatients = new Set<Id>();
        map_composite_existingPatientsBu = new Map<String, Patient_Business_Unit__c>();
        usedNewPatients = new Set<Id>();

        for (Patient_Business_Unit__c patientBusinessUnit : pbus) {
            if (patientBusinessUnit.Won__c) {
                existingPatients.add(patientBusinessUnit.Account__c);
            }
            map_composite_existingPatientsBu.put(patientBusinessUnit.Composite_Key__c, patientBusinessUnit);
        }

        System.debug('::TH_OPP_PUB: accounts size at end of prepareAfter: ' + accountIds.size());
        System.debug('::TH_OPP_PUB: map_composite_existingPatientsBu size at end of prepareAfter: ' + map_composite_existingPatientsBu.size());

    }

    public override void beforeUpdate(SObject old, SObject o) {
        calculatePBU(o);
    }

    @TestVisible
    private void calculatePBU(SObject o) {
        Opportunity op = (Opportunity) o;

        if (oppsToProcessIds.contains(op.Id)) {

            String compositeKey = op.AccountId + '@' + op.Business_Unit__c;

            Boolean newPatientFlag = !existingPatients.contains(op.AccountId) && !usedNewPatients.contains(op.AccountId);
            if (newPatientFlag) {
                System.debug('::TH_OPP_PUB:new patient flag for ' + compositeKey);
                usedNewPatients.add(op.AccountId);
            }

            Patient_Business_Unit__c pbu = map_composite_existingPatientsBu.get(compositeKey);
            if (pbu == null) {
                pbu = new Patient_Business_Unit__c(
                        Account__c = op.AccountId,
                        Business_Unit__c = op.Business_Unit__c,
                        New_Patient__c = newPatientFlag,
                        First_Opportunity__c = op.Id,
                        Latest_Opportunity__c = op.Id);
            }

            if (pbu.Latest_Opportunity__c == null || (pbu.Latest_Opportunity__c != null && pbu.Latest_Opportunity__r.CreatedDate != null && pbu.Latest_Opportunity__r.CreatedDate < op.CreatedDate)) pbu.Latest_Opportunity__c = op.Id;
            if (pbu.First_Opportunity__c == null || (pbu.First_Opportunity__c != null && pbu.First_Opportunity__r.CreatedDate != null && pbu.First_Opportunity__r.CreatedDate > op.CreatedDate)) pbu.First_Opportunity__c = op.Id;

            if (newPatientFlag) pbu.New_Patient__c = true;

            pbu.Composite_Key__c = compositeKey;
            map_composite_existingPatientsBu.put(pbu.Composite_Key__c, pbu);

            pbusToUpsert.add(pbu);

            //save any existing ones on the opportunity lookup
            if (pbu.Id != null) op.Patient_Business_Unit__c = pbu.Id;
        }
    }

    public override void finish() {
        if (!pbusToUpsert.isEmpty()) {
            Map<String, Patient_Business_Unit__c> uniquePbus = new Map<String, Patient_Business_Unit__c>();
            for (Patient_Business_Unit__c patientBusinessUnit : pbusToUpsert) {
                uniquePbus.put(patientBusinessUnit.Composite_Key__c, patientBusinessUnit);
            }
            Database.upsert(uniquePbus.values(), Patient_Business_Unit__c.Composite_Key__c, false);

            //any new ones should also get on the opportunity lookup
            Map<String, Id> map_compositeKey_Id = new Map<String, Id>();
            for (Patient_Business_Unit__c patientBusinessUnit : uniquePbus.values()) {
                map_compositeKey_Id.put(patientBusinessUnit.Composite_Key__c, patientBusinessUnit.Id);
            }
            for (Opportunity opportunity : oppsToProcess) {
                if (opportunity.Patient_Business_Unit__c==null) opportunity.Patient_Business_Unit__c = map_compositeKey_Id.get(opportunity.AccountId + '@' + opportunity.Business_Unit__c);
            }
        }

    }
}