/**
 * Created 17.9.2022..
 */

@IsTest
public class GoCardlessServiceMock implements HttpCalloutMock {

    public static final String POST_CREATE_REDIRECT_FLOW_RESPONSE = '{' +
            '    "redirect_flows": {' +
            '        "id": "RE0004VYKH0N140C76G5264K7R09B0SR",' +
            '        "description": "MHC Membership",' +
            '        "session_token": "0be1e751-53cc-4767-b777-718264f52fb0",' +
            '        "scheme": null,' +
            '        "success_redirect_url": "https://myhealthcareclinic--uat.sandbox.my.salesforce-sites.com/signup?page=gcl",' +
            '        "created_at": "2022-09-15T09:56:45.808Z",' +
            '        "links": {' +
            '            "creditor": "CR00007716SXGG"' +
            '        },' +
            '        "metadata": {},' +
            '        "redirect_url": "https://pay-sandbox.gocardless.com/flow/RE0004VYKH0N140C76G5264K7R09B0SR"' +
            '    }' +
            '}';

    public static final String POST_COMPLETE_REDIRECT_FLOW_RESPONSE = '{' +
            '    "redirect_flows": {' +
            '        "id": "RE0004VYKH0N140C76G5264K7R09B0SR",' +
            '        "description": "MHC Membership",' +
            '        "session_token": "0be1e751-53cc-4767-b777-718264f52fb0",' +
            '        "scheme": "bacs",' +
            '        "success_redirect_url": "https://myhealthcareclinic--uat.sandbox.my.salesforce-sites.com/signup?page=gcl",' +
            '        "created_at": "2022-09-15T09:56:45.808Z",' +
            '        "links": {' +
            '            "creditor": "CR00007716SXGG",' +
            '            "mandate": "MD000NS2FN6HCT",' +
            '            "customer": "CU000PCHHGHEDN",' +
            '            "customer_bank_account": "BA000NR6ADMVX1"' +
            '        },' +
            '        "metadata": {},' +
            '        "confirmation_url": "https://pay-sandbox.gocardless.com/flow/RE0004VYKH0N140C76G5264K7R09B0SR/success",' +
            '        "mandate_reference": "ANTHOLOGYPAR-KM66R"' +
            '    }' +
            '}';

    public static final String POST_CREATE_SUBSCRIPTION_RESPONSE = '{' +
            '    "subscriptions": {' +
            '        "id": "SB0007Y16CMH84",' +
            '        "created_at": "2022-09-15T10:23:49.457Z",' +
            '        "amount": 2500,' +
            '        "currency": "GBP",' +
            '        "status": "active",' +
            '        "name": "MHC Membership Plan",' +
            '        "start_date": "2022-10-03",' +
            '        "end_date": "2023-09-04",' +
            '        "interval": 1,' +
            '        "interval_unit": "monthly",' +
            '        "day_of_month": 1,' +
            '        "month": null,' +
            '        "count": 12,' +
            '        "metadata": {' +
            '            "order_no": "MHC-ABCD1234"' +
            '        },' +
            '        "payment_reference": null,' +
            '        "upcoming_payments": [' +
            '            {' +
            '                "charge_date": "2022-10-03",' +
            '                "amount": 2500' +
            '            },' +
            '            {' +
            '                "charge_date": "2022-11-01",' +
            '                "amount": 2500' +
            '            },' +
            '            {' +
            '                "charge_date": "2022-12-01",' +
            '                "amount": 2500' +
            '            },' +
            '            {' +
            '                "charge_date": "2023-01-03",' +
            '                "amount": 2500' +
            '            },' +
            '            {' +
            '                "charge_date": "2023-02-01",' +
            '                "amount": 2500' +
            '            },' +
            '            {' +
            '                "charge_date": "2023-03-01",' +
            '                "amount": 2500' +
            '            },' +
            '            {' +
            '                "charge_date": "2023-04-03",' +
            '                "amount": 2500' +
            '            },' +
            '            {' +
            '                "charge_date": "2023-05-02",' +
            '                "amount": 2500' +
            '            },' +
            '            {' +
            '                "charge_date": "2023-06-01",' +
            '                "amount": 2500' +
            '            },' +
            '            {' +
            '                "charge_date": "2023-07-03",' +
            '                "amount": 2500' +
            '            }' +
            '        ],' +
            '        "app_fee": null,' +
            '        "links": {' +
            '            "mandate": "MD000NS2FN6HCT"' +
            '        },' +
            '        "retry_if_possible": false,' +
            '        "earliest_charge_date_after_resume": null' +
            '    }' +
            '}';

    public static final String GET_SUBSCRIPTIONS_RESPONSE = '{\n' +
            '    "subscriptions": [\n' +
            '        {\n' +
            '            "id": "SB000A3VVBCG14",\n' +
            '            "created_at": "2023-06-30T09:15:51.378Z",\n' +
            '            "amount": 6500,\n' +
            '            "currency": "GBP",\n' +
            '            "status": "active",\n' +
            '            "name": "MHC Premium Plan",\n' +
            '            "start_date": "2023-07-31",\n' +
            '            "end_date": null,\n' +
            '            "interval": 1,\n' +
            '            "interval_unit": "monthly",\n' +
            '            "day_of_month": null,\n' +
            '            "month": null,\n' +
            '            "count": null,\n' +
            '            "metadata": {\n' +
            '                "order_no": "MSF-000070"\n' +
            '            },\n' +
            '            "payment_reference": null,\n' +
            '            "upcoming_payments": [\n' +
            '                {\n' +
            '                    "charge_date": "2024-07-31",\n' +
            '                    "amount": 6500\n' +
            '                },\n' +
            '                {\n' +
            '                    "charge_date": "2024-09-02",\n' +
            '                    "amount": 6500\n' +
            '                },\n' +
            '                {\n' +
            '                    "charge_date": "2024-09-30",\n' +
            '                    "amount": 6500\n' +
            '                },\n' +
            '                {\n' +
            '                    "charge_date": "2024-10-31",\n' +
            '                    "amount": 6500\n' +
            '                },\n' +
            '                {\n' +
            '                    "charge_date": "2024-12-02",\n' +
            '                    "amount": 6500\n' +
            '                },\n' +
            '                {\n' +
            '                    "charge_date": "2024-12-31",\n' +
            '                    "amount": 6500\n' +
            '                },\n' +
            '                {\n' +
            '                    "charge_date": "2025-01-31",\n' +
            '                    "amount": 6500\n' +
            '                },\n' +
            '                {\n' +
            '                    "charge_date": "2025-02-28",\n' +
            '                    "amount": 6500\n' +
            '                },\n' +
            '                {\n' +
            '                    "charge_date": "2025-03-31",\n' +
            '                    "amount": 6500\n' +
            '                },\n' +
            '                {\n' +
            '                    "charge_date": "2025-04-30",\n' +
            '                    "amount": 6500\n' +
            '                }\n' +
            '            ],\n' +
            '            "app_fee": null,\n' +
            '            "links": {\n' +
            '                "mandate": "MD000TZPZR5R3B"\n' +
            '            },\n' +
            '            "retry_if_possible": false,\n' +
            '            "earliest_charge_date_after_resume": null,\n' +
            '            "parent_plan_paused": false\n' +
            '        }\n' +
            '    ],\n' +
            '    "meta": {\n' +
            '        "cursors": {\n' +
            '            "before": null,\n' +
            '            "after": null\n' +
            '        },\n' +
            '        "limit": 500\n' +
            '    }\n' +
            '}';

public static final String GET_MANDATES_RESPONSE = '{\n' +
        '    "mandates": [\n' +
        '        {\n' +
        '            "id": "MD000TZPZR5R3B",\n' +
        '            "created_at": "2023-06-30T09:15:50.987Z",\n' +
        '            "reference": "ANTHOLOGYPAR-C4CMS",\n' +
        '            "status": "active",\n' +
        '            "scheme": "bacs",\n' +
        '            "next_possible_charge_date": "2024-07-09",\n' +
        '            "payments_require_approval": false,\n' +
        '            "metadata": {},\n' +
        '            "links": {\n' +
        '                "customer_bank_account": "BA000V2PRJ5TEA",\n' +
        '                "creditor": "CR00007716SXGG",\n' +
        '                "customer": "CU000XCJ8NVE0Q"\n' +
        '            },\n' +
        '            "consent_parameters": null,\n' +
        '            "verified_at": null,\n' +
        '            "funds_settlement": "managed"\n' +
        '        },\n' +
        '        {\n' +
        '            "id": "MD000R9DZK8KHF",\n' +
        '            "created_at": "2023-02-02T19:32:46.517Z",\n' +
        '            "reference": "ANTHOLOGYPAR-92SK5",\n' +
        '            "status": "active",\n' +
        '            "scheme": "bacs",\n' +
        '            "next_possible_charge_date": "2024-07-09",\n' +
        '            "payments_require_approval": false,\n' +
        '            "metadata": {},\n' +
        '            "links": {\n' +
        '                "customer_bank_account": "BA000RBEGMZ6XX",\n' +
        '                "creditor": "CR00007716SXGG",\n' +
        '                "customer": "CU000S8NZT43YX"\n' +
        '            },\n' +
        '            "consent_parameters": null,\n' +
        '            "verified_at": null,\n' +
        '            "funds_settlement": "managed"\n' +
        '        }\n' +
        '    ],\n' +
        '    "meta": {\n' +
        '        "cursors": {\n' +
        '            "before": null,\n' +
        '            "after": null\n' +
        '        },\n' +
        '        "limit": 50\n' +
        '    }\n' +
        '}';

    public static void setAsMock() {
        Test.setMock(HttpCalloutMock.class, new GoCardlessServiceMock(true));
    }

    public static void setFailMock() {
        Test.setMock(HttpCalloutMock.class, new GoCardlessServiceMock(false));
    }

    private Boolean succeed;

    private GoCardlessServiceMock(Boolean succeed) {
        this.succeed = succeed;
    }

    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(this.succeed ? 200 : 404);

        System.debug('::GCMock:body' + req.getBody());

        if (req.getMethod() == 'POST' && req.getEndpoint().contains('/redirect_flows') && req.getEndpoint().contains('/actions/complete'))
        {
            res.setBody(POST_COMPLETE_REDIRECT_FLOW_RESPONSE);
        }
        else if (req.getMethod() == 'POST' && req.getEndpoint().contains('/redirect_flows'))
        {
            res.setBody(POST_CREATE_REDIRECT_FLOW_RESPONSE);
        }
        else if (req.getMethod() == 'GET' && req.getEndpoint().contains('/subscriptions'))
        {
            res.setBody(GET_SUBSCRIPTIONS_RESPONSE);
        }
        else if (req.getMethod() == 'GET' && req.getEndpoint().contains('/mandates'))
        {
            res.setBody(GET_MANDATES_RESPONSE);
        }
        else if (req.getMethod() == 'POST' && req.getEndpoint().contains('/subscriptions'))
        {
            res.setBody(POST_CREATE_SUBSCRIPTION_RESPONSE);
        }
        else {

        }

        return res;
    }
}