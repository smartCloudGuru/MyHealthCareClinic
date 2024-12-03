/**
 * Created 29.3.2022..
 */

@IsTest
private class ExternalSyncAppointmentsTest {

    @TestSetup
    static void dataSetup() {

        List<Asset> assets = new List<Asset>();
        assets.add(new Asset(Name = 'A1'));
        assets.add(new Asset(Name = 'A2'));
        insert assets;

        Asset asset2 = new Asset(Name = 'A2');
        insert asset2;

        List<WorkTypeGroup> wtgsToInsert = new List<WorkTypeGroup>();
        for (Integer i = 1; i <= 4; i++) {
            wtgsToInsert.add(new WorkTypeGroup(
                    Name = 'WTG' + i,
                    Heydoc_Id__c = 'mock_hd_wtg_id_' + i,
                    Service_Type__c = 'Medical'));
        }

        for (Integer i = 1; i <= 4; i++) {
            wtgsToInsert.add(new WorkTypeGroup(
                    Name = 'WTG_D' + i,
                    Aerona_Id__c = '9000' + i,
                    Service_Type__c = 'Dental'));
        }

        insert wtgsToInsert;

        //create WTGMembers for WTGS
        List<WorkType> workTypes = new List<WorkType>();
        for (WorkTypeGroup wtg : wtgsToInsert) {
            workTypes.add(new WorkType(
                    Name = 'T' + wtg.Name,
                    EstimatedDuration = 10
            ));
        }
        insert workTypes;

        List<WorkTypeGroupMember> wtgms = new List<WorkTypeGroupMember>();
        for (Integer i = 0; i < wtgsToInsert.size(); i++) {
            wtgms.add(new WorkTypeGroupMember(WorkTypeGroupId = wtgsToInsert[i].Id, WorkTypeId = workTypes[i].Id));
        }
        insert wtgms;

        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);

        accounts[0].HeyDoc_Id__c = 'mock_hd_pat_id';
        accounts[0].Aerona_Id__c = '1111';
        update accounts;

        OperatingHours oh = new OperatingHours();
        oh.Name = 'test Opening Hours';
        insert oh;

        ServiceTerritory stM = new ServiceTerritory();
        stM.Name = 'Medical location';
        stM.Heydoc_Id__c = 'mock_hd_territory_id';
        stM.IsActive = true;
        stM.OperatingHoursId = oh.Id;
        insert stM;

        ServiceTerritory stD = new ServiceTerritory();
        stD.Name = 'Dental location';
        stD.Aerona_Id__c = '2222';
        stD.IsActive = true;
        stD.OperatingHoursId = oh.Id;
        insert stD;

        ServiceResource srM = new ServiceResource();
        srM.Name = 'Medical SR1';
        srM.IsActive = true;
        srM.ResourceType = 'S';
        srM.AssetId = assets[0].Id;
        srM.Heydoc_Id__c = 'mock_hd_sr_id';
        insert srM;

        ServiceResource srD = new ServiceResource();
        srD.Name = 'Dental SR1';
        srD.IsActive = true;
        srD.ResourceType = 'S';
        srD.AssetId = assets[1].Id;
        insert srD;

        ServiceTerritoryMember stmToInsert = new ServiceTerritoryMember();
        stmToInsert.ServiceTerritoryId = stD.Id;
        stmToInsert.ServiceResourceId = srD.Id;
        stmToInsert.Aerona_Clinician_Id__c = '1555';
        stmToInsert.EffectiveStartDate = Date.today().addYears(-1);
        insert stmToInsert;

    }

    @IsTest
    static void test_deleteAppointmentsFuture_Heydoc() {
        HeyDocServiceMock.setAsMock();
        List<ExternalSyncAppointments.IdsByExternalSystemRequest> eIds = new List<ExternalSyncAppointments.IdsByExternalSystemRequest>();
        eIds.add(new ExternalSyncAppointments.IdsByExternalSystemRequest(ExternalSyncAppointments.HEYDOC, 'mock_hd'));

        Test.startTest();
        ExternalSyncAppointments.deleteAppointmentsFuture(JSON.serialize(eIds));
        Test.stopTest();
    }

    @IsTest
    static void test_deleteAppointmentsFuture_Aerona() {
        //TODO AERONA
        AeronaServiceMock.setAsMock();

        List<ExternalSyncAppointments.IdsByExternalSystemRequest> eIds = new List<ExternalSyncAppointments.IdsByExternalSystemRequest>();
        eIds.add(new ExternalSyncAppointments.IdsByExternalSystemRequest(ExternalSyncAppointments.AERONA, '12345'));

        Test.startTest();
        ExternalSyncAppointments.deleteAppointmentsFuture(JSON.serialize(eIds));
        Test.stopTest();
    }

    @IsTest
    static void test_syncAppointments_noNeedToSyncPatient_Heydoc() {

        Account acc = [SELECT Id FROM Account LIMIT 1];
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE Name LIKE 'Medical%' LIMIT 1];
        ServiceResource sr = [SELECT Id FROM ServiceResource WHERE Name LIKE 'Medical%' LIMIT 1];

        ServiceAppointment sa = new ServiceAppointment();
        sa.ParentRecordId = acc.Id;
        sa.Heydoc_Appointment_Id__c = null;
        sa.ServiceTerritoryId = st.Id;
        sa.WorkTypeId = [SELECT Id FROM WorkType WHERE Name = 'TWTG1'].Id;

        Opportunity opp = new Opportunity();
        opp.Name = 'test';
        opp.AccountId = acc.Id;
        opp.StageName = 'Closed Won';
        opp.CloseDate = Date.today();
        opp.Online_Mobile__c = 'throwaway';

        insert opp;

        sa.Treatment__c = opp.Id;

        insert sa;

        AssignedResource assignedResource = new AssignedResource();
        assignedResource.ServiceResourceId = sr.Id;
        assignedResource.IsRequiredResource = true;
        assignedResource.ServiceAppointmentId = sa.Id;
        insert assignedResource;

        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
        serviceAppointments.add(sa);
        HeyDocServiceMock.setAsMock();
        Test.startTest();
        ExternalSyncAppointments.syncAppointments(serviceAppointments);
        Test.stopTest();

        sa = [SELECT Id, Heydoc_Appointment_Id__c FROM ServiceAppointment WHERE Id = :sa.Id];
        System.assert(sa.Heydoc_Appointment_Id__c != null);

    }

    @IsTest
    static void test_syncAppointments_noNeedToSyncPatient_Aerona() {

        Account acc = [SELECT Id FROM Account LIMIT 1];
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE Name LIKE 'Dental%' LIMIT 1];
        ServiceResource sr = [SELECT Id FROM ServiceResource WHERE Name LIKE 'Dental%' LIMIT 1];
        Id workTypeId = [SELECT Id FROM WorkType WHERE Name = 'TWTG_D1'].Id;

        ServiceAppointment sa = new ServiceAppointment();
        sa.ParentRecordId = acc.Id;
        sa.Aerona_Id__c = null;
        sa.ServiceTerritoryId = st.Id;
        sa.WorkTypeId = workTypeId;
        sa.SchedStartTime = Datetime.now();
        sa.SchedEndTime = Datetime.now().addMinutes(30);

        Opportunity opp = new Opportunity();
        opp.Name = 'test';
        opp.AccountId = acc.Id;
        opp.StageName = 'Closed Won';
        opp.CloseDate = Date.today();
        opp.Online_Mobile__c = 'throwaway';

        insert opp;

        sa.Treatment__c = opp.Id;

        insert sa;

        AssignedResource assignedResource = new AssignedResource();
        assignedResource.ServiceResourceId = sr.Id;
        assignedResource.IsRequiredResource = true;
        assignedResource.ServiceAppointmentId = sa.Id;
        insert assignedResource;

        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
        serviceAppointments.add(sa);
        AeronaServiceMock.setAsMock();
        Test.startTest();
        ExternalSyncAppointments.syncAppointments(serviceAppointments);
        Test.stopTest();

        sa = [SELECT Id, Aerona_Id__c FROM ServiceAppointment WHERE Id = :sa.Id];
        System.assert(sa.Aerona_Id__c != null);

    }


    @IsTest
    static void test_UpdateAppointment_Aerona() {

        Account acc = [SELECT Id FROM Account LIMIT 1];
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE Name LIKE 'Dental%' LIMIT 1];
        ServiceResource sr = [SELECT Id FROM ServiceResource WHERE Name LIKE 'Dental%' LIMIT 1];
        Id workTypeId = [SELECT Id FROM WorkType WHERE Name = 'TWTG_D1'].Id;

        ServiceAppointment sa = new ServiceAppointment();
        sa.ParentRecordId = acc.Id;
        sa.Aerona_Id__c = '10101';
        sa.ServiceTerritoryId = st.Id;
        sa.WorkTypeId = workTypeId;
        sa.SchedStartTime = Datetime.now();
        sa.SchedEndTime = Datetime.now().addMinutes(30);

        Opportunity opp = new Opportunity();
        opp.Name = 'test';
        opp.AccountId = acc.Id;
        opp.StageName = 'Closed Won';
        opp.CloseDate = Date.today();
        opp.Online_Mobile__c = 'throwaway';

        insert opp;

        sa.Treatment__c = opp.Id;

        insert sa;

        AssignedResource assignedResource = new AssignedResource();
        assignedResource.ServiceResourceId = sr.Id;
        assignedResource.IsRequiredResource = true;
        assignedResource.ServiceAppointmentId = sa.Id;
        insert assignedResource;

        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
        serviceAppointments.add(sa);
        AeronaServiceMock.setAsMock();
        Test.startTest();
        ExternalSyncAppointments.syncAppointments(serviceAppointments);
        Test.stopTest();
    }

    @IsTest
    static void test_syncAppointments_whenAppCancelled_Heydoc() {

        Account acc = [SELECT Id FROM Account LIMIT 1];
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE Name LIKE 'Medical%' LIMIT 1];
        Id workTypeId = [SELECT Id FROM WorkType WHERE Name = 'TWTG1'].Id;

        ServiceAppointment sa = new ServiceAppointment();
        sa.ParentRecordId = acc.Id;
        sa.Heydoc_Appointment_Id__c = 'mock_hd_app_id';
        sa.ServiceTerritoryId = st.Id;
        sa.Status = 'Canceled';
        sa.WorkTypeId = workTypeId;

        Opportunity opp = new Opportunity();
        opp.Name = 'test';
        opp.AccountId = acc.Id;
        opp.StageName = 'Closed Won';
        opp.CloseDate = Date.today();
        opp.Online_Mobile__c = 'throwaway';

        insert opp;

        sa.Treatment__c = opp.Id;

        insert sa;

        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
        serviceAppointments.add(sa);
        HeyDocServiceMock.setAsMock();
        Test.startTest();
        ExternalSyncAppointments.syncAppointments(serviceAppointments);
        Test.stopTest();

    }

    @IsTest
    static void test_syncAppointments_whenAppCancelled_Aerona() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE Name LIKE 'Dental%' LIMIT 1];
        Id workTypeId = [SELECT Id FROM WorkType WHERE Name = 'TWTG_D1'].Id;

        ServiceAppointment sa = new ServiceAppointment();
        sa.ParentRecordId = acc.Id;
        sa.Aerona_Id__c = '123456';
        sa.ServiceTerritoryId = st.Id;
        sa.Status = 'Canceled';
        sa.WorkTypeId = workTypeId;

        Opportunity opp = new Opportunity();
        opp.Name = 'test';
        opp.AccountId = acc.Id;
        opp.StageName = 'Closed Won';
        opp.CloseDate = Date.today();
        opp.Online_Mobile__c = 'throwaway';

        insert opp;

        sa.Treatment__c = opp.Id;

        insert sa;



        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
        serviceAppointments.add(sa);
        AeronaServiceMock.setAsMock();
        Test.startTest();
        ExternalSyncAppointments.syncAppointments(serviceAppointments);
        Test.stopTest();
    }

    @IsTest
    static void test_validateSyncCanBeDone_Heydoc() {
        System.debug(':test_validateSyncCanBeDone_Heydoc:assert 1');
        System.assert(ExternalSyncAppointments.validateSyncCanBeDone_Heydoc(null) == false);

        Account acc = [SELECT Id FROM Account LIMIT 1];
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE Name LIKE 'Medical%' LIMIT 1];
        ServiceResource sr = [SELECT Id FROM ServiceResource WHERE Name LIKE 'Medical%' LIMIT 1];

        st.Heydoc_Id__c = null;

        update st;
        update sr;

        ServiceAppointment sa = new ServiceAppointment();
        sa.ParentRecordId = acc.Id;
        sa.Heydoc_Appointment_Id__c = null;
        sa.ServiceTerritoryId = st.Id;
        System.debug(':test_validateSyncCanBeDone_Heydoc:assert 2');
        System.assert(ExternalSyncAppointments.validateSyncCanBeDone_Heydoc(sa) == false);

        insert sa;

        sa = [
                SELECT
                        Id,
                        AccountId, (SELECT Id, ServiceResource.Heydoc_Id__c FROM ServiceResources),
                        ServiceTerritory.Heydoc_Id__c

                FROM ServiceAppointment
                WHERE Id = :sa.Id
        ];
        System.debug(':test_validateSyncCanBeDone_Heydoc:assert 3');
        System.assert(ExternalSyncAppointments.validateSyncCanBeDone_Heydoc(sa) == false);

        sr.Heydoc_Id__c = 'mock_hd_sr_id_12313';
        update sr;

        System.debug(':test_validateSyncCanBeDone_Heydoc:assert 4');
        System.assert(ExternalSyncAppointments.validateSyncCanBeDone_Heydoc(sa) == false);

        AssignedResource assignedResource = new AssignedResource();
        assignedResource.ServiceResourceId = sr.Id;
        assignedResource.IsRequiredResource = true;
        assignedResource.ServiceAppointmentId = sa.Id;
        insert assignedResource;

        sa = [
                SELECT
                        Id,
                        AccountId, (SELECT Id, ServiceResource.Heydoc_Id__c FROM ServiceResources),
                        ServiceTerritory.Heydoc_Id__c

                FROM ServiceAppointment
                WHERE Id = :sa.Id
        ];

        System.debug(':test_validateSyncCanBeDone_Heydoc:assert 5');
        System.assert(ExternalSyncAppointments.validateSyncCanBeDone_Heydoc(sa) == false);

        st.Heydoc_Id__c = 'mock_hd_loc_123321';
        update st;

        sa = [
                SELECT
                        Id,
                        AccountId, (SELECT Id, ServiceResource.Heydoc_Id__c FROM ServiceResources),
                        ServiceTerritory.Heydoc_Id__c

                FROM ServiceAppointment
                WHERE Id = :sa.Id
        ];

        System.debug(':test_validateSyncCanBeDone_Heydoc:assert 6');
        System.assert(ExternalSyncAppointments.validateSyncCanBeDone_Heydoc(sa) == true);

    }


    @IsTest
    static void test_validateSyncCanBeDone_Aerona() {
        System.debug(':test_validateSyncCanBeDone_Aerona:assert 1');
        System.assert(ExternalSyncAppointments.validateSyncCanBeDone_Aerona(null) == false);

        Account acc = [SELECT Id FROM Account LIMIT 1];
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE Name LIKE 'Dental%' LIMIT 1];
        ServiceResource sr = [SELECT Id FROM ServiceResource WHERE Name LIKE 'Dental%' LIMIT 1];

        st.Aerona_Id__c = null;

        update sr;
        update st;

        ServiceAppointment sa = new ServiceAppointment();
        sa.ParentRecordId = acc.Id;
        sa.Heydoc_Appointment_Id__c = null;
        sa.ServiceTerritoryId = st.Id;

        System.debug(':test_validateSyncCanBeDone_Aerona:assert 2');
        System.assert(ExternalSyncAppointments.validateSyncCanBeDone_Aerona(sa) == false);

        insert sa;



        sa = [
                SELECT
                        Id,
                        AccountId, (SELECT Id, ServiceResourceId FROM ServiceResources),
                        ServiceTerritory.Aerona_Id__c

                FROM ServiceAppointment
                WHERE Id = :sa.Id
        ];

        System.debug(':test_validateSyncCanBeDone_Aerona:assert 3');
        System.assert(ExternalSyncAppointments.validateSyncCanBeDone_Aerona(sa) == false);

        update sr;

        System.debug(':test_validateSyncCanBeDone_Aerona:assert 4');
        System.assert(ExternalSyncAppointments.validateSyncCanBeDone_Aerona(sa) == false);

        AssignedResource assignedResource = new AssignedResource();
        assignedResource.ServiceResourceId = sr.Id;
        assignedResource.IsRequiredResource = true;
        assignedResource.ServiceAppointmentId = sa.Id;
        insert assignedResource;

        sa = [
                SELECT
                        Id,
                        AccountId, (SELECT Id, ServiceResourceId FROM ServiceResources),
                        ServiceTerritory.Aerona_Id__c

                FROM ServiceAppointment
                WHERE Id = :sa.Id
        ];

        System.debug(':test_validateSyncCanBeDone_Aerona:assert 5');
        System.assert(ExternalSyncAppointments.validateSyncCanBeDone_Aerona(sa) == false);

        st.Aerona_Id__c = '1231';
        update st;

        sa = [
                SELECT
                        Id,
                        AccountId, (SELECT Id, ServiceResourceId FROM ServiceResources),
                        ServiceTerritory.Aerona_Id__c

                FROM ServiceAppointment
                WHERE Id = :sa.Id
        ];

        System.debug(':test_validateSyncCanBeDone_Aerona:assert 6');
        System.assert(ExternalSyncAppointments.validateSyncCanBeDone_Aerona(sa) == true);

    }

    @IsTest
    static void test_checkIsDifferentThanLastSync_Heydoc() {
        HeyDocService.BookingDataInput full = new HeyDocService.BookingDataInput();
        HeyDocService.BookingDataInput partial = new HeyDocService.BookingDataInput();
        HeyDocService.BookingDataInput old = new HeyDocService.BookingDataInput();

        System.assert(ExternalSyncAppointments.checkIsDifferentThanLastSync(full, partial, old) == false);

        full.start = Datetime.now();
        System.assert(ExternalSyncAppointments.checkIsDifferentThanLastSync(full, partial, old) == true);
        System.assert(partial.start == full.start);

        full.end_jsonsafe = Datetime.now();
        System.assert(ExternalSyncAppointments.checkIsDifferentThanLastSync(full, partial, old) == true);
        System.assert(partial.end_jsonsafe == full.end_jsonsafe);

    }

    @IsTest
    static void test_removeItemFromMultiPicklist() {
        String before = 'a;b;c';
        String after = ExternalSyncAppointments.removeItemFromMultiPicklist(before, 'b');
        System.assert(after == 'a;c');
        before = null;
        after = ExternalSyncAppointments.removeItemFromMultiPicklist(before, 'b');
        System.assert(after == null);
    }

    @IsTest
    static void testFutureBehavior() {
        List<ServiceAppointment> sas = new List<ServiceAppointment>();
        ExternalSyncAppointmentsF.syncAppointments(sas);
    }

    @IsTest
    static void testDelFutureBehavior() {
        List<ServiceAppointment> sas = new List<ServiceAppointment>();
        ExternalSyncDelAppointmentsF.syncAppointments(sas);
    }

    @IsTest
    static void executeWatchdogCheck_test() {
        ExternalSyncAppointments.executeWatchdogCheck();
    }

    @IsTest
    static void testMapAeronaStatusFromSFStatus() {
        System.assertEquals(10, ExternalSyncAppointments.mapAeronaStatusFromSFStatus('Scheduled'));
        System.assertEquals(3, ExternalSyncAppointments.mapAeronaStatusFromSFStatus('Arrived'));
        System.assertEquals(4, ExternalSyncAppointments.mapAeronaStatusFromSFStatus('Did Not Arrive'));
        System.assertEquals(5, ExternalSyncAppointments.mapAeronaStatusFromSFStatus('Canceled'));
        System.assertEquals(7, ExternalSyncAppointments.mapAeronaStatusFromSFStatus('Completed'));
        System.assertEquals(10, ExternalSyncAppointments.mapAeronaStatusFromSFStatus('Not Match Any Case'));
    }

    @IsTest
    static void logAndSetSyncTest() {
        // Setup test data
        Account acc = [SELECT Id FROM Account LIMIT 1];
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE Name LIKE 'Medical%' LIMIT 1];
        ServiceResource sr = [SELECT Id FROM ServiceResource WHERE Name LIKE 'Medical%' LIMIT 1];

        ServiceAppointment sa = new ServiceAppointment();
        sa.ParentRecordId = acc.Id;
        sa.Heydoc_Appointment_Id__c = null;
        sa.ServiceTerritoryId = st.Id;
        sa.WorkTypeId = [SELECT Id FROM WorkType WHERE Name = 'TWTG1'].Id;
        insert sa;

        String testMessage = 'This is a test message';
        String testStack = 'Here is a test stack';
        String testLogDetail = 'This is a detail for test log';
        String testSyncTo = null;

        Test.startTest();

        ExternalSyncAppointments.logAndSetSync(LoggingLevel.ERROR, sa, testMessage, testStack, testLogDetail, testSyncTo);

        Test.stopTest();

        // Reload the appointment
        sa = [SELECT Id, NeedsSyncTo__c FROM ServiceAppointment WHERE Id = :sa.Id];
        System.assertEquals(testSyncTo, sa.NeedsSyncTo__c, 'The sync to was not set correctly');
    }


}