/**
 * Created 16.12.2022..
 */

@RestResource(UrlMapping='/m/passwordvalidation/*')
global without sharing class StorePasswordMngRestResource {

    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        res.headers.put('Content-Type', 'application/json');

        try {
            System.debug(LoggingLevel.FINE, 'doPost - RestContext.request.requestBody.toString(): ' + req.requestBody.toString());

            PasswordValidationRequest pvr = (PasswordValidationRequest) JSON.deserialize(RestContext.request.requestBody.toString(), PasswordValidationRequest.class);

            String identification = pvr.Username;
            if (String.isEmpty(identification))
            {
                identification = pvr.Email;
            }

            String ret = OnlBookUI.checkAccountLoginWithConnectedAccounts(identification, pvr.Password);

            if (ret != null) {
                OnlBookUI.AccountWithConnectedAccounts accRet = (OnlBookUI.AccountWithConnectedAccounts) JSON.deserialize(ret, OnlBookUI.AccountWithConnectedAccounts.class);
                resFromMHCApiResponse(res, 200, accRet?.main?.Id);
                System.debug(LoggingLevel.INFO, '::M:StorePasswordMngRestResource:POST:resp: ' + accRet?.main?.Id);
            }
            else {
                resFromMHCApiResponse(res, 404, null);
            }
        }
        catch (System.JSONException ex) {
            resFromMHCApiResponse(res, 400, 'Malformed JSON input');
        }
        catch (Exception ex) {
            resFromMHCApiResponse(res, 500, ex.getMessage());
        }
    }

    public static void resFromMHCApiResponse(RestResponse res, Integer code, String msg) {
        res.statusCode = code;
        res.responseBody = Blob.valueOf(JSON.serialize(new MHCAPIResponse(code, msg), true));
    }

    global class PasswordValidationRequest {
        public String Email;
        public String Username;
        public String Password;
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