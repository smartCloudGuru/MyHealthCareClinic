/**
 * Created 21.1.2023..
 */

@IsTest
public class LeadConvertCtrlTest {

    @TestSetup
    static void setUp() {

        Lead l = new Lead();
        l.FirstName = 'First';
        l.LastName = 'Last';
        insert l;
    }

    @IsTest
    static void testGetClinicValues()
    {
        System.assert(LeadConvertCtrl.getClinicValues()!=null);
    }

    @IsTest
    static void testGetPotentialDuplicates()
    {
        String leadId  = [SELECT Id FROM Lead LIMIT 1].Id;
        System.debug(LeadConvertCtrl.getPotentialDuplicates(leadId));
    }

    @IsTest
    static void testDoConvert()
    {
        String fromId = [SELECT Id FROM Lead LIMIT 1].Id;
        String toId = null;
        String clinicName = Lead.Clinic_Booked__c.getDescribe().getPicklistValues().get(0).value;
        System.assert(LeadConvertCtrl.doConvert(fromId, toId, clinicName)!=null);
    }

    @IsTest
    static void testDoConvert2()
    {
        String fromId = [SELECT Id FROM Lead LIMIT 1].Id;
        String toId = null;
        String clinicName = Lead.Clinic_Booked__c.getDescribe().getPicklistValues().get(0).value;
        System.assert(LeadConvertCtrl.doConvertAndReturnLeadConvertResult(fromId, toId, clinicName)!=null);
    }

    @IsTest
    static void testNewAuraHandledException()
    {
        System.debug(LeadConvertCtrl.newAuraHandledException('msg'));
    }
}