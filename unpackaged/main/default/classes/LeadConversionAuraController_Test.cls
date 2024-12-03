/**
 * Created by usman on 1/21/2020.
 */
@IsTest
Private class LeadConversionAuraController_Test {
    Private Static TestMethod Void myUnitTest() {
        Lead objLead = new Lead();
        objLead.LastName = 'lname';
        objLead.FirstName= 'fname';
        objLead.Email= 'reg_email@test.com';
        objLead.Date_of_birth__c = System.Today();
        objLead.Address1__c= 'add1';
        objLead.Address2__c= 'add2';
        objLead.Address3__c= 'add3';
        objLead.City= 'city';
        objLead.Country= 'country';
        objLead.PostalCode= 'postcode';
        objLead.MobilePhone= '+918887766522';
        insert objLead;
        String accId = LeadConversionAuraController.convertSelectedLead(objLead.Id+'','Fulham');
        System.assert(accId != null);
    }
}