/**
* @author Zoran Zunko
* @date 4/19/21
*
*/
@IsTest global class GeoCodeAPITest {

    @IsTest static void gecode_test() {
        Test.setMock(HttpCalloutMock.class, new GeoCodeServiceMock(TestDataFactory.GECODE_JSON, 200, 'OK', 'POST'));
        System.Location loc =  GeoCodeAPI.getGeocode('UK ' + '441');

        System.assertEquals(51.5107179, loc.latitude);
        System.assertEquals(-0.1377979, loc.longitude);
    }

    global class GeoCodeServiceMock implements HttpCalloutMock {

        public String body { get; private set; }
        public String method { get; private set; }
        public String status { get; private set; }
        public Integer code { get; private set; }
        public Boolean throwException { get; private set; }

        global GeoCodeServiceMock(String body, Integer code, String status, String method) {
            this(body, code, status, method, false);
        }
        global GeoCodeServiceMock(String body, Integer code, String status, String method, Boolean throwException) {
            this.body = body;
            this.code = code;
            this.method = method;
            this.status = status;
            this.throwException = throwException;
        }

        global HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            if (throwException) {
                Integer divideByZero = 2 / 0;
            }
            System.assert(req != null);
//			System.assertEquals(method, req.getMethod());
            res.setBody(body);
            res.setStatusCode(code);
            res.setStatus(status);
            return res;
        }
    }
}