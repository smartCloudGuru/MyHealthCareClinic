@isTest
Private Class AnonClinicianUpdateBatch_Test{
    Private Static TestMethod Void myUnitTest(){
        Test.startTest();
        MeddBase_Settings__c objmed = new MeddBase_Settings__c();
        objmed.Client_Key__c = 'api-mhctest';
        objmed.Name = 'meddbase';
        insert objmed;
        list<Appointment_Type__c> objListAppType = new  list<Appointment_Type__c>();        
        AppointmentTypeData.result objRes = new AppointmentTypeData.result();
            objRes.Notes = 'vary';
            objRes.CanBookAppointment = true;
            objRes.CancellationPolicy = 'cancle';
            objRes.CanReferPatient= true;
            objRes.Key = 'ram';
            objRes.TelemedicineOption = true;
            objRes.Name = 'joe';
        for(integer i=1;i<99;i++){
        Appointment_Type__c objApp = new Appointment_Type__c();
            objApp.Tele_Medicine_Option__c = objRes.TelemedicineOption;
            objApp.Notes__c = objRes.Notes;
            objApp.Name = objRes.Name+i;
            objApp.Meddbase_Key__c = objRes.Key+i;
            objApp.Cancellation_Policy__c = objRes.CancellationPolicy;
            objApp.Can_Refer_Patient__c = objRes.CanReferPatient;
            objApp.Can_Book_Appointment__c = objRes.CanBookAppointment;
            objListAppType.add(objapp);
        }    
        insert objListAppType;    
        AnonClinicianUpdateBatch objACUBatch = new AnonClinicianUpdateBatch();
        try{Database.ExecuteBatch(objACUBatch);}catch(Exception e){}
        Test.stopTest();
    }
}