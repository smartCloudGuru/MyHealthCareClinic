/**
 * Created 17.9.2022..
 */

@IsTest
public class GoCardlessServiceTest {

    @IsTest
    static void createRedirectFlow_Test() {

        GoCardlessServiceMock.setAsMock();

        GoCardlessService.RedirectFlowEntity redirectFlowEntity = new GoCardlessService.RedirectFlowEntity();

        Test.startTest();
        GoCardlessService.RedirectFlowEntity res = GoCardlessService.createRedirectFlow(redirectFlowEntity, null);
        Test.stopTest();

        System.assert(res != null);
    }

    @IsTest
    static void completeRedirectFlow_Test() {

        GoCardlessServiceMock.setAsMock();

        Test.startTest();
        GoCardlessService.RedirectFlowEntity res = GoCardlessService.completeRedirectFlow('flowId', 'sessionId');
        Test.stopTest();

        System.assert(res != null);
    }


    @IsTest
    static void createSubscription_Test() {
        GoCardlessServiceMock.setAsMock();

        GoCardlessService.SubscriptionEntity req = new GoCardlessService.SubscriptionEntity();

        Test.startTest();
        GoCardlessService.SubscriptionEntity res = GoCardlessService.createSubscription(req);
        Test.stopTest();

        System.assert(res != null);
        System.assert(res.id != null);
        System.debug(res.start_date);
        System.debug(res.end_date);
    }

    @IsTest
    static void getSubscriptions_Test() {
        GoCardlessServiceMock.setAsMock();

        Test.startTest();
        List<GoCardlessService.SubscriptionWrapper> ret = GoCardlessService.getSubscriptions();
        Test.stopTest();

        System.assert(ret != null);
        System.assert(!ret.isEmpty());
    }

    @IsTest
    static void getMandates_Test() {
        GoCardlessServiceMock.setAsMock();

        Test.startTest();
        List<GoCardlessService.MandateWrapper> ret = GoCardlessService.getMandates();
        Test.stopTest();

        System.assert(ret != null);
        System.assert(!ret.isEmpty());
    }


}