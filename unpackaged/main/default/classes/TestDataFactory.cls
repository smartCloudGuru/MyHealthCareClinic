/**
* @author Zoran Zunko
* @date 2/19/21
*
*/
@IsTest public class TestDataFactory {
    //region GECODE_JSON
    public static final String GECODE_JSON = '{"results": [{"address_components": [{"long_name": "48", "short_name": "48", "types": ["street_number"]}, {"long_name": "Warwick Street", "short_name": "Warwick St", "types": ["route"]}, {"long_name": "West End", "short_name": "West End", "types": ["neighborhood", "political"]}, {"long_name": "London", "short_name": "London", "types": ["postal_town"]}, {"long_name": "Greater London", "short_name": "Greater London", "types": ["administrative_area_level_2", "political"]}, {"long_name": "England", "short_name": "England", "types": ["administrative_area_level_1", "political"]}, {"long_name": "United Kingdom", "short_name": "GB", "types": ["country", "political"]}, {"long_name": "W1B 5AW", "short_name": "W1B 5AW", "types": ["postal_code"]}], "formatted_address": "48 Warwick St, West End, London W1B 5AW, UK", "geometry": {"location": {"lat": 51.5107179, "lng": -0.1377979}, "location_type": "ROOFTOP", "viewport": {"northeast": {"lat": 51.51206688029151, "lng": -0.136448919708498}, "southwest": {"lat": 51.50936891970851, "lng": -0.139146880291502}}}, "place_id": "ChIJjS5R-t8FdkgRdD_mj5xXsrw", "plus_code": {"compound_code": "GV66+7V London, UK", "global_code": "9C3XGV66+7V"}, "types": ["establishment", "finance", "point_of_interest"]}], "status": "OK"}';
    //endregion

    //region RANDOX AUTH PROVIDER JSON
    public static final String RANDOX_AUTH_PROVIDER_JSON = '{"attributes":{"type":"Randox_Auth_Provider__mdt","url":"/services/data/v51.0/sobjects/Randox_Auth_Provider__mdt/m0C3H00000007BBUAY"},"Client_Id__c":"12312","DeveloperName":"Randox_Dev","Grant_Type__c":"password","Id":"m0C3H00000007BBUAY","Label":"Randox Dev","Language":"en_US","MasterLabel":"Randox Dev","Password__c":"12312","QualifiedApiName":"Randox_Dev","Response_Type__c":"token id_token","Scope__c":"openid https://randoxhealthcovid.onmicrosoft.com/access-api/user_impersonation offline_access","Token_Endpoint__c":"https://randoxhealthcovid.b2clogin.com/randoxhealthcovid.onmicrosoft.com/oauth2/v2.0/token?p=b2c_1_dev_ropc_auth","Username__c":"sfdcdev@anthologypartners.com","API_Url__c":"https://devcovidapimanagement.azure-api.net"}';
    //endregion

    //region RANDOX_AUTH_RESPONSE
    public static final String RANDOX_AUTH_RESPONSE = '{\n' +
            '  "access_token": "adsdasda",\n' +
            '  "token_type": "Bearer",\n' +
            '  "expires_in": "28800",\n' +
            '  "refresh_token": "asfsdasfasas",\n' +
            '  "id_token": "asasfasffafasfasfas"\n' +
            '}';
    //endregion
    //
    // region RANDOX_REGISTER_RESPONSE
    public static final String RANDOX_REGISTER_RESPONSE = 'Registration has been successfully created.';
    //endregion

    //region STRIPE_SESSION_RESPONSE
    public static final String STRIPE_SESSION_RESPONSE = '{\n' +
            '  "id": "cs_test_a170MjOvhUJHerzqPnUT3JmEjbmwaU8bB5QSLot6w2brNNBm7vIACJR6nK",\n' +
            '  "object": "checkout.session",\n' +
            '  "allow_promotion_codes": null,\n' +
            '  "amount_subtotal": 14900,\n' +
            '  "amount_total": 14900,\n' +
            '  "billing_address_collection": null,\n' +
            '  "cancel_url": "https://uat-myhealthcareclinic.cs122.force.com/checkout/PaymentTestPage?opid=b112f522-1154-4606-aaea-b7851a3455ca",\n' +
            '  "client_reference_id": "0063H000004KkEMQA0",\n' +
            '  "currency": "gbp",\n' +
            '  "customer": null,\n' +
            '  "customer_details": null,\n' +
            '  "customer_email": "someone@example.com@gmail.com",\n' +
            '  "display_items": [\n' +
            '    {\n' +
            '      "amount": 14900,\n' +
            '      "currency": "gbp",\n' +
            '      "custom": {\n' +
            '        "description": null,\n' +
            '        "images": null,\n' +
            '        "name": "PCR Test 48 Hours"\n' +
            '      },\n' +
            '      "quantity": 1,\n' +
            '      "type": "custom"\n' +
            '    }\n' +
            '  ],\n' +
            '  "livemode": false,\n' +
            '  "locale": null,\n' +
            '  "metadata": {\n' +
            '    "AccountId": "0013H00000CSxAEQA1",\n' +
            '    "ContactId": "0033H00000AEQA3",\n' +
            '    "OpportunityId": "0063H000004KkEMQA0"\n' +
            '  },\n' +
            '  "mode": "payment",\n' +
            '  "payment_intent": "pi_1IVC7xCiDr3U3U64OVIP98jj",\n' +
            '  "payment_method_types": [\n' +
            '    "card"\n' +
            '  ],\n' +
            '  "payment_status": "unpaid",\n' +
            '  "setup_intent": null,\n' +
            '  "shipping": null,\n' +
            '  "shipping_address_collection": null,\n' +
            '  "submit_type": null,\n' +
            '  "subscription": null,\n' +
            '  "success_url": "https://uat-myhealthcarecommunity.cs122.force.com/booking/s/teststripe?success=true",\n' +
            '  "total_details": {\n' +
            '    "amount_discount": 0,\n' +
            '    "amount_tax": 0\n' +
            '  }\n' +
            '}';
    //endregion

    //region STRIPE_COUPON_RESPONSE
    public static final String STRIPE_COUPON_RESPONSE = '{\n' +
            '  "id": "couponId"' +
            '}';
    //endregion

    //region SEARCH_PRODUCTS_RESPONSE
    public static final String SEARCH_PRODUCTS_RESPONSE = '{\n' +
            '  "result": {\n' +
            '    "serviceTerritories": [\n' +
            '      {\n' +
            '        "city": "London",\n' +
            '        "country": "United Kingdom",\n' +
            '        "id": "0Hh4H0000004CZJSA2",\n' +
            '        "latitude": 51.46422,\n' +
            '        "longitude": -0.18544,\n' +
            '        "name": "Wandsworth - Baltimore House",\n' +
            '        "operatingHoursId": "0OH4H0000004CgyWAE",\n' +
            '        "postalCode": "SW18 1TS"\n' +
            '      },\n' +
            '      {\n' +
            '        "city": "London",\n' +
            '        "country": "United Kingdom",\n' +
            '        "id": "0Hh4H0000004CZFSA2",\n' +
            '        "latitude": 51.4814751436297,\n' +
            '        "longitude": -0.1988727417720674,\n' +
            '        "name": "Fulham Clinic",\n' +
            '        "operatingHoursId": "0OH4H0000004CgsWAE",\n' +
            '        "postalCode": "SW6 1AY",\n' +
            '        "street": "5 Vanston Place"\n' +
            '      },\n' +
            '      {\n' +
            '        "city": "London",\n' +
            '        "country": "UK",\n' +
            '        "id": "0Hh4H0000004CZTSA2",\n' +
            '        "latitude": 51.53186634197499,\n' +
            '        "longitude": -0.1094490245677326,\n' +
            '        "name": "KingsCross",\n' +
            '        "operatingHoursId": "0OH4H0000004CgxWAE",\n' +
            '        "postalCode": "N1 9LA",\n' +
            '        "street": "Double Tree Hilton, \\r\\n60 Pentonville Rd"\n' +
            '      },\n' +
            '      {\n' +
            '        "city": "Hounslow",\n' +
            '        "country": "UK",\n' +
            '        "id": "0Hh4H0000004CZPSA2",\n' +
            '        "latitude": 51.47054,\n' +
            '        "longitude": -0.41452,\n' +
            '        "name": "Heathrow",\n' +
            '        "operatingHoursId": "0OH4H0000004Ch2WAE",\n' +
            '        "postalCode": "TW6 2SQ",\n' +
            '        "state": "Middlesex",\n' +
            '        "street": "Hilton Garden Inn\\r\\nLondon Heathrow Airport\\r\\nEastern Perimeter Road\\r\\nHatton Cross"\n' +
            '      }\n' +
            '    ]\n' +
            '  }\n' +
            '}';
    //endregion

    //region GET_AVAILABLE_TERRITORY_SLOTS_RESPONSE
    public static final String GET_AVAILABLE_TERRITORY_SLOTS_RESPONSE = '{\n' +
            '  "result": {\n' +
            '    "territorySlots": [\n' +
            '      {\n' +
            '        "slots": [\n' +
            '          {\n' +
            '            "endTime": "2021-03-15T10:20:00.000Z",\n' +
            '            "resources": [\n' +
            '              "0Hn4H000000CbaOSAS",\n' +
            '              "0Hn4H000000CbaTSAS",\n' +
            '              "0Hn4H000000CbaYSAS",\n' +
            '              "0Hn4H000000Cba4SAC",\n' +
            '              "0Hn4H000000CbaJSAS"\n' +
            '            ],\n' +
            '            "startTime": "2021-03-15T10:10:00.000Z"\n' +
            '          },\n' +
            '          {\n' +
            '            "endTime": "2021-03-15T10:30:00.000Z",\n' +
            '            "resources": [\n' +
            '              "0Hn4H000000CbaOSAS",\n' +
            '              "0Hn4H000000CbaTSAS",\n' +
            '              "0Hn4H000000CbaYSAS",\n' +
            '              "0Hn4H000000Cba4SAC",\n' +
            '              "0Hn4H000000CbaJSAS"\n' +
            '            ],\n' +
            '            "startTime": "2021-03-15T10:20:00.000Z"\n' +
            '          }\n' +
            '        ],\n' +
            '        "territoryId": "0Hh4H0000004CZJSA2"\n' +
            '      },\n' +
            '      {\n' +
            '        "slots": [\n' +
            '          {\n' +
            '            "endTime": "2021-03-15T10:20:00.000Z",\n' +
            '            "resources": [\n' +
            '              "0Hn4H000000CbaUSAS"\n' +
            '            ],\n' +
            '            "startTime": "2021-03-15T10:10:00.000Z"\n' +
            '          },\n' +
            '          {\n' +
            '            "endTime": "2021-03-15T10:40:00.000Z",\n' +
            '            "resources": [\n' +
            '              "0Hn4H000000CbaPSAS",\n' +
            '              "0Hn4H000000CbaUSAS"\n' +
            '            ],\n' +
            '            "startTime": "2021-03-15T10:30:00.000Z"\n' +
            '          }\n' +
            '        ],\n' +
            '        "territoryId": "0Hh4H0000004CZFSA2"\n' +
            '      },\n' +
            '      {\n' +
            '        "slots": [],\n' +
            '        "territoryId": "0Hh4H0000004CZTSA2"\n' +
            '      },\n' +
            '      {\n' +
            '        "slots": [],\n' +
            '        "territoryId": "0Hh4H0000004CZPSA2"\n' +
            '      }\n' +
            '    ]\n' +
            '  }\n' +
            '}';
    //endregion

    //region BOOK_APPOINTMENT_RESPONSE
    public static final String BOOK_APPOINTMENT_RESPONSE = '{\n' +
            '  "result": {\n' +
            '    "assignedResourceIds": [\n' +
            '      "03r3H0000004YldQAE"\n' +
            '    ],\n' +
            '    "serviceAppointmentId": "08p3H000000ASeQQAW"\n' +
            '  }\n' +
            '}';
    //endregion

    //region LOGIN_RESPONSE
    public static final String LOGIN_RESPONSE = '<?xml version="1.0" encoding="UTF-8"?>\n' +
            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns="urn:partner.soap.sforce.com"\n' +
            '                  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n' +
            '    <soapenv:Body>\n' +
            '        <loginResponse>\n' +
            '            <result>\n' +
            '                <metadataServerUrl>\n' +
            '                    https://myhealthcareclinic--uat.my.salesforce.com/services/Soap/m/51.0/00D3H0000008luE\n' +
            '                </metadataServerUrl>\n' +
            '                <passwordExpired>false</passwordExpired>\n' +
            '                <sandbox>true</sandbox>\n' +
            '                <serverUrl>https://myhealthcareclinic--uat.my.salesforce.com/services/Soap/u/51.0/00D3H0000008luE\n' +
            '                </serverUrl>\n' +
            '                <sessionId>SESSION_ID_REMOVED</sessionId>\n' +
            '                <userId>0054H000006fz9RQAQ</userId>\n' +
            '                <userInfo>\n' +
            '                    <accessibilityMode>false</accessibilityMode>\n' +
            '                    <chatterExternal>false</chatterExternal>\n' +
            '                    <currencySymbol>£</currencySymbol>\n' +
            '                    <orgAttachmentFileSizeLimit>5242880</orgAttachmentFileSizeLimit>\n' +
            '                    <orgDefaultCurrencyIsoCode>GBP</orgDefaultCurrencyIsoCode>\n' +
            '                    <orgDefaultCurrencyLocale>en_GB</orgDefaultCurrencyLocale>\n' +
            '                    <orgDisallowHtmlAttachments>false</orgDisallowHtmlAttachments>\n' +
            '                    <orgHasPersonAccounts>true</orgHasPersonAccounts>\n' +
            '                    <organizationId>00D3H0000008luEUAQ</organizationId>\n' +
            '                    <organizationMultiCurrency>false</organizationMultiCurrency>\n' +
            '                    <organizationName>My Healthcare Clinic</organizationName>\n' +
            '                    <profileId>00e58000000tZT2AAM</profileId>\n' +
            '                    <roleId xsi:nil="true"/>\n' +
            '                    <sessionSecondsValid>7200</sessionSecondsValid>\n' +
            '                    <userDefaultCurrencyIsoCode xsi:nil="true"/>\n' +
            '                    <userEmail>david@anthologypartners.com</userEmail>\n' +
            '                    <userFullName>Anthology Partners</userFullName>\n' +
            '                    <userId>0054H000006fz9RQAQ</userId>\n' +
            '                    <userLanguage>en_US</userLanguage>\n' +
            '                    <userLocale>en_GB</userLocale>\n' +
            '                    <userName>myhealthcareclinic@anthologypartners.sfdc.uat</userName>\n' +
            '                    <userTimeZone>Europe/London</userTimeZone>\n' +
            '                    <userType>Standard</userType>\n' +
            '                    <userUiSkin>Theme3</userUiSkin>\n' +
            '                </userInfo>\n' +
            '            </result>\n' +
            '        </loginResponse>\n' +
            '    </soapenv:Body>\n' +
            '</soapenv:Envelope>';
    //endregion

    public static List<Account> createPersonAccounts(Integer count, Boolean save) {
        List<Account> results = new List<Account>();
        for (Integer x = 0; x < count; x++) {
            results.add(
                    new Account(
                            FirstName = 'First' + String.valueOf(x),
                            LastName = 'Last' + String.valueOf(x),
                            PersonEmail = 'someone' + String.valueOf(x) + '@example.com',
                            RecordTypeId = Cache.recordTypeId(AccountManager.RT_PERSON_ACCOUNT),
                            BillingCity = 'BillingCity',
                            BillingCountry = 'BillingCountry',
                            BillingPostalCode = '600075',
                            BillingState = 'BillingState',
                            BillingStreet = 'BillingStreet',
                            ShippingCity = 'ShippingCity',
                            ShippingCountry = 'ShippingCountry',
                            ShippingPostalCode = '897649',
                            ShippingState = 'ShippingState',
                            ShippingStreet = 'ShippingStreet',
                            Phone = '12345566',
                            Fax = '12345566',
                            PersonMobilePhone = '12345566'
                    )
            );
        }
        if (save) {
            insert results;
        }
        return results;
    }

    public static List<Opportunity> createOpportunities(List<Account> parents, Integer count, Boolean save) {
        List<Opportunity> results = new List<Opportunity>();
        for (Account parent : parents) {
            for (Integer x = 0; x < count; x++) {
                results.add(
                        new Opportunity(
                                AccountId = parent.Id,
                                LeadSource = 'Did Not Obtain',
                                CloseDate = Date.today(),
                                StageName = 'Closed Won',
                                Site__c = 'Home',
                                Business_Unit__c = 'Covid-19 testing',
                                Mode__c = 'Online Booking'
                        )
                );
        }

        }
        if (save) {
            insert results;
        }
        return results;
    }

    public static List<COVID_Test__c> createCovidTests(List<Account> parents, Integer count, Boolean save) {
        List<COVID_Test__c> results = new List<COVID_Test__c>();
        for (Account parent : parents) {
            for (Integer x = 0; x < count; x++) {
                results.add(
                        new COVID_Test__c(
                                Patient__c = parent.Id,
                                Test_Type__c = 'Rapid Test'
                        )
                );
            }
        }
        if (save) {
            insert results;
        }
        return results;
    }

    public static OnlineStoreSettings__c getOnlineStoreSettings() {

        User user;

        List<User> users = [SELECT ID From User LIMIT 1];

        if (users.size()==0) {

            user = new User();
            user.Username = 'userName@example.com';
            user.Email = 'email@example.com';
            user.FirstName = 'firstName';
            user.LastName = 'lastName';
            user.CommunityNickname = 'communityNickname';
            user.Alias = 'alias';
            user.TimeZoneSidKey = 'Europe/London';
            user.LocaleSidKey = 'en_US';
            user.EmailEncodingKey = 'UTF-8';
            user.LanguageLocaleKey = 'en_US';
            user.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id;
            insert user;
        }
        else user = users[0];

        OnlineStoreSettings__c onlineStoreSettings = OnlineStoreSettings__c.getInstance();

        onlineStoreSettings.Username__c = 'testu';
        onlineStoreSettings.Password__c = 'testp';
        onlineStoreSettings.Login_URL__c = 'https://test.salesforce.com';
        onlineStoreSettings.Stripe_URL__c = 'https://api.stripe.com/v1';
        onlineStoreSettings.Stripe_Private_Key__c = '12312312312';
        onlineStoreSettings.Stripe_Public_Key__c = 'qqwewq423423';
        onlineStoreSettings.Stripe_Cancel_URL__c = 'https://uat-myhealthcareclinic.cs122.force.com/checkout/PaymentTestPage?opid={0}';
        onlineStoreSettings.Stripe_Success_URL__c = 'https://uat-myhealthcarecommunity.cs122.force.com/booking/s/teststripe?success=true';
        onlineStoreSettings.Stripe_Payment_Method_Types__c = 'card';
        onlineStoreSettings.Default_Home_Test_Results_Queue__c = user.Id;

        return onlineStoreSettings;
    }

    public static Randox_Auth_Provider__mdt getRandoxAuthProviders() {
        return (Randox_Auth_Provider__mdt) JSON.deserialize(RANDOX_AUTH_PROVIDER_JSON, Randox_Auth_Provider__mdt.class);
    }
}