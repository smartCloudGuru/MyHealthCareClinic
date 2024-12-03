@isTest
private class AeronaFindSlots_schTest {
    static testMethod void unitTest() {
        Test.StartTest();
      try{
        AeronaFindSlots_sch  testsche = new AeronaFindSlots_sch();
        String sch = '0 0 23 * * ?';
        system.schedule('Sync Aerona Slots', sch, testsche);
      }catch(Exception e){}
    Test.stopTest();
    }
}