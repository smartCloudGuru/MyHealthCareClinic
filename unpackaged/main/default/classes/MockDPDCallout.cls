/**
 * Created 2.11.2021..
 */

global class MockDPDCallout implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {

        String uri = '' + req.getEndpoint();

        if (uri.contains('action=login')) {

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"error": null,"data": {"geoSession": "11111111-83b7-2222-9740-333333333333","flag": "7"}}');
            res.setStatusCode(200);

            return res;
        }

        if (uri.contains('shipping/shipment')) {

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{\n' +
                    '    "error": null,\n' +
                    '    "data": {\n' +
                    '        "shipmentId": 777777777,\n' +
                    '        "consolidated": false,\n' +
                    '        "consignmentDetail": [\n' +
                    '            {\n' +
                    '                "consignmentNumber": "5555555555",\n' +
                    '                "parcelNumbers": [\n' +
                    '                    "11111111111111"\n' +
                    '                ]\n' +
                    '            }\n' +
                    '        ]\n' +
                    '    }\n' +
                    '}');
            res.setStatusCode(200);

            return res;
        }

        return null;
    }
}