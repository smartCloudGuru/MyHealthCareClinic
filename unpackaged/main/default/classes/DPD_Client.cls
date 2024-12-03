/**
 * Created 2.11.2021..
 */

/*
See DPD API Integration Specification v3.2.pdf
 */
public without sharing class DPD_Client {

    /**
     * Do login to DPD
     * provide Basic auth
     * expect GeoSession in response
     * if successful, save GeoSession to custom config
     *
     * @return
     */
    public static String login() {

        DPD_Configuration__c config = [
                SELECT Id,
                        Api_Url__c,
                        Account_Id__c,
                        Username__c,
                        Password__c
                FROM DPD_Configuration__c
                LIMIT 1
        ];

        HttpRequest req = new HttpRequest();
        String url = config.Api_Url__c + '/user/?action=login';
        req.setEndpoint(url);

        Blob headerValue = Blob.valueOf(config.Username__c + ':' + config.Password__c);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authorizationHeader);
        req.setHeader('Accept', '*/*');

        req.setMethod('POST');
        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug(res.getBody());

        if (res != null && res.getBody() != null) {
            DpdApiResponse resp = null;

            try {
                resp = (DpdApiResponse) JSON.deserialize(res.getBody(), DpdApiResponse.class);
            }
            catch (Exception ex) {
                System.debug(LoggingLevel.ERROR, 'Unexpected response: ' + res.getBody());
                System.debug(LoggingLevel.ERROR, ex.getMessage());
            }

            if (resp != null && resp.data != null & resp.data.geoSession != null) {
                return resp.data.geoSession;
            }
        }

        return null;
    }


    //    /**
    //     * Example response
    //     * [{"service":{"serviceDescription":"Sunday","serviceCode":"1^16"}},{..}}]
    //     *
    //     * @param toPostalCode
    //     * @param fromPostalCode
    //     *
    //     * @return String, JSON list of services
    //     */
    //    public static String listServices(String toPostalCode, String fromPostalCode) {
    //
    //        DPD_Configuration__c config = [
    //                SELECT
    //                        Api_Url__c,
    //                        Account_Id__c,
    //                        GeoSession__c
    //                FROM DPD_Configuration__c
    //                LIMIT 1
    //        ];
    //
    //        String url = config.Api_Url__c
    //                + '/shipping/network/'
    //                + '?businessUnit=0'
    //                + '&deliveryDirection=1'
    //                + '&numberOfParcels=1'
    //                + '&shipmentType=0'
    //                + '&totalWeight=1.0'
    //                + '&deliveryDetails.address.countryCode=GB'
    //                + '&deliveryDetails.address.postcode=' + EncodingUtil.urlEncode(toPostalCode, 'UTF-8')
    //                + '&collectionDetails.address.countryCode=GB'
    //                + '&collectionDetails.address.postcode=' + EncodingUtil.urlEncode(fromPostalCode, 'UTF-8');
    //
    //        HttpRequest req = new HttpRequest();
    //        req.setEndpoint(url);
    //
    //        req.setHeader('GeoClient', 'account/' + config.Account_Id__c);
    //        req.setHeader('GeoSession', config.GeoSession__c);
    //        req.setHeader('Accept', '*/*');
    //
    //        req.setMethod('GET');
    //        Http http = new Http();
    //        HttpResponse res = http.send(req);
    //
    //        System.debug(res.getBody());
    //
    //        if (res != null && res.getBody() != null) {
    //            DpdApiResponseListServices resp = (DpdApiResponseListServices) JSON.deserialize(res.getBody(), DpdApiResponseListServices.class);
    //
    //            if (resp != null && resp.data != null) {
    //                List<DpdApiResponseListService> services = resp.data;
    //                return JSON.serialize(services);
    //            }
    //        }
    //
    //        return '[]';
    //    }

    /**
     * Insert Shipment
     * URL=POST:/shipping/shipment
     * Creates a shipment object
     *
     * @param params
     *
     * @return String
     */
    @AuraEnabled
    public static String insertShipment(String params) {

        String geoSession = login();

        if (geoSession == null) {
            return null; // todo return error
        }

        System.debug('::insertShipment:geoSession:' + geoSession);

        InsertShipmentRequest isRequest = (InsertShipmentRequest) JSON.deserialize(params, InsertShipmentRequest.class);

        Opportunity opp = [
                SELECT Id,
                        Online_Order_Number__c,
                        Online_Shipping_First_Name__c,
                        Online_Shipping_Last_Name__c,
                        Online_Shipping_Phone__c,
                        Online_Shipping_Email__c,
                        Online_Shipping_Postcode__c,
                        Online_Shipping_Address_Line_1__c,
                        Online_Shipping_Address_Line_2__c,
                        Online_Shipping_City__c,
                        Online_Shipping_County__c,
                        Delivery_Type__c,
                        Package_Weight__c,
                        Delivery_Product__r.ProductCode
                FROM Opportunity
                WHERE Id = :isRequest.oppId
                LIMIT 1
        ];

        DPD_Configuration__c config = [
                SELECT
                        Api_Url__c,
                        Account_Id__c
                FROM DPD_Configuration__c
                LIMIT 1
        ];

        if (opp.Online_Shipping_County__c == null) opp.Online_Shipping_County__c = '';

        String url = config.Api_Url__c + '/shipping/shipment';

        // move the collection date to next day if midday has pased
        Datetime collectionDate = Datetime.now();
        if (collectionDate.hour() >= 12) collectionDate = collectionDate.addHours(24);
        String formatted_collectionDate = collectionDate.format('yyyy-MM-dd\'T\'HH:mm:ss');
        formatted_collectionDate = formatted_collectionDate.substring(0, 11) + '15:00:00';

        String networkCode = '';

        //todo deprecated, used only until all opportunities moved to the new, Product based calcualtion
        if (opp.Delivery_Type__c != null) {
            switch on opp.Delivery_Type__c {
                when 'EXPRESSPAK Next Day' {
                    networkCode = '1^32';
                }
                when 'EXPRESSPAK Saturday' {
                    networkCode = '1^36';
                }
                when 'EXPRESSPAK Sunday' {
                    networkCode = '1^09';
                }
                when else {
                    networkCode = '1^32';
                }
            }
        }
        else if (opp.Delivery_Product__c != null) {
            networkCode = opp.Delivery_Product__r.ProductCode;
        }
        else {
            networkCode = '1^32';
        }

        String body = '{\n' +
                '    "jobId": null,\n' +
                '    "collectionOnDelivery": false,\n' +
                '    "invoice": null,\n' +
                '    "consolidate": false,\n' +
                '    "collectionDate": "' + formatted_collectionDate + '",\n' +
                '    "consignment": [\n' +
                '        {\n' +
                '            "consignmentNumber": null,\n' +
                '            "consignmentRef": null,\n' +
                '            "parcel": [],\n' +
                '            "collectionDetails": {\n' +
                '                "contactDetails": {\n' +
                '                    "contactName": "DUSH GUNASEKERA",\n' +
                '                    "telephone": "0207 099 5555"\n' +
                '                },\n' +
                '                "address": {\n' +
                '                    "organisation": "MYHEALTHCARE CLINIC LTD",\n' +
                '                    "countryCode": "GB",\n' +
                '                    "postcode": "SW181TW",\n' +
                '                    "street": "Juniper Drive",\n' +
                '                    "locality": "Wandsworth",\n' +
                '                    "town": "London",\n' +
                '                    "county": "London"\n' +
                '                }\n' +
                '            },\n' +
                '            "deliveryDetails": {\n' +
                '                "contactDetails": {\n' +
                '                    "contactName": "' + opp.Online_Shipping_First_Name__c + ' ' + opp.Online_Shipping_Last_Name__c + '",\n' +
                '                    "telephone": "' + ((opp.Online_Shipping_Phone__c==null)? '' : opp.Online_Shipping_Phone__c ) + '"\n' +
                '                },\n' +
                '                "address": {\n' +
                '                    "organisation": "' + opp.Online_Shipping_First_Name__c + ' ' + opp.Online_Shipping_Last_Name__c + '",\n' +
                '                    "countryCode": "GB",\n' +
                '                    "postcode": "' + opp.Online_Shipping_Postcode__c + '",\n' +
                '                    "street": "' + opp.Online_Shipping_Address_Line_1__c + '",\n' +
                '                    "locality": "' + opp.Online_Shipping_Address_Line_2__c + '",\n' +
                '                    "county": "' + opp.Online_Shipping_County__c + '",\n' +
                '                    "town": "' + opp.Online_Shipping_City__c + '"\n' +
                '                },\n' +
                '                "notificationDetails": {\n' +
                '                    "email": "' + opp.Online_Shipping_Email__c + '",\n' +
                '                    "mobile": "' + ((opp.Online_Shipping_Phone__c==null)? '' : opp.Online_Shipping_Phone__c ) + '"\n' +
                '                }\n' +
                '            },\n' +
                '            "networkCode": "' + networkCode + '",\n' +
                '            "numberOfParcels": 1,\n' +
                '            "shippingRef1": "' + opp.Online_Order_Number__c + '",\n' +
                '            "shippingRef2": "",\n' +
                '            "shippingRef3": "",\n' +
                '            "totalWeight": ' + opp.Package_Weight__c + ',\n' +
                '            "customsValue": null,\n' +
                '            "deliveryInstructions": "",\n' +
                '            "parcelDescription": "",\n' +
                '            "liabilityValue": null,\n' +
                '            "liability": false\n' +
                '        }\n' +
                '    ]\n' +
                '}';


        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);

        req.setHeader('GeoClient', 'account/' + config.Account_Id__c);
        req.setHeader('GeoSession', geoSession);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', '*/*');

        req.setMethod('POST');
        System.debug(body);
        req.setBody(body);

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug(res.getBody());

        try {
            if (res != null && res.getBody() != null) {
                DpdApiResponse resp = (DpdApiResponse) JSON.deserialize(res.getBody(), DpdApiResponse.class);

                if (resp != null && resp.data != null) {

                    opp.Shipment_Id__c = resp.data.shipmentId;
                    if (resp.data.consignmentDetail != null && resp.data.consignmentDetail.get(0) != null) opp.Shipment_Consignment_No__c = resp.data.consignmentDetail.get(0).consignmentNumber;
                    update opp;
                    return opp.Shipment_Id__c;
                }
            }
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            //todo hide error from customer
            throw newAuraHandledException(e.getMessage() + '|DPD response: ' + res.getBody());
        }

        return null;
    }


    public static Exception newAuraHandledException(String msg) {
        AuraHandledException aEx = new AuraHandledException(msg);
        aEx.setMessage(msg);
        return aEx;
    }

    public class InsertShipmentRequest {
        public String oppId { get; set; }
    }

    public class DpdApiResponse {
        public DpdApiResponseError error { get; set; }
        public DpdApiResponseData data { get; set; }
    }

    public class DpdApiResponseError {

    }

    public class DpdApiResponseData {
        public String geoSession { get; set; }
        public String flag { get; set; }
        public String shipmentId { get; set; }
        public List<DppApiConsignmentDetail> consignmentDetail { get; set; }
    }

    //    public class DpdApiResponseListServices {
    //        public List<DpdApiResponseListService> data { get; set; }
    //    }
    //
    //    public class DpdApiResponseListService {
    //        public DpdApiService service;
    //    }

    //    public class DpdApiService {
    //        public String serviceCode { get; set; }
    //        public String serviceDescription { get; set; }
    //    }

    public class DppApiConsignmentDetail {
        public String consignmentNumber { get; set; }
    }


}