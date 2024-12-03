/**
 * Created 17.5.2023..
 */

@RestResource(UrlMapping='/m/store/*')
global without sharing class StoreRestResource {

    public static final String storeName = 'Appointments';

    @HttpGet
    global static void getRecord() {

        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        res.headers.put('Content-Type', 'application/json');

        try {
            if (req.requestURI.toLowerCase().indexOf('/m/store/departments') >= 0 && req.params.get('service') != null) {
                String ret = OnlBookUI.getAvailableCategories(storeName, req.params.get('service'));
                res.responseBody = Blob.valueOf(ret);
                res.statusCode = 200;
            }
            else if (req.requestURI.toLowerCase().indexOf('/m/store/discount') >= 0 && req.params.get('code') != null && req.params.get('productId') != null) {
                Discount_Code__c dCode = DiscountCodeManager.validateDiscountCode(
                        storeName,
                        req.params.get('code'),
                        req.params.get('productId'),
                        req.params.get('locationId'),
                        null,
                        null); //todo start time when needed
                if (dCode!=null) res.statusCode = 200;
                else res.statusCode = 404;
            }
            else {
                System.debug(req.params.get('service'));
                res.statusCode = 400;
                res.responseBody = Blob.valueOf(JSON.serializePretty(new AccountRestResource.MHCAPIResponse(400, 'Query not valid')));
            }
        }
        catch (Exception ex) {
            System.debug(ex.getStackTraceString());
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serializePretty(new AccountRestResource.MHCAPIResponse(500, ex.getMessage())));
        }
    }

}