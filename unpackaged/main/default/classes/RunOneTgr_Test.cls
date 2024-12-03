@isTest
    Public Class RunOneTgr_Test{
    Public static boolean run = true;
    @isTest
      public static void RunOnceFlag() {
      Test.StartTest();
         RunOnceTgr.runOnce();
     Test.StopTest();
    }
}