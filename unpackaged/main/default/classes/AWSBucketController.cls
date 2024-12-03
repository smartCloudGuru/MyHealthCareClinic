/**
 * Created 9.5.2023..
 */

public without sharing class AWSBucketController {

    public static Boolean putFileInS3FromContentDocument(ContentVersion contentVersion, String s3url) {

        if (contentVersion!=null) {
            String attachmentBody = EncodingUtil.base64Encode(contentVersion.VersionData);
            String formattedDateString = Datetime.now().formatGMT('EEE, dd MMM yyyy HH:mm:ss z');
            String contentType= 'application/pdf';

            HttpRequest req  = new HttpRequest();
            HttpResponse res  = new HttpResponse();

            req.setMethod('PUT');
            req.setEndpoint(s3url);
            req.setHeader('Content-Length', String.valueOf(attachmentBody.length()));
            req.setHeader('Content-Encoding', 'UTF-8');
            req.setHeader('Content-type', contentType);
            req.setHeader('Connection', 'keep-alive');
            req.setHeader('Date', formattedDateString);

            Blob pdfBlob = EncodingUtil.base64Decode(attachmentBody);

            req.setBodyAsBlob(pdfBlob);
            Http http = new Http();
            res = http.send(req);
            System.debug(res.getStatusCode());
            System.debug(res.getBody());

            return res.getStatusCode()>=200 && res.getStatusCode()<300;
        }
        else return false;
    }
}