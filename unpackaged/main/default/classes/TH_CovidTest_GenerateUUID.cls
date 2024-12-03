/**
* @author Zoran Zunko
* @date 4/19/21
*
*/
public with sharing class TH_CovidTest_GenerateUUID extends AnthologyTriggerHandler.DelegateBase {

    public TH_CovidTest_GenerateUUID(AnthologyTriggerHandler.AnthologyTriggerContext anthTriggerContext) {
        this.anthTriggerContext = anthTriggerContext;
        name = 'TH_CovidTest_GenerateUUID';
        skipLoop = false;
    }

    public override void beforeInsert(SObject o) {
        COVID_Test__c covidTest = (COVID_Test__c) o;
        Uuid newUuid = new Uuid();
        covidTest.UUID__c = newUuid.getValue();
    }

    public override void beforeUpdate(SObject old, SObject o) {
        COVID_Test__c covidTest = (COVID_Test__c) (o);
        if(covidTest.UUID__c == null) {
            Uuid newUuid = new Uuid();
            covidTest.UUID__c = newUuid.getValue();
        }

    }
}