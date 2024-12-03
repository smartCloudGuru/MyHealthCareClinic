/**
 * Created 2.9.2022..
 */

/*
 * Aerona API Specification
 * <h2>Overview</h2> This is the documentation for the Aerona API. Aerona provides a secure set of APIs to integrate with Aerona Clinic from third party software. These APIs use a combination of RESTful URIs and JSON objects to pass the data back to the client. They will be only accessible via a Secure Socket Layer (HTTPS) connection meaning all data communicated between the two systems will be encrypted using TLS. <h3>Usage</h3> To use the API, the Login API must be called first to retrieve a token. This token is returned in the AERONA-AUTH-TOKEN header in the Login response. This token must be subsequently passed to all other API requests in a header field called AERONA-AUTH-TOKEN. <h3>Rate Limit</h3> This token is valid for a period of one hour after which it expires and you will have to log in again. A rate limit of 300 requests per 15 minute period is in place. If you exceed this rate limit, your token will be invalidated. <h3>Webhooks</h3> Webhooks can be setup to notify you when an event happens in Aerona (e.g. when a new appointment has been created). Each Webhook can be sent to a different URL, however you must use an SSL/TLS URL. A response should be returned from your webhook handler with a 200-status code, to tell Aerona that the request was successful. If no response is received or a response other than a status code of 200 is received then Aerona will retry the webhook up to 24 more times (once each hour). <br><br>Webhooks are available for the following types of objects.<ul> <li>Patient</li> <li>Appointment</li> <li>Treatment</li></ul>
 *
 * The version of the OpenAPI document: 1.0
 * Contact: support@aerona.com
 *
 */

public class AeronaServiceOAS {

    public static final AeronaIntegrationSettings__mdt INTEGRATIONS_SETTINGS = [
            SELECT Username__c, Password__c, PIN__c, loginEndpoint__c
            FROM AeronaIntegrationSettings__mdt
            LIMIT 1
    ];

    private static final String HEADER_CONTENT_TYPE = 'Content-Type';
    private static final String HEADER_ACCEPT = 'Accept';
    private static final String HEADER_ACCEPT_DELIMITER = ',';

    public class Param {
        private String name, value;

        public Param(String name, String value) {
            this.name = name;
            this.value = value;
        }

        public override String toString() {
            if (!String.isBlank(value) && !String.isBlank(name))
                return EncodingUtil.urlEncode(name, 'UTF-8') + '=' + EncodingUtil.urlEncode(value, 'UTF-8');
            else return '';
        }
    }

    public interface MappedProperties {
        Map<String, String> getPropertyMappings();
    }

    public class ApiException extends Exception {
        private final Integer code;
        private final String status;
        private final Map<String, String> headers;
        private final String body;

        public ApiException(Integer code, String status, Map<String, String> headers, String body) {
            this('API returned HTTP ' + code + ': ' + status);
            this.code = code;
            this.status = status;
            this.headers = headers;
            this.body = body;
        }

        public Integer getStatusCode() {
            return code;
        }

        public String getStatus() {
            return status;
        }

        public Map<String, String> getHeaders() {
            return headers;
        }

        public String getBody() {
            return body;
        }
    }

    public virtual class ApiClient {
        protected String preferredContentType = 'application/json';
        protected String preferredAccept = 'application/json';
        protected final String basePath;
        protected final String calloutName;

        // for free slots, we have to login with a dedicated PIN, so this enables overriding the PIN per operation
        protected String currentPIN = null;
        public void setPIN(String pin) {
            if (pin != currentPIN) {
                p_authToken = null;
                currentPIN = pin;
            }
        }


        private Datetime tokenValidity = Datetime.now().addHours(-1);
        private String p_authToken;
        private String authToken {
            get {
                if (p_authToken == null || tokenValidity <= Datetime.now()) {
                    System.debug('::AeronaServiceOAS:authToken:NEW_TOKEN:val:' + tokenValidity);
                    AeronaServiceOASApi.OASLoginRequest loginRequest = new AeronaServiceOASApi.OASLoginRequest();
                    loginRequest.username = INTEGRATIONS_SETTINGS.Username__c;
                    loginRequest.password = INTEGRATIONS_SETTINGS.Password__c;
                    loginRequest.pin = currentPIN;
                    if (loginRequest.pin == null) loginRequest.pin = INTEGRATIONS_SETTINGS.PIN__c;

                    try {

                        HttpResponse res = getResponse('POST', INTEGRATIONS_SETTINGS.loginEndpoint__c + '/login',
                                loginRequest, new List<AeronaServiceOAS.Param>(),
                                new List<AeronaServiceOAS.Param>(),
                                new Map<String, Object>(),
                                new Map<String, Object>(),
                                new List<String>(), new List<String>());

                        //System.debug('::AeronaServiceOAS:invokeLogin:res.body:' + res?.getBody());
                        //System.debug('::AeronaServiceOAS:invokeLogin:res.header.token:' + res?.getHeader('AERONA-AUTH-TOKEN'));

                        Integer code = res.getStatusCode();
                        Boolean isFailure = code / 100 != 2;

                        if (isFailure) {
                            throw new ApiException(code, res.getStatus(), getHeaders(res), res.getBody());
                        }
                        else {
                            p_authToken = res.getHeader('AERONA-AUTH-TOKEN');
                            if (p_authToken != null) {
                                tokenValidity = Datetime.now().addMinutes(51);
                            }
                            else {
                                tokenValidity = Datetime.now().addHours(-1);
                            }
                        }
                    }
                    catch (Exception e) {
                        tokenValidity = Datetime.now().addHours(-1);
                        System.debug(LoggingLevel.ERROR, '::AeronaServiceOAS:invokeLogin:ex:' + e);
                        return null;
                    }
                }
                return p_authToken;
            }
            private set;
        }


        public virtual Object invokeGET(String path, Type returnType) {
            return invoke(
                    'GET', path, '', null, null, null,
                    new Map<String, Object>{'AERONA-AUTH-TOKEN' => authToken},
                    new List<String>{'application/json', '*/*'},
                    null, returnType
            );
        }

        public virtual Object invokeGET(String path, Map<String, Object> pathParams, Type returnType) {
            return invoke(
                    'GET', path, null, null, null, pathParams,
                    new Map<String, Object>{'AERONA-AUTH-TOKEN' => authToken},
                    new List<String>{'application/json', '*/*'},
                    null, returnType
            );
        }

        public virtual Object invokeGET(String path, List<Param> query, Type returnType) {
            return invoke(
                    'GET', path, '', query, null, null,
                    new Map<String, Object>{'AERONA-AUTH-TOKEN' => authToken},
                    new List<String>{'application/json', '*/*'},
                    null, returnType
            );
        }
        //
        //        public virtual Object invokeGET(String path, Map<String, Object> pathParams, List<Param> form, Type returnType)
        //        {
        //            return invoke(
        //                    'GET', path, '', null, form, pathParams,
        //                    new Map<String, Object>{'AERONA-AUTH-TOKEN' => authToken},
        //                    new List<String>{'application/json', '*/*'},
        //                    null, null, returnType
        //            );
        //        }

        public virtual Object invokePOST(String path, Object request, Type returnType) {
            return invoke(
                    'POST', path, request, null, null, null,
                    new Map<String, Object>{'AERONA-AUTH-TOKEN' => authToken},
                    new List<String>{'application/json', '*/*'},
                    null, returnType
            );
        }

        public virtual Object invokePUT(String path, Object request, Map<String, Object> pathParams, Type returnType) {
            return invoke(
                    'PUT', path, request, null, null, pathParams,
                    new Map<String, Object>{'AERONA-AUTH-TOKEN' => authToken},
                    new List<String>{'application/json', '*/*'},
                    new List<String>{'application/json'}, returnType
            );
        }

        public virtual Object invoke(
                String method,
                String path,
                Object body,
                List<Param> query,
                List<Param> form,
                Map<String, Object> pathParams,
                Map<String, Object> headers,
                List<String> accepts,
                List<String> contentTypes,
                Type returnType) {

            path = INTEGRATIONS_SETTINGS.loginEndpoint__c + path;
            if (query == null) query = new List<AeronaServiceOAS.Param>();
            if (form == null) form = new List<AeronaServiceOAS.Param>();
            if (pathParams == null) pathParams = new Map<String, Object>();
            if (headers == null) headers = new Map<String, Object>();
            if (contentTypes == null) contentTypes = new List<String>();

            if (headers != null && headers.get('FORCE-AERONA-AUTH-TOKEN') != null) {
                headers.put('AERONA-AUTH-TOKEN', headers.get('FORCE-AERONA-AUTH-TOKEN'));
            }
            else {
                headers.put('AERONA-AUTH-TOKEN', authToken);
            }

            try {
                System.debug('::AeronaServiceOAS:invoke:' + method + ' ' + path + ' ' + pathParams + ' ' + contentTypes);
                HttpResponse res = getResponse(method, path, body, query, form, pathParams, headers,
                        accepts, contentTypes);

                if (res?.getStatusCode() != null && res?.getStatusCode() >= 400) {
                    publishIntegrationLog(true, null, method + ' ' + path,
                            path + ' | ' + pathParams + ' | ' + body + ' | ' + query + ' | ' + form,
                            res?.getBody(), res?.getStatusCode());
                }

                System.debug('::AeronaServiceOAS:invoke:res.body:' + res?.getBody());

                List<String> resHeaderKeys = res.getHeaderKeys();

                if (resHeaderKeys!=null)
                {
                    for (String hdr : resHeaderKeys) {
                        System.debug('::ASO:invoke:resp:header:' + hdr +'=' + res.getHeader(hdr));
                    }
                }


                Integer code = res.getStatusCode();
                Boolean isFailure = code / 100 != 2;

                if (isFailure) {
                    throw new ApiException(code, res.getStatus(), getHeaders(res), res.getBody());
                }
                else if (returnType != null) {
                    return toReturnValue(res.getBody(), returnType, getHeaders(res));
                }
                return null;
            }
            catch (ApiException e) {
                System.debug(LoggingLevel.ERROR, '::invoke:ex1:' + e);
                throw e;
            }
            catch (Exception e) {
                System.debug(LoggingLevel.ERROR, '::invoke:ex2:' + e);
                throw e;
            }
        }

        @TestVisible
        protected virtual Map<String, String> getHeaders(HttpResponse res) {
            Map<String, String> headers = new Map<String, String>();
            List<String> headerKeys = res.getHeaderKeys();
            for (String headerKey : headerKeys) {
                headers.put(headerKey, res.getHeader(headerKey));
            }
            return headers;
        }

        @TestVisible
        protected virtual Object toReturnValue(String body, Type returnType, Map<String, String> headers) {
            String contentType = headers.get('Content-Type');
            if (contentType != null && contentType.contains('application/json')) {
                if (returnType == Long.class) {
                    return Long.valueOf(body);
                }
                if (returnType == Boolean.class) {
                    return Boolean.valueOf(body);
                }

                JSONParser parser = JSON.createParser(body);
                parser.nextToken();
                if (returnType == AeronaServiceOASApi.OASStandardResponse.class) {
                    AeronaServiceOASApi.OASStandardResponse ret = (AeronaServiceOASApi.OASStandardResponse) parser.readValueAs(returnType);
                    ret.headers = headers;
                    return ret;
                }
                return parser.readValueAs(returnType);
            }
            return body;
        }

        @TestVisible
        protected virtual HttpResponse getResponse(
                String method, String path, Object body, List<Param> query, List<Param> form,
                Map<String, Object> pathParams, Map<String, Object> headers, List<String> accepts,
                List<String> contentTypes) {

            HttpRequest req = new HttpRequest();
            req.setMethod(method);
            req.setEndpoint(toEndpoint(path, pathParams, query));
            req.setTimeout(110000);

            String contentType = setContentTypeHeader(contentTypes, headers);
            setAcceptHeader(accepts, headers);

            setHeaders(req, headers);

            if (method != 'GET') {
                req.setBody(toBody(contentType, body, form));
                req.setBody(req?.getBody().replaceAll('.[0-9]{3}Z"', 'Z"')); // AERONA does not like .000Z at the end of timestamps :(
            }

            System.debug('::AESOAS:send:' + req);
            System.debug('::AESOAS:send:' + req.getEndpoint());
            System.debug('::AESOAS:send:body:' + req.getBody());
            System.debug('::AESOAS:send:type:' + req.getHeader('Content-Type'));
            return new Http().send(req);
        }

        @TestVisible
        protected virtual void setHeaders(HttpRequest req, Map<String, Object> headers) {
            for (String headerName : headers.keySet()) {
                if (headers.get(headerName) != null) {
                    req.setHeader(headerName, String.valueOf(headers.get(headerName)));
                }
                else {
                    System.debug(LoggingLevel.WARN, '::AESOAS:send:unable to set NULL header for:' + headerName);
                }
            }
        }

        @TestVisible
        protected virtual String toBody(String contentType, Object body, List<Param> form) {
            if (contentType.contains('application/x-www-form-urlencoded')) {
                return paramsToString(form);
            }
            else if (contentType.contains('application/json')) {
                String ret = JSON.serialize(body, true);
                if (ret != null) ret = ret.replaceAll('_jsonsafe"', '"');
                return ret;
            }
            return String.valueOf(body);
        }

        @TestVisible
        protected virtual String setContentTypeHeader(List<String> contentTypes,
                Map<String, Object> headers) {
            if (contentTypes.isEmpty()) {
                headers.put(HEADER_CONTENT_TYPE, preferredContentType);
                return preferredContentType;
            }
            for (String contentType : contentTypes) {
                if (preferredContentType == contentType) {
                    headers.put(HEADER_CONTENT_TYPE, contentType);
                    return contentType;
                }
            }
            String contentType = contentTypes.get(0);
            headers.put(HEADER_CONTENT_TYPE, contentType);
            return contentType;
        }

        @TestVisible
        protected virtual void setAcceptHeader(List<String> accepts, Map<String, Object> headers) {
            for (String accept : accepts) {
                if (preferredAccept == accept) {
                    headers.put(HEADER_ACCEPT, accept);
                    return;
                }
            }
            if (!accepts.isEmpty()) {
                headers.put(HEADER_ACCEPT, String.join(accepts, HEADER_ACCEPT_DELIMITER));
            }
        }

        @TestVisible
        protected virtual String toPath(String path, Map<String, Object> params) {
            String formatted = path;
            for (String key : params.keySet()) {
                formatted = formatted.replace('{' + key + '}', String.valueOf(params.get(key)));
            }
            return formatted;
        }

        @TestVisible
        protected virtual String toEndpoint(String path, Map<String, Object> params,
                List<Param> queryParams) {
            String query = '?' + paramsToString(queryParams);
            return toPath(path, params) + query.removeEnd('?');
        }

        @TestVisible
        protected virtual String paramsToString(List<Param> params) {
            String s = '';
            for (Param p : params) {
                s += '&' + p;
            }
            return s.removeStart('&');
        }
    }

    public static void publishIntegrationLog(Boolean isError, String relatedId, String operation, String request, String detail, Integer httpCode) {
        try {

            if (request != null && request.length() > 10000) request = request.substring(0, 10000);
            if (detail != null && detail.length() > 20000) detail = detail.substring(0, 20000);

            List<Integration_Log__e> events = new List<Integration_Log__e>();
            events.add(new Integration_Log__e(
                    System__c = 'Aerona',
                    Detail__c = detail,
                    Error__c = isError,
                    Http_Code__c = '' + httpCode,
                    Related_Id__c = relatedId,
                    Request__c = request,
                    Operation__c = operation
            ));
            EventBus.publish(events);
        }
        catch (Exception ex) {
            System.debug(LoggingLevel.WARN, 'Unable to publish Integration_Log__e:' + ex.getMessage());
        }
    }
}