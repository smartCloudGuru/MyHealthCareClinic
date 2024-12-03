@isTest
private class SyncOneWeekApptsByInteUser_schTest {
    static testMethod void unitTest() {
        Test.StartTest();
             SyncOneWeekApptsByInteUser_sch objSync = new SyncOneWeekApptsByInteUser_sch();  
             String sch = '0 0 23 * * ?';
             system.schedule('Test Weekly Synch', sch, objSync);
        Test.StopTest();
    }
}