/**
* @author Zoran Zunko
* @date 4/16/21
*
*/
@IsTest
public class RandoxAuthProviderManagerTest {
    @IsTest static void getRandoxAuthProvider_test() {
        System.assert(null != RandoxAuthProviderManager.getRandoxAuthProvider());

        RandoxAuthProviderManager.randoxAuthProvider = TestDataFactory.getRandoxAuthProviders();
        System.assert(RandoxAuthProviderManager.getRandoxAuthProvider() != null);
    }
}