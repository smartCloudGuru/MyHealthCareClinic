/**
 * @author Zoran Zunko
 *
 * @date 5/14/21
 */
@IsTest
public class eml_CancelEmailCtrlTest {
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
        eml_CancelEmailCtrl ctrl = new eml_CancelEmailCtrl();
        ctrl.recId = app.Id;
        System.assert(ctrl.patientName!=null);
        System.assert(ctrl.dateAndTime!=null);
        System.assert(ctrl.location!=null);

    }


}