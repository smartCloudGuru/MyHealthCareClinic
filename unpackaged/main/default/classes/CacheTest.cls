@IsTest
public class CacheTest {
    @IsTest
    static void testRecordTypeId() {
        RecordType rt = [SELECT Id, DeveloperName, SobjectType FROM RecordType WHERE IsActive = TRUE LIMIT 1];
        String recordTypeId;
        Test.startTest();
        recordTypeId = Cache.recordTypeId(rt.SobjectType + '.' + rt.DeveloperName);
        Test.stopTest();

        System.assertEquals(rt.Id, recordTypeId);
    }
}