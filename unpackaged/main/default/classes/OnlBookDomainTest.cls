/**
 * Created by Matija on 28.11.2023..
 */

@IsTest
global class OnlBookDomainTest {

    @TestSetup
    static void dataSetup() {

        Id pbid = Test.getStandardPricebookId();
        Pricebook2 pb = new Pricebook2(Id = pbid);
        pb.IsActive = true;
        update pb;

        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
        accounts[0].PersonEmail = 'emai@example.com';
        accounts[0].Store_password__c = 'pass';
        update accounts[0];

        WorkTypeGroup wtg1 = new WorkTypeGroup(Name = 'WTG 1', Heydoc_Id__c = 'mock_hd_wtg_id', Service_Type__c = 'Medical', IsActive = true, Appointment_Type__c = 'CLINIC');
        insert wtg1;

        WorkType wt1 = new WorkType(Name = 'WT for ' + wtg1.Name, EstimatedDuration = 40);
        insert wt1;

        WorkTypeGroupMember wtgm1 = new WorkTypeGroupMember();
        wtgm1 = new WorkTypeGroupMember(WorkTypeGroupId = wtg1.Id, WorkTypeId = wt1.Id);
        insert wtgm1;

        Product2 product = new Product2(Name = 'GP 1', Work_Type_Group__c = wtg1.Id, IsActive = true, Available_in_Stores__c = 'Appointments', Include_in_Store__c = true, Appointment__c = true);
        product.ProductCode = 'T-P-A';
        product.Store_Categories__c = 'GP Consultation';
        product.Business_Unit__c = 'GP';
        insert product;

        insert new PricebookEntry(Pricebook2Id = pb.Id, Product2Id = product.Id, IsActive = true, UnitPrice = 10);

        OperatingHours oh1 = new OperatingHours();
        oh1.Name = 'test Opening Hours';
        insert oh1;

        ServiceTerritory st1 = new ServiceTerritory();
        st1.Name = 'unit test location';
        st1.Heydoc_Id__c = 'test_st_hd_id';
        st1.IsActive = true;
        st1.OperatingHoursId = oh1.Id;
        insert st1;

        Asset asset1 = new Asset(Name = 'A1');
        insert asset1;

        ServiceResource sr1 = new ServiceResource();
        sr1.Name = 'SR1';
        sr1.IsActive = true;
        sr1.ResourceType = 'S';
        sr1.AssetId = asset1.Id;
        sr1.Heydoc_Id__c = 'mock_hd_sr_id';
        insert sr1;

        ServiceTerritoryWorkType stwt = new ServiceTerritoryWorkType(ServiceTerritoryId = st1.Id, WorkTypeId = wt1.Id);
        insert stwt;

    }

    @IsTest
    static void getServiceCentersForWT_test() {
        System.assert(OnlBookDomain.getServiceCentersForWT([SELECT Id FROM WorkType LIMIT 1].Id).size() > 0);
    }

    @IsTest
    static void getServiceResourcesForTerritoryWithWTId_test() {
        System.assert(OnlBookDomain.getServiceResourcesIdsForWorTypeSkills([SELECT Id FROM WorkType LIMIT 1].Id) != null);
    }

    @IsTest
    static void getServiceResourcesForWorkTypeGroupSkills_test() {
        System.assert(OnlBookDomain.getServiceResourcesForWorkTypeGroupSkills([SELECT Id FROM WorkTypeGroup LIMIT 1].Id) != null);
    }

    @IsTest
    public static void ExtendedTerritorySlot_test() {
        OnlBookDomain.ExtendedTerritorySlot ets1 = new OnlBookDomain.ExtendedTerritorySlot();
        SchedulerAPI.TerritorySlot ts = new SchedulerAPI.TerritorySlot();
        ts.resources = new List<String>();
        ts.resources.add('ri');
        OnlBookDomain.ExtendedTerritorySlot ets2 = new OnlBookDomain.ExtendedTerritorySlot('tid1', ts);
        ets2.appendTerritorySlot('tid2', ts);
    }

    @IsTest
    public static void sortExtendedTerritorySlot_test() {
        OnlBookDomain.ExtendedTerritorySlot s1 = new OnlBookDomain.ExtendedTerritorySlot();
        OnlBookDomain.ExtendedTerritorySlot s2 = new OnlBookDomain.ExtendedTerritorySlot();
        OnlBookDomain.ExtendedTerritorySlot s3 = new OnlBookDomain.ExtendedTerritorySlot();
        OnlBookDomain.ExtendedTerritorySlot s4 = new OnlBookDomain.ExtendedTerritorySlot();
        OnlBookDomain.ExtendedTerritorySlot s5 = new OnlBookDomain.ExtendedTerritorySlot();
        s1.startTime = Datetime.now().addDays(1);
        s2.startTime = Datetime.now().addDays(0);
        s3.startTime = Datetime.now().addDays(2);
        s4.startTime = s3.startTime;
        s5.startTime = Datetime.now().addDays(-2);
        List<OnlBookDomain.ExtendedTerritorySlot> slots = new List<OnlBookDomain.ExtendedTerritorySlot>();
        slots.add(s1);
        slots.add(s2);
        slots.add(s3);
        slots.add(s4);
        slots.add(s5);
        slots.sort();
        System.assert(slots[0].startTime < slots[1].startTime);
        System.assert(slots[4].startTime == slots[3].startTime);
    }

    @IsTest
    static void testCreateContentDocumentLink() {
        // Arrange
        String testContentVersionId = '06826000001EAxjAAG';
        String testRecordId = [SELECT Id FROM Account LIMIT 1].Id;

        // Act
        ContentDocumentLink result = OnlBookDomain.createContentDocumentLink(testContentVersionId, testRecordId);

        // Assert
        System.assertEquals(testContentVersionId, result.ContentDocumentId, 'ContentDocumentId is wrong');
        System.assertEquals(testRecordId, result.LinkedEntityId, 'LinkedEntityId is wrong');
        System.assertEquals('V', result.ShareType, 'ShareType is not V');
    }

    @IsTest
    static void testCreateContentVersion() {
        // Arrange
        String filename = 'testFile';
        Blob data = Blob.valueOf('test content');
        String base64Data = EncodingUtil.base64Encode(data);

        // Act
        ContentVersion cv = OnlBookDomain.createContentVersion(filename, base64Data);

        // Assert
        System.assertNotEquals(null, cv, 'ContentVersion should not be null');
        System.assertEquals(data, cv.VersionData, 'VersionData did not match');
        System.assertEquals(filename, cv.Title, 'Title did not match');
        System.assertEquals(filename, cv.PathOnClient, 'PathOnClient did not match');
    }

    @IsTest static void testOptionWrapper() {
        // Initialize data and assign it to OptionWrapper object
        OnlBookDomain.OptionWrapper testOptionWrapper1 = new OnlBookDomain.OptionWrapper();
        testOptionWrapper1.label = 'Label_1';
        testOptionWrapper1.value = 'Value_1';
        testOptionWrapper1.wtgId = 'wtgId_1';
        testOptionWrapper1.wtId = 'wtId_1';
        testOptionWrapper1.isVideoOrTel = false;

        // Verify the values are correctly assigned
        System.assertEquals('Label_1', testOptionWrapper1.label);
        System.assertEquals('Value_1', testOptionWrapper1.value);
        System.assertEquals('wtgId_1', testOptionWrapper1.wtgId);
        System.assertEquals('wtId_1', testOptionWrapper1.wtId);
        System.assertEquals(false, testOptionWrapper1.isVideoOrTel);

        // Test another constructor
        OnlBookDomain.OptionWrapper testOptionWrapper2 = new OnlBookDomain.OptionWrapper('Label_2', 'Value_2');

        // Verify the values are correctly assigned
        System.assertEquals('Label_2', testOptionWrapper2.label);
        System.assertEquals('Value_2', testOptionWrapper2.value);
        System.assertEquals(null, testOptionWrapper2.wtgId);
        System.assertEquals(null, testOptionWrapper2.wtId);
        System.assertEquals(false, testOptionWrapper2.isVideoOrTel);

        // Test another constructor
        OnlBookDomain.OptionWrapper testOptionWrapper3 = new OnlBookDomain.OptionWrapper('Label_3', 'Value_3', 'wtgId_3', 'wtId_3', true);

        // Verify the values are correctly assigned
        System.assertEquals('Label_3', testOptionWrapper3.label);
        System.assertEquals('Value_3', testOptionWrapper3.value);
        System.assertEquals('wtgId_3', testOptionWrapper3.wtgId);
        System.assertEquals('wtId_3', testOptionWrapper3.wtId);
        System.assertEquals(true, testOptionWrapper3.isVideoOrTel);
    }
}