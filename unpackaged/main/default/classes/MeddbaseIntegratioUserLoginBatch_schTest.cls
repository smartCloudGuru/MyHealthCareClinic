@isTest
private class MeddbaseIntegratioUserLoginBatch_schTest {
    static testMethod void unitTest() {
        Test.StartTest();
      try{
        MeddbaseIntegrationUserLoginBatch_sch  testsche = new MeddbaseIntegrationUserLoginBatch_sch();
        String sch = '0 0 23 * * ?';
        system.schedule('Login Integration User', sch, testsche);
      }catch(Exception e){}
    Test.stopTest();
    }
}