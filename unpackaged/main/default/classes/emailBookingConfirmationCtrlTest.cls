/**
 * Created 31.5.2023..
 */

@IsTest
private class emailBookingConfirmationCtrlTest {

    @TestSetup
    static void dataSetup() {
        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);

        OperatingHours oh = new OperatingHours();
        oh.Name = 'OH Name';
        insert oh;

        ServiceTerritory serviceTerritory = new ServiceTerritory();
        serviceTerritory.OperatingHoursId = oh.Id;
        serviceTerritory.Name = 'test';
        serviceTerritory.IsActive = true;
        insert serviceTerritory;

        ServiceAppointment sa = new ServiceAppointment();
        sa.ParentRecordId = accounts[0].Id;
        sa.SchedEndTime = Datetime.now();
        sa.ServiceTerritoryId = serviceTerritory.Id;

        insert sa;
    }

    @IsTest static void testPageLoad() {

        ServiceAppointment app = [SELECT Id FROM ServiceAppointment LIMIT 1];
        emailBookingConfirmationCtrl ctrl = new emailBookingConfirmationCtrl();
        ctrl.recId = app.Id;

    }
}