@isTest
private class SyncAppontmntsByIntegrationUser_schTest{
    static testMethod void unitTest() {
        Test.StartTest();
      try{
        SyncAppointmentsByIntegrationUser_sch  testsche = new SyncAppointmentsByIntegrationUser_sch();
        String sch = '0 0 23 * * ?';
        system.schedule('Sync Appointment by Integration user', sch, testsche);
      }catch(Exception e){}
    Test.stopTest();
    }
}