/**
 * Created 14.9.2022..
 */

public without sharing class GoCardlessService {


    public static final GoCardless_Integration_Setting__mdt INTEGRATIONS_SETTINGS = [
            SELECT Bearer_token__c, Endpoint__c, Version__c, Redirect_URL__c
            FROM GoCardless_Integration_Setting__mdt
            LIMIT 1
    ];

    public static RedirectFlowEntity createRedirectFlow(RedirectFlowEntity redirectFlowsRequest, String successUrlOverride) {

        HttpRequest req = createHttpRequest('redirect_flows');

        if (String.isNotBlank(successUrlOverride)) redirectFlowsRequest.success_redirect_url = successUrlOverride;
        else redirectFlowsRequest.success_redirect_url = INTEGRATIONS_SETTINGS.Redirect_URL__c + '?page=gcl';

        RedirectFlows redirectFlows = new RedirectFlows();
        redirectFlows.redirect_flows = redirectFlowsRequest;

        req.setBody(JSON.serialize(redirectFlows, true));

        System.debug('::GoCardlessService:createRedirectFlow:POST:body=' + req.getBody());

        Http callout = new Http();
        HttpResponse res = callout.send(req);

        System.debug('::GoCardlessService:sendPOST:createRedirectFlow:resp.code=' + res.getStatusCode());
        System.debug('::GoCardlessService:sendPOST:createRedirectFlow:resp.body=' + res.getBody());

        //logIfError(req, res);

        if (res.getBody() != null && res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
            RedirectFlows response = (RedirectFlows) JSON.deserialize(res.getBody(), RedirectFlows.class);
            return response.redirect_flows;
        }

        return null;
    }

    public static RedirectFlowEntity completeRedirectFlow(String redirectFlowId, String sessionId) {
        HttpRequest req = createHttpRequest('redirect_flows/' + redirectFlowId + '/actions/complete');

        req.setBody('{"data": { "session_token": "' + +sessionId + '"}}');

        System.debug('::GoCardlessService:createRedirectFlow:POST:body=' + req.getBody());

        Http callout = new Http();
        HttpResponse res = callout.send(req);

        System.debug('::GoCardlessService:sendPOST:createRedirectFlow:resp.code=' + res.getStatusCode());
        System.debug('::GoCardlessService:sendPOST:createRedirectFlow:resp.body=' + res.getBody());

        //logIfError(req, res);

        if (res.getBody() != null && res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
            RedirectFlows response = (RedirectFlows) JSON.deserialize(res.getBody(), RedirectFlows.class);
            return response.redirect_flows;
        }

        return null;
    }

    public static SubscriptionEntity createSubscription(SubscriptionEntity request) {

        HttpRequest req = createHttpRequest('subscriptions');

        Subscriptions subscriptions = new Subscriptions();
        subscriptions.subscriptions = request;

        String body = JSON.serializePretty(subscriptions, true).replaceAll('_jsonsafe', '');
        req.setBody(body);

        System.debug('::GoCardlessService: :POST:body=' + req.getBody());

        Http callout = new Http();
        HttpResponse res = callout.send(req);

        System.debug('::GoCardlessService:sendPOST:createSubscription:resp.code=' + res.getStatusCode());
        System.debug('::GoCardlessService:sendPOST:createSubscription:resp.body=' + res.getBody());

        if (res.getBody() != null && res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
            String resBody = res.getBody()?.replaceAll('"currency"', '"currency_jsonsafe"');
            Subscriptions response = (Subscriptions) JSON.deserialize(resBody, Subscriptions.class);
            return response.subscriptions;
        }
        else {
            Subscriptions response = (Subscriptions) JSON.deserialize(res.getBody(), Subscriptions.class);
            if (response.error != null) throw new GCException(response.error.message);
        }

        return null;
    }

    public static void getCustomers() {
        HttpRequest req = createHttpRequest('customers');
        req.setMethod('GET');

        Http callout = new Http();
        HttpResponse res = callout.send(req);

        System.debug('::GoCardlessService:sendGET:getCustomers:resp.code=' + res.getStatusCode());
        System.debug('::GoCardlessService:sendGET:getCustomers:resp.body=' + res.getBody());
    }


    //    public static void getCustomer(String customerid) {
    //        HttpRequest req = createHttpRequest('customers/' + customerid);
    //        req.setMethod('GET');
    //
    //        Http callout = new Http();
    //        HttpResponse res = callout.send(req);
    //
    //        System.debug('::GoCardlessService:sendGET:getCustomer:resp.code=' + res.getStatusCode());
    //        System.debug('::GoCardlessService:sendGET:getCustomer:resp.body=' + res.getBody());
    //    }

    public static List<MandateWrapper> getMandates() {
        Integer num_limit = 500;
        String cursor_after = null;

        List<MandateWrapper> allMandates = new List<MandateWrapper>();

        do {
            String path = 'mandates?limit=' + num_limit;
            if (cursor_after != null) path += '&after=' + cursor_after;

            HttpRequest req = createHttpRequest(path);
            req.setMethod('GET');

            Http callout = new Http();
            HttpResponse res = callout.send(req);

            System.debug('::GoCardlessService:sendGET:getMandates:resp.code=' + res.getStatusCode());
            System.debug('::GoCardlessService:sendGET:getMandates:resp.body=' + res.getBody());


            if (res.getStatusCode() == 200) {
                MandateDataWrapper mdw = (MandateDataWrapper) JSON.deserialize(res.getBody(), MandateDataWrapper.class);

                if (mdw == null) break;
                if (mdw.mandates == null) break;
                if (mdw != null && mdw.mandates != null) allMandates.addAll(mdw.mandates);

                if (mdw.meta == null) break;
                if (mdw.meta.cursors == null) break;
                if (mdw.meta.cursors.after == null) break;

                if (mdw.meta.cursors.after == cursor_after) break;

                cursor_after = mdw.meta.cursors.after;
            }
            else {
                //todo log not-200 response
                System.debug(LoggingLevel.WARN, 'GoCardless error response ' + res.getStatusCode());
                break;
            }

        }
        while (cursor_after != null); // after will be set to null at the last response from GC

        System.debug('::GoCardlessService:sendGET:getMandates:allMandates.size=' + allMandates.size());
        return allMandates;
    }

    //    public static void getMandate(String mandateId) {
    //        HttpRequest req = createHttpRequest('mandates/' + mandateId);
    //        req.setMethod('GET');
    //
    //        Http callout = new Http();
    //        HttpResponse res = callout.send(req);
    //
    //        System.debug('::GoCardlessService:sendGET:getMandate:resp.code=' + res.getStatusCode());
    //        System.debug('::GoCardlessService:sendGET:getMandate:resp.body=' + res.getBody());
    //    }

    public static List<SubscriptionWrapper> getSubscriptions() {

        Integer num_limit = 500;
        String cursor_after = null;

        List<SubscriptionWrapper> allSubscriptions = new List<SubscriptionWrapper>();

        do {

            String path = 'subscriptions?limit=' + num_limit;
            if (cursor_after != null) path += '&after=' + cursor_after;

            HttpRequest req = createHttpRequest(path);
            req.setMethod('GET');

            Http callout = new Http();
            HttpResponse res = callout.send(req);

            System.debug('::GoCardlessService:sendGET:getSubscriptions:resp.code=' + res.getStatusCode());
            System.debug('::GoCardlessService:sendGET:getSubscriptions:resp.body=' + res.getBody());


            if (res.getStatusCode() == 200) {
                SubscriptionDataWrapper sdw = (SubscriptionDataWrapper) JSON.deserialize(res.getBody(), SubscriptionDataWrapper.class);

                if (sdw == null) break;
                if (sdw.subscriptions == null) break;
                if (sdw != null && sdw.subscriptions != null) allSubscriptions.addAll(sdw.subscriptions);

                if (sdw.meta == null) break;
                if (sdw.meta.cursors == null) break;
                if (sdw.meta.cursors.after == null) break;

                if (sdw.meta.cursors.after == cursor_after) break;

                cursor_after = sdw.meta.cursors.after;
            }
            else {
                //todo log not-200 response
                System.debug(LoggingLevel.WARN, 'GoCardless error response ' + res.getStatusCode());
                break;
            }

        }
        while (cursor_after != null); // after will be set to null at the last response from GC

        System.debug('::GoCardlessService:sendGET:getSubscriptions:allSubscriptions.size=' + allSubscriptions.size());
        return allSubscriptions;
    }

    //    public static void getSubscription(String subscriptionId) {
    //        HttpRequest req = createHttpRequest('subscriptions/' + subscriptionId);
    //        req.setMethod('GET');
    //
    //        Http callout = new Http();
    //        HttpResponse res = callout.send(req);
    //
    //        System.debug('::GoCardlessService:sendGET:getSubscription:resp.code=' + res.getStatusCode());
    //        System.debug('::GoCardlessService:sendGET:getSubscription:resp.body=' + res.getBody());
    //    }

    //    public static void updateSubscriptionEnd(String subscriptionId, Date endDate) {
    //        HttpRequest req = createHttpRequest('subscriptions/' + subscriptionId);
    //        req.setMethod('PUT');
    //
    //        Http callout = new Http();
    //        HttpResponse res = callout.send(req);
    //
    //        String formatedDate = null;
    //        if (endDate != null) formatedDate = Datetime.newInstance (endDate, Time.newInstance(12, 0, 0, 0)).format('yyyy-MM-dd');
    //
    //        String body = '{subscriptions: {"end_date": "' + formatedDate + '"}}';
    //        req.setBody(body);
    //
    //        System.debug('::GoCardlessService:sendGET:getSubscription:resp.code=' + res.getStatusCode());
    //        System.debug('::GoCardlessService:sendGET:getSubscription:resp.body=' + res.getBody());
    //    }

    public static HttpRequest createHttpRequest(String path) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(INTEGRATIONS_SETTINGS.Endpoint__c + path);
        req.setHeader('content-type', 'application/json');
        req.setHeader('GoCardless-Version', INTEGRATIONS_SETTINGS.Version__c);
        req.setHeader('Authorization', 'Bearer ' + INTEGRATIONS_SETTINGS.Bearer_token__c);
        req.setMethod('POST');
        req.setTimeout(110000);

        return req;
    }

    public class Subscriptions {
        public SubscriptionEntity subscriptions;
        public GcError error;
    }

    public class RedirectFlows {
        public RedirectFlowEntity redirect_flows;
        public GcError error;
    }

    public class SubscriptionEntity {
        public String id;
        public String amount;
        public String currency_jsonsafe = 'GBP';
        public String status;
        public String name;
        public Date start_date;
        public Date end_date;
        public String count;
        public String interval_unit;
        public String day_of_month;
        public Metadata metadata = new Metadata();
        public Links links = new Links();
    }

    public class SubscriptionDataWrapper {
        public List<SubscriptionWrapper> subscriptions;
        public MetaWrapper meta;
    }

    public class SubscriptionWrapper {
        public String id;
        public String created_at;
        public Integer amount;
        public String status;
        public String name;
        public String start_date;
        public String end_date;
        public Integer interval;
        public String interval_unit;
        public String day_of_month;
        public String month;
        public String count;
        public MetadataWrapper metadata;
        public String payment_reference;
        public List<UpcomingPaymentWrapper> upcoming_payments;
        public String app_fee;
        public LinksWrapper links;
        public Boolean retry_if_possible;
        public String earliest_charge_date_after_resume;
        public Boolean parent_plan_paused;
    }

    public class MandateDataWrapper {
        public List<MandateWrapper> mandates;
        public MetaWrapper meta;
    }

    public class MandateWrapper {
        public String id;
        public String created_at;
        public String reference;
        public String status;
        public String scheme;
        public String next_possible_charge_date;
        public Boolean payments_require_approval;
        public MetadataWrapper metadata;
        public LinksWrapper links;
        public String consent_parameters;
        public String verified_at;
        public String funds_settlement;
    }

    public class MetadataWrapper {
        public String order_no;
    }

    public class UpcomingPaymentWrapper {
        public String charge_date;
        public Integer amount;
    }

    public class LinksWrapper {
        public String mandate;
        public String customer_bank_account;
        public String creditor;
        public String customer;
    }

    public class MetaWrapper {
        public CursorsWrapper cursors;
    }
    
    public class CursorsWrapper {
        public String before;
        public String after;
    }


    public class GcError {
        public String message;
    }

    public class Links {
        public String mandate;
        public String customer;
        public String creditor;
        public String customer_bank_account;
    }

    public class Metadata {
        public String order_no;
    }

    public class RedirectFlowEntity {
        public String id;
        public String description;
        public String success_redirect_url;
        public String redirect_url;
        public String session_token;
        public String mandate_reference;

        public Links links = new Links();
        public Metadata metadata = new Metadata();
        public PrefilledCustomer prefilled_customer = new PrefilledCustomer();
    }

    public class PrefilledCustomer {

        public String given_name;
        public String family_name;
        public String email;
    }

    public virtual class GCException extends Exception {
    }
}