/**
 * Class used to Login to Salesforce and retrieve the Session Id required for connect API access
* @author Zoran Zunko
* @date 3/9/21
*/
public inherited sharing class Login {
    private static final String NS_SOAP = 'http://schemas.xmlsoap.org/soap/envelope/';
    private static final String NS_SF = 'urn:partner.soap.sforce.com';

    public class LoginResponse {
        public String sessionId;
        public String salesforceUrl;

        public LoginResponse(String sessionId, String salesforceUrl) {
            this.sessionId = sessionId;
            this.salesforceUrl = salesforceUrl;
        }
    }
    public static LoginResponse login(String user, String password, String loginURL) {
        // As per http://wiki.developerforce.com/page/Enterprise_Login
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setTimeout(60000);
        req.setEndpoint(loginURL + '/services/Soap/u/51.0');
        req.setHeader('Content-Type', 'text/xml;charset=UTF-8');
        req.setHeader('SOAPAction', '""');
        req.setBody('<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Header/><Body><login xmlns="urn:partner.soap.sforce.com"><username>' + user + '</username><password>' + password + '</password></login></Body></Envelope>');
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            Dom.Document responseDocument = res.getBodyDocument();
            Dom.XmlNode rootElm = responseDocument.getRootElement(); // soapenv:Envelope
            Dom.XmlNode bodyElm = rootElm.getChildElement('Body', NS_SOAP); // soapenv:Body
            Dom.XmlNode faultElm = bodyElm.getChildElement('Fault', NS_SOAP); // soapenv:Fault
            Dom.XmlNode faultStringElm = faultElm.getChildElement('faultstring', null); // faultstring
            throw new LoginException(faultStringElm.getText());
        }

        System.debug(LoggingLevel.ERROR, 'login - req.getBody(): ' + req.getBody());
        // As per http://wiki.developerforce.com/page/Enterprise_Login
        Dom.Document responseDocument = res.getBodyDocument();
        Dom.XmlNode rootElm = responseDocument.getRootElement(); // soapenv:Envelope
        Dom.XmlNode bodyElm = rootElm.getChildElement('Body', NS_SOAP); // soapenv:Body
        Dom.XmlNode loginResponseElm = bodyElm.getChildElement('loginResponse', NS_SF); // loginResponse
        Dom.XmlNode resultElm = loginResponseElm.getChildElement('result', NS_SF); // result
        Dom.XmlNode serverUrlElm = resultElm.getChildElement('serverUrl', NS_SF); // server url
        Dom.XmlNode sessionIdElm = resultElm.getChildElement('sessionId', NS_SF); // sessionId
        return new LoginResponse(sessionIdElm.getText(), serverUrlElm.getText().split('/services')[0]);
    }

    public class LoginException extends Exception {
    }
}