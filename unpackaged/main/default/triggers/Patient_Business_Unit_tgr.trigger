/**
 * Created by Matija on 12.9.2023..
 */

trigger Patient_Business_Unit_tgr on Patient_Business_Unit__c (before insert, before update) {

    for (Patient_Business_Unit__c fa : Trigger.new) {
        fa.Composite_Key__c = fa.Account__c + '@' + fa.Business_Unit__c;
    }
}