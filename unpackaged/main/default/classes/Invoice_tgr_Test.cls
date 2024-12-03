/*****************************
Code coverage for below triggers:
Invoice_tgr 94%
Invoice_tgr_SendEmail 100%  
*****************************/
@isTest()
private class Invoice_tgr_Test{
 public static testMethod void testIvn(){  
    Proposed_Appointment__c Pap = new Proposed_Appointment__c();
      Pap.MeddBase_key__c= '12341';
      insert Pap;   
    Invoice__c Inv = new Invoice__c();
      string Mde = 'a120E0000007UDjQAM-1eefcde7d689d617f6530c9d552a67c6';
      Inv.Meddbase_Key__c= Pap.id;//.split('-')[0];
      insert Inv;
      Inv.Paid__c = true;
      update Inv;
      set<string> pIds = new set<string>();
      pIds.add(Inv.Meddbase_Key__c.split('-')[0]);
  }
}