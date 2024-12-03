/**
 * Created 7.9.2022..
 */

@IsTest
public class AeronaServiceMock implements HttpCalloutMock {

    private static final String LOGIN_RESP = '{"status":"mocked_ok"}';
    private static final String POST_APPOINTMENT_RESP = '34234';
    private static final String POST_PAYMENT_RESP = '9326691';
    private static final String POST_INVOICE_RESP = '1726534';
    private static final String POST_CARE_PLAN = '2254';
    private static final String GET_SLOTS_RESP = '[{"clinicianId": 34567,"clinicianName": "Dr. John Smith","slotStartTime": "#TOMORROW#T09:00:00+01:00"}]';
    private static final String GET_PAYMENT_METHODS = '[{"id":1,"method":"Cash"},{"id":2,"method":"Cheque"},{"id":3,"method":"Credit Card"},{"id":4,"method":"Voucher"},{"id":5,"method":"Direct Debit"},{"id":6,"method":"Standing Order"},{"id":7,"method":"Debit Card"},{"id":8,"method":"BACS Transfer"},{"id":9,"method":"AMEX"},{"id":10,"method":"Credit Card - Online"},{"id":11,"method":"Debit Card - Online"},{"id":12,"method":"AMEX - Online"},{"id":13,"method":"Insurance"},{"id":18,"method":"Finance"}]';
    private static final String GET_APPOINTMENT_RESP = '{"practiceId": 9876,"userId": 34567,"appointmentTypeId": 1864,"appointmentStatusId": 7,"appointmentTime": "2023-01-19T13:30:00Z","emergency": false,"appointmentNotes": "Patient is nervous.","duration": 45,"appointmentId": 123,"patientId": 426709}';
    private static final String PUT_APPOINTMENT_RESP = 'true';
    private static final String GET_PATIENT_SEARCH_RESP = '[{"patientId": 426709,"patientFullName": "Mary Simpson","patientFullAddress": "The Cottage, Killylane, Eglinton, Co.Derry","dob": "2000-09-13"}]';
    private static final String GET_PATIENT_RESP = '{"patientId": 426709,"patientFullName": "Mary Simpson","patientFullAddress": "The Cottage, Killylane, Eglinton, Co.Derry","dob": "2000-09-13", "appointments":[{"practiceId": 9876,"userId": 34567,"appointmentTypeId": 1864,"appointmentStatusId": 7,"appointmentTime": "2023-01-19T13:30:00Z","emergency": false,"appointmentNotes": "Patient is nervous.","duration": 45,"appointmentId": 0,"patientId": 426709}]}';
    private static final String POST_PATIENT_RESP = '{"id": 426709,"duplicatePatients": []}';
    private static final String POST_PATIENT_RESP_DUPLICATES = '{"id": 0,"duplicatePatients": [{"patientId": 426709,"patientFullName": "Mary Simpson","patientFullAddress": "The Cottage, Killylane, Eglinton, Co. Derry","dob": "1980-08-24"}]}';
    private static final String PUT_PATIENT_RESP = 'true';
    private static final String GET_CLINICIANS_RESP = '[{"id": "1","clinicianName": "dent one"},{"id": "2","clinicianName": "dent two"}]';
    private static final String GET_APPTYPES_RESP = '[{"id":2928,"type":"Basic Exam","duration":30,"enabled":true,"saleItemId":0},{"id":2930,"type":"Bone Graft Review","duration":60,"enabled":true,"saleItemId":0},{"id":2931,"type":"Botox - Filler","duration":45,"enabled":true,"saleItemId":0},{"id":2932,"type":"Consultation","duration":30,"enabled":true,"saleItemId":0},{"id":2933,"type":"Dental Check up","duration":30,"enabled":true,"saleItemId":0},{"id":2929,"type":"Exam","duration":45,"enabled":true,"saleItemId":0},{"id":2934,"type":"Extraction","duration":60,"enabled":true,"saleItemId":0},{"id":2935,"type":"Implant","duration":30,"enabled":true,"saleItemId":0},{"id":2927,"type":"S&P","duration":30,"enabled":true,"saleItemId":0},{"id":2943,"type":"Test","duration":5,"enabled":true,"saleItemId":0}]';
    private static final String GET_CARE_PLANS = '[ {' +
            '        "id": 1084,' +
            '        "description": "2022Sep MHC Dental",' +
            '        "weeklyAmount": 0.0,' +
            '        "monthlyAmount": 0.0,' +
            '        "yearlyAmount": 0.0,' +
            '        "enabled": true' +
            '    },' +
            '    {' +
            '        "id": 1085,' +
            '        "description": "2022Sep MHC Premium",' +
            '        "weeklyAmount": 0.0,' +
            '        "monthlyAmount": 0.0,' +
            '        "yearlyAmount": 0.0,' +
            '        "enabled": true' +
            '    }]';

    private static final String GET_TREATMENTS_RESP = '[]';
    private static final String GET_TREATMENTPLANS_RESP = '[]';

    public static void setAsMock() {
        Test.setMock(HttpCalloutMock.class, new AeronaServiceMock(true));
    }

    public static void setFailMock() {
        Test.setMock(HttpCalloutMock.class, new AeronaServiceMock(false));
    }

    private Boolean succeed;

    private AeronaServiceMock(Boolean succeed) {
        AeronaService.FORCE_ENABLED = true;
        this.succeed = succeed;
    }

    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();

        res.setStatusCode(this.succeed ? 200 : 404);

        if (!req.getEndpoint().contains('/login') && String.isBlank(req.getHeader('AERONA-AUTH-TOKEN'))) {
            res.setStatusCode(401);
            return res;
        }

        res.setHeader('Content-Type', 'application/json');

        System.debug('::AeronaMOCK: method=' + req.getMethod() + ' ' + req.getEndpoint() + ' body=' + req.getBody() + ' AERONA-AUTH-TOKEN=' + req.getHeader('AERONA-AUTH-TOKEN'));


        if (req.getEndpoint().contains('/login')) {
            res.setBody(LOGIN_RESP);
            res.setHeader('AERONA-AUTH-TOKEN', 'mock_token');
            return res;
        }
        if (req.getEndpoint().contains('/v1/payment-methods')) {
            res.setBody(GET_PAYMENT_METHODS);
            return res;
        }
        if (req.getEndpoint().contains('/v1/appointments') && req.getMethod() == 'POST') {
            res.setBody(POST_APPOINTMENT_RESP);
            return res;
        }
        if (req.getEndpoint().contains('/v1/patients/treatmentplans') && req.getMethod() == 'GET') {
            res.setBody(GET_TREATMENTPLANS_RESP);
            return res;
        }if (req.getEndpoint().contains('/v1/patients/treatments') && req.getMethod() == 'GET') {
            res.setBody(GET_TREATMENTS_RESP);
            return res;
        }
        if (req.getEndpoint().contains('/v1/patients') && req.getMethod() == 'POST' && req.getBody().contains('FORCE_DUPLICATE')) {
            res.setBody(POST_PATIENT_RESP_DUPLICATES);
            return res;
        }
        if (req.getEndpoint().contains('/v1/patients') && req.getMethod() == 'POST') {
            res.setBody(POST_PATIENT_RESP);
            return res;
        }
        if (req.getEndpoint().contains('/v1/patients') && req.getMethod() == 'PUT') {
            res.setBody(PUT_PATIENT_RESP);
            return res;
        }
        if (req.getEndpoint().contains('/v1/payments') && req.getMethod() == 'POST') {
            res.setBody(POST_PAYMENT_RESP);
            return res;
        }
        if (req.getEndpoint().contains('/v1/invoices') && req.getMethod() == 'POST') {
            res.setBody(POST_INVOICE_RESP);
            return res;
        }
        if (req.getEndpoint().contains('/v1/appointments') && req.getMethod() == 'GET') {
            res.setBody(GET_APPOINTMENT_RESP);
            return res;
        }
        if (req.getEndpoint().contains('/v1/appointments') && req.getMethod() == 'PUT') {
            res.setBody(PUT_APPOINTMENT_RESP);
            return res;
        }
        if (req.getEndpoint().contains('/v1/find-appointment-slots') && req.getMethod() == 'GET') {
            res.setBody(GET_SLOTS_RESP.replaceAll('#TOMORROW#', getTOMORROWDateYYYYMMDD()));
            return res;
        }
        if (req.getEndpoint().contains('/v1/clinicians') && req.getMethod() == 'GET') {
            res.setBody(GET_CLINICIANS_RESP);
            return res;
        }
        if (req.getEndpoint().contains('/v1/appointment-types') && req.getMethod() == 'GET') {
            res.setBody(GET_APPTYPES_RESP);
            return res;
        }
        if (req.getEndpoint().contains('/v1/care-plans') && req.getMethod() == 'GET') {
            res.setBody(GET_CARE_PLANS);
            return res;
        }
        if (req.getEndpoint().contains('/v1/patients/search') && req.getMethod() == 'GET') {
            res.setBody(GET_PATIENT_SEARCH_RESP);
            return res;
        }
        if (req.getEndpoint().contains('/v1/patient/care-plan') && req.getMethod() == 'POST') {
            res.setBody(POST_CARE_PLAN);
            return res;
        }
        if (req.getEndpoint().contains('/v1/patient') && req.getMethod() == 'GET') {
            res.setBody(GET_PATIENT_RESP);
            return res;
        }

        return res;
    }

    public static String getTOMORROWDateYYYYMMDD() {
        return Datetime.newInstance(Date.today().addDays(1), Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd');
    }
}