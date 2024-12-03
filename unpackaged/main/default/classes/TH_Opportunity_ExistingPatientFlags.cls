/**
 * Created by Matija on 18.9.2023..
 */
/**
 * On after insert/update of a closed won opportunity, check if Patient flags (Patient type, existing GP, Existing Dental) need to be updated
 */

public without sharing class TH_Opportunity_ExistingPatientFlags extends AnthologyTriggerHandler.DelegateBase {

    public static final Map<String, String> map_bu_service = new Map<String, String>{
            'Dentist' => 'Dental',
            'Dermatology (GP)' => 'Medical',
            'Diagnostics' => 'Medical',
            'Did not obtain' => 'Other',
            'Fertility' => 'Medical',
            'GP' => 'Medical',
            'Healthchecks' => 'Medical',
            'Hygiene' => 'Dental',
            'Implants' => 'Dental',
            'Medical Consultants' => 'Medical',
            'Membership' => 'Membership',
            'Minor Surgery' => 'Medical',
            'Orthodontics' => 'Dental',
            'Other' => 'Other',
            'Pathology & Vaccines' => 'Medical',
            'Sexual Health' => 'Medical',
            'Therapists' => 'Medical',
            'Weight Loss' => 'Medical'
    };

    private Map<Id, Account> map_accounts = new Map<Id, Account>();
    private Map<Id, Account> map_accountsToUpdate = new Map<Id, Account>();
    private Set<Id> oppsToProcessIds = new Set<Id>();

    public TH_Opportunity_ExistingPatientFlags(AnthologyTriggerHandler.AnthologyTriggerContext anthTriggerContext) {
        this.anthTriggerContext = anthTriggerContext;
        name = 'TH_Opportunity_ExistingPatientFlags';
    }

    // build maps to use while calculating and to update on finish
    public override void prepareAfter() {

        map_accounts = new Map<Id, Account>();
        map_accountsToUpdate = new Map<Id, Account>();

        //put accounts to map
        Set<Id> accountIds = new Set<Id>();
        List<Opportunity> newOppsOrig = anthTriggerContext.newList;

        //consider only recent closed won opps with business units
        if (newOppsOrig==null) {
            System.debug('::TH_OPP_EPF: no opps to process');
            return; // LEAVE
        }

        List<Opportunity> newOpps = new List<Opportunity>();


        //consider only recent closed won opps with business units
        for (Opportunity op : newOppsOrig) {
            if (String.isNotBlank(op.Business_Unit__c) && op.AccountId != null && op.StageName == 'Closed Won') {
                newOpps.add(op);
                accountIds.add(op.AccountId);
                oppsToProcessIds.add(op.Id);
            }
        }

        if (newOpps.isEmpty()) return; // LEAVE IF NO CLOSED OPS WITH BU

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
            if (account != null && account.Id != null) map_accounts.put(account.Id, account);
        }

        System.debug('::TH_OPP_EPF: map size at end of prepareAfter: ' + map_accounts.size());
    }
    public override void afterInsert(SObject o) {
        calculateExistingPatientFlags(o);
    }
    public override void afterUpdate(SObject old, SObject o) {
        calculateExistingPatientFlags(o);
    }

    @TestVisible
    private void calculateExistingPatientFlags(SObject o) {
        Opportunity op = (Opportunity) o;

        if (!oppsToProcessIds.contains(op.Id)) return;

        Account acc = map_accounts.get(op.AccountId);
        Integer accNeedsUpdating = 0;
        if (acc != null) {
            if (map_bu_service.get(op.Business_Unit__c) == 'Dental') {
                if (acc.Existing_Dental_Patient__c == false) accNeedsUpdating = 1;
                acc.Existing_Dental_Patient__c = true;
            }
            else if (map_bu_service.get(op.Business_Unit__c) == 'Medical') {
                if (acc.Existing_GP_Patient__c == false) accNeedsUpdating += 10;
                acc.Existing_GP_Patient__c = true;
            }

            if (acc.Patient_Type__c == 'New' && (acc.Existing_Dental_Patient__c || acc.Existing_GP_Patient__c)) {
                accNeedsUpdating += 100;
                acc.Patient_Type__c = 'Registered';
            }

            if (accNeedsUpdating > 0) {
                System.debug('::TH_OPP_EPF:acc needs updating due to ' + accNeedsUpdating + ': ' + acc.Id);
                map_accountsToUpdate.put(acc.Id, acc);
            }
        }
    }

    //update accounts
    public override void finish() {
        if (!map_accountsToUpdate.isEmpty()) {
            Database.update(map_accountsToUpdate.values(), false);
        }
    }


}