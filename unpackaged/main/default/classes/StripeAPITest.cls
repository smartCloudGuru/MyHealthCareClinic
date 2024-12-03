/**
* @author Zoran Zunko
* @date 3/13/21
*
*/
@IsTest global class StripeAPITest {

    //region Opportunity JSON
    public static final String OPPORTUNITY_JSON = '{\n' +
            '  "attributes" : {\n' +
            '    "type" : "Opportunity",\n' +
            '    "url" : "/services/data/v51.0/sobjects/Opportunity/0063H000004T7MFQA0"\n' +
            '  },\n' +
            '  "Id" : "0063H000004T7MFQA0",\n' +
            '  "AccountId" : "0013H00000CSxAEQA1",\n' +
            '  "UUID__c" : "4c6244cf-d06b-4494-9a1a-3440af99a600",\n' +
            '  "StageName" : "Closed Won",\n' +
            '  "IsWon" : true,\n' +
            '  "OpportunityLineItems" : {\n' +
            '    "totalSize" : 3,\n' +
            '    "done" : true,\n' +
            '    "records" : [ {\n' +
            '      "attributes" : {\n' +
            '        "type" : "OpportunityLineItem",\n' +
            '        "url" : "/services/data/v51.0/sobjects/OpportunityLineItem/00k3H0000053BDqQAM"\n' +
            '      },\n' +
            '      "OpportunityId" : "0063H000004T7MFQA0",\n' +
            '      "Id" : "00k3H0000053BDqQAM",\n' +
            '      "TotalPrice" : 149.00,\n' +
            '      "UnitPrice" : 149.00,\n' +
            '      "Quantity" : 1.00,\n' +
            '      "Product2Id" : "01t3H000000xB9RQAU",\n' +
            '      "Product2" : {\n' +
            '        "attributes" : {\n' +
            '          "type" : "Product2",\n' +
            '          "url" : "/services/data/v51.0/sobjects/Product2/01t3H000000xB9RQAU"\n' +
            '        },\n' +
            '        "Id" : "01t3H000000xB9RQAU",\n' +
            '        "Name" : "PCR Test 48 Hours",\n' +
            '        "Is_Discount__c" : false\n' +
            '      }\n' +
            '    }, {\n' +
            '      "attributes" : {\n' +
            '        "type" : "OpportunityLineItem",\n' +
            '        "url" : "/services/data/v51.0/sobjects/OpportunityLineItem/00k3H0000053BDrQAM"\n' +
            '      },\n' +
            '      "OpportunityId" : "0063H000004T7MFQA0",\n' +
            '      "Id" : "00k3H0000053BDrQAM",\n' +
            '      "TotalPrice" : 122.00,\n' +
            '      "UnitPrice" : 122.00,\n' +
            '      "Quantity" : 1.00,\n' +
            '      "Product2Id" : "01t58000005I7QGAA0",\n' +
            '      "Product2" : {\n' +
            '        "attributes" : {\n' +
            '          "type" : "Product2",\n' +
            '          "url" : "/services/data/v51.0/sobjects/Product2/01t58000005I7QGAA0"\n' +
            '        },\n' +
            '        "Id" : "01t58000005I7QGAA0",\n' +
            '        "Name" : "Obagi Gentle Cleanser #1",\n' +
            '        "Is_Discount__c" : false\n' +
            '      }\n' +
            '    }, {\n' +
            '      "attributes" : {\n' +
            '        "type" : "OpportunityLineItem",\n' +
            '        "url" : "/services/data/v51.0/sobjects/OpportunityLineItem/00k3H0000053BDsQAM"\n' +
            '      },\n' +
            '      "OpportunityId" : "0063H000004T7MFQA0",\n' +
            '      "Id" : "00k3H0000053BDsQAM",\n' +
            '      "Description" : "15 percent off COVID Tests",\n' +
            '      "TotalPrice" : -16.39,\n' +
            '      "UnitPrice" : -16.39,\n' +
            '      "Quantity" : 1.00,\n' +
            '      "Product2Id" : "01t3H0000011zJkQAI",\n' +
            '      "Product2" : {\n' +
            '        "attributes" : {\n' +
            '          "type" : "Product2",\n' +
            '          "url" : "/services/data/v51.0/sobjects/Product2/01t3H0000011zJkQAI"\n' +
            '        },\n' +
            '        "Id" : "01t3H0000011zJkQAI",\n' +
            '        "Name" : "Discount",\n' +
            '        "Is_Discount__c" : true\n' +
            '      }\n' +
            '    } ]\n' +
            '  },\n' +
            '  "Account" : {\n' +
            '    "attributes" : {\n' +
            '      "type" : "Account",\n' +
            '      "url" : "/services/data/v51.0/sobjects/Account/0013H00000CSxAEQA1"\n' +
            '    },\n' +
            '    "Id" : "0013H00000CSxAEQA1",\n' +
            '    "PersonEmail" : "someone@example.com",\n' +
            '    "ContactId__c" : "0033H00000AEQA3"\n' +
            '  }\n' +
            '}';
    //endregion

    //region Discount OLI JSON
    public static final String DISCOUNT_OLI_JSON = '{\n' +
            '  "attributes" : {\n' +
            '    "type" : "OpportunityLineItem",\n' +
            '    "url" : "/services/data/v51.0/sobjects/OpportunityLineItem/00k3H0000053BDsQAM"\n' +
            '  },\n' +
            '  "Id" : "00k3H0000053BDsQAM",\n' +
            '  "Description" : "15 percent off COVID Tests",\n' +
            '  "TotalPrice" : -16.39,\n' +
            '  "UnitPrice" : -16.39,\n' +
            '  "Quantity" : 1.00,\n' +
            '  "Product2Id" : "01t3H0000011zJkQAI",\n' +
            '  "OpportunityId" : "0063H000004T7MFQA0",\n' +
            '  "Product2" : {\n' +
            '    "attributes" : {\n' +
            '      "type" : "Product2",\n' +
            '      "url" : "/services/data/v51.0/sobjects/Product2/01t3H0000011zJkQAI"\n' +
            '    },\n' +
            '    "Id" : "01t3H0000011zJkQAI",\n' +
            '    "Name" : "Discount",\n' +
            '    "Is_Discount__c" : true\n' +
            '  }\n' +
            '}';
    //endregion

    @IsTest static void test_GenerateStripeSession() {

        Opportunity opp = (Opportunity) JSON.deserialize(OPPORTUNITY_JSON, Opportunity.class);

        OnlineStoreSettings__c onlineStoreSettings = TestDataFactory.getOnlineStoreSettings();

        Test.setMock(HttpCalloutMock.class, new Stripe_ServiceMock(TestDataFactory.STRIPE_SESSION_RESPONSE, 200, 'OK', 'POST'));
        StripeAPI stripe = new StripeAPI(
                onlineStoreSettings.Stripe_URL__c,
                'gbp',
                onlineStoreSettings.Stripe_Payment_Method_Types__c);

        Test.startTest();
        String paymentSession = stripe.createPaymentSession(
                onlineStoreSettings.Stripe_Private_Key__c,
                opp,
                onlineStoreSettings.Stripe_Success_URL__c,
                onlineStoreSettings.Stripe_Cancel_URL__c,
                '12333',
                null
        );
        Test.stopTest();

        System.assertEquals('cs_test_a170MjOvhUJHerzqPnUT3JmEjbmwaU8bB5QSLot6w2brNNBm7vIACJR6nK', paymentSession);
    }

    @IsTest
    static void test_createCoupon() {

        OpportunityLineItem discountOLI = (OpportunityLineItem) JSON.deserialize(DISCOUNT_OLI_JSON, OpportunityLineItem.class);

        OnlineStoreSettings__c onlineStoreSettings = TestDataFactory.getOnlineStoreSettings();

        Test.setMock(HttpCalloutMock.class, new Stripe_ServiceMock(TestDataFactory.STRIPE_COUPON_RESPONSE, 200, 'OK', 'POST'));
        StripeAPI stripe = new StripeAPI(
                onlineStoreSettings.Stripe_URL__c,
                'gbp',
                onlineStoreSettings.Stripe_Payment_Method_Types__c);

        Test.startTest();
        String couponId = stripe.createCoupon(
                onlineStoreSettings.Stripe_Private_Key__c,
                discountOLI
        );
        Test.stopTest();

        System.assertEquals('couponId', couponId);
    }

    @IsTest
    static void test_getPaymentSessionPaid()
    {
        OnlineStoreSettings__c onlineStoreSettings = TestDataFactory.getOnlineStoreSettings();
        Test.setMock(HttpCalloutMock.class, new Stripe_ServiceMock(TestDataFactory.STRIPE_SESSION_RESPONSE, 200, 'OK', 'POST'));
        StripeAPI stripe = new StripeAPI(
                onlineStoreSettings.Stripe_URL__c,
                'gbp',
                onlineStoreSettings.Stripe_Payment_Method_Types__c);

        Test.startTest();
        Boolean paid = stripe.getPaymentSessionPaid('cs_test_a170MjOvhUJHerzqPnUT3JmEjbmwaU8bB5QSLot6w2brNNBm7vIACJR6nK');
        Test.stopTest();

        System.assertEquals(paid, false);

    }


    @IsTest static void test_BuildPaymentMethods() {
        String paymentMethods = StripeAPI.buildPaymentMethods(new List<String>{
                'card', 'other'
        });
        System.assertEquals(
                EncodingUtil.urlEncode('payment_method_types[0]', 'UTF-8') + '=card&' + EncodingUtil.urlEncode('payment_method_types[1]', 'UTF-8') + '=other',
                paymentMethods
        );
    }

    @IsTest static void test_BuildLineItems() {
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.UnitPrice = 23.0;
        oli.Quantity = 2.0;
        oli.Product2 = new Product2(Name = 'Product 213');

        OpportunityLineItem oli2 = new OpportunityLineItem();
        oli2.UnitPrice = 25.756;
        oli2.Quantity = 3.0;
        oli2.Product2 = new Product2(Name = 'Product !!!213');

        String olis = StripeAPI.buildLineItems(new List<OpportunityLineItem>{
                oli,
                oli2
        }, 'gbp');
        System.assertEquals(
                EncodingUtil.urlEncode('line_items[0][amount]', 'UTF-8') + '=' + EncodingUtil.urlEncode('2300', 'UTF-8') + '&' +
                        EncodingUtil.urlEncode('line_items[0][quantity]', 'UTF-8') + '=' + EncodingUtil.urlEncode('2', 'UTF-8') + '&' +
                        EncodingUtil.urlEncode('line_items[0][currency]', 'UTF-8') + '=' + EncodingUtil.urlEncode('gbp', 'UTF-8') + '&' +
                        EncodingUtil.urlEncode('line_items[0][name]', 'UTF-8') + '=' + EncodingUtil.urlEncode('Product 213', 'UTF-8') + '&' +
                        EncodingUtil.urlEncode('line_items[1][amount]', 'UTF-8') + '=' + EncodingUtil.urlEncode('2575', 'UTF-8') + '&' +
                        EncodingUtil.urlEncode('line_items[1][quantity]', 'UTF-8') + '=' + EncodingUtil.urlEncode('3', 'UTF-8') + '&' +
                        EncodingUtil.urlEncode('line_items[1][currency]', 'UTF-8') + '=' + EncodingUtil.urlEncode('gbp', 'UTF-8') + '&' +
                        EncodingUtil.urlEncode('line_items[1][name]', 'UTF-8') + '=' + EncodingUtil.urlEncode('Product !!!213', 'UTF-8'),
                olis
        );
    }

    global class Stripe_ServiceMock implements HttpCalloutMock {

        public String body { get; private set; }
        public String method { get; private set; }
        public String status { get; private set; }
        public Integer code { get; private set; }
        public Boolean throwException { get; private set; }

        global Stripe_ServiceMock(String body, Integer code, String status, String method) {
            this(body, code, status, method, false);
        }
        global Stripe_ServiceMock(String body, Integer code, String status, String method, Boolean throwException) {
            this.body = body;
            this.code = code;
            this.method = method;
            this.status = status;
            this.throwException = throwException;
        }

        global HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            if (throwException) {
                Integer divideByZero = 2 / 0;
            }
            System.assert(req != null);
//			System.assertEquals(method, req.getMethod());
            res.setBody(body);
            res.setStatusCode(code);
            res.setStatus(status);
            return res;
        }
    }
}