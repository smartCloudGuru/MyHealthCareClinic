/**
 * Created 28.3.2022..
 */

@IsTest
private class ExternalSyncAppsForPatientTest {
    @IsTest
    static void testBehavior() {

        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);

        OperatingHours oh = new OperatingHours();
        oh.Name = 'test Opening Hours';
        insert oh;

        ServiceTerritory st = new ServiceTerritory();
        st.Name = 'unit test location';
        st.Heydoc_Id__c = 'test_st_hd_id';
        st.IsActive = true;
        st.OperatingHoursId = oh.Id;
        insert st;

        ServiceAppointment sa = new ServiceAppointment();
        sa.ParentRecordId = accounts[0].Id;
        sa.Heydoc_Appointment_Id__c = null;
        sa.ServiceTerritoryId = st.Id;

        insert sa;

        Test.startTest();
        ExternalSyncAppsForPatient esap = new ExternalSyncAppsForPatient(accounts);
        esap.execute(null);
        Test.stopTest();

    }

    @IsTest
    static void testBehavior2() {

        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);

        OperatingHours oh = new OperatingHours();
        oh.Name = 'test Opening Hours';
        insert oh;

        ServiceTerritory st = new ServiceTerritory();
        st.Name = 'unit test location';
        st.Heydoc_Id__c = 'test_st_hd_id';
        st.IsActive = true;
        st.OperatingHoursId = oh.Id;
        insert st;

        ServiceAppointment sa = new ServiceAppointment();
        sa.ParentRecordId = accounts[0].Id;
        sa.Heydoc_Appointment_Id__c = null;
        sa.ServiceTerritoryId = st.Id;

        insert sa;

        Set<String> accIds = new Set<String>();
        accIds.add(accounts[0].Id);

        Test.startTest();
        ExternalSyncAppsForPatient esap = new ExternalSyncAppsForPatient(accIds);
        esap.execute(null);
        Test.stopTest();

    }
}