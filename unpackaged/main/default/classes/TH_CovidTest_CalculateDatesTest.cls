/**
 * Created by david on 25/03/2021.
 */

@IsTest
global class TH_CovidTest_CalculateDatesTest {

    //region Order JSON no Coupon
    static String orderJSONNoCoupon = '{\n' +
            '    "personalDetails": {\n' +
            '        "firstName": "Some",\n' +
            '        "lastName": "One",\n' +
            '        "email": "someone@example.com",\n' +
            '        "phone": "9234567896"\n' +
            '    },\n' +
            '    "basket": [\n' +
            '        {\n' +
            '            "id": "{0}",\n' +
            '            "quantity": 1,\n' +
            '            "type": "covid"\n' +
            '        },\n' +
            '        {\n' +
            '            "id": "{1}",\n' +
            '            "quantity": 1,\n' +
            '            "type": "product"\n' +
            '        }' +
            '    ],\n' +
            '    "shippingInformation": {\n' +
            '        "firstName": "First",\n' +
            '        "lastName": "Last",\n' +
            '        "street": "Street North XC4",\n' +
            '        "city": "London",\n' +
            '        "postalCode": "W11",\n' +
            '        "country": "UK",\n' +
            '        "phone": "9867543210"\n' +
            '    },\n' +
            '    "basketId": "{2}",\n' +
            '    "defaultLocation": {\n' +
            '        "postalcode": "W1",\n' +
            '        "distance": "10"\n' +
            '    }\n,' +
            '   "checkTerms": true,\n' +
            '   "checkMarketing": true\n' +
            '}';
    //endregion

    // region Order JSON coupon
    static String orderJSONCoupon = '{\n' +
            '    "personalDetails": {\n' +
            '        "firstName": "Some",\n' +
            '        "lastName": "One",\n' +
            '        "email": "someone@example.com",\n' +
            '        "phone": "9234567896"\n' +
            '    },\n' +
            '    "basket": [\n' +
            '        {\n' +
            '            "id": "{0}",\n' +
            '            "quantity": 1,\n' +
            '            "type": "covid"\n' +
            '        },\n' +
            '        {\n' +
            '            "id": "{1}",\n' +
            '            "quantity": 1,\n' +
            '            "type": "product"\n' +
            '        },\n' +
            '        {\n' +
            '            "id": "{2}",\n' +
            '            "type": "coupon"\n' +
            '        }\n' +
            '    ],\n' +
            '    "shippingInformation": {\n' +
            '        "firstName": "First",\n' +
            '        "lastName": "Last",\n' +
            '        "street": "Street North XC4",\n' +
            '        "city": "London",\n' +
            '        "postalCode": "W11",\n' +
            '        "country": "UK",\n' +
            '        "phone": "9867543210"\n' +
            '    },\n' +
            '    "basketId": "{3}",\n' +
            '    "defaultLocation": {\n' +
            '        "postalcode": "W1",\n' +
            '        "distance": "10"\n' +
            '    },' +
            '   "checkTerms": true,\n' +
            '   "checkMarketing": true\n' +
            '}';
    //endregion

    //region Basket JSON
    static String basketJSONNoCoupon = '{' +
            '  "basket": [' +
            '    {' +
            '      "id": "{0}",' +
            '      "product": {' +
            '        "Quantity_of_COVID_Tests__c": 1,' +
            '        "Turnaround_Time__c": "48 hour",' +
            '        "Requires_scheduling__c": true,' +
            '        "Requires_delivery__c": false,' +
            '        "Product_Sub_Family__c": "PCR Test",' +
            '        "Work_Type_Group__c": "0VS4H000000000YWAQ",' +
            '        "Name": "PCR Test 48 Hours",' +
            '        "Id": "01t3H000000xB9RQAU"' +
            '        "type": "covid"' +
            '      },' +
            '      "quantity": 1,' +
            '      "type": "covid",' +
            '      "delivery": false,' +
            '      "scheduling": true,' +
            '      "totalPrice": 149' +
            '    },' +
            '    {' +
            '      "id": "{1}",' +
            '      "product": {' +
            '        "Requires_scheduling__c": false,' +
            '        "Requires_delivery__c": true,' +
            '        "Name": "Obagi Professional Vit-C serum 15%",' +
            '        "Id": "01t58000005I7QLAA0"' +
            '        "type": "product"' +
            '      },' +
            '      "quantity": 1,' +
            '      "type": "product",' +
            '      "delivery": true,' +
            '      "scheduling": false,' +
            '      "totalPrice": 21' +
            '    }' +
            '  ],' +
            '  "defaultLocation": {' +
            '    "postalcode": "W12",' +
            '    "distance": "25"' +
            '  }' +
            '}';

    //endregion

    //region WORK_TYPE_GROUP_STRING
    public static final String WORK_TYPE_GROUP_STRING = '[' +
            '  {' +
            '    "attributes": {' +
            '      "type": "WorkTypeGroup",' +
            '      "url": "/services/data/v51.0/sobjects/WorkTypeGroup/0VS4H0000000001WAA"' +
            '    },' +
            '    "Clinic_Service_Code__c": "FTF",' +
            '    "GroupType": "Default",' +
            '    "Id": "0VS4H0000000001WAA",' +
            '    "IsActive": true,' +
            '    "Name": "Fit to Fly Same Day",' +
            '    "Price__c": 149.00,' +
            '    "Turnaround_Time__c": "Same Day"' +
            '  },' +
            '  {' +
            '    "attributes": {' +
            '      "type": "WorkTypeGroup",' +
            '      "url": "/services/data/v51.0/sobjects/WorkTypeGroup/0VS4H0000000006WAA"' +
            '    },' +
            '    "Clinic_Service_Code__c": "PCR",' +
            '    "GroupType": "Default",' +
            '    "Id": "0VS4H0000000006WAA",' +
            '    "IsActive": true,' +
            '    "Name": "PCR Test Same Day",' +
            '    "Price__c": 149.00,' +
            '    "Turnaround_Time__c": "Same Day"' +
            '  },' +
            '  {' +
            '    "attributes": {' +
            '      "type": "WorkTypeGroup",' +
            '      "url": "/services/data/v51.0/sobjects/WorkTypeGroup/0VS4H0000000007WAA"' +
            '    },' +
            '    "Clinic_Service_Code__c": "TTR",' +
            '    "GroupType": "Default",' +
            '    "Id": "0VS4H0000000007WAA",' +
            '    "IsActive": true,' +
            '    "Name": "Test to Release Test Same Day",' +
            '    "Price__c": 149.00,' +
            '    "Turnaround_Time__c": "Same Day"' +
            '  },' +
            '  {' +
            '    "attributes": {' +
            '      "type": "WorkTypeGroup",' +
            '      "url": "/services/data/v51.0/sobjects/WorkTypeGroup/0VS4H0000000008WAA"' +
            '    },' +
            '    "Clinic_Service_Code__c": "FTFTTR",' +
            '    "GroupType": "Default",' +
            '    "Id": "0VS4H0000000008WAA",' +
            '    "IsActive": true,' +
            '    "Name": "Fit to Fly & Test to Release Package Same Day",' +
            '    "Price__c": 149.00,' +
            '    "Turnaround_Time__c": "Same Day"' +
            '  },' +
            '  {' +
            '    "attributes": {' +
            '      "type": "WorkTypeGroup",' +
            '      "url": "/services/data/v51.0/sobjects/WorkTypeGroup/0VS4H000000000BWAQ"' +
            '    },' +
            '    "Clinic_Service_Code__c": "ANTIBODY",' +
            '    "GroupType": "Default",' +
            '    "Id": "0VS4H000000000BWAQ",' +
            '    "IsActive": true,' +
            '    "Name": "Antibody Test",' +
            '    "Price__c": 69.00,' +
            '    "Turnaround_Time__c": "Next Day"' +
            '  },' +
            '  {' +
            '    "attributes": {' +
            '      "type": "WorkTypeGroup",' +
            '      "url": "/services/data/v51.0/sobjects/WorkTypeGroup/0VS4H000000000CWAQ"' +
            '    },' +
            '    "Clinic_Service_Code__c": "RT",' +
            '    "GroupType": "Default",' +
            '    "Id": "0VS4H000000000CWAQ",' +
            '    "IsActive": true,' +
            '    "Name": "Rapid Test",' +
            '    "Price__c": 149.00,' +
            '    "Turnaround_Time__c": "Next Day"' +
            '  },' +
            '  {' +
            '    "attributes": {' +
            '      "type": "WorkTypeGroup",' +
            '      "url": "/services/data/v51.0/sobjects/WorkTypeGroup/0VS4H000000000SWAQ"' +
            '    },' +
            '    "Clinic_Service_Code__c": "TTR",' +
            '    "GroupType": "Default",' +
            '    "Id": "0VS4H000000000SWAQ",' +
            '    "IsActive": true,' +
            '    "Name": "Test to Release Next Day",' +
            '    "Price__c": 149.00,' +
            '    "Turnaround_Time__c": "Next Day"' +
            '  },' +
            '  {' +
            '    "attributes": {' +
            '      "type": "WorkTypeGroup",' +
            '      "url": "/services/data/v51.0/sobjects/WorkTypeGroup/0VS4H000000000TWAQ"' +
            '    },' +
            '    "Clinic_Service_Code__c": "TTR",' +
            '    "GroupType": "Default",' +
            '    "Id": "0VS4H000000000TWAQ",' +
            '    "IsActive": true,' +
            '    "Name": "Test to Release 48 Hour",' +
            '    "Price__c": 149.00,' +
            '    "Turnaround_Time__c": "Next Day"' +
            '  },' +
            '  {' +
            '    "attributes": {' +
            '      "type": "WorkTypeGroup",' +
            '      "url": "/services/data/v51.0/sobjects/WorkTypeGroup/0VS4H000000000UWAQ"' +
            '    },' +
            '    "Clinic_Service_Code__c": "FTFTTR",' +
            '    "GroupType": "Default",' +
            '    "Id": "0VS4H000000000UWAQ",' +
            '    "IsActive": true,' +
            '    "Name": "Fit to Fly & Test To Release Next Day",' +
            '    "Price__c": 149.00,' +
            '    "Turnaround_Time__c": "Next Day"' +
            '  },' +
            '  {' +
            '    "attributes": {' +
            '      "type": "WorkTypeGroup",' +
            '      "url": "/services/data/v51.0/sobjects/WorkTypeGroup/0VS4H000000000XWAQ"' +
            '    },' +
            '    "Clinic_Service_Code__c": "PCR",' +
            '    "GroupType": "Default",' +
            '    "Id": "0VS4H000000000XWAQ",' +
            '    "IsActive": true,' +
            '    "Name": "PCR Test Next Day",' +
            '    "Price__c": 149.00,' +
            '    "Turnaround_Time__c": "Next Day"' +
            '  },' +
            '  {' +
            '    "attributes": {' +
            '      "type": "WorkTypeGroup",' +
            '      "url": "/services/data/v51.0/sobjects/WorkTypeGroup/0VS4H000000000YWAQ"' +
            '    },' +
            '    "Clinic_Service_Code__c": "PCR",' +
            '    "GroupType": "Default",' +
            '    "Id": "0VS4H000000000YWAQ",' +
            '    "IsActive": true,' +
            '    "Name": "PCR Test 48 Hours",' +
            '    "Price__c": 149.00,' +
            '    "Turnaround_Time__c": "Next Day"' +
            '  },' +
            '  {' +
            '    "attributes": {' +
            '      "type": "WorkTypeGroup",' +
            '      "url": "/services/data/v51.0/sobjects/WorkTypeGroup/0VS4H000000000kWAA"' +
            '    },' +
            '    "Clinic_Service_Code__c": "FTF",' +
            '    "GroupType": "Default",' +
            '    "Id": "0VS4H000000000kWAA",' +
            '    "IsActive": true,' +
            '    "Name": "Fit to Fly Next Day",' +
            '    "Price__c": 149.00,' +
            '    "Turnaround_Time__c": "Next Day"' +
            '  },' +
            '  {' +
            '    "attributes": {' +
            '      "type": "WorkTypeGroup",' +
            '      "url": "/services/data/v51.0/sobjects/WorkTypeGroup/0VS4H000000000lWAA"' +
            '    },' +
            '    "Clinic_Service_Code__c": "FTF",' +
            '    "GroupType": "Default",' +
            '    "Id": "0VS4H000000000lWAA",' +
            '    "IsActive": true,' +
            '    "Name": "Fit to Fly 48 Hour",' +
            '    "Price__c": 149.00,' +
            '    "Turnaround_Time__c": "Next Day"' +
            '  },' +
            '  {' +
            '    "attributes": {' +
            '      "type": "WorkTypeGroup",' +
            '      "url": "/services/data/v51.0/sobjects/WorkTypeGroup/0VS4H000000000pWAA"' +
            '    },' +
            '    "Clinic_Service_Code__c": "FTFTTR",' +
            '    "GroupType": "Default",' +
            '    "Id": "0VS4H000000000pWAA",' +
            '    "IsActive": true,' +
            '    "Name": "Fit to Fly & Test To Release 48 Hour",' +
            '    "Price__c": 149.00,' +
            '    "Turnaround_Time__c": "Next Day"' +
            '  }' +
            ']';
    //endregion

    //region SERVICE_APPOINTMENT_STRING
    public static final String SERVICE_APPOINTMENT_STRING = '[ {\n' +
            '  "attributes" : {\n' +
            '    "type" : "ServiceAppointment",\n' +
            '    "url" : "/services/data/v51.0/sobjects/ServiceAppointment/08p3H000000ASefQAG"\n' +
            '  },\n' +
            '  "Address" : {\n' +
            '    "city" : "London",\n' +
            '    "country" : "United Kingdom",\n' +
            '    "geocodeAccuracy" : "ExtendedZip",\n' +
            '    "latitude" : 51.46422,\n' +
            '    "longitude" : -0.18544,\n' +
            '    "postalCode" : "SW18 1TS",\n' +
            '    "state" : null,\n' +
            '    "street" : null\n' +
            '  },\n' +
            '  "ArrivalWindowEndTime" : "2021-03-15T11:30:00.000+0000",\n' +
            '  "ArrivalWindowStartTime" : "2021-03-15T11:20:00.000+0000",\n' +
            '  "City" : "London",\n' +
            '  "Country" : "United Kingdom",\n' +
            '  "DueDate" : "2021-03-22T11:10:40.000+0000",\n' +
            '  "DurationType" : "Hours",\n' +
            '  "EarliestStartTime" : "2021-03-15T11:10:40.000+0000",\n' +
            '  "Latitude" : 51.464220000000000,\n' +
            '  "Longitude" : -0.185440000000000,\n' +
            '  "PostalCode" : "SW18 1TS",\n' +
            '  "SchedEndTime" : "2021-03-15T11:30:00.000+0000",\n' +
            '  "SchedStartTime" : "2021-03-15T11:20:00.000+0000",\n' +
            '  "Status" : "Scheduled",\n' +
            '  "StatusCategory" : "Scheduled",\n' +
            '  "Id" : "08p3H000000ASefQAG"\n' +
            '} ]';
    //endregion

    //region SERVICE_TERRITORY_STRING
    public static final String SERVICE_TERRITORY_STRING = '[ {\n' +
            '  "attributes" : {\n' +
            '    "type" : "ServiceTerritory",\n' +
            '    "url" : "/services/data/v51.0/sobjects/ServiceTerritory/0Hh4H0000004CZJSA2"\n' +
            '  },\n' +
            '  "Address" : {\n' +
            '    "city" : "London",\n' +
            '    "country" : "United Kingdom",\n' +
            '    "geocodeAccuracy" : "ExtendedZip",\n' +
            '    "latitude" : 51.46422,\n' +
            '    "longitude" : -0.18544,\n' +
            '    "postalCode" : "SW18 1TS",\n' +
            '    "state" : null,\n' +
            '    "street" : null\n' +
            '  },\n' +
            '  "City" : "London",\n' +
            '  "Country" : "United Kingdom",\n' +
            '  "GeocodeAccuracy" : "ExtendedZip",\n' +
            '  "IsActive" : true,\n' +
            '  "Latitude" : 51.464220000000000,\n' +
            '  "Longitude" : -0.185440000000000,\n' +
            '  "Name" : "Wandsworth - Baltimore House",\n' +
            '  "PostalCode" : "SW18 1TS",\n' +
            '  "SystemModstamp" : "2021-02-08T13:18:29.000+0000",\n' +
            '  "Id" : "0Hh4H0000004CZJSA2"\n' +
            '} ]';
    //endregion

    //region OPERATING_HOURS_STRING
    public static final String OPERATING_HOURS_STRING = '[ {\n' +
            '  "attributes" : {\n' +
            '    "type" : "OperatingHours",\n' +
            '    "url" : "/services/data/v51.0/sobjects/OperatingHours/0OH4H0000004CgyWAE"\n' +
            '  },\n' +
            '  "Id" : "0OH4H0000004CgyWAE",\n' +
            '  "Name" : "Wandsworth Baltimore Opening Hours",\n' +
            '  "TimeZone" : "Europe/London"\n' +
            '} ]';
    //endregion

    //region WORK_TYPE_STRING
    public static final String WORK_TYPE_STRING = '[ {\n' +
            '  "attributes" : {\n' +
            '    "type" : "WorkType",\n' +
            '    "url" : "/services/data/v51.0/sobjects/WorkType/08q4H0000004CdSQAU"\n' +
            '  },\n' +
            '  "BlockTimeAfterUnit" : "Minutes",\n' +
            '  "BlockTimeBeforeUnit" : "Minutes",\n' +
            '  "DurationInMinutes" : 10.00,\n' +
            '  "DurationType" : "Minutes",\n' +
            '  "EstimatedDuration" : 10.00,\n' +
            '  "Id" : "08q4H0000004CdSQAU",\n' +
            '  "Name" : "Antibody Test",\n' +
            '  "TimeFrameEndUnit" : "Days",\n' +
            '  "TimeFrameStartUnit" : "Days"\n' +
            '}, {\n' +
            '  "attributes" : {\n' +
            '    "type" : "WorkType",\n' +
            '    "url" : "/services/data/v51.0/sobjects/WorkType/08q4H0000004CdTQAU"\n' +
            '  },\n' +
            '  "BlockTimeAfterUnit" : "Minutes",\n' +
            '  "BlockTimeBeforeUnit" : "Minutes",\n' +
            '  "DurationInMinutes" : 10.00,\n' +
            '  "DurationType" : "Minutes",\n' +
            '  "EstimatedDuration" : 10.00,\n' +
            '  "Id" : "08q4H0000004CdTQAU",\n' +
            '  "Name" : "PCR Test 48 Hours",\n' +
            '  "TimeFrameEndUnit" : "Days",\n' +
            '  "TimeFrameStartUnit" : "Days"\n' +
            '}, {\n' +
            '  "attributes" : {\n' +
            '    "type" : "WorkType",\n' +
            '    "url" : "/services/data/v51.0/sobjects/WorkType/08q4H0000004CdXQAU"\n' +
            '  },\n' +
            '  "BlockTimeAfterUnit" : "Minutes",\n' +
            '  "BlockTimeBeforeUnit" : "Minutes",\n' +
            '  "DurationInMinutes" : 10.00,\n' +
            '  "DurationType" : "Minutes",\n' +
            '  "EstimatedDuration" : 10.00,\n' +
            '  "Id" : "08q4H0000004CdXQAU",\n' +
            '  "Name" : "PCR Same Day - Weekdays Only",\n' +
            '  "OperatingHoursId" : "0OH4H0000004ChHWAU",\n' +
            '  "TimeFrameEndUnit" : "Days",\n' +
            '  "TimeFrameStartUnit" : "Days"\n' +
            '}, {\n' +
            '  "attributes" : {\n' +
            '    "type" : "WorkType",\n' +
            '    "url" : "/services/data/v51.0/sobjects/WorkType/08q4H0000004CdcQAE"\n' +
            '  },\n' +
            '  "BlockTimeAfterUnit" : "Minutes",\n' +
            '  "BlockTimeBeforeUnit" : "Minutes",\n' +
            '  "DurationInMinutes" : 10.00,\n' +
            '  "DurationType" : "Minutes",\n' +
            '  "EstimatedDuration" : 10.00,\n' +
            '  "Id" : "08q4H0000004CdcQAE",\n' +
            '  "Name" : "Fit To Fly Same Day - Weekdays Only",\n' +
            '  "OperatingHoursId" : "0OH4H0000004ChHWAU",\n' +
            '  "TimeFrameEndUnit" : "Days",\n' +
            '  "TimeFrameStartUnit" : "Days"\n' +
            '}, {\n' +
            '  "attributes" : {\n' +
            '    "type" : "WorkType",\n' +
            '    "url" : "/services/data/v51.0/sobjects/WorkType/08q4H0000004CdhQAE"\n' +
            '  },\n' +
            '  "BlockTimeAfterUnit" : "Minutes",\n' +
            '  "BlockTimeBeforeUnit" : "Minutes",\n' +
            '  "DurationInMinutes" : 600.00,\n' +
            '  "DurationType" : "Hours",\n' +
            '  "EstimatedDuration" : 10.00,\n' +
            '  "Id" : "08q4H0000004CdhQAE",\n' +
            '  "Name" : "Test to Release Same Day - Weekdays Only",\n' +
            '  "OperatingHoursId" : "0OH4H0000004ChHWAU",\n' +
            '  "TimeFrameEndUnit" : "Days",\n' +
            '  "TimeFrameStartUnit" : "Days"\n' +
            '}, {\n' +
            '  "attributes" : {\n' +
            '    "type" : "WorkType",\n' +
            '    "url" : "/services/data/v51.0/sobjects/WorkType/08q4H0000004CdmQAE"\n' +
            '  },\n' +
            '  "BlockTimeAfterUnit" : "Minutes",\n' +
            '  "BlockTimeBeforeUnit" : "Minutes",\n' +
            '  "DurationInMinutes" : 600.00,\n' +
            '  "DurationType" : "Hours",\n' +
            '  "EstimatedDuration" : 10.00,\n' +
            '  "Id" : "08q4H0000004CdmQAE",\n' +
            '  "Name" : "Fit to Fly & Test To Release Same Day - Weekdays Only",\n' +
            '  "OperatingHoursId" : "0OH4H0000004ChHWAU",\n' +
            '  "TimeFrameEndUnit" : "Days",\n' +
            '  "TimeFrameStartUnit" : "Days"\n' +
            '}, {\n' +
            '  "attributes" : {\n' +
            '    "type" : "WorkType",\n' +
            '    "url" : "/services/data/v51.0/sobjects/WorkType/08q4H0000004Cd3QAE"\n' +
            '  },\n' +
            '  "BlockTimeAfterAppointment" : 0,\n' +
            '  "BlockTimeAfterUnit" : "Minutes",\n' +
            '  "BlockTimeBeforeAppointment" : 0,\n' +
            '  "BlockTimeBeforeUnit" : "Minutes",\n' +
            '  "DurationInMinutes" : 10.00,\n' +
            '  "DurationType" : "Minutes",\n' +
            '  "EstimatedDuration" : 10.00,\n' +
            '  "Id" : "08q4H0000004Cd3QAE",\n' +
            '  "Name" : "Fit To Fly Same Day - 7 Days",\n' +
            '  "OperatingHoursId" : "0OH4H0000004CgiWAE",\n' +
            '  "TimeFrameEndUnit" : "Days",\n' +
            '  "TimeFrameStartUnit" : "Days"\n' +
            '}, {\n' +
            '  "attributes" : {\n' +
            '    "type" : "WorkType",\n' +
            '    "url" : "/services/data/v51.0/sobjects/WorkType/08q4H0000004Cd8QAE"\n' +
            '  },\n' +
            '  "BlockTimeAfterUnit" : "Minutes",\n' +
            '  "BlockTimeBeforeUnit" : "Minutes",\n' +
            '  "DurationInMinutes" : 10.00,\n' +
            '  "DurationType" : "Minutes",\n' +
            '  "EstimatedDuration" : 10.00,\n' +
            '  "Id" : "08q4H0000004Cd8QAE",\n' +
            '  "Name" : "Fit to Fly Next Day",\n' +
            '  "OperatingHoursId" : "0OH4H0000004CgnWAE",\n' +
            '  "TimeFrameEndUnit" : "Days",\n' +
            '  "TimeFrameStartUnit" : "Days"\n' +
            '}, {\n' +
            '  "attributes" : {\n' +
            '    "type" : "WorkType",\n' +
            '    "url" : "/services/data/v51.0/sobjects/WorkType/08q4H0000004Cd9QAE"\n' +
            '  },\n' +
            '  "BlockTimeAfterUnit" : "Minutes",\n' +
            '  "BlockTimeBeforeUnit" : "Minutes",\n' +
            '  "DurationInMinutes" : 10.00,\n' +
            '  "DurationType" : "Minutes",\n' +
            '  "EstimatedDuration" : 10.00,\n' +
            '  "Id" : "08q4H0000004Cd9QAE",\n' +
            '  "Name" : "Test to Release Same Day - 7 Days",\n' +
            '  "OperatingHoursId" : "0OH4H0000004CgiWAE",\n' +
            '  "TimeFrameEndUnit" : "Days",\n' +
            '  "TimeFrameStartUnit" : "Days"\n' +
            '}, {\n' +
            '  "attributes" : {\n' +
            '    "type" : "WorkType",\n' +
            '    "url" : "/services/data/v51.0/sobjects/WorkType/08q4H0000004CdDQAU"\n' +
            '  },\n' +
            '  "BlockTimeAfterUnit" : "Minutes",\n' +
            '  "BlockTimeBeforeUnit" : "Minutes",\n' +
            '  "DurationInMinutes" : 10.00,\n' +
            '  "DurationType" : "Minutes",\n' +
            '  "EstimatedDuration" : 10.00,\n' +
            '  "Id" : "08q4H0000004CdDQAU",\n' +
            '  "Name" : "Fit to Fly 48 Hour",\n' +
            '  "TimeFrameEndUnit" : "Days",\n' +
            '  "TimeFrameStartUnit" : "Days"\n' +
            '}, {\n' +
            '  "attributes" : {\n' +
            '    "type" : "WorkType",\n' +
            '    "url" : "/services/data/v51.0/sobjects/WorkType/08q4H0000004CdEQAU"\n' +
            '  },\n' +
            '  "BlockTimeAfterUnit" : "Minutes",\n' +
            '  "BlockTimeBeforeUnit" : "Minutes",\n' +
            '  "DurationInMinutes" : 10.00,\n' +
            '  "DurationType" : "Minutes",\n' +
            '  "EstimatedDuration" : 10.00,\n' +
            '  "Id" : "08q4H0000004CdEQAU",\n' +
            '  "Name" : "Fit to Fly & Test To Release 48 Hour",\n' +
            '  "TimeFrameEndUnit" : "Days",\n' +
            '  "TimeFrameStartUnit" : "Days"\n' +
            '}, {\n' +
            '  "attributes" : {\n' +
            '    "type" : "WorkType",\n' +
            '    "url" : "/services/data/v51.0/sobjects/WorkType/08q4H0000004CdFQAU"\n' +
            '  },\n' +
            '  "BlockTimeAfterUnit" : "Minutes",\n' +
            '  "BlockTimeBeforeUnit" : "Minutes",\n' +
            '  "DurationInMinutes" : 10.00,\n' +
            '  "DurationType" : "Minutes",\n' +
            '  "EstimatedDuration" : 10.00,\n' +
            '  "Id" : "08q4H0000004CdFQAU",\n' +
            '  "Name" : "PCR Test Same Day - 7 Days",\n' +
            '  "OperatingHoursId" : "0OH4H0000004CgiWAE",\n' +
            '  "TimeFrameEndUnit" : "Days",\n' +
            '  "TimeFrameStartUnit" : "Days"\n' +
            '}, {\n' +
            '  "attributes" : {\n' +
            '    "type" : "WorkType",\n' +
            '    "url" : "/services/data/v51.0/sobjects/WorkType/08q4H0000004CdGQAU"\n' +
            '  },\n' +
            '  "BlockTimeAfterUnit" : "Minutes",\n' +
            '  "BlockTimeBeforeUnit" : "Minutes",\n' +
            '  "DurationInMinutes" : 10.00,\n' +
            '  "DurationType" : "Minutes",\n' +
            '  "EstimatedDuration" : 10.00,\n' +
            '  "Id" : "08q4H0000004CdGQAU",\n' +
            '  "Name" : "PCR Test Next Day",\n' +
            '  "OperatingHoursId" : "0OH4H0000004CgnWAE",\n' +
            '  "TimeFrameEndUnit" : "Days",\n' +
            '  "TimeFrameStartUnit" : "Days"\n' +
            '}, {\n' +
            '  "attributes" : {\n' +
            '    "type" : "WorkType",\n' +
            '    "url" : "/services/data/v51.0/sobjects/WorkType/08q4H0000004CdHQAU"\n' +
            '  },\n' +
            '  "BlockTimeAfterUnit" : "Minutes",\n' +
            '  "BlockTimeBeforeUnit" : "Minutes",\n' +
            '  "DurationInMinutes" : 10.00,\n' +
            '  "DurationType" : "Minutes",\n' +
            '  "EstimatedDuration" : 10.00,\n' +
            '  "Id" : "08q4H0000004CdHQAU",\n' +
            '  "Name" : "Rapid Test",\n' +
            '  "TimeFrameEndUnit" : "Days",\n' +
            '  "TimeFrameStartUnit" : "Days"\n' +
            '}, {\n' +
            '  "attributes" : {\n' +
            '    "type" : "WorkType",\n' +
            '    "url" : "/services/data/v51.0/sobjects/WorkType/08q4H0000004CdIQAU"\n' +
            '  },\n' +
            '  "BlockTimeAfterUnit" : "Minutes",\n' +
            '  "BlockTimeBeforeUnit" : "Minutes",\n' +
            '  "DurationInMinutes" : 10.00,\n' +
            '  "DurationType" : "Minutes",\n' +
            '  "EstimatedDuration" : 10.00,\n' +
            '  "Id" : "08q4H0000004CdIQAU",\n' +
            '  "Name" : "Test to Release Next Day",\n' +
            '  "OperatingHoursId" : "0OH4H0000004CgnWAE",\n' +
            '  "TimeFrameEndUnit" : "Days",\n' +
            '  "TimeFrameStartUnit" : "Days"\n' +
            '}, {\n' +
            '  "attributes" : {\n' +
            '    "type" : "WorkType",\n' +
            '    "url" : "/services/data/v51.0/sobjects/WorkType/08q4H0000004CdJQAU"\n' +
            '  },\n' +
            '  "BlockTimeAfterUnit" : "Minutes",\n' +
            '  "BlockTimeBeforeUnit" : "Minutes",\n' +
            '  "DurationInMinutes" : 10.00,\n' +
            '  "DurationType" : "Minutes",\n' +
            '  "EstimatedDuration" : 10.00,\n' +
            '  "Id" : "08q4H0000004CdJQAU",\n' +
            '  "Name" : "Test to Release 48 Hour",\n' +
            '  "TimeFrameEndUnit" : "Days",\n' +
            '  "TimeFrameStartUnit" : "Days"\n' +
            '}, {\n' +
            '  "attributes" : {\n' +
            '    "type" : "WorkType",\n' +
            '    "url" : "/services/data/v51.0/sobjects/WorkType/08q4H0000004CdNQAU"\n' +
            '  },\n' +
            '  "BlockTimeAfterAppointment" : 0,\n' +
            '  "BlockTimeAfterUnit" : "Minutes",\n' +
            '  "BlockTimeBeforeAppointment" : 0,\n' +
            '  "BlockTimeBeforeUnit" : "Minutes",\n' +
            '  "DurationInMinutes" : 10.00,\n' +
            '  "DurationType" : "Minutes",\n' +
            '  "EstimatedDuration" : 10.00,\n' +
            '  "Id" : "08q4H0000004CdNQAU",\n' +
            '  "Name" : "Fit to Fly & Test To Release Same Day - 7 Days",\n' +
            '  "OperatingHoursId" : "0OH4H0000004CgiWAE",\n' +
            '  "TimeframeEnd" : 0,\n' +
            '  "TimeFrameEndUnit" : "Days",\n' +
            '  "TimeframeStart" : 0,\n' +
            '  "TimeFrameStartUnit" : "Days"\n' +
            '}, {\n' +
            '  "attributes" : {\n' +
            '    "type" : "WorkType",\n' +
            '    "url" : "/services/data/v51.0/sobjects/WorkType/08q4H0000004CdOQAU"\n' +
            '  },\n' +
            '  "BlockTimeAfterUnit" : "Minutes",\n' +
            '  "BlockTimeBeforeUnit" : "Minutes",\n' +
            '  "DurationInMinutes" : 10.00,\n' +
            '  "DurationType" : "Minutes",\n' +
            '  "EstimatedDuration" : 10.00,\n' +
            '  "Id" : "08q4H0000004CdOQAU",\n' +
            '  "Name" : "Fit to Fly & Test To Release Next Day",\n' +
            '  "OperatingHoursId" : "0OH4H0000004CgnWAE",\n' +
            '  "TimeFrameEndUnit" : "Days",\n' +
            '  "TimeFrameStartUnit" : "Days"\n' +
            '} ]';
    //endregion

    global class ServiceMock implements HttpCalloutMock {

        public Map<String, MockConfig> mockConfigs;

        global ServiceMock(Map<String, MockConfig> mockConfigs) {
            this.mockConfigs = mockConfigs;
        }

        global HttpResponse respond(HttpRequest req) {
            for (String str : mockConfigs.keySet()) {
                if (req.getEndpoint().contains(str)) {
                    MockConfig mConfig = mockConfigs.get(str);
                    if (mConfig.throwException) {
                        Integer divideByZero = 2 / 0;
                    }
                    HttpResponse res = new HttpResponse();

                    System.assert(req != null);
                    //			System.assertEquals(method, req.getMethod());
                    res.setBody(mConfig.body);
                    res.setStatusCode(mConfig.code);
                    res.setStatus(mConfig.status);
                    return res;
                }
            }
            return null;

        }
    }

    global class MockConfig {
        public String body ;
        public String status ;
        public Integer code ;
        public Boolean throwException;

        public MockConfig(
                String body,
                String status,
                Integer code,
                Boolean throwException
        ) {
            this.body = body;
            this.status = status;
            this.code = code;
            this.throwException = throwException;
        }
    }


    @TestSetup static void dataSetup() {
        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
        List<ServiceTerritory> serviceTerritories = (List<ServiceTerritory>) JSON.deserialize(SERVICE_TERRITORY_STRING, List<ServiceTerritory>.class);
        List<ServiceAppointment> serviceAppointments = (List<ServiceAppointment>) JSON.deserialize(SERVICE_APPOINTMENT_STRING, List<ServiceAppointment>.class);
        List<OperatingHours> operatingHours = (List<OperatingHours>) JSON.deserialize(OPERATING_HOURS_STRING, List<OperatingHours>.class);
        List<WorkType> workTypes = (List<WorkType>) JSON.deserialize(WORK_TYPE_STRING, List<WorkType>.class);

        for (OperatingHours operatingHour : operatingHours) {
            operatingHour.Id = null;
        }
        insert operatingHours;

        for (ServiceTerritory serviceTerritory : serviceTerritories) {
            serviceTerritory.Id = null;
            serviceTerritory.OperatingHoursId = operatingHours[0].Id;
        }
        insert serviceTerritories;

        List<WorkTypeGroup> workTypeGroups = (List<WorkTypeGroup>) JSON.deserialize(WORK_TYPE_GROUP_STRING, List<WorkTypeGroup>.class);
        for (WorkTypeGroup workTypeGroup : workTypeGroups) {
            workTypeGroup.Id = null;
        }

        insert workTypeGroups;

        for (WorkType workType : workTypes) {
            workType.Id = null;
            workType.OperatingHoursId = operatingHours[0].Id;
        }
        insert workTypes;

        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            serviceAppointment.Id = null;
            serviceAppointment.ServiceTerritoryId = serviceTerritories[0].Id;
            serviceAppointment.ParentRecordId = accounts[0].Id;
            serviceAppointment.WorkTypeId = workTypes[0].Id;
        }
        insert serviceAppointments;

        insert new WorkTypeGroupMember(WorkTypeId = workTypes[0].Id, WorkTypeGroupId = workTypeGroups[0].Id);
        insert new WorkTypeGroupMember(WorkTypeId = workTypes[1].Id, WorkTypeGroupId = workTypeGroups[0].Id);
        insert new ServiceTerritoryWorkType(WorkTypeId = workTypes[0].Id, ServiceTerritoryId = serviceTerritories[0].Id);

        Map<String, String> productNameMap = new Map<String, String>{
                'ANTIBODY' => 'Antibody Test',
                'FTF' => 'Fit to Fly PCR Test',
                'PCR' => 'PCR Test',
                'RT' => 'Rapid Test',
                'FTFTTR' => 'Fit to Fly Rapid (Lateral Flow)',
                'TTR' => 'Day 5 Test to Release'
        };

        List<Product2> productsToInsert = new List<Product2>();
        System.debug(LoggingLevel.ERROR, 'dataSetup - workTypeGroups: ' + workTypeGroups.size());
        for (WorkTypeGroup workTypeGroup : workTypeGroups) {
            Product2 newProduct = new Product2();
            newProduct.Name = workTypeGroup.Name;
            newProduct.Membership_Price__c = workTypeGroup.Price__c;
            newProduct.Non_Membership_Price__c = workTypeGroup.Price__c;
            newProduct.Family = 'COVID Tests';
            newProduct.IsActive = true;
            newProduct.Quantity_of_COVID_Tests__c = 1;
            newProduct.Quantity__c = '' + 1;
            newProduct.Include_in_Store__c = true;
            newProduct.Requires_scheduling__c = true;
            newProduct.Requires_delivery__c = false;
            newProduct.Turnaround_Time_Global__c = workTypeGroup.Turnaround_Time__c;
            newProduct.Product_Sub_Family__c = productNameMap.get(workTypeGroup.Clinic_Service_Code__c);
            newProduct.Work_Type_Group__c = workTypeGroup.Id;
            newProduct.Store_Categories__c = productNameMap.get(workTypeGroup.Clinic_Service_Code__c) + ';' + workTypeGroup.Turnaround_Time__c;

            productsToInsert.add(newProduct);
        }

        Product2 newProduct = new Product2();
        newProduct.Name = 'Cream';
        newProduct.Membership_Price__c = 150;
        newProduct.Non_Membership_Price__c = 150;
        newProduct.Family = 'Skin';
        newProduct.IsActive = true;
        newProduct.Quantity__c = '' + 1;
        newProduct.Include_in_Store__c = true;
        newProduct.Requires_scheduling__c = false;
        newProduct.Requires_delivery__c = true;
        newProduct.Store_Categories__c = 'Products';
        productsToInsert.add(newProduct);

        newProduct = new Product2();
        newProduct.Name = 'Discount';
        newProduct.Membership_Price__c = 0;
        newProduct.Non_Membership_Price__c = 0;
        newProduct.Family = 'Discount';
        newProduct.IsActive = true;
        newProduct.Quantity__c = '' + 1;
        newProduct.Include_in_Store__c = false;
        newProduct.Requires_scheduling__c = false;
        newProduct.Requires_delivery__c = false;
        productsToInsert.add(newProduct);

        insert productsToInsert;
        List<Default_COVID_Test__c> defaultTestsToInsert = new List<Default_COVID_Test__c>();
        for (Product2 prod : productsToInsert) {
            if (prod.Family == 'COVID Tests') {
                Default_COVID_Test__c defaultCOVIDTest = new Default_COVID_Test__c();
                defaultCOVIDTest.Product__c = prod.Id;
                defaultCOVIDTest.COVID_Test_Type__c = Product2.Test_Type__c.getDescribe().getPicklistValues()[0].getValue();
                defaultCOVIDTest.Number_of_Tests__c = 1;
                defaultCOVIDTest.Work_Type_Group__c = prod.Work_Type_Group__c;
                defaultCOVIDTest.First_Available__c = true;
                defaultTestsToInsert.add(defaultCOVIDTest);
            }
        }
        insert defaultTestsToInsert;

        Id pbid = Test.getStandardPricebookId();
        Pricebook2 pb = new Pricebook2(Id = pbid);
        pb.IsActive = true;
        update pb;
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();

        for (Product2 prod : productsToInsert) {
            PricebookEntry pbEntry = new PricebookEntry();
            pbEntry.Product2Id = prod.Id;
            pbEntry.UnitPrice = prod.Membership_Price__c;
            //    pbEntry.UseStandardPrice = true;
            pbEntry.Pricebook2Id = pbid;
            pbEntry.IsActive = true;

            pricebookEntries.add(pbEntry);
        }

        insert pricebookEntries;
    }

    @IsTest
    static void testCalculateDates() {


        Uuid newUuid = new Uuid();
        String basketSession = newUuid.getValue();
        Basket__c newBasket = new Basket__c(
                Session_Id__c = basketSession,
                Basket_JSON__c = basketJSONNoCoupon
        );

        insert newBasket;

        OnlineStoreSettingsManager.storeSettings = TestDataFactory.getOnlineStoreSettings();
        ServiceAppointment serviceAppointment = [SELECT Id, ServiceTerritoryId, WorkTypeId FROM ServiceAppointment LIMIT 1];
        WorkTypeGroupMember workTypeGrMember = [SELECT Id, WorkTypeGroupId FROM WorkTypeGroupMember WHERE WorkTypeId = :serviceAppointment.WorkTypeId];

        PricebookEntry covidPbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Work_Type_Group__c = :workTypeGrMember.WorkTypeGroupId LIMIT 1];
        PricebookEntry productPbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Requires_scheduling__c = FALSE AND Product2.Family != 'Discount' LIMIT 1];

        String opp_uuid = onl_CheckoutCtrl.createOrder(orderJSONNoCoupon.replace('{0}', covidPbEntry.Product2Id).replace('{1}', productPbEntry.Product2Id).replace('{2}', newBasket.Session_Id__c));

        Map<String, MockConfig> mockConfigs = new Map<String, MockConfig>{
                '/services/Soap/u/51.0' => new MockConfig(TestDataFactory.LOGIN_RESPONSE, 'OK', 200, false),
                '/scheduling/service-territories?workTypeGroupId' => new MockConfig(TestDataFactory.SEARCH_PRODUCTS_RESPONSE, 'OK', 200, false),
                '/scheduling/available-territory-slots' => new MockConfig(TestDataFactory.GET_AVAILABLE_TERRITORY_SLOTS_RESPONSE, 'OK', 201, false),
                '/scheduling/service-appointments' => new MockConfig(TestDataFactory.BOOK_APPOINTMENT_RESPONSE.replace('08p3H000000ASeQQAW', serviceAppointment.Id), 'OK', 201, false)
        };


        Test.setMock(HttpCalloutMock.class, new ServiceMock(mockConfigs));

        COVID_Test__c cTest = [
                SELECT Id,
                        Work_Type_Group__c
                FROM COVID_Test__c
                LIMIT 1
        ];
        Test.startTest();


        System.assert([SELECT Id, Scheduled_Appointment__c FROM COVID_Test__c].Scheduled_Appointment__c != null);

        cTest = [
                SELECT Id,
                        Scheduled_Appointment__r.SchedStartTime,
                        Scheduled_Appointment__r.SchedEndTime,
                        Turnaround_Time_Global__c,
                        Test_Type__c
                FROM COVID_Test__c
                WHERE Id =: cTest.Id
                LIMIT 1
        ];



        System.assert(cTest.Scheduled_Appointment__c !=null);
        System.debug('ctest schApp start ' + cTest.Scheduled_Appointment__r.SchedStartTime);


        List<SObject> newList = new List<SObject>();

        cTest.Turnaround_Time_Global__c = '4 Hour';

        newList.add(cTest);
        AnthologyTriggerHandler.AnthologyTriggerContext context = new AnthologyTriggerHandler.AnthologyTriggerContext(
                COVID_Test__c.SObjectType,
                System.TriggerOperation.BEFORE_INSERT,
                false,
                newList,
                null,
                null,
                null
        );

        TH_CovidTest_CalculateDates th = new TH_CovidTest_CalculateDates(context);
        th.prepareBefore();
        th.beforeInsert(cTest);
        Test.stopTest();

    }




}