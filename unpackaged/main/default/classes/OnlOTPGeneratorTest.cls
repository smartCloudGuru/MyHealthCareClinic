/**
 * Created 15.12.2021..
 */

@IsTest
public class OnlOTPGeneratorTest {

    @IsTest static void test_generateOTP()
    {
        OnlOTPGenerator og = new OnlOTPGenerator();
        og.generateOTP();

        System.assert([SELECT Id From OneTimePassword__c].size()>0);

    }
}