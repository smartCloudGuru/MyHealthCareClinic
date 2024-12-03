@isTest
private class AeronaStdBtnCallout_Test{ 
    Static testMethod void unitTest(){
     Test.StartTest();
      AeronaStdBtnCallout.getAeronaSites();
      AeronaStdBtnCallout.getPatientSearch(); 
      AeronaStdBtnCallout.getAeronaAppointment(); 
     Test.StopTest();
    }
   }