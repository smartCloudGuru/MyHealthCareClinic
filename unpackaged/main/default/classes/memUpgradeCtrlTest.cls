/**
 * Created 16.9.2022..
 */

@IsTest
public class memUpgradeCtrlTest {


    @IsTest
    static void testLeadInsert() {

        String ret = memUpgradeFormCtrl.createUpgradeEnquiry('fn', 'ln', 'test@example.com', 'Complete', 'da');
        System.debug('testLeadInsert:ret:' + ret);

        System.assertNotEquals(ret, null);
    }

}