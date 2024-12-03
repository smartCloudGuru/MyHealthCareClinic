/**
 * Created 27.5.2024..
 */

@IsTest
global class OpportunityManagerTest {

    @IsTest
    public static void testGetDental_Tracker_RT() {
        Test.startTest();

        // Try to get the Dental_Tracker RecordType.
        RecordType rt = OpportunityManager.getDental_Tracker_RT();

        Test.stopTest();
    }

    @IsTest
    public static void testGetDental_Tracker_RT_Id() {
        Test.startTest();

        // Try to get the Dental_Tracker RecordType.
        Id rt = OpportunityManager.getDental_Tracker_RT_Id();

        Test.stopTest();

    }


    @IsTest
    public static void testGetDTP_RT() {
        Test.startTest();

        // Try to get the Dental_Tracker RecordType.
        RecordType rt = OpportunityManager.getDental_TreatmentPlan_RT();

        Test.stopTest();
    }

    @IsTest
    public static void testGetDTP_Id() {
        Test.startTest();

        // Try to get the Dental_Tracker RecordType.
        Id rt = OpportunityManager.getDental_TreatmentPlan_RT_Id();

        Test.stopTest();

    }
}