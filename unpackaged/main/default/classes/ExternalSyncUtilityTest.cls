/**
 * Created 28.3.2022..
 */

@IsTest
private class ExternalSyncUtilityTest {
    @IsTest
    static void test_addItemToMultiPicklist() {
        String before = 'a;b;c';
        String after = ExternalSyncUtility.addItemToMultiPicklist(before,'d');
        System.assert(after=='a;b;c;d');
    }

    @IsTest
    static void test_removeItemFromMultiPicklist() {
        String before = 'a;b;c';
        String after = ExternalSyncUtility.removeItemFromMultiPicklist(before,'b');
        System.assert(after=='a;c');
    }
}