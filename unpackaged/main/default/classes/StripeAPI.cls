/**
 * Contains all Stripe API operations
 *
 * @author Zoran Zunko
 *
 * @date 3/12/21
 */
public class StripeAPI {
    @TestVisible
    String stripeBaseURL;

    @TestVisible
    String stripeCurrency;

    @TestVisible
    List<String> paymentMethods;

    @TestVisible
    final String checkoutSessionURL = '/checkout/sessions';
    @TestVisible String getCheckoutSessionURL() {
        return stripeBaseURL + checkoutSessionURL;
    }

    @TestVisible
    final String createCouponURL = '/coupons';
    @TestVisible String getCreateCouponURL() {
        return stripeBaseURL + createCouponURL;
    }

    static final String lineItemMemberFormat = 'line_items[{0}]';
    static final String lineItemAmount = '[amount]';
    static final String lineItemQuantity = '[quantity]';
    static final String lineItemCurrency = '[currency]';
    static final String lineItemName = '[name]';
    @TestVisible static String buildLineItems(List<OpportunityLineItem> products, String stripeCurrencyCode) {
        String lineItemsString = '';
        Integer sequence = 0;
        for (Integer i = 0; i < products.size(); i++) {
            if (products[i].UnitPrice >= 0) {
                if (!products[i].Product2.Is_Discount__c) {
                    String lineItemBase = String.format(lineItemMemberFormat, new List<String>{
                            String.valueOf(sequence)
                    });
                    lineItemsString += EncodingUtil.urlEncode(lineItemBase + lineItemAmount, 'UTF-8') + '=' + EncodingUtil.urlEncode((100 * products[i].UnitPrice).setScale(2).intValue() + '', 'UTF-8') + '&';
                    lineItemsString += EncodingUtil.urlEncode(lineItemBase + lineItemQuantity, 'UTF-8') + '=' + EncodingUtil.urlEncode(products[i].Quantity.setScale(0).intValue() + '', 'UTF-8') + '&';
                    lineItemsString += EncodingUtil.urlEncode(lineItemBase + lineItemCurrency, 'UTF-8') + '=' + EncodingUtil.urlEncode(stripeCurrencyCode, 'UTF-8') + '&';

                    //delivery optionsa re sent with description to Stripe, but all others with Name of the product
                    if (products[i].Product2.Is_Delivery_Option__c) {
                        lineItemsString += EncodingUtil.urlEncode(lineItemBase + lineItemName, 'UTF-8') + '=' + EncodingUtil.urlEncode(products[i].Product2.Description, 'UTF-8');
                    }
                    else {
                        lineItemsString += EncodingUtil.urlEncode(lineItemBase + lineItemName, 'UTF-8') + '=' + EncodingUtil.urlEncode(products[i].Product2.Name, 'UTF-8');
                    }

                    lineItemsString += (i == (products.size() - 1)) ? '' : '&';
                    sequence++;
                }
                else // hack to use negative Discounts as surcharges
                {
                    if (products[i].UnitPrice > 0) {
                        String lineItemBase = String.format(lineItemMemberFormat, new List<String>{
                                String.valueOf(sequence)
                        });
                        lineItemsString += EncodingUtil.urlEncode(lineItemBase + lineItemAmount, 'UTF-8') + '=' + EncodingUtil.urlEncode((100 * products[i].UnitPrice).setScale(2).intValue() + '', 'UTF-8') + '&';
                        lineItemsString += EncodingUtil.urlEncode(lineItemBase + lineItemQuantity, 'UTF-8') + '=1&';
                        lineItemsString += EncodingUtil.urlEncode(lineItemBase + lineItemCurrency, 'UTF-8') + '=' + EncodingUtil.urlEncode(stripeCurrencyCode, 'UTF-8') + '&';
                        lineItemsString += EncodingUtil.urlEncode(lineItemBase + lineItemName, 'UTF-8') + '=' + EncodingUtil.urlEncode(products[i].Description, 'UTF-8');

                        lineItemsString += (i == (products.size() - 1)) ? '' : '&';
                    }
                    sequence++;
                }
            }
        }
        lineItemsString = lineItemsString.removeEnd('&');
        return lineItemsString;
    }

    static final String paymentMethodFormat = 'payment_method_types[{0}]';
    @TestVisible static String buildPaymentMethods(List<String> paymentMethods) {
        String paymentMethodsString = '';
        for (Integer i = 0; i < paymentMethods.size(); i++) {
            String paymentMethodBase = String.format(paymentMethodFormat, new List<String>{
                    String.valueOf(i)
            });
            paymentMethodsString += EncodingUtil.urlEncode(paymentMethodBase, 'UTF-8') + '=' + EncodingUtil.urlEncode(paymentMethods[i], 'UTF-8');
            paymentMethodsString += (i == (paymentMethods.size() - 1)) ? '' : '&';
        }
        return paymentMethodsString;
    }

    public StripeAPI(String stripeBaseURL, String stripeCurrency, String paymentMethods) {
        this.stripeBaseURL = stripeBaseURL;
        this.stripeCurrency = stripeCurrency;
        this.paymentMethods = paymentMethods.split(';');
    }

    /**
     * https://stripe.com/docs/api/checkout/sessions/object
     */
    public class StripeResponse {
        public String id;
    }
    public class StripeSessionResponse {
        public String id;
        public String payment_status;
    }
    /**
     * Generates Stripe paymet session
     *
     * @param stripePrivateKey stripe private key
     * @param opp opportunity used to generate line items and create cancel url
     * @param successURL where to redirect if payment successful
     * @param cancelURL where to redirect if payment cancelled
     * @param discountCouponId stripe Id of the discount applied to the order
     * @param deliveryCouponId stripe Id of the delivery discount applied to the order
     *
     * @return payment session id as generated by Stripe
     */
    public String createPaymentSession(String stripePrivateKey, Opportunity opp, String successURL, String cancelURL, String discountCouponId, String deliveryCouponId) {


        String cancelURLFormatted = cancelURL;
        if (cancelURL.contains('{0}')) {
            cancelURL = String.format(cancelURL, new List<String>{
                    opp.UUID__c
            });
        }

        String endPoint = getCheckoutSessionURL() + '?';
        endPoint += 'success_url=' + EncodingUtil.urlEncode(successURL, 'UTF-8') + '&';
        endPoint += 'cancel_url=' + EncodingUtil.urlEncode(cancelURL, 'UTF-8') + '&';
        endPoint += buildPaymentMethods(this.paymentMethods) + '&';
        endPoint += 'client_reference_id=' + EncodingUtil.urlEncode(opp.Id, 'UTF-8') + '&';
        endPoint += 'customer_email=' + EncodingUtil.urlEncode(opp.Account.PersonEmail, 'UTF-8') + '&';
        endPoint += 'payment_intent_data[metadata][AccountId]=' + EncodingUtil.urlEncode(opp.AccountId, 'UTF-8') + '&';
        endPoint += 'payment_intent_data[metadata][ContactId]=' + EncodingUtil.urlEncode(opp.Account.ContactId__c, 'UTF-8') + '&';
        endPoint += 'payment_intent_data[metadata][OpportunityId]=' + EncodingUtil.urlEncode(opp.Id, 'UTF-8') + '&';
        endPoint += buildLineItems(opp.OpportunityLineItems, this.stripeCurrency);

        Integer numDiscounts = 0;
        if (String.isNotBlank(deliveryCouponId)) {
            endPoint += '&discounts[' + numDiscounts + '][coupon]=' + EncodingUtil.urlEncode(deliveryCouponId, 'UTF-8') + '&';
            numDiscounts++;
        }
        if (String.isNotBlank(discountCouponId)) {
            endPoint += '&discounts[' + numDiscounts + '][coupon]=' + EncodingUtil.urlEncode(discountCouponId, 'UTF-8') + '&';
        }

        System.debug(LoggingLevel.ERROR, 'createPaymentSession - endPoint: ' + endPoint);

        HttpRequest req = getHTTPRequest(endPoint, stripePrivateKey, 'POST');
        Http httpClient = new Http();
        HttpResponse res = httpClient.send(req);

        System.debug(LoggingLevel.FINE, 'res: ' + res);
        System.debug(LoggingLevel.FINE, 'res: ' + res.getStatusCode());
        System.debug(LoggingLevel.FINE, 'res: ' + res.getStatus());
        System.debug(LoggingLevel.FINE, 'res: ' + res.getBody());

        return ((StripeResponse) JSON.deserialize(res.getBody(), StripeResponse.class)).id;
    }

    public Boolean getPaymentSessionPaid(String sessionId) {

        String stripePrivateKey = OnlineStoreSettingsManager.getStoreSettings().Stripe_Private_Key__c;
        String endPoint = getCheckoutSessionURL() + '/' + sessionId;

        System.debug(LoggingLevel.ERROR, 'getPaymentSessionPaid - endPoint: ' + endPoint);

        HttpRequest req = getHTTPRequest(endPoint, stripePrivateKey, 'GET');
        Http httpClient = new Http();
        HttpResponse res = httpClient.send(req);

        System.debug(LoggingLevel.FINE, 'res: ' + res);
        System.debug(LoggingLevel.FINE, 'res: ' + res.getStatusCode());
        System.debug(LoggingLevel.FINE, 'res: ' + res.getStatus());
        System.debug(LoggingLevel.FINE, 'res: ' + res.getBody());

        return (((StripeSessionResponse) JSON.deserialize(res.getBody(), StripeSessionResponse.class))?.payment_status == 'paid');
    }


    /**
     * Generates Stripe one time coupon
     *
     * @param stripePrivateKey stripe private key
     * @param couponData Opportunity Line Item which contains coupon discount information
     *
     * @return payment session id as generated by Stripe
     */
    public String createCoupon(String stripePrivateKey, OpportunityLineItem couponData) {

        String description;
        // this makes us send "Click and Collect" if the "coupon" is the discount for click and collect
        if (couponData.Product2.Is_Delivery_Option__c) description = couponData.Product2.Name;
        else description = couponData.Description;
        description = description.replaceAll('&', 'and');
        if (description.length() > 40) description = description.substring(0, 36) + '...';

        String endPoint = getCreateCouponURL() + '?';
        endPoint += 'amount_off=' + EncodingUtil.urlEncode(String.valueOf(Math.abs(couponData.TotalPrice.setScale(2) * 100).intValue()), 'UTF-8') + '&';
        endPoint += 'currency=' + EncodingUtil.urlEncode(this.stripeCurrency, 'UTF-8') + '&';
        endPoint += 'duration=once&';
        endPoint += 'name=' + EncodingUtil.urlEncode(description, 'UTF-8');

        HttpRequest req = getHTTPRequest(endPoint, stripePrivateKey, 'POST');
        Http httpClient = new Http();
        HttpResponse res = httpClient.send(req);

        System.debug(LoggingLevel.FINE, 'res: ' + res);
        System.debug(LoggingLevel.FINE, 'res: ' + res.getStatusCode());
        System.debug(LoggingLevel.FINE, 'res: ' + res.getStatus());
        System.debug(LoggingLevel.FINE, 'res: ' + res.getBody());

        return ((StripeResponse) JSON.deserialize(res.getBody(), StripeResponse.class)).id;
    }

    /**
 * Generates Stripe one time coupon
 *
 * @param stripePrivateKey stripe private key
 *
 * @return payment session id as generated by Stripe
 */
    public String createCoupon(String stripePrivateKey, String description, Decimal totalPrice) {

        // this makes us send "Click and Collect" if the "coupon" is the discount for click and collect
        description = description.replaceAll('&', 'and');
        if (description.length() > 40) description = description.substring(0, 36) + '...';

        String endPoint = getCreateCouponURL() + '?';
        endPoint += 'amount_off=' + EncodingUtil.urlEncode(String.valueOf(Math.abs(totalPrice.setScale(2) * 100).intValue()), 'UTF-8') + '&';
        endPoint += 'currency=' + EncodingUtil.urlEncode(this.stripeCurrency, 'UTF-8') + '&';
        endPoint += 'duration=once&';
        endPoint += 'name=' + EncodingUtil.urlEncode(description, 'UTF-8');

        HttpRequest req = getHTTPRequest(endPoint, stripePrivateKey, 'POST');
        Http httpClient = new Http();
        HttpResponse res = httpClient.send(req);

        System.debug(LoggingLevel.FINE, 'res: ' + res);
        System.debug(LoggingLevel.FINE, 'res: ' + res.getStatusCode());
        System.debug(LoggingLevel.FINE, 'res: ' + res.getStatus());
        System.debug(LoggingLevel.FINE, 'res: ' + res.getBody());

        return ((StripeResponse) JSON.deserialize(res.getBody(), StripeResponse.class)).id;
    }

    @TestVisible HttpRequest getHTTPRequest(String endpoint, String privateKey, String method) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Authorization', 'Bearer ' + privateKey);
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setMethod(method);

        return req;
    }
}