/**
 * Created by Atlas on 4.03.2021.
 */

@IsTest
public class AppointmentIntegrationTest{

    public static string patientInfoJSON = '{\n' +
            '    "status": "Success",\n' +
            '    "result": {\n' +
            '        "recordType": null,\n' +
            '        "practiceId": 250,\n' +
            '        "patientTypeId": null,\n' +
            '        "sourceId": null,\n' +
            '        "referrerId": null,\n' +
            '        "insRefNumber": null,\n' +
            '        "insRefNumber2": null,\n' +
            '        "genderId": null,\n' +
            '        "titleId": 859,\n' +
            '        "forename": "Georgina",\n' +
            '        "surname": "Goodman",\n' +
            '        "maidenName": null,\n' +
            '        "occupation": null,\n' +
            '        "dob": 745628400000,\n' +
            '        "knownAs": null,\n' +
            '        "address1": "406, Chapelier House",\n' +
            '        "address2": "Eastfields Avenue",\n' +
            '        "address3": "LONDON",\n' +
            '        "address4": null,\n' +
            '        "code": "SW18 1LR",\n' +
            '        "emailAddress": "georginagoodman@live.com",\n' +
            '        "mobileNumber": "447875377457",\n' +
            '        "homeNumber": null,\n' +
            '        "workNumber": null,\n' +
            '        "faxNumber": null,\n' +
            '        "allowText": true,\n' +
            '        "allowEmail": true,\n' +
            '        "allowPrint": false,\n' +
            '        "userId": null,\n' +
            '        "statusId": 1,\n' +
            '        "insExpiry1": null,\n' +
            '        "insExpiry2": null,\n' +
            '        "policyNo": null,\n' +
            '        "patientCarePlans": []\n' +
            '    },\n' +
            '    "errorResult": null,\n' +
            '    "errorCode": 0\n' +
            '}';

    public static string patientInfoJSON2 = '{\n' +
            '    "status": "Success",\n' +
            '    "result": {\n' +
            '        "recordType": null,\n' +
            '        "practiceId": 250,\n' +
            '        "patientTypeId": null,\n' +
            '        "sourceId": null,\n' +
            '        "referrerId": null,\n' +
            '        "insRefNumber": null,\n' +
            '        "insRefNumber2": null,\n' +
            '        "genderId": null,\n' +
            '        "titleId": 859,\n' +
            '        "forename": "Georgina",\n' +
            '        "surname": "Goodman",\n' +
            '        "maidenName": null,\n' +
            '        "occupation": null,\n' +
            '        "dob": 745628400000,\n' +
            '        "knownAs": null,\n' +
            '        "address1": "406, Chapelier House",\n' +
            '        "address2": "Eastfields Avenue",\n' +
            '        "address3": "LONDON",\n' +
            '        "address4": null,\n' +
            '        "code": "SW18 1LR",\n' +
            '        "emailAddress": "georginagoodman@live.com",\n' +
            '        "mobileNumber": "447875377457",\n' +
            '        "homeNumber": null,\n' +
            '        "workNumber": null,\n' +
            '        "faxNumber": null,\n' +
            '        "allowText": true,\n' +
            '        "allowEmail": true,\n' +
            '        "allowPrint": false,\n' +
            '        "userId": null,\n' +
            '        "statusId": 3,\n' +
            '        "insExpiry1": null,\n' +
            '        "insExpiry2": null,\n' +
            '        "policyNo": null,\n' +
            '        "patientCarePlans": []\n' +
            '    },\n' +
            '    "errorResult": null,\n' +
            '    "errorCode": 0\n' +
            '}';

    public static string patientInfoJSON3 = '{\n' +
            '    "status": "Success",\n' +
            '    "result": {\n' +
            '        "recordType": null,\n' +
            '        "practiceId": 250,\n' +
            '        "patientTypeId": null,\n' +
            '        "sourceId": null,\n' +
            '        "referrerId": null,\n' +
            '        "insRefNumber": null,\n' +
            '        "insRefNumber2": null,\n' +
            '        "genderId": null,\n' +
            '        "titleId": 859,\n' +
            '        "forename": "Georgina",\n' +
            '        "surname": "Goodman",\n' +
            '        "maidenName": null,\n' +
            '        "occupation": null,\n' +
            '        "dob": 745628400000,\n' +
            '        "knownAs": null,\n' +
            '        "address1": "406, Chapelier House",\n' +
            '        "address2": "Eastfields Avenue",\n' +
            '        "address3": "LONDON",\n' +
            '        "address4": null,\n' +
            '        "code": "SW18 1LR",\n' +
            '        "emailAddress": "georginagoodman@live.com",\n' +
            '        "mobileNumber": "447875377457",\n' +
            '        "homeNumber": null,\n' +
            '        "workNumber": null,\n' +
            '        "faxNumber": null,\n' +
            '        "allowText": true,\n' +
            '        "allowEmail": true,\n' +
            '        "allowPrint": false,\n' +
            '        "userId": null,\n' +
            '        "statusId": 5,\n' +
            '        "insExpiry1": null,\n' +
            '        "insExpiry2": null,\n' +
            '        "policyNo": null,\n' +
            '        "patientCarePlans": []\n' +
            '    },\n' +
            '    "errorResult": null,\n' +
            '    "errorCode": 0\n' +
            '}';

    public static string patientInfoJSON4 = '{\n' +
            '    "status": "Success",\n' +
            '    "result": {\n' +
            '        "recordType": null,\n' +
            '        "practiceId": 250,\n' +
            '        "patientTypeId": null,\n' +
            '        "sourceId": null,\n' +
            '        "referrerId": null,\n' +
            '        "insRefNumber": null,\n' +
            '        "insRefNumber2": null,\n' +
            '        "genderId": null,\n' +
            '        "titleId": 859,\n' +
            '        "forename": "Georgina",\n' +
            '        "surname": "Goodman",\n' +
            '        "maidenName": null,\n' +
            '        "occupation": null,\n' +
            '        "dob": 745628400000,\n' +
            '        "knownAs": null,\n' +
            '        "address1": "406, Chapelier House",\n' +
            '        "address2": "Eastfields Avenue",\n' +
            '        "address3": "LONDON",\n' +
            '        "address4": null,\n' +
            '        "code": "SW18 1LR",\n' +
            '        "emailAddress": "georginagoodman@live.com",\n' +
            '        "mobileNumber": "447875377457",\n' +
            '        "homeNumber": null,\n' +
            '        "workNumber": null,\n' +
            '        "faxNumber": null,\n' +
            '        "allowText": true,\n' +
            '        "allowEmail": true,\n' +
            '        "allowPrint": false,\n' +
            '        "userId": null,\n' +
            '        "statusId": 7,\n' +
            '        "insExpiry1": null,\n' +
            '        "insExpiry2": null,\n' +
            '        "policyNo": null,\n' +
            '        "patientCarePlans": []\n' +
            '    },\n' +
            '    "errorResult": null,\n' +
            '    "errorCode": 0\n' +
            '}';

    public static string practiceInfoJSON = '[\n' +
            '    {\n' +
            '        "key": 130,\n' +
            '        "value": "MyHealthcare Clinic - Wandsworth"\n' +
            '    },\n' +
            '    {\n' +
            '        "key": 249,\n' +
            '        "value": "Wandsworth Clinic"\n' +
            '    },\n' +
            '    {\n' +
            '        "key": 250,\n' +
            '        "value": "MyHealthCare Clinic - Fulham"\n' +
            '    },\n' +
            '    {\n' +
            '        "key": 330,\n' +
            '        "value": "MyHealthCare Clinic - Wimpole Street"\n' +
            '    }\n' +
            ']';

    public static string appointmentTypeListJSON = '{\n' +
            '    "status": "Success",\n' +
            '    "result": [\n' +
            '        {\n' +
            '            "id": 10846,\n' +
            '            "type": " Laser Whitening Consultation",\n' +
            '            "duration": 15,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 11091,\n' +
            '            "type": "3-Months recall",\n' +
            '            "duration": 60,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 10851,\n' +
            '            "type": "Airflow (Hygienist)",\n' +
            '            "duration": 60,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 10865,\n' +
            '            "type": "Anti-snoring device fit",\n' +
            '            "duration": 20,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 10864,\n' +
            '            "type": "Anti-snoring device impressions",\n' +
            '            "duration": 20,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 14385,\n' +
            '            "type": "Bone Graft Procedure",\n' +
            '            "duration": 60,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 14386,\n' +
            '            "type": "Bone Graft Review",\n' +
            '            "duration": 10,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 4340,\n' +
            '            "type": "Botox - Filler 45mins",\n' +
            '            "duration": 45,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 10892,\n' +
            '            "type": "Child Clean",\n' +
            '            "duration": 15,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 5684,\n' +
            '            "type": "Classic Clean",\n' +
            '            "duration": 30,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 10895,\n' +
            '            "type": "Classic Clean (OFFER)",\n' +
            '            "duration": 30,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 4452,\n' +
            '            "type": "Crowns and Bridge",\n' +
            '            "duration": 60,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 14665,\n' +
            '            "type": "Dental Examination",\n' +
            '            "duration": 30,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 14823,\n' +
            '            "type": "Dental Examination - (Online Booking new pt)",\n' +
            '            "duration": 30,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 4457,\n' +
            '            "type": "Dental Examination- (Online Existing Pt)",\n' +
            '            "duration": 30,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 10323,\n' +
            '            "type": "Dentist Consultation - New Patient Offer",\n' +
            '            "duration": 45,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 12669,\n' +
            '            "type": "Dentist Consultation-GPDQ",\n' +
            '            "duration": 30,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 4448,\n' +
            '            "type": "Dentures",\n' +
            '            "duration": 30,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 11418,\n' +
            '            "type": "Dry Socket Emergency Treatment",\n' +
            '            "duration": 20,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 7409,\n' +
            '            "type": "Emergency (Existing Patient)",\n' +
            '            "duration": 20,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 7408,\n' +
            '            "type": "Emergency (Online-1st visit to clinic)",\n' +
            '            "duration": 30,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 4451,\n' +
            '            "type": "Filling",\n' +
            '            "duration": 30,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 10311,\n' +
            '            "type": "General Appointment For Online Booking",\n' +
            '            "duration": 15,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 14820,\n' +
            '            "type": "Hygiene - Classic Clean (Online existing pt)",\n' +
            '            "duration": 30,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 14821,\n' +
            '            "type": "Hygiene Clean (Online Booking new pt)",\n' +
            '            "duration": 30,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 10867,\n' +
            '            "type": "Implant Additional Surgery",\n' +
            '            "duration": 60,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 10888,\n' +
            '            "type": "Implant Consultation",\n' +
            '            "duration": 30,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 14818,\n' +
            '            "type": "Implant Consultation (Online Booking)",\n' +
            '            "duration": 30,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 10866,\n' +
            '            "type": "Implant Consultation - Follow-up",\n' +
            '            "duration": 20,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 10321,\n' +
            '            "type": "Implant Consultation - New Patient Offer",\n' +
            '            "duration": 45,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 14323,\n' +
            '            "type": "Implant Exposure",\n' +
            '            "duration": 20,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 14324,\n' +
            '            "type": "Implant Impressions",\n' +
            '            "duration": 30,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 4364,\n' +
            '            "type": "Implant placement surgery",\n' +
            '            "duration": 60,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 4443,\n' +
            '            "type": "Implant Recall",\n' +
            '            "duration": 10,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 4311,\n' +
            '            "type": "Implant Restoration",\n' +
            '            "duration": 30,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 5768,\n' +
            '            "type": "Initial Periodontal Treatment",\n' +
            '            "duration": 60,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 10853,\n' +
            '            "type": "Internal whitening (1st session)",\n' +
            '            "duration": 20,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 10855,\n' +
            '            "type": "Internal whitening (follow-up)",\n' +
            '            "duration": 20,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 12055,\n' +
            '            "type": "Invisalign Assessment - New Patient",\n' +
            '            "duration": 20,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 14817,\n' +
            '            "type": "Invisalign Consultation (Online Booking)",\n' +
            '            "duration": 30,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 14981,\n' +
            '            "type": "Invisalign Consultation (Video)",\n' +
            '            "duration": 20,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 10868,\n' +
            '            "type": "Invisalign Consultation - Follow-up",\n' +
            '            "duration": 30,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 11855,\n' +
            '            "type": "Invisalign EXC SB",\n' +
            '            "duration": 30,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 6827,\n' +
            '            "type": "Invisalign First Consultation",\n' +
            '            "duration": 30,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 6828,\n' +
            '            "type": "Invisalign Recall Visit",\n' +
            '            "duration": 30,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 10870,\n' +
            '            "type": "Invisalign Records",\n' +
            '            "duration": 20,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 10871,\n' +
            '            "type": "Laser Whitening",\n' +
            '            "duration": 60,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 4453,\n' +
            '            "type": "Miscellaneous",\n' +
            '            "duration": 30,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 7298,\n' +
            '            "type": "New Patient Veneer Consultation",\n' +
            '            "duration": 30,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 14824,\n' +
            '            "type": "Online Orthodontic assessment(Online Booking)",\n' +
            '            "duration": 15,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 10858,\n' +
            '            "type": "Oral Surgery",\n' +
            '            "duration": 20,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 10859,\n' +
            '            "type": "Oral Surgery - New Patient",\n' +
            '            "duration": 20,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 4446,\n' +
            '            "type": "Oral Surgery Recall",\n' +
            '            "duration": 15,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 4444,\n' +
            '            "type": "Ortho Recall",\n' +
            '            "duration": 30,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 13060,\n' +
            '            "type": "Orthodontic Assessment- New patient",\n' +
            '            "duration": 20,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 4353,\n' +
            '            "type": "Orthodontic bond-up",\n' +
            '            "duration": 90,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 14819,\n' +
            '            "type": "Orthodontic Consultation (Online Booking)",\n' +
            '            "duration": 30,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 10869,\n' +
            '            "type": "Orthodontic Consultation - Follow-up",\n' +
            '            "duration": 30,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 10320,\n' +
            '            "type": "Orthodontic Consultation - New Patient Offer",\n' +
            '            "duration": 30,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 10465,\n' +
            '            "type": "Orthodontic Debond",\n' +
            '            "duration": 45,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 10466,\n' +
            '            "type": "Orthodontic Debond + BR",\n' +
            '            "duration": 60,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 11665,\n' +
            '            "type": "Orthodontic Emergency",\n' +
            '            "duration": 20,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 11072,\n' +
            '            "type": "Orthodontic Screening",\n' +
            '            "duration": 15,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 7757,\n' +
            '            "type": "Periodontal 6-points charting",\n' +
            '            "duration": 20,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 10860,\n' +
            '            "type": "Periodontal Reassessment",\n' +
            '            "duration": 45,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 13734,\n' +
            '            "type": "Phone consultation",\n' +
            '            "duration": 10,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 12239,\n' +
            '            "type": "Premium Dental Fitness Fee Check",\n' +
            '            "duration": 45,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 11037,\n' +
            '            "type": "Referral Implant ",\n' +
            '            "duration": 30,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 11038,\n' +
            '            "type": "Referral Ortho",\n' +
            '            "duration": 30,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 11410,\n' +
            '            "type": "Retainer fit",\n' +
            '            "duration": 15,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 4447,\n' +
            '            "type": "Root Canal Treatment",\n' +
            '            "duration": 45,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 14387,\n' +
            '            "type": "Sinus Lift Procedure",\n' +
            '            "duration": 90,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 14388,\n' +
            '            "type": "Sinus Lift Review",\n' +
            '            "duration": 10,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 10863,\n' +
            '            "type": "Sport or Night Guard fit",\n' +
            '            "duration": 15,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 10862,\n' +
            '            "type": "Sport or Night Guard impressions",\n' +
            '            "duration": 15,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 7446,\n' +
            '            "type": "Treatment Coordinator Consultation",\n' +
            '            "duration": 15,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 5685,\n' +
            '            "type": "Ultra Clean",\n' +
            '            "duration": 60,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 4459,\n' +
            '            "type": "Whitening Fit (trays) ",\n' +
            '            "duration": 15,\n' +
            '            "enabled": true\n' +
            '        },\n' +
            '        {\n' +
            '            "id": 10861,\n' +
            '            "type": "Whitening Impressions",\n' +
            '            "duration": 15,\n' +
            '            "enabled": true\n' +
            '        }\n' +
            '    ],\n' +
            '    "errorResult": null,\n' +
            '    "errorCode": 0\n' +
            '}';
    @IsTest
    static void testBehavior(){

        string appointmentINFOJSON = '{\n' +
        '                "recordType": null,\n' +
        '                "practiceId": 250,\n' +
        '                "userId": 6886,\n' +
        '                "appointmentTypeId": 13060,\n' +
        '                "appointmentStatusId": 10,\n' +
        '                "appointmentTime": 1615389600000,\n' +
        '                "emergency": false,\n' +
        '                "appointmentNotes": "\\r\\ncovid screened. \\r\\nunsure which braces, wants advice. Bishal 03.03.2021",\n' +
        '                "duration": 30,\n' +
        '                "appointmentId": 14610852,\n' +
        '                "patientId": 2281878\n' +
        '            }';

        AeronaAppointment.Appointment appt = (AeronaAppointment.Appointment)JSON.deserialize(appointmentINFOJSON, AeronaAppointment.Appointment.class);


        RestRequest request = new RestRequest();
        request.requestURI ='services/apexrest/AppointmentIntegration/v1/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueof(appointmentINFOJSON);
        RestContext.request = request;

        AppointmentIntegration service = new AppointmentIntegration();
        AppointmentIntegration.doPost();

    }

    @IsTest
    static void testBehavior2(){


        Account testPatient = new Account();
        testPatient.PersonEmail = 'test@patient.com';
        testPatient.Aerona_Id__c = '2281878';
        testPatient.FirstName = 'abc';
        testPatient.LastName = 'defg';
        testPatient.Date_of_Birth__c = System.today();
        testPatient.PersonBirthdate = system.today();
        testPatient.Gender__c = 'male';
        testPatient.Patient_Type__c = 'New';

        insert testPatient;

        string appointmentINFOJSON = '{\n' +
                '                "recordType": null,\n' +
                '                "practiceId": 250,\n' +
                '                "userId": 6886,\n' +
                '                "appointmentTypeId": 13060,\n' +
                '                "appointmentStatusId": 10,\n' +
                '                "appointmentTime": 1615389600000,\n' +
                '                "emergency": false,\n' +
                '                "appointmentNotes": "\\r\\ncovid screened. \\r\\nunsure which braces, wants advice. Bishal 03.03.2021",\n' +
                '                "duration": 30,\n' +
                '                "appointmentId": 14610852,\n' +
                '                "patientId": 2281878\n' +
                '            }';

        AeronaAppointment.Appointment appt = (AeronaAppointment.Appointment)JSON.deserialize(appointmentINFOJSON, AeronaAppointment.Appointment.class);


        RestRequest request = new RestRequest();
        request.requestURI ='services/apexrest/AppointmentIntegration/v1/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueof(appointmentINFOJSON);
        RestContext.request = request;

        AppointmentIntegration service = new AppointmentIntegration();
        AppointmentIntegration.doPost();

    }

    @IsTest
    static void testBehavior3(){


        Account testPatient = new Account();
        testPatient.PersonEmail = 'test@patient.com';
        testPatient.Aerona_Id__c = '2281878';
        testPatient.FirstName = 'abc';
        testPatient.LastName = 'defg';
        testPatient.Date_of_Birth__c = System.today();
        testPatient.PersonBirthdate = system.today();
        testPatient.Gender__c = 'male';
        testPatient.Patient_Type__c = 'New';

        insert testPatient;

        string appointmentINFOJSON2 = '{\n' +
                '                "recordType": null,\n' +
                '                "practiceId": 250,\n' +
                '                "userId": 6886,\n' +
                '                "appointmentTypeId": 13060,\n' +
                '                "appointmentStatusId": 3,\n' +
                '                "appointmentTime": 1615389600000,\n' +
                '                "statusId": 3,\n' +
                '                "emergency": false,\n' +
                '                "appointmentNotes": "\\r\\ncovid screened. \\r\\nunsure which braces, wants advice. Bishal 03.03.2021",\n' +
                '                "duration": 30,\n' +
                '                "appointmentId": 14610852,\n' +
                '                "patientId": 2281878\n' +
                '            }';

        AeronaAppointment.Appointment appt2 = (AeronaAppointment.Appointment)JSON.deserialize(appointmentINFOJSON2, AeronaAppointment.Appointment.class);


        RestRequest request = new RestRequest();
        request.requestURI ='services/apexrest/AppointmentIntegration/v1/';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueof(appointmentINFOJSON2);
        RestContext.request = request;

        AppointmentIntegration service = new AppointmentIntegration();
        AppointmentIntegration.doPost();

        string appointmentINFOJSON3 = '{\n' +
                '                "recordType": null,\n' +
                '                "practiceId": 250,\n' +
                '                "userId": 6886,\n' +
                '                "appointmentTypeId": 13060,\n' +
                '                "appointmentStatusId": 2,\n' +
                '                "appointmentTime": 1615389600000,\n' +
                '                "statusId": 3,\n' +
                '                "emergency": false,\n' +
                '                "appointmentNotes": "\\r\\ncovid screened. \\r\\nunsure which braces, wants advice. Bishal 03.03.2021",\n' +
                '                "duration": 30,\n' +
                '                "appointmentId": 14610852,\n' +
                '                "patientId": 2281878\n' +
                '            }';


        RestRequest request2 = new RestRequest();
        request2.requestURI ='services/apexrest/AppointmentIntegration/v1/';
        request2.httpMethod = 'POST';
        request2.requestBody = Blob.valueof(appointmentINFOJSON3);
        RestContext.request = request2;

        AppointmentIntegration service2 = new AppointmentIntegration();
        AppointmentIntegration.doPost();

        //

        string appointmentINFOJSON4 = '{\n' +
                '                "recordType": null,\n' +
                '                "practiceId": 250,\n' +
                '                "userId": 6886,\n' +
                '                "appointmentTypeId": 13060,\n' +
                '                "appointmentStatusId": 4,\n' +
                '                "appointmentTime": 1615389600000,\n' +
                '                "statusId": 3,\n' +
                '                "emergency": false,\n' +
                '                "appointmentNotes": "\\r\\ncovid screened. \\r\\nunsure which braces, wants advice. Bishal 03.03.2021",\n' +
                '                "duration": 30,\n' +
                '                "appointmentId": 14610852,\n' +
                '                "patientId": 2281878\n' +
                '            }';


        RestRequest request3 = new RestRequest();
        request3.requestURI ='services/apexrest/AppointmentIntegration/v1/';
        request3.httpMethod = 'POST';
        request3.requestBody = Blob.valueof(appointmentINFOJSON4);
        RestContext.request = request3;

        AppointmentIntegration service3 = new AppointmentIntegration();
        AppointmentIntegration.doPost();

        //

        string appointmentINFOJSON5 = '{\n' +
                '                "recordType": null,\n' +
                '                "practiceId": 250,\n' +
                '                "userId": 6886,\n' +
                '                "appointmentTypeId": 13060,\n' +
                '                "appointmentStatusId": 5,\n' +
                '                "appointmentTime": 1615389600000,\n' +
                '                "statusId": 3,\n' +
                '                "emergency": false,\n' +
                '                "appointmentNotes": "\\r\\ncovid screened. \\r\\nunsure which braces, wants advice. Bishal 03.03.2021",\n' +
                '                "duration": 30,\n' +
                '                "appointmentId": 14610852,\n' +
                '                "patientId": 2281878\n' +
                '            }';


        RestRequest request4 = new RestRequest();
        request4.requestURI ='services/apexrest/AppointmentIntegration/v1/';
        request4.httpMethod = 'POST';
        request4.requestBody = Blob.valueof(appointmentINFOJSON4);
        RestContext.request = request4;

        AppointmentIntegration service4 = new AppointmentIntegration();
        AppointmentIntegration.doPost();

        //

        string appointmentINFOJSON6 = '{\n' +
                '                "recordType": null,\n' +
                '                "practiceId": 250,\n' +
                '                "userId": 6886,\n' +
                '                "appointmentTypeId": 13060,\n' +
                '                "appointmentStatusId":6 ,\n' +
                '                "appointmentTime": 1615389600000,\n' +
                '                "statusId": 3,\n' +
                '                "emergency": false,\n' +
                '                "appointmentNotes": "\\r\\ncovid screened. \\r\\nunsure which braces, wants advice. Bishal 03.03.2021",\n' +
                '                "duration": 30,\n' +
                '                "appointmentId": 14610852,\n' +
                '                "patientId": 2281878\n' +
                '            }';


        RestRequest request5 = new RestRequest();
        request5.requestURI ='services/apexrest/AppointmentIntegration/v1/';
        request5.httpMethod = 'POST';
        request5.requestBody = Blob.valueof(appointmentINFOJSON6);
        RestContext.request = request5;

        AppointmentIntegration service5 = new AppointmentIntegration();
        AppointmentIntegration.doPost();

        //

        string appointmentINFOJSON7 = '{\n' +
                '                "recordType": null,\n' +
                '                "practiceId": 250,\n' +
                '                "userId": 6886,\n' +
                '                "appointmentTypeId": 13060,\n' +
                '                "appointmentStatusId":7 ,\n' +
                '                "appointmentTime": 1615389600000,\n' +
                '                "statusId": 3,\n' +
                '                "emergency": false,\n' +
                '                "appointmentNotes": "\\r\\ncovid screened. \\r\\nunsure which braces, wants advice. Bishal 03.03.2021",\n' +
                '                "duration": 30,\n' +
                '                "appointmentId": 14610852,\n' +
                '                "patientId": 2281878\n' +
                '            }';


        RestRequest request6 = new RestRequest();
        request6.requestURI ='services/apexrest/AppointmentIntegration/v1/';
        request6.httpMethod = 'POST';
        request6.requestBody = Blob.valueof(appointmentINFOJSON7);
        RestContext.request = request6;

        AppointmentIntegration service6 = new AppointmentIntegration();
        AppointmentIntegration.doPost();

        //

        string appointmentINFOJSON8 = '{\n' +
                '                "recordType": null,\n' +
                '                "practiceId": 250,\n' +
                '                "userId": 6886,\n' +
                '                "appointmentTypeId": 13060,\n' +
                '                "appointmentStatusId":8 ,\n' +
                '                "appointmentTime": 1615389600000,\n' +
                '                "statusId": 3,\n' +
                '                "emergency": false,\n' +
                '                "appointmentNotes": "\\r\\ncovid screened. \\r\\nunsure which braces, wants advice. Bishal 03.03.2021",\n' +
                '                "duration": 30,\n' +
                '                "appointmentId": 14610852,\n' +
                '                "patientId": 2281878\n' +
                '            }';


        RestRequest request7 = new RestRequest();
        request7.requestURI ='services/apexrest/AppointmentIntegration/v1/';
        request7.httpMethod = 'POST';
        request7.requestBody = Blob.valueof(appointmentINFOJSON8);
        RestContext.request = request7;

        AppointmentIntegration service7 = new AppointmentIntegration();
        AppointmentIntegration.doPost();

        //

        string appointmentINFOJSON9 = '{\n' +
                '                "recordType": null,\n' +
                '                "practiceId": 250,\n' +
                '                "userId": 6886,\n' +
                '                "appointmentTypeId": 13060,\n' +
                '                "appointmentStatusId":9 ,\n' +
                '                "appointmentTime": 1615389600000,\n' +
                '                "statusId": 3,\n' +
                '                "emergency": false,\n' +
                '                "appointmentNotes": "\\r\\ncovid screened. \\r\\nunsure which braces, wants advice. Bishal 03.03.2021",\n' +
                '                "duration": 30,\n' +
                '                "appointmentId": 14610852,\n' +
                '                "patientId": 2281878\n' +
                '            }';


        RestRequest request8 = new RestRequest();
        request8.requestURI ='services/apexrest/AppointmentIntegration/v1/';
        request8.httpMethod = 'POST';
        request8.requestBody = Blob.valueof(appointmentINFOJSON9);
        RestContext.request = request8;

        AppointmentIntegration service8 = new AppointmentIntegration();
        AppointmentIntegration.doPost();

        //

        string appointmentINFOJSON10 = '{\n' +
                '                "recordType": null,\n' +
                '                "practiceId": 250,\n' +
                '                "userId": 6886,\n' +
                '                "appointmentTypeId": 13060,\n' +
                '                "appointmentStatusId":10 ,\n' +
                '                "appointmentTime": 1615389600000,\n' +
                '                "statusId": 3,\n' +
                '                "emergency": false,\n' +
                '                "appointmentNotes": "\\r\\ncovid screened. \\r\\nunsure which braces, wants advice. Bishal 03.03.2021",\n' +
                '                "duration": 30,\n' +
                '                "appointmentId": 14610852,\n' +
                '                "patientId": 2281878\n' +
                '            }';


        RestRequest request9 = new RestRequest();
        request9.requestURI ='services/apexrest/AppointmentIntegration/v1/';
        request9.httpMethod = 'POST';
        request9.requestBody = Blob.valueof(appointmentINFOJSON10);
        RestContext.request = request9;

        AppointmentIntegration service9 = new AppointmentIntegration();
        AppointmentIntegration.doPost();

        //

        string appointmentINFOJSON11 = '{\n' +
                '                "recordType": null,\n' +
                '                "practiceId": 250,\n' +
                '                "userId": 6886,\n' +
                '                "appointmentTypeId": 13060,\n' +
                '                "appointmentStatusId":11 ,\n' +
                '                "appointmentTime": 1615389600000,\n' +
                '                "statusId": 3,\n' +
                '                "emergency": false,\n' +
                '                "appointmentNotes": "\\r\\ncovid screened. \\r\\nunsure which braces, wants advice. Bishal 03.03.2021",\n' +
                '                "duration": 30,\n' +
                '                "appointmentId": 14610852,\n' +
                '                "patientId": 2281878\n' +
                '            }';


        RestRequest request10 = new RestRequest();
        request10.requestURI ='services/apexrest/AppointmentIntegration/v1/';
        request10.httpMethod = 'POST';
        request10.requestBody = Blob.valueof(appointmentINFOJSON11);
        RestContext.request = request10;

        AppointmentIntegration service10 = new AppointmentIntegration();
        AppointmentIntegration.doPost();

        //

        string appointmentINFOJSON12 = '{\n' +
                '                "recordType": null,\n' +
                '                "practiceId": 250,\n' +
                '                "userId": 6886,\n' +
                '                "appointmentTypeId": 13060,\n' +
                '                "appointmentStatusId":12 ,\n' +
                '                "appointmentTime": 1615389600000,\n' +
                '                "statusId": 3,\n' +
                '                "emergency": false,\n' +
                '                "appointmentNotes": "\\r\\ncovid screened. \\r\\nunsure which braces, wants advice. Bishal 03.03.2021",\n' +
                '                "duration": 30,\n' +
                '                "appointmentId": 14610852,\n' +
                '                "patientId": 2281878\n' +
                '            }';


        RestRequest request11 = new RestRequest();
        request11.requestURI ='services/apexrest/AppointmentIntegration/v1/';
        request11.httpMethod = 'POST';
        request11.requestBody = Blob.valueof(appointmentINFOJSON12);
        RestContext.request = request11;

        AppointmentIntegration service11 = new AppointmentIntegration();
        AppointmentIntegration.doPost();



    }








}