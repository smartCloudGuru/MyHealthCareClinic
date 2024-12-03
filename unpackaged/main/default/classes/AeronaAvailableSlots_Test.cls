@isTest
Private class AeronaAvailableSlots_Test{
    static testMethod void AeronaAvailableSlotsTest(){ 
        AeronaAvailableSlots aas = new AeronaAvailableSlots();
        aas.errorResult='ddd';
        aas.errorCode=123;
        aas.status='new'; 
        list<AeronaAvailableSlots.result> lst = new list<AeronaAvailableSlots.result>(); 
        AeronaAvailableSlots.result aasr = new AeronaAvailableSlots.result();
        aasr.slotStartTime=12;
        aasr.clinicianName='Dr';
        aasr.clinicianId=123; 
        aas.result = lst;   
    }     
}