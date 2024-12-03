@IsTest
public class HeyDocServiceMock implements HttpCalloutMock {
    public static final Integer MOCK_RESULT_COUNT = 1;
    public static final String MOCK_HEYDOC_PATIENT_ID = '5fbd1955d9aa7d001170fcb6';
    private static final String MOCK_DATA = '{"data":{"bookings":{"data":[{"id":"5fbd195dd9aa7d001170fcde","cancellationReason":null,"doctorName":"Doc","start":"2020-12-08T08:00:00.000Z","end":"2020-12-08T08:10:00.000Z","patientId":"5fbd1955d9aa7d001170fcb6","createdAt":"2020-11-24T14:31:57.618Z","appointment":{"title":"PCR Swab Test - Fit to Fly ","duration":10,"price":149},"bookingJourney":{"arrived":"2020-12-08T07:55:36.901Z","consultation":null,"departed":"2020-12-08T08:18:21.467Z","dna":null},"patient":{"id":"5fbd1955d9aa7d001170fcb6","status":"active","firstName":"TEST","lastName":"TEST","dob":"2020-12-08T08:00:00.000Z","gender":"female","sex":"","email":"test@test.co.uk","occupation":"","membershipName":null,"membershipStartDate":null,"accountNumber":"","phones":[{"phoneType":"Mobile","phoneNumber":"070000000"}],"address":{"address":"ROAD ","city":"CITY","postcode":"POST","country":"GB"}}}],"pageInfo":{"page":1,"pageSize":1}}}}';
    private static final String MOCK_CREATE_PATIENT_DOCUMENT_RESPONSE = '{  "data": {\n' +
    '        "createPatientDocument": { "data": { "id": "645a1ae9c31e04001101df69",\n' +
            '                "title": null, "patientId": null, "path": "/",\n' +
            '                "name": "test1.pdf", "type": "application/pdf",\n' +
            '                "url": "626805c30699f5001240bded/628f2e803b0b410012caaf4e/645a1ae9c31e04001101df69.pdf",\n' +
            '                "uploadUrl": "https://s3.eu-west-2.amazonaws.com/app102938",\n' +
            '                "downloadUrl": "https://s3.eu-west-2.amazonaws.com/appw3409283"\n' +
            '            }, "error": null } } }';

    private static final String MOCK_QUERY_INVOICES_RESP = '{\n' +
            '  "data": {' +
            '    "invoices": {' +
            '      "data": [{"id":"6491d0745b7ab50012ebaee2","status":"active","date":"2023-06-20T00:00:00.000Z","patientId":"6491ad67b0a15e0012e9aef5","total":250,"outstanding":0,"lineItems":[{"title":"Ozempic (250mcg, 500mcg, 1mg) - 1 month supply","productType":"medication","itemCode":""}],"paymentReference":null,"invoiceNumber":1297039,"payeeDetails":"Deidre Test\\nFulham\\nLondon, SW6\\nUnited Kingdom","comments":"TEST","extraInfo":"TEST","type":"invoice"}], ' +
            '      "pageInfo": { "page": 1, "pageSize": 1 }' +
            '    }\n' +
            '  }\n' +
            '}';

    private static final String MOCK_QUERY_BOOKINGS_RESP = '{\n' +
            '    "data": {\n' +
            '        "bookings": {\n' +
            '            "data": [\n' +
            '                {\n' +
            '                    "id": "mock_hd_book_id",\n' +
            '                    "deleted": false,\n' +
            '                    "cancellationReason": "abc123",\n' +
            '                    "doctorName": "xyz789",\n' +
            '                    "doctor": {\n' +
            '                        "id": "mock_doc_id",\n' +
            '                        "firstName": "xyz789",\n' +
            '                        "lastName": "xyz789",\n' +
            '                        "email": "abc123",\n' +
            '                        "fullName": "abc123",\n' +
            '                        "isDoctor": false\n' +
            '                    },\n' +
            '                    "location": {\n' +
            '                        "id": "mock_hd_loc_id",\n' +
            '                        "header": "xyz789",\n' +
            '                        "name": "xyz789"\n' +
            '                    },\n' +
            '                    "appointment": {\n' +
            '                        "title": "abc123",\n' +
            '                        "duration": 987,\n' +
            '                        "price": 123,\n' +
            '                        "id": "mock_hd_app_ip"\n' +
            '                    },\n' +
            '                    "start": "2022-03-28T15:03:34.841Z",\n' +
            '                    "end": "2022-03-28T15:03:34.841Z",\n' +
            '                    "patient": {\n' +
            '                        "id": "5fbd1955d9aa7d001170fcb6",\n' +
            '                        "title": "abc123",\n' +
            '                        "status": "abc123",\n' +
            '                        "firstName": "xyz789",\n' +
            '                        "lastName": "xyz789",\n' +
            '                        "fullName": "xyz789",\n' +
            '                        "dob": "2021-09-28T15:03:34.841Z",\n' +
            '                        "gender": "abc123",\n' +
            '                        "sex": "xyz789",\n' +
            '                        "email": "xyz789@example.com",\n' +
            '                        "googleClientId": "abc123",\n' +
            '                        "paymentReference": "xyz789",\n' +
            '                        "phones": [\n' +
            '                            {\n' +
            '                                "phoneId": "mock_hd_phone_id",\n' +
            '                                "phoneType": "abc123",\n' +
            '                                "phoneNumber": "xyz789"\n' +
            '                            }\n' +
            '                        ],\n' +
            '                        "occupation": "xyz789",\n' +
            '                        "address": {\n' +
            '                            "address": "abc123",\n' +
            '                            "city": "xyz789",\n' +
            '                            "postcode": "xyz789",\n' +
            '                            "country": "xyz789"\n' +
            '                        },\n' +
            '                        "membershipName": "xyz789",\n' +
            '                        "membershipStartDate": "abc123",\n' +
            '                        "createdAt": "2021-09-28T15:03:34.841Z",\n' +
            '                        "updatedAt": "2021-09-28T15:03:34.841Z"\n' +
            '                    },\n' +
            '                    "patientId": "5fbd1955d9aa7d001170fcb6",\n' +
            '                    "bookingJourney": {\n' +
            '                        "arrived": "2021-09-28T15:03:34.841Z",\n' +
            '                        "consultation": "2021-09-28T15:03:34.841Z",\n' +
            '                        "departed": "2022-03-28T15:03:34.841Z",\n' +
            '                        "dna": "2022-03-28T15:03:34.841Z"\n' +
            '                    },\n' +
            '                    "createdAt": "2021-09-28T15:03:34.841Z",\n' +
            '                    "updatedAt": "2021-09-28T15:03:34.841Z",\n' +
            '                    "videoUrl": "abc123",\n' +
            '                    "comments": "abc123",\n' +
            '                    "reference": "xyz789"\n' +
            '                }\n' +
            '            ],\n' +
            '            "pageInfo": {\n' +
            '                "page": 1,\n' +
            '                "pageSize": 1\n' +
            '            }\n' +
            '        }\n' +
            '    }\n' +
            '}';
    private static final String MOCK_AUTH = '{"data":{"signIn":{"token":"token"}}}';
    private static final String MOCK_CREATE_PATIENT_RESP = '{\n' +
            '    "data": {\n' +
            '        "createPatient": {\n' +
            '            "data": {\n' +
            '                "id": "5fbd1955d9aa7d001170fcb6"\n' +
            '            },\n' +
            '            "error": null\n' +
            '        }\n' +
            '    }\n' +
            '}';
    private static final String MOCK_UPDATE_PATIENT_RESP = '{\n' +
            '    "data": {\n' +
            '        "updatePatient": {\n' +
            '            "data": {\n' +
            '                "id": "5fbd1955d9aa7d001170fcb6"\n' +
            '            },\n' +
            '            "error": null\n' +
            '        }\n' +
            '    }\n' +
            '}';
    private static final String MOCK_CREATE_BOOKING_RESP = '{\n' +
            '    "data": {\n' +
            '        "createBooking": {\n' +
            '            "data": {\n' +
            '                "id": "mock_hd_book_id"\n' +
            '            },\n' +
            '            "error": null\n' +
            '        }\n' +
            '    }\n' +
            '}';

    private static final String MOCK_UPDATE_BOOKING_RESP = '{\n' +
            '    "data": {\n' +
            '        "updateBooking": {\n' +
            '            "data": {\n' +
            '                "id": "mock_hd_book_id"\n' +
            '            },\n' +
            '            "error": null\n' +
            '        }\n' +
            '    }\n' +
            '}';

    private static final String MOCK_QUERY_PATIENT_RESP = '{\n' +
            '  "data": {\n' +
            '    "patient": {\n' +
            '      "id": "4",\n' +
            '      "title": "abc123",\n' +
            '      "bookings":[{"id" : "b1id"}],\n'+
            '      "status": "abc123",\n' +
            '      "firstName": "xyz789",\n' +
            '      "lastName": "xyz789",\n' +
            '      "fullName": "abc123",\n' +
            '      "dob": "2007-12-03",\n' +
            '      "gender": "abc123",\n' +
            '      "sex": "abc123",\n' +
            '      "email": "xyz789@example.com",\n' +
            '      "googleClientId": "xyz789",\n' +
            '      "paymentReference": "xyz789",\n' +
            '      "phones": [{ "phoneId":"somephoneid", "phoneType" : "Mobile", "phoneNumber":"123456789"}],\n' +
            '      "occupation": "abc123",\n' +
            '      "membershipName": "abc123",\n' +
            '      "membershipStartDate": "xyz789",\n' +
            '      "createdAt": "2007-12-03",\n' +
            '      "updatedAt": "2007-12-03",\n' +
            '      "comments": "abc123"\n' +
            '    }\n' +
            '  }\n' +
            '}';

    private static final String MOCK_ADD_PATIENTPHONENO_RESP = '{"data": {"addPatientPhoneNumber": {"data": {"id": "someid"}}}}';

    private static final String MOCK_UPDATE_PATIENTPHONENO_RESP = '{"data": {"updatePatientPhoneNumber": {"data": {"id": "someptid"}}}}';

    private static final String MOCK_REMOVE_PATIENTPHONENO_RESP = '{"data": {"removePatientPhoneNumber": {"data": {"id": "someptid"}}}}';

    private static final String MOCK_QUERY_PATIENTS_RESP = '{"data":{"patients":{"data":[{"id":"5fbd1955d9aa7d001170fcb6","status":"active","firstName":"Hdmock","lastName":"Martin","dob":"1998-08-04T00:00:00.000Z","email":"test2map@example.com","gender":"female","address":{"address":"5 Air Street","city":"London","postcode":"W1J 0AD","country":"GB"},"phones":[{"phoneType":"Mobile","phoneNumber":"08123456789"}],"updatedAt":"2022-03-28T13:19:05.213Z"}],"pageInfo":{"hasMore":false}}}}';

    private static final String MOCK_CREATE_INVOICE_RESP = '{"data": {"createInvoice": {"data": {"id": "someid"}}}}';

    private static final String MOCK_QUERY_PRODUCTS_RESP = '{"data":{"products":{"data":[{"id":"62975905169aa30012e30f5c","productType":"other","name":"Blood Test Fee","price":35,"itemCode":"4015 VAT E","supplierName":"","duration":0,"isBookable":false,"cost":0,"comments":"","isVideoConsultation":false},{"id":"628cccf938d6600013a74b08","productType":"appointment","name":"Ultrasound - Harmony pre natal blood test & Scan","price":475,"itemCode":"4016 VAT E","supplierName":"","duration":30,"isBookable":true,"cost":0,"comments":"","isVideoConsultation":false},{"id":"628ccddf99284c0012ad643d","productType":"appointment","name":"Ultrasound - Harmony pre natal blood test EXCLUDING SCAN (with GP or Nurse)","price":425,"itemCode":"4016 VAT E","supplierName":"","duration":30,"isBookable":true,"cost":0,"comments":"","isVideoConsultation":false}],"pageInfo":{"hasMore":false}}}}';

    public static void setAsMock() {
        Test.setMock(HttpCalloutMock.class, new HeyDocServiceMock(true));
    }

    public static void setFailMock() {
        Test.setMock(HttpCalloutMock.class, new HeyDocServiceMock(false));
    }

    private Boolean succeed;

    private HeyDocServiceMock(Boolean succeed) {
        this.succeed = succeed;
    }

    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(this.succeed ? 200 : 404);

        System.debug('::HDMOCK:body' + req.getBody());

        if (req.getHeader('x-token') == null) {
            res.setBody(MOCK_AUTH);
        }
        else if (req.getBody().contains('mutation addPatientPhoneNumber')) {
            res.setBody(MOCK_ADD_PATIENTPHONENO_RESP);
        }
        else if (req.getBody().contains('mutation updatePatientPhoneNumber')) {
            res.setBody(MOCK_UPDATE_PATIENTPHONENO_RESP);
        }
        else if (req.getBody().contains('mutation removePatientPhoneNumber')) {
            res.setBody(MOCK_REMOVE_PATIENTPHONENO_RESP);
        }
        else if (req.getBody().contains(' createBooking')) {
            res.setBody(MOCK_CREATE_BOOKING_RESP);
        }
        else if (req.getBody().contains('query bookings')) {
            res.setBody(MOCK_QUERY_BOOKINGS_RESP);
        }
        else if (req.getBody().contains('query invoices')) {
            res.setBody(MOCK_QUERY_INVOICES_RESP);
        }
        else if (req.getBody().contains('mutation createPatientDocument')) {
            res.setBody(MOCK_CREATE_PATIENT_DOCUMENT_RESPONSE);
        }
        else if (req.getBody().contains(' createPatient')) {
            res.setBody(MOCK_CREATE_PATIENT_RESP);
        }
        else if (req.getBody().contains(' updatePatient')) {
            res.setBody(MOCK_UPDATE_PATIENT_RESP);
        }
        else if (req.getBody().contains(' updateBooking(')) {
            res.setBody(MOCK_UPDATE_BOOKING_RESP);
        }
        else if (req.getBody().contains('query patients(')) {
            res.setBody(MOCK_QUERY_PATIENTS_RESP);
        }
        else if (req.getBody().contains('query patient(')) {
            res.setBody(MOCK_QUERY_PATIENT_RESP);
        }
        else if (req.getBody().contains(' createInvoice(')) {
            res.setBody(MOCK_CREATE_INVOICE_RESP);
        }
        else if (req.getBody().contains('query products(')) {
            res.setBody(MOCK_QUERY_PRODUCTS_RESP);
        }
        else {
            res.setBody(MOCK_DATA);
        }

        return res;
    }
}