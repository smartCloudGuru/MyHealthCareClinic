/**
 * Created 17.2.2023..
 */

@IsTest
private class AeronaCarePlanSyncTest {
    @IsTest
    static void syncAllPlanIds_test() {
        AeronaServiceMock.setAsMock();

        Test.startTest();
        AeronaCarePlanSync.syncAllPlanIds();
        Test.stopTest();
    }
}