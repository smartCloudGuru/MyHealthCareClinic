/**
* @author Zoran Zunko
* @date 4/13/21
*
*/

/**
 * NOTE: this was changed, it actually runs if a Send Results is needed, and the Queueable_COVID_Test_Certificate
 * then decides if the certificate is to be attached
 */
public with sharing class TH_CovidTest_GenerateCertificate extends AnthologyTriggerHandler.DelegateBase {

    @TestVisible Set<Id> covidTestIds = new Set<Id>();

    public TH_CovidTest_GenerateCertificate(AnthologyTriggerHandler.AnthologyTriggerContext anthTriggerContext) {
        this.anthTriggerContext = anthTriggerContext;
        name = 'TH_CovidTest_GenerateCertificate';
        skipLoop = false;
    }

    public override void beforeInsert(SObject o) {

        COVID_Test__c covidTest = (COVID_Test__c) (o);
        //we need to clone the object because calculate formula will not work on the object we intend to modify
        COVID_Test__c clone = covidTest.clone();
        Formula.recalculateFormulas(new List<COVID_Test__c>{clone});
        if (String.isNotBlank(covidTest.Test_URN__c) || covidTest.Is_Home_Kit_Test__c || covidTest.Excluded_from_Randox__c) {
            if (clone.Generates_Results_Email__c) {
                covidTestIds.add(covidTest.Id);
            }
        }
    }

    public override void beforeUpdate(SObject old, SObject o) {
        COVID_Test__c covidTest = (COVID_Test__c) (o);
        COVID_Test__c covidTestOld = (COVID_Test__c) (old);
        //we need to clone the object because calculate formula will not work on the object we intend to modify
        COVID_Test__c clone = covidTest.clone();
        Formula.recalculateFormulas(new List<COVID_Test__c>{clone});
        if (String.isNotBlank(covidTest.Test_URN__c) || covidTest.Is_Home_Kit_Test__c || covidTest.Excluded_from_Randox__c) {
            if (clone.Generates_Results_Email__c) {
                if (!covidTest.Test_Certificate_Generated__c
                        || (covidTestOld.COVID_Test_Status__c != covidTest.COVID_Test_Status__c)
                        || (covidTestOld.Certificate_Custom_Text__c != covidTest.Certificate_Custom_Text__c)) {
                    covidTestIds.add(covidTest.Id);
                }
            }
        }
    }

    public override void finish() {
        if (!covidTestIds.isEmpty()) {
            Queueable_COVID_Test_Certificate.queueJob(covidTestIds);
        }
    }


}