@isTest
private class AeronaPatient_Test{
    Static testMethod void unitTest(){
     list<AeronaPatient.result> wrapperList = new list<AeronaPatient.result>();
        AeronaPatient ae = new AeronaPatient();
        ae.errorResult = 'aaa';
        ae.errorCode = 122;
        ae.status = 'aass';
        ae.result = wrapperList;
        //List<result> li = conConsole.result();
        //insert ae;
        AeronaPatient.result Ar = new AeronaPatient.result();
        Ar.dob = 123;
        Ar.patientFullAddress = 'aaaaaaa'; 
        Ar.patientFullName = 'aaaaaaa';
        Ar.patientId = 12;
        //insert Ar;
    } 
}