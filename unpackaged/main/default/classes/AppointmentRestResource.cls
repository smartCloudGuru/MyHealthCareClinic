/**
 * Created 18.5.2022..
 */

@RestResource(UrlMapping='/m/appointment/*')
global with sharing class AppointmentRestResource {

    //    @HttpGet
    //    global static void getRecord() {
    //
    //        RestRequest req = RestContext.request;
    //        RestResponse res = RestContext.response;
    //
    //        res.headers.put('Content-Type', 'application/json');
    //
    //        try {
    //            if (req.requestBody != null) System.debug(LoggingLevel.FINE, 'doGet - RestContext.request.requestBody.toString(): ' + req.requestBody.toString());
    //
    //            String id = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
    //
    //            if (String.isBlank(id)) {
    //                res.statusCode = 400;
    //                res.responseBody = Blob.valueOf(JSON.serializePretty(new MHCAPIResponse(400, 'Invalid query parameters')));
    //                return;
    //            }
    //
    //            List<ServiceAppointment> apps = [
    //                    SELECT Id, SchedStartTime, SchedEndTime, Status, StatusCategory, Journey_Status__c, ServiceTerritory.Id, ServiceTerritory.Name, (SELECT Id, ServiceResourceId, ServiceResource.Name, IsRequiredResource FROM ServiceResources) FROM ServiceAppointment WHERE Id = :id
    //            ];
    //
    //            if (apps.size() == 0) {
    //                res.statusCode = 404;
    //                res.responseBody = Blob.valueOf(JSON.serializePretty(new MHCAPIResponse(404, 'Not found')));
    //                return;
    //            }
    //
    //            res.statusCode = 200;
    //            res.responseBody = Blob.valueOf(JSON.serialize(apps[0]));
    //
    //        }
    //        catch (Exception ex) {
    //            System.debug(ex.getStackTraceString());
    //            res.statusCode = 500;
    //            res.responseBody = Blob.valueOf(JSON.serializePretty(new MHCAPIResponse(500, ex.getMessage())));
    //        }
    //    }

    @HttpPatch
    global static void doPatch() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        res.headers.put('Content-Type', 'application/json');

        try {
            System.debug(LoggingLevel.INFO, '::M:AppointmentRestResource:PATCH:requestBody: ' + req?.requestBody?.toString());

            res.statusCode = 200;

            ServiceAppointment saReq = (ServiceAppointment) JSON.deserialize(req.requestBody.toString(), ServiceAppointment.class);

            if (String.isEmpty(saReq?.Id)) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf(JSON.serialize(new MHCAPIResponse(400, 'Id is required')));
                System.debug(LoggingLevel.INFO, '::M:AppointmentRestResource:PATCH:requestBody: ' + 'Id is required');
                return;
            }

            ServiceAppointment saToUpdate = new ServiceAppointment();
            saToUpdate.Id = saReq.Id;
            if (saReq.Status != null) saToUpdate.Status = saReq.Status;
            if (saReq.CancellationReason != null) saToUpdate.CancellationReason = saReq.CancellationReason;
            if (saReq.Status == 'Canceled') saReq.CancellationReason = 'Requested by Patient';

            update saToUpdate;

            res.responseBody = Blob.valueOf(JSON.serialize(saToUpdate));
            System.debug(LoggingLevel.INFO, '::M:AppointmentRestResource:PATCH:requestBody: ' + JSON.serialize(saToUpdate));


        }
        catch (System.JSONException ex) {
            resFromMHCApiResponse(res, 400, 'Malformed JSON input');
            System.debug(LoggingLevel.INFO, '::M:AppointmentRestResource:PATCH:requestBody: ' + 'Malformed JSON input');
        }
        catch (Exception ex) {
            resFromMHCApiResponse(res, 500, ex.getMessage());
            System.debug(LoggingLevel.INFO, '::M:AppointmentRestResource:PATCH:requestBody: ' + ex.getMessage());
        }
    }

    public static void resFromMHCApiResponse(RestResponse res, Integer code, String msg) {
        res.statusCode = code;
        res.responseBody = Blob.valueOf(JSON.serialize(new MHCAPIResponse(code, msg), true));
    }


    public class MHCAPIResponse {
        public Integer code;
        public String message;

        public MHCAPIResponse(Integer code, String message) {
            this.code = code;
            this.message = message;
        }
    }

}