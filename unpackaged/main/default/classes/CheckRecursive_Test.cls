@isTest
private class CheckRecursive_Test{  
    public static testMethod void testRec(){
        Test.startTest();
        CheckRecursive.onTgr();
        system.assert(CheckRecursive.run);
        CheckRecursive.offTgr();
        system.assert(CheckRecursive.run == false);
        Test.stopTest();
    }
}