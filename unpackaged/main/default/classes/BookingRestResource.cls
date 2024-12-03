/**
 * Created 18.5.2022..
 */

@RestResource(UrlMapping='/m/book/*')
global with sharing class BookingRestResource {

    @HttpGet
    global static void getRecord() {

        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        res.headers.put('Content-Type', 'application/json');

        try {
            System.debug(LoggingLevel.INFO, '::M:BookingRestResource:GET:requestURI: ' + req?.requestURI);

            String id = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);

            if (req.requestURI.containsIgnoreCase('/m/book/locations/product')) {
                String resp = JSON.serializePretty(OnlBookUI.getServiceCentersForProduct(id));
                res.responseBody = Blob.valueOf(resp);
                res.headers.put('Content-Type', 'application/json');
                res.statusCode = 200;
                System.debug(LoggingLevel.INFO, '::M:BookingRestResource:GET:resp: ' + resp);
            }
            else if (req.requestURI.containsIgnoreCase('/m/book/resources')) {
                System.debug('::M:BookingRestResource:resources:params=' + req.params);
                res.statusCode = 400;
                res.responseBody = Blob.valueOf(JSON.serializePretty(new MHCAPIResponse(400, 'Invalid query parameters')));

                if (req.params == null || req.params.get('wtgid') == null) {
                    System.debug(LoggingLevel.INFO, '::M:BookingRestResource:GET:resp: ' + 'Invalid query parameters');
                    return;
                }

                String toRet = JSON.serializePretty(OnlBookDomain.getServiceResourcesForWorkTypeGroupSkills(req.params.get('wtgid')));
                res.statusCode = 200;
                res.responseBody = Blob.valueOf(toRet);
                System.debug(LoggingLevel.INFO, '::M:BookingRestResource:GET:resp:timeslots: ' + toRet);
                return;

            }
            else if (req.requestURI.containsIgnoreCase('/m/book/timeslots')) {
                System.debug('::M:BookingRestResource:timeslots:params=' + req.params);
                res.statusCode = 400;
                res.responseBody = Blob.valueOf(JSON.serializePretty(new MHCAPIResponse(400, 'Invalid query parameters')));

                if (req.params == null || req.params.get('wtgid') == null) {
                    System.debug(LoggingLevel.INFO, '::M:BookingRestResource:GET:resp: ' + 'Invalid query parameters');
                    return;
                }

                if (req.params.get('date') == null && (req.params.get('dateFrom') == null || req.params.get('dateTo') == null)) {
                    System.debug(LoggingLevel.INFO, '::M:BookingRestResource:GET:resp: ' + 'Invalid query parameters');
                    return;
                }


                Date dte = null;
                Date dteFrom = null;
                Date dteTo = null;

                if (req.params.get('date') != null) dte = Date.valueOf(req.params.get('date'));
                if (req.params.get('dateFrom') != null) dteFrom = Date.valueOf(req.params.get('dateFrom'));
                if (req.params.get('dateTo') != null) dteTo = Date.valueOf(req.params.get('dateTo'));

                res.statusCode = 400;

                String wtgId = req.params.get('wtgid');
                String productId = req.params.get('productid');

                if (String.isNotBlank(productId)) {
                    List<Product2> prods = [SELECT Id, Work_Type_Group__c FROM Product2 WHERE Id = :productId AND IsActive = TRUE];
                    if (prods.isEmpty()) {
                        res.statusCode = 400;
                        res.responseBody = Blob.valueOf(JSON.serializePretty(new MHCAPIResponse(400, 'No such product with ID: ' + productId)));
                        System.debug(LoggingLevel.INFO, '::M:BookingRestResource:GET:resp: ' + 'No such product with ID: ' + productId);
                        return;
                    }
                    else {
                        wtgId = prods[0].Work_Type_Group__c;
                    }
                }

                String ret;
                if (dte != null) {
                    res.statusCode = 200;
                    ret = OnlBookUI.getAvailableSlots_raw(
                            wtgId, req.params.get('stid'), dte, dte
                    );
                    res.responseBody = Blob.valueOf(ret);
                }

                if (dteFrom != null && dteTo != null) {
                    res.statusCode = 200;
                    ret = OnlBookUI.getAvailableSlots_raw(
                            wtgId, req.params.get('stid'), dteFrom, dteTo
                    );
                    res.responseBody = Blob.valueOf(ret);
                }

                System.debug(LoggingLevel.INFO, '::M:BookingRestResource:GET:resp:timeslots: ' + ret);
            }
            else if (req.requestURI.containsIgnoreCase('/m/book/quote')) {

                if (req.params == null || req.params.size() < 2 || req.params.get('quoteid') == null || req.params.get('appid') == null) {
                    res.statusCode = 400;
                    res.responseBody = Blob.valueOf(JSON.serializePretty(new MHCAPIResponse(400, 'Invalid query parameters')));
                    System.debug(LoggingLevel.INFO, '::M:BookingRestResource:GET:resp: ' + 'Invalid query parameters');
                    return;
                }

                res.statusCode = 200;
                res.responseBody = Blob.valueOf(OnlBookUI.checkQuoteCalculated(req.params.get('quoteid'), req.params.get('appid')));
            }

        }
        catch (Exception ex) {
            System.debug(ex.getStackTraceString());
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serializePretty(new MHCAPIResponse(500, ex.getMessage())));
            System.debug(LoggingLevel.INFO, '::M:BookingRestResource:GET:resp: ' + ex.getMessage());
        }
    }

    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        res.headers.put('Content-Type', 'application/json');

        try {
            System.debug(LoggingLevel.INFO, '::M:BookingRestResource:POST:requestURI: ' + req?.requestBody?.toString());

            res.statusCode = 200;
            if (req.requestURI.endsWithIgnoreCase('/m/book')) {
                OnlBookUI.BookRequest bookRequest = (OnlBookUI.BookRequest) JSON.deserialize(req.requestBody.toString(), OnlBookUI.BookRequest.class);
                if (String.isEmpty(bookRequest.mode)) bookRequest.mode = 'Mobile Application';
                String resp = OnlBookUI.doBooking(JSON.serialize(bookRequest));
                res.responseBody = Blob.valueOf(resp);
                System.debug(LoggingLevel.INFO, '::M:BookingRestResource:POST:resp: ' + resp);
            }
            else if (req.requestURI.containsIgnoreCase('/m/book/confirm')) {
                String oppid = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
                String ret = OnlBookUI.closeOpportunity(oppid, false);
                res.responseBody = Blob.valueOf(JSON.serialize(new MHCAPIResponse(200, ret)));
                System.debug(LoggingLevel.INFO, '::M:BookingRestResource:POST:resp: ' + ret);
            }

        }
        catch (System.JSONException ex) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf(JSON.serialize(new MHCAPIResponse(400, 'Malformed JSON input')));
            System.debug(LoggingLevel.INFO, '::M:BookingRestResource:POST:resp: ' + 'Malformed JSON input');
        }
        catch (Exception ex) {

            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serializePretty(new MHCAPIResponse(500, ex.getMessage())));
            System.debug(LoggingLevel.INFO, '::M:BookingRestResource:POST:resp: ' + ex.getMessage());
        }
    }

    public class MHCAPIResponse {
        public Integer code;
        public String message;
        public Boolean error;

        public MHCAPIResponse() {
        }

        public MHCAPIResponse(Integer code, String message) {
            this.code = code;
            this.message = message;
            this.error = (code > 299);
        }
    }

}