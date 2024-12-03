@isTest
 private class Confirmation_ctrl_Test{
   private static testMethod void testMethod1(){
      Proposed_Appointment__c objPap = new Proposed_Appointment__c();
           objPap.MeddBase_key__c = 'konno';
           objPap.Payer_Type__c= 'Rajwara';
           insert objPap;
           Apexpages.currentpage().getparameters().put('paId',objPap.Id);
     Confirmation_ctrl objCnf = new Confirmation_ctrl();
      System.assertNotEquals(objCnf.bookedAppointment,null);
 }
}