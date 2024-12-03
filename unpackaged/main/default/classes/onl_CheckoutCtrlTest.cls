/**
 * ++
 *
 * @author Zoran Zunko
 *
 * @date 3/15/21
 */
@IsTest
global class onl_CheckoutCtrlTest {
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
            '    "Name": "Fit to Fly PCR Next Day",' +
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
            '  "Name" : "Fit to Fly PCR Next Day",\n' +
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

    @TestSetup
    static void dataSetup() {
        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
        List<ServiceTerritory> serviceTerritories = (List<ServiceTerritory>) JSON.deserialize(SERVICE_TERRITORY_STRING, List<ServiceTerritory>.class);
        List<ServiceAppointment> serviceAppointments = (List<ServiceAppointment>) JSON.deserialize(SERVICE_APPOINTMENT_STRING, List<ServiceAppointment>.class);
        List<OperatingHours> operatingHours = (List<OperatingHours>) JSON.deserialize(OPERATING_HOURS_STRING, List<OperatingHours>.class);
        List<WorkType> workTypes = (List<WorkType>) JSON.deserialize(WORK_TYPE_STRING, List<WorkType>.class);

        for (OperatingHours operatingHour : operatingHours) {
            operatingHour.Id = null;
        }
        insert operatingHours;

        Integer i = 0;
        for (ServiceTerritory serviceTerritory : serviceTerritories) {
            serviceTerritory.Id = null;
            serviceTerritory.OperatingHoursId = operatingHours[0].Id;
            serviceTerritory.Heydoc_Id__c = 'HD_some_ID_' + i++;
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

        Asset asset1 = new Asset(Name = 'A1');
        insert asset1;

        ServiceResource sr1 = new ServiceResource();
        sr1.Name = 'SR1';
        sr1.IsActive = true;
        sr1.ResourceType = 'S';
        sr1.AssetId = asset1.Id;
        sr1.Heydoc_Id__c = 'mock_hd_sr_id';
        insert sr1;


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
            newProduct.Store_Categories__c = 'Products';

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
        newProduct.Store_Categories__c = 'Appointments';
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
        newProduct.Store_Categories__c = 'Appointments';
        productsToInsert.add(newProduct);


        Product2 pClickCollect = new Product2();
        pClickCollect.Name = 'cc';
        pClickCollect.Family = onl_CheckoutCtrl.PRODUCT_DELIVERY_FAMILY;
        pClickCollect.Delivery_Class__c = onl_CheckoutCtrl.PRODUCT_DELIVERY_CLASS_CLICKCOLLECT;
        pClickCollect.Available_in_Stores__c = 'My Healthcare';
        pClickCollect.IsActive = true;
        pClickCollect.Membership_Price__c = -2;
        pClickCollect.Store_Categories__c = 'Appointments';

        productsToInsert.add(pClickCollect);

        Product2 pCourier = new Product2();
        pCourier.Name = 'delivery by courier';
        pCourier.Family = onl_CheckoutCtrl.PRODUCT_DELIVERY_FAMILY;
        pCourier.Delivery_Class__c = 'Saturday';
        pCourier.Available_in_Stores__c = 'My Healthcare';
        pCourier.IsActive = true;
        pCourier.Membership_Price__c = 3;
        pCourier.Delivery_Product_Within_Days__c = 1;
        pCourier.Delivery_Product_By_Hours__c = Time.newInstance(10, 10, 10, 0);
        pCourier.Store_Categories__c = 'Appointments';

        productsToInsert.add(pCourier);

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

    @IsTest static void test_searchCovidTests() {
        OnlineStoreSettingsManager.storeSettings = TestDataFactory.getOnlineStoreSettings();

        Map<String, MockConfig> mockConfigs = new Map<String, onl_CheckoutCtrlTest.MockConfig>{
                '/services/Soap/u/51.0' => new MockConfig(TestDataFactory.LOGIN_RESPONSE, 'OK', 200, false),
                '/scheduling/service-territories?workTypeGroupId' => new MockConfig(TestDataFactory.SEARCH_PRODUCTS_RESPONSE, 'OK', 200, false),
                '/scheduling/available-territory-slots' => new MockConfig(TestDataFactory.GET_AVAILABLE_TERRITORY_SLOTS_RESPONSE, 'OK', 201, false),
                'https://maps.googleapis.com/maps/api/geocode/' => new MockConfig(TestDataFactory.GECODE_JSON, 'OK', 200, false)
        };

        Map<String, Object> params = new Map<String, Object>{
                'postalcode' => 'W1A 1AA',
                'distance' => '10',
                'type' => 'Products',
                'turnaround' => 'Next Day',
                'store' => 'My Healthcare'
        };
        Test.setMock(HttpCalloutMock.class, new onl_CheckoutCtrlTest_ServiceMock(mockConfigs));
        Test.startTest();
        String response = onl_CheckoutCtrl.searchCovidTests(JSON.serialize(params));
        Test.stopTest();

//        List<onl_CheckoutCtrl.SearchTestCenterResponse> centerResponses = (List<onl_CheckoutCtrl.SearchTestCenterResponse>) JSON.deserialize(response, List<onl_CheckoutCtrl.SearchTestCenterResponse>.class);
//        System.assert(!centerResponses.isEmpty());
//        System.assertEquals(4, centerResponses[0].locations.size());
    }

    @IsTest static void test_searchProducts() {
        OnlineStoreSettingsManager.storeSettings = TestDataFactory.getOnlineStoreSettings();


        Test.startTest();
        String response = onl_CheckoutCtrl.searchProducts('My Healthcare');

        Test.stopTest();

        List<Product2> pbEntries = [SELECT Id, Non_Membership_Price__c, Quantity__c, Requires_scheduling__c, Requires_delivery__c, Name, Store_Categories__c, Description, Is_Home_Test__c FROM Product2 WHERE Include_in_Store__c = TRUE AND Requires_delivery__c = TRUE AND IsActive = TRUE AND Store_Categories__c INCLUDES ('Products')];
        //System.assert(!pbEntries.isEmpty());
        //System.assertEquals(JSON.serialize(pbEntries, true), response);
    }

    @IsTest static void test_createOrder_noDiscount() {

        Uuid newUuid = new Uuid();
        String basketSession = newUuid.getValue();
        Basket__c newBasket = new Basket__c(
                Session_Id__c = basketSession,
                Basket_JSON__c = basketJSONNoCoupon
        );

        insert newBasket;

        OnlineStoreSettingsManager.storeSettings = TestDataFactory.getOnlineStoreSettings();
        PricebookEntry covidPbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Requires_scheduling__c = TRUE AND Product2.Family != 'Discount' AND IsActive = TRUE LIMIT 1];
        PricebookEntry productPbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Requires_scheduling__c = FALSE AND Product2.Family != 'Discount' AND IsActive = TRUE LIMIT 1];


        Test.startTest();
        String response = onl_CheckoutCtrl.createOrder(orderJSONNoCoupon.replace('{0}', covidPbEntry.Product2Id).replace('{1}', productPbEntry.Product2Id).replace('{2}', newBasket.Session_Id__c));
        Test.stopTest();

        Opportunity opp = [
                SELECT Id,
                        LeadSource,
                        CloseDate,
                        StageName,
                        Site__c,
                        Business_Unit__c,
                        Mode__c,
                        Date_Appointment_Made__c,
                        Appointment_Date__c,
                        Online_First_Name__c,
                        Online_Last_Name__c,
                        Online_Email__c,
                        Online_Phone__c,
                        Online_Mobile__c,
                        Online_Post_Code__c,
                        Online_Radius__c,
                        UUID__c,
                        Account.ShippingCity,
                        Account.ShippingStreet,
                        Account.ShippingPostalCode,
                        Account.ShippingCountry
                FROM Opportunity
        ];
        System.assertEquals(opp.UUID__c, response);
        System.assertEquals(opp.LeadSource, 'Did Not Obtain');
        System.assertEquals(opp.CloseDate, Date.today());
        System.assertEquals(opp.StageName, 'Qualification');
        System.assertEquals(opp.Mode__c, 'Online Booking');
        System.assertEquals(opp.Date_Appointment_Made__c, Date.today());
        System.assertEquals(opp.Appointment_Date__c, Date.today());
        System.assertEquals(opp.Online_First_Name__c, 'Some');
        System.assertEquals(opp.Online_Last_Name__c, 'One');
        System.assertEquals(opp.Online_Email__c, 'someone@example.com');
        System.assertEquals(opp.Online_Phone__c, '9234567896');
        System.assertEquals(opp.Online_Mobile__c, '9234567896');
        System.assertEquals(opp.Online_Post_Code__c, 'W1');
        System.assertEquals(opp.Online_Radius__c, '10');
        System.assertEquals(opp.Account.ShippingCity, 'London');
        System.assertEquals(opp.Account.ShippingStreet, 'Street North XC4');
        System.assertEquals(opp.Account.ShippingPostalCode, 'W11');
        System.assertEquals(opp.Account.ShippingCountry, 'UK');
        System.assertEquals(2, [SELECT Id FROM OpportunityLineItem].size());
    }

    @IsTest static void test_createOrder_discount() {

        Uuid newUuid = new Uuid();
        String basketSession = newUuid.getValue();
        Basket__c newBasket = new Basket__c(
                Session_Id__c = basketSession,
                Basket_JSON__c = basketJSONNoCoupon
        );

        Discount_Code__c discountCode = new Discount_Code__c(
                Coupon_Code__c = '12321',
                Discount_Amount__c = 20,
                Discount_Product__c = [SELECT Id FROM Product2 WHERE Family = 'Discount' LIMIT 1].Id,
                Start_date__c = Date.today().addDays(-1),
                End_date__c = Date.today().addDays(3)
        );
        insert discountCode;

        insert newBasket;

        OnlineStoreSettingsManager.storeSettings = TestDataFactory.getOnlineStoreSettings();
        PricebookEntry covidPbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Requires_scheduling__c = TRUE AND Product2.Family != 'Discount' LIMIT 1];
        PricebookEntry productPbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Requires_scheduling__c = FALSE AND Product2.Family != 'Discount' LIMIT 1];


        Test.startTest();
        String response = onl_CheckoutCtrl.createOrder(orderJSONCoupon.replace('{0}', covidPbEntry.Product2Id).replace('{1}', productPbEntry.Product2Id).replace('{2}', discountCode.Id).replace('{3}', newBasket.Session_Id__c));
        Test.stopTest();

        //no extra assertions since they are all checked above
        String oppUUID = [SELECT Id, UUID__c FROM Opportunity].UUID__c;
        System.assertEquals(oppUUID, response);
        System.assertEquals(3, [SELECT Id FROM OpportunityLineItem].size());
    }

    @IsTest static void test_getLocations() {
        Uuid newUuid = new Uuid();
        String basketSession = newUuid.getValue();
        Basket__c newBasket = new Basket__c(
                Session_Id__c = basketSession,
                Basket_JSON__c = basketJSONNoCoupon
        );

        insert newBasket;

        OnlineStoreSettingsManager.storeSettings = TestDataFactory.getOnlineStoreSettings();
        PricebookEntry covidPbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Requires_scheduling__c = TRUE AND Product2.Family != 'Discount' LIMIT 1];
        PricebookEntry productPbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Requires_scheduling__c = FALSE AND Product2.Family != 'Discount' LIMIT 1];

        onl_CheckoutCtrl.createOrder(orderJSONNoCoupon.replace('{0}', covidPbEntry.Product2Id).replace('{1}', productPbEntry.Product2Id).replace('{2}', newBasket.Session_Id__c));

        Map<String, MockConfig> mockConfigs = new Map<String, onl_CheckoutCtrlTest.MockConfig>{
                '/services/Soap/u/51.0' => new MockConfig(TestDataFactory.LOGIN_RESPONSE, 'OK', 200, false),
                '/scheduling/service-territories?workTypeGroupId' => new MockConfig(TestDataFactory.SEARCH_PRODUCTS_RESPONSE, 'OK', 200, false),
                '/scheduling/available-territory-slots' => new MockConfig(TestDataFactory.GET_AVAILABLE_TERRITORY_SLOTS_RESPONSE, 'OK', 201, false),
                'https://maps.googleapis.com/maps/api/geocode/' => new MockConfig(TestDataFactory.GECODE_JSON, 'OK', 200, false)
        };


        Test.setMock(HttpCalloutMock.class, new onl_CheckoutCtrlTest_ServiceMock(mockConfigs));

        COVID_Test__c cTest = [SELECT Id FROM COVID_Test__c LIMIT 1];
        onl_CheckoutCtrl.getTestDetails(cTest.Id);
        Test.startTest();
        String response = onl_CheckoutCtrl.getLocations('W1A 1AA', '10', cTest.Id);
        Test.stopTest();

        onl_CheckoutCtrl.SearchTestCenterResponse centerResponse = (onl_CheckoutCtrl.SearchTestCenterResponse) JSON.deserialize(response, onl_CheckoutCtrl.SearchTestCenterResponse.class);
        System.assertEquals(4, centerResponse.locations.size());
    }

    @IsTest static void test_getOpportunity() {
        Uuid newUuid = new Uuid();
        String basketSession = newUuid.getValue();
        Basket__c newBasket = new Basket__c(
                Session_Id__c = basketSession,
                Basket_JSON__c = basketJSONNoCoupon
        );

        insert newBasket;

        OnlineStoreSettingsManager.storeSettings = TestDataFactory.getOnlineStoreSettings();
        PricebookEntry covidPbEntry = [SELECT Id FROM PricebookEntry WHERE Product2.Requires_scheduling__c = TRUE AND Product2.Family != 'Discount' LIMIT 1];
        PricebookEntry productPbEntry = [SELECT Id FROM PricebookEntry WHERE Product2.Requires_scheduling__c = FALSE AND Product2.Family != 'Discount' LIMIT 1];


        onl_CheckoutCtrl.createOrder(orderJSONNoCoupon.replace('{0}', covidPbEntry.Id).replace('{1}', productPbEntry.Id).replace('{2}', newBasket.Session_Id__c));

        Opportunity opp = [SELECT Id, UUID__c FROM Opportunity LIMIT 1];
        Test.startTest();
        String response = onl_CheckoutCtrl.getOpportunity(opp.UUID__c);
        Test.stopTest();

        System.assert(response.contains('opportunityId'));
        System.assert(response.contains('covidTests'));
    }

    //    @IsTest static void test_getAvailableSlots() {
    //        Uuid newUuid = new Uuid();
    //        String basketSession = newUuid.getValue();
    //        Basket__c newBasket = new Basket__c(
    //                Session_Id__c = basketSession,
    //                Basket_JSON__c = basketJSONNoCoupon
    //        );
    //
    //        insert newBasket;
    //
    //        OnlineStoreSettingsManager.storeSettings = TestDataFactory.getOnlineStoreSettings();
    //        PricebookEntry covidPbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Requires_scheduling__c = TRUE AND Product2.Family != 'Discount' LIMIT 1];
    //        PricebookEntry productPbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Requires_scheduling__c = FALSE AND Product2.Family != 'Discount' LIMIT 1];
    //
    //
    //        onl_CheckoutCtrl.createOrder(orderJSONNoCoupon.replace('{0}', covidPbEntry.Product2Id).replace('{1}', productPbEntry.Product2Id).replace('{2}', newBasket.Session_Id__c));
    //
    //        Map<String, MockConfig> mockConfigs = new Map<String, onl_CheckoutCtrlTest.MockConfig>{
    //                '/services/Soap/u/51.0' => new MockConfig(TestDataFactory.LOGIN_RESPONSE, 'OK', 200, false),
    //                '/scheduling/service-territories?workTypeGroupId' => new MockConfig(TestDataFactory.SEARCH_PRODUCTS_RESPONSE, 'OK', 200, false),
    //                '/scheduling/available-territory-slots' => new MockConfig(TestDataFactory.GET_AVAILABLE_TERRITORY_SLOTS_RESPONSE, 'OK', 201, false)
    //        };
    //
    //
    //        Test.setMock(HttpCalloutMock.class, new onl_CheckoutCtrlTest_ServiceMock(mockConfigs));
    //
    //        COVID_Test__c cTest = [SELECT Id FROM COVID_Test__c LIMIT 1];
    //        Test.startTest();
    //        String response = onl_CheckoutCtrl.getAvailableSlots(cTest.Id, 'serviceCenterId', Date.today());
    //        Test.stopTest();
    //        List<SchedulerAPI.TerritorySlot> territorySlots = (List<SchedulerAPI.TerritorySlot>) JSON.deserialize(response, List<SchedulerAPI.TerritorySlot>.class);
    //        System.assertEquals(2, territorySlots.size());
    //    }

    @IsTest static void test_scheduleAppointment() {
        Uuid newUuid = new Uuid();
        String basketSession = newUuid.getValue();
        Basket__c newBasket = new Basket__c(
                Session_Id__c = basketSession,
                Basket_JSON__c = basketJSONNoCoupon
        );

        insert newBasket;

        OnlineStoreSettingsManager.storeSettings = TestDataFactory.getOnlineStoreSettings();
        OnlineStoreSettingsManager.storeSettings.Default_AccountId__c = [SELECT Id FROM Account LIMIT 1].Id;
        ServiceAppointment serviceAppointment = [SELECT Id, ServiceTerritoryId, WorkTypeId FROM ServiceAppointment LIMIT 1];
        WorkTypeGroupMember workTypeGrMember = [SELECT Id, WorkTypeGroupId FROM WorkTypeGroupMember WHERE WorkTypeId = :serviceAppointment.WorkTypeId];

        PricebookEntry covidPbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Work_Type_Group__c = :workTypeGrMember.WorkTypeGroupId LIMIT 1];
        PricebookEntry productPbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Requires_scheduling__c = FALSE AND Product2.Family != 'Discount' LIMIT 1];

        String opp_uuid = onl_CheckoutCtrl.createOrder(orderJSONNoCoupon.replace('{0}', covidPbEntry.Product2Id).replace('{1}', productPbEntry.Product2Id).replace('{2}', newBasket.Session_Id__c));

        Map<String, onl_CheckoutCtrlTest.MockConfig> mockConfigs = new Map<String, onl_CheckoutCtrlTest.MockConfig>{
                '/services/Soap/u/51.0' => new MockConfig(TestDataFactory.LOGIN_RESPONSE, 'OK', 200, false),
                '/scheduling/service-territories?workTypeGroupId' => new MockConfig(TestDataFactory.SEARCH_PRODUCTS_RESPONSE, 'OK', 200, false),
                '/scheduling/available-territory-slots' => new MockConfig(TestDataFactory.GET_AVAILABLE_TERRITORY_SLOTS_RESPONSE, 'OK', 201, false),
                '/scheduling/service-appointments' => new MockConfig(TestDataFactory.BOOK_APPOINTMENT_RESPONSE.replace('08p3H000000ASeQQAW', serviceAppointment.Id), 'OK', 201, false)
        };


        Test.setMock(HttpCalloutMock.class, new onl_CheckoutCtrlTest_ServiceMock(mockConfigs));
        COVID_Test__c cTest = [
                SELECT Id,
                        Work_Type_Group__c
                FROM COVID_Test__c
                LIMIT 1
        ];
        Test.startTest();
        System.assert(onl_CheckoutCtrl.scheduleAppointment(
                cTest.Id,
                serviceAppointment.ServiceTerritoryId,
                '2021-03-14T09:00:00.000Z',
                '2021-03-14T09:10:00.000Z',
                [SELECT Id FROM ServiceResource LIMIT 1].Id
        ));
        Test.stopTest();
        System.assert([SELECT Id, Scheduled_Appointment__c FROM COVID_Test__c].Scheduled_Appointment__c != null);

        Opportunity opp = [SELECT Id FROM Opportunity WHERE UUID__c = :opp_uuid LIMIT 1];

        cTest = [
                SELECT Id,
                        Scheduled_Appointment__r.SchedStartTime,
                        Scheduled_Appointment__r.SchedEndTime,
                        Test_Type__c
                FROM COVID_Test__c
                WHERE Id = :cTest.Id
                LIMIT 1
        ];

        //test ics files
        List <Messaging.EmailFileAttachment> efas = OnlIcsFilesGenerator.generateIcsFiles(opp.Id);
        //System.assertEquals(1, efas.size());

        //test email calendar fields
        eml_ConfEmailCtrl.TestWrapper tw = new eml_ConfEmailCtrl.TestWrapper(cTest);
    }

    @IsTest static void test_saveBasket() {

        String basketId = onl_CheckoutCtrl.saveBasket(null, basketJSONNoCoupon);

        List<Basket__c> baskets = [SELECT Id, Session_Id__c FROM Basket__c];
        System.assertEquals(1, baskets.size());
        System.assertEquals(basketId, baskets[0].Session_Id__c);


    }

    @IsTest static void test_getBasket() {
        Uuid newUuid = new Uuid();
        String basketSession = newUuid.getValue();
        Basket__c newBasket = new Basket__c(
                Session_Id__c = basketSession,
                Basket_JSON__c = basketJSONNoCoupon
        );

        insert newBasket;

        System.assertEquals(basketJSONNoCoupon, onl_CheckoutCtrl.getBasket(basketSession));

        Account acc = [SELECT Id FROM Account];
        Opportunity opp = new Opportunity(AccountId = acc.Id);
        opp.StageName = 'Closed Won';
        opp.CloseDate = Date.today();
        opp.Name = 'Test';
        insert opp;

        //if basket has opportunity return null
        newBasket.Opportunity__c = opp.Id;
        update newBasket;
        System.assert(onl_CheckoutCtrl.getBasket(basketSession) == null);
    }

    @IsTest static void test_getStripeSession() {

        Uuid newUuid = new Uuid();
        String basketSession = newUuid.getValue();
        Basket__c newBasket = new Basket__c(
                Session_Id__c = basketSession,
                Basket_JSON__c = basketJSONNoCoupon
        );

        Discount_Code__c discountCode = new Discount_Code__c(
                Coupon_Code__c = '12321',
                Discount_Amount__c = 20,
                Discount_Product__c = [SELECT Id FROM Product2 WHERE Family = 'Discount' LIMIT 1].Id,
                Start_date__c = Date.today().addDays(-1),
                End_date__c = Date.today().addDays(3)
        );
        insert discountCode;

        insert newBasket;

        OnlineStoreSettingsManager.storeSettings = TestDataFactory.getOnlineStoreSettings();
        PricebookEntry covidPbEntry = [SELECT Id FROM PricebookEntry WHERE Product2.Requires_scheduling__c = TRUE AND Product2.Family != 'Discount' LIMIT 1];
        PricebookEntry productPbEntry = [SELECT Id FROM PricebookEntry WHERE Product2.Requires_scheduling__c = FALSE AND Product2.Family != 'Discount' LIMIT 1];

        String response = onl_CheckoutCtrl.createOrder(orderJSONCoupon.replace('{0}', covidPbEntry.Id).replace('{1}', productPbEntry.Id).replace('{2}', discountCode.Id).replace('{3}', newBasket.Session_Id__c));

        Map<String, onl_CheckoutCtrlTest.MockConfig> mockConfigs = new Map<String, onl_CheckoutCtrlTest.MockConfig>{
                '/coupons' => new MockConfig(TestDataFactory.STRIPE_COUPON_RESPONSE, 'OK', 200, false),
                '/checkout/sessions' => new MockConfig(TestDataFactory.STRIPE_SESSION_RESPONSE, 'OK', 200, false)
        };
        Test.setMock(HttpCalloutMock.class, new onl_CheckoutCtrlTest_ServiceMock(mockConfigs));

        Test.startTest();
        String stripeSession = onl_CheckoutCtrl.getStripeSession(response);
        Test.stopTest();

        Opportunity opp = [
                SELECT
                        Id,
                        UUID__c,
                        Online_Stripe_Session__c, (SELECT Id, Stripe_Coupon_Id__c FROM Discount_Code_Usages__r)
                FROM Opportunity
                WHERE UUID__c = :response
        ];
        //no extra assertions since they are all checked above
        System.assertEquals(stripeSession, 'cs_test_a170MjOvhUJHerzqPnUT3JmEjbmwaU8bB5QSLot6w2brNNBm7vIACJR6nK');
        System.assertEquals(opp.Online_Stripe_Session__c, stripeSession);
        System.assertEquals(opp.Discount_Code_Usages__r.size(), 1);
        System.assertEquals(opp.Discount_Code_Usages__r[0].Stripe_Coupon_Id__c, 'couponId');
    }

    @IsTest static void test_getProductsCountOpportunity() {
        Uuid newUuid = new Uuid();
        String basketSession = newUuid.getValue();
        Basket__c newBasket = new Basket__c(
                Session_Id__c = basketSession,
                Basket_JSON__c = basketJSONNoCoupon
        );

        insert newBasket;

        OnlineStoreSettingsManager.storeSettings = TestDataFactory.getOnlineStoreSettings();
        PricebookEntry covidPbEntry = [SELECT Id FROM PricebookEntry WHERE Product2.Requires_scheduling__c = TRUE AND Product2.Family != 'Discount' LIMIT 1];
        PricebookEntry productPbEntry = [SELECT Id FROM PricebookEntry WHERE Product2.Requires_scheduling__c = FALSE AND Product2.Family != 'Discount' LIMIT 1];


        onl_CheckoutCtrl.createOrder(orderJSONNoCoupon.replace('{0}', covidPbEntry.Id).replace('{1}', productPbEntry.Id).replace('{2}', newBasket.Session_Id__c));

        Opportunity opp = [SELECT Id, UUID__c FROM Opportunity LIMIT 1];
        Test.startTest();
        String response = onl_CheckoutCtrl.getProductsCountOpportunity(opp.UUID__c);
        Test.stopTest();

        System.assert(response.contains('covidTests'));
        System.assert(response.contains('products'));
        System.assert(response.contains('discounts'));
        System.assert(response.contains('status'));
    }

    @IsTest static void test_getLocationsDefaultTest() {
        Default_COVID_Test__c defaultCOVIDTest = [SELECT Id FROM Default_COVID_Test__c LIMIT 1];
        Uuid newUuid = new Uuid();
        String basketSession = newUuid.getValue();
        Basket__c newBasket = new Basket__c(
                Session_Id__c = basketSession,
                Basket_JSON__c = basketJSONNoCoupon
        );

        insert newBasket;
        OnlineStoreSettingsManager.storeSettings = TestDataFactory.getOnlineStoreSettings();
        PricebookEntry covidPbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Requires_scheduling__c = TRUE AND Product2.Family != 'Discount' LIMIT 1];
        PricebookEntry productPbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Requires_scheduling__c = FALSE AND Product2.Family != 'Discount' LIMIT 1];

        onl_CheckoutCtrl.createOrder(orderJSONNoCoupon.replace('{0}', covidPbEntry.Product2Id).replace('{1}', productPbEntry.Product2Id).replace('{2}', newBasket.Session_Id__c));

        Map<String, MockConfig> mockConfigs = new Map<String, onl_CheckoutCtrlTest.MockConfig>{
                '/services/Soap/u/51.0' => new MockConfig(TestDataFactory.LOGIN_RESPONSE, 'OK', 200, false),
                '/scheduling/service-territories?workTypeGroupId' => new MockConfig(TestDataFactory.SEARCH_PRODUCTS_RESPONSE, 'OK', 200, false),
                '/scheduling/available-territory-slots' => new MockConfig(TestDataFactory.GET_AVAILABLE_TERRITORY_SLOTS_RESPONSE, 'OK', 201, false),
                'https://maps.googleapis.com/maps/api/geocode/' => new MockConfig(TestDataFactory.GECODE_JSON, 'OK', 200, false)
        };


        Test.setMock(HttpCalloutMock.class, new onl_CheckoutCtrlTest_ServiceMock(mockConfigs));

        Test.startTest();
        String response = onl_CheckoutCtrl.getLocationsDefaultTest('W1A 1AA', '10', defaultCOVIDTest.Id);
        Test.stopTest();

        onl_CheckoutCtrl.SearchTestCenterResponse centerResponse = (onl_CheckoutCtrl.SearchTestCenterResponse) JSON.deserialize(response, onl_CheckoutCtrl.SearchTestCenterResponse.class);
        System.assertEquals(4, centerResponse.locations.size());

    }

    //    @IsTest static void test_getAvailableSlotsDefaultTest() {
    //        Default_COVID_Test__c defaultCOVIDTest = [SELECT Id, Work_Type_Group__c FROM Default_COVID_Test__c LIMIT 1];
    //
    //        Uuid newUuid = new Uuid();
    //        String basketSession = newUuid.getValue();
    //        Basket__c newBasket = new Basket__c(
    //                Session_Id__c = basketSession,
    //                Basket_JSON__c = basketJSONNoCoupon
    //        );
    //
    //        insert newBasket;
    //
    //        OnlineStoreSettingsManager.storeSettings = TestDataFactory.getOnlineStoreSettings();
    //        PricebookEntry covidPbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Requires_scheduling__c = TRUE AND Product2.Family != 'Discount' LIMIT 1];
    //        PricebookEntry productPbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Requires_scheduling__c = FALSE AND Product2.Family != 'Discount' LIMIT 1];
    //
    //
    //        onl_CheckoutCtrl.createOrder(orderJSONNoCoupon.replace('{0}', covidPbEntry.Product2Id).replace('{1}', productPbEntry.Product2Id).replace('{2}', newBasket.Session_Id__c));
    //
    //        Map<String, MockConfig> mockConfigs = new Map<String, onl_CheckoutCtrlTest.MockConfig>{
    //                '/services/Soap/u/51.0' => new MockConfig(TestDataFactory.LOGIN_RESPONSE, 'OK', 200, false),
    //                '/scheduling/service-territories?workTypeGroupId' => new MockConfig(TestDataFactory.SEARCH_PRODUCTS_RESPONSE, 'OK', 200, false),
    //                '/scheduling/available-territory-slots' => new MockConfig(TestDataFactory.GET_AVAILABLE_TERRITORY_SLOTS_RESPONSE, 'OK', 201, false)
    //        };
    //
    //
    //        Test.setMock(HttpCalloutMock.class, new onl_CheckoutCtrlTest_ServiceMock(mockConfigs));
    //
    //        COVID_Test__c cTest = [SELECT Id FROM COVID_Test__c LIMIT 1];
    //        Test.startTest();
    //        String response = onl_CheckoutCtrl.getAvailableSlotsDefaultTest(defaultCOVIDTest.Id,
    //                [SELECT Id FROM ServiceTerritory LIMIT 1].Id,
    //                Date.today());
    //        Test.stopTest();
    //        List<SchedulerAPI.TerritorySlot> territorySlots = (List<SchedulerAPI.TerritorySlot>) JSON.deserialize(response, List<SchedulerAPI.TerritorySlot>.class);
    //        System.assertEquals(2, territorySlots.size());
    //
    //        List<String> locationIDs = new List<String>();
    //        locationIDs.add('serviceCenterId');
    //        onl_CheckoutCtrl.getAvailableSlotsByWorkTypeGroupAtMultipleLocations(defaultCOVIDTest.Work_Type_Group__c, locationIDs, Date.today());
    //    }


    @IsTest
    static void test_getAvailableSlotsDefaultTest() {
        Default_COVID_Test__c defaultCOVIDTest = [SELECT Id, Work_Type_Group__c FROM Default_COVID_Test__c LIMIT 1];

        Uuid newUuid = new Uuid();
        String basketSession = newUuid.getValue();
        Basket__c newBasket = new Basket__c(
                Session_Id__c = basketSession,
                Basket_JSON__c = basketJSONNoCoupon
        );

        insert newBasket;

        OnlineStoreSettingsManager.storeSettings = TestDataFactory.getOnlineStoreSettings();
        PricebookEntry covidPbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Requires_scheduling__c = TRUE AND Product2.Family != 'Discount' LIMIT 1];
        PricebookEntry productPbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Requires_scheduling__c = FALSE AND Product2.Family != 'Discount' LIMIT 1];


        onl_CheckoutCtrl.createOrder(orderJSONNoCoupon.replace('{0}', covidPbEntry.Product2Id).replace('{1}', productPbEntry.Product2Id).replace('{2}', newBasket.Session_Id__c));

        Test.setMock(HttpCalloutMock.class, new OnlSembleAvailabilityTest.Test_SembleMock());

        COVID_Test__c cTest = [SELECT Id FROM COVID_Test__c LIMIT 1];
        Test.startTest();
        String response = onl_CheckoutCtrl.getAvailableSlotsDefaultTest(defaultCOVIDTest.Id,
                [SELECT Id FROM ServiceTerritory LIMIT 1].Id,
                Date.today());
        Test.stopTest();
        List<SchedulerAPI.TerritorySlot> territorySlots = (List<SchedulerAPI.TerritorySlot>) JSON.deserialize(response, List<SchedulerAPI.TerritorySlot>.class);
        //System.assertEquals(2, territorySlots.size());

    }

    @IsTest static void test_scheduleAppointmentAndAddToBasket() {
        Default_COVID_Test__c defaultCOVIDTest = [SELECT Id FROM Default_COVID_Test__c LIMIT 1];

        Uuid newUuid = new Uuid();
        String basketSession = newUuid.getValue();
        Basket__c newBasket = new Basket__c(
                Session_Id__c = basketSession,
                Basket_JSON__c = basketJSONNoCoupon
        );

        insert newBasket;

        OnlineStoreSettingsManager.storeSettings = TestDataFactory.getOnlineStoreSettings();
        OnlineStoreSettingsManager.storeSettings.Default_AccountId__c = [SELECT Id FROM Account LIMIT 1].Id;
        ServiceAppointment serviceAppointment = [SELECT Id, ServiceTerritoryId, WorkTypeId FROM ServiceAppointment LIMIT 1];


        Map<String, onl_CheckoutCtrlTest.MockConfig> mockConfigs = new Map<String, onl_CheckoutCtrlTest.MockConfig>{
                '/services/Soap/u/51.0' => new MockConfig(TestDataFactory.LOGIN_RESPONSE, 'OK', 200, false),
                '/scheduling/service-territories?workTypeGroupId' => new MockConfig(TestDataFactory.SEARCH_PRODUCTS_RESPONSE, 'OK', 200, false),
                '/scheduling/available-territory-slots' => new MockConfig(TestDataFactory.GET_AVAILABLE_TERRITORY_SLOTS_RESPONSE, 'OK', 201, false),
                '/scheduling/service-appointments' => new MockConfig(TestDataFactory.BOOK_APPOINTMENT_RESPONSE.replace('08p3H000000ASeQQAW', serviceAppointment.Id), 'OK', 201, false)
        };


        Test.setMock(HttpCalloutMock.class, new onl_CheckoutCtrlTest_ServiceMock(mockConfigs));

        onl_CheckoutCtrl.ScheduleAppointment scheduleAppointment = new onl_CheckoutCtrl.ScheduleAppointment();
        scheduleAppointment.defaultCovidTestId = defaultCOVIDTest.Id;
        scheduleAppointment.startTime = JSON.serialize(Datetime.now()).replace('"', '');
        System.debug(LoggingLevel.ERROR, 'test_scheduleAppointmentAndAddToBasket - scheduleAppointment.startTime: ' + scheduleAppointment.startTime);
        scheduleAppointment.endTime = JSON.serialize(Datetime.now()).replace('"', '');
        scheduleAppointment.serviceCenterId = serviceAppointment.ServiceTerritoryId;
        scheduleAppointment.store = 'My Healthcare';
        scheduleAppointment.resourceId = [SELECT Id FROM ServiceResource LIMIT 1].Id;
        scheduleAppointment.personalDetails = (onl_CheckoutCtrl.PersonalDetails) JSON.deserialize('{"firstName": "Some","lastName": "One","email": "someone@example.com","phone": "9234567896"}', onl_CheckoutCtrl.PersonalDetails.class);
        Test.startTest();
        String response = onl_CheckoutCtrl.scheduleAppointmentAndAddToBasket(JSON.serialize(scheduleAppointment));
        Test.stopTest();
        System.assert(String.isNotBlank(response));
    }

    @IsTest static void test_addToBasket() {
        Default_COVID_Test__c defaultCOVIDTest = [SELECT Id FROM Default_COVID_Test__c LIMIT 1];

        Uuid newUuid = new Uuid();
        String basketSession = newUuid.getValue();
        Basket__c newBasket = new Basket__c(
                Session_Id__c = basketSession,
                Basket_JSON__c = basketJSONNoCoupon
        );

        insert newBasket;

        OnlineStoreSettingsManager.storeSettings = TestDataFactory.getOnlineStoreSettings();
        OnlineStoreSettingsManager.storeSettings.Default_AccountId__c = [SELECT Id FROM Account LIMIT 1].Id;
        ServiceAppointment serviceAppointment = [SELECT Id, ServiceTerritoryId, WorkTypeId FROM ServiceAppointment LIMIT 1];


        Map<String, onl_CheckoutCtrlTest.MockConfig> mockConfigs = new Map<String, onl_CheckoutCtrlTest.MockConfig>{
                '/services/Soap/u/51.0' => new MockConfig(TestDataFactory.LOGIN_RESPONSE, 'OK', 200, false),
                '/scheduling/service-territories?workTypeGroupId' => new MockConfig(TestDataFactory.SEARCH_PRODUCTS_RESPONSE, 'OK', 200, false),
                '/scheduling/available-territory-slots' => new MockConfig(TestDataFactory.GET_AVAILABLE_TERRITORY_SLOTS_RESPONSE, 'OK', 201, false),
                '/scheduling/service-appointments' => new MockConfig(TestDataFactory.BOOK_APPOINTMENT_RESPONSE.replace('08p3H000000ASeQQAW', serviceAppointment.Id), 'OK', 201, false)
        };


        Test.setMock(HttpCalloutMock.class, new onl_CheckoutCtrlTest_ServiceMock(mockConfigs));

        onl_CheckoutCtrl.ScheduleAppointment scheduleAppointment = new onl_CheckoutCtrl.ScheduleAppointment();
        scheduleAppointment.defaultCovidTestId = defaultCOVIDTest.Id;
        scheduleAppointment.startTime = JSON.serialize(Datetime.now()).replace('"', '');
        scheduleAppointment.endTime = JSON.serialize(Datetime.now()).replace('"', '');
        scheduleAppointment.serviceCenterId = serviceAppointment.ServiceTerritoryId;
        scheduleAppointment.store = 'My Healthcare';
        Test.startTest();
        String response = onl_CheckoutCtrl.addToBasket(JSON.serialize(scheduleAppointment));
        Test.stopTest();
        System.assert(String.isNotBlank(response));
    }

    @IsTest static void test_confirmOrder() {
        Uuid newUuid = new Uuid();
        String basketSession = newUuid.getValue();
        Basket__c newBasket = new Basket__c(
                Session_Id__c = basketSession,
                Basket_JSON__c = basketJSONNoCoupon
        );

        insert newBasket;

        OnlineStoreSettingsManager.storeSettings = TestDataFactory.getOnlineStoreSettings();
        PricebookEntry covidPbEntry = [SELECT Id FROM PricebookEntry WHERE Product2.Requires_scheduling__c = TRUE AND Product2.Family != 'Discount' LIMIT 1];
        PricebookEntry productPbEntry = [SELECT Id FROM PricebookEntry WHERE Product2.Requires_scheduling__c = FALSE AND Product2.Family != 'Discount' LIMIT 1];


        onl_CheckoutCtrl.createOrder(orderJSONNoCoupon.replace('{0}', covidPbEntry.Id).replace('{1}', productPbEntry.Id).replace('{2}', newBasket.Session_Id__c));

        Opportunity opp = [SELECT Id, UUID__c FROM Opportunity LIMIT 1];

        onl_CheckoutCtrl.CreateOrderRequest orderRequest = new onl_CheckoutCtrl.CreateOrderRequest();
        orderRequest.checkMarketing = true;
        orderRequest.checkShare = true;
        orderRequest.checkTerms = true;
        orderRequest.oppid = opp.UUID__c;
        orderRequest.personalDetails = (onl_CheckoutCtrl.PersonalDetails) JSON.deserialize('{"firstName": "Some","lastName": "One","email": "someone@example.com","phone": "9234567896"}', onl_CheckoutCtrl.PersonalDetails.class);
        Test.startTest();
        String response = onl_CheckoutCtrl.confirmOrder(JSON.serialize(orderRequest));
        Test.stopTest();

        System.assert(response == opp.UUID__c);
    }

    @IsTest static void test_updatePersonalInfo() {
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

        onl_CheckoutCtrl.createOrder(orderJSONNoCoupon.replace('{0}', covidPbEntry.Product2Id).replace('{1}', productPbEntry.Product2Id).replace('{2}', newBasket.Session_Id__c));

        COVID_Test__c cTest = [SELECT Id, Work_Type_Group__c FROM COVID_Test__c LIMIT 1];

        Test.startTest();
        Boolean response = onl_CheckoutCtrl.updatePersonalInfo(new List<String>{cTest.Id}, 'test', 'tester2', 'no@example.com', '12345678901', '12345678901');
        Test.stopTest();

        System.assert(response);
    }


    @IsTest static void test_validateCouponAndAddToBasket() {
        Uuid newUuid = new Uuid();
        String basketSession = newUuid.getValue();
        Basket__c newBasket = new Basket__c(
                Session_Id__c = basketSession,
                Basket_JSON__c = basketJSONNoCoupon
        );

        Discount_Code__c discountCode = new Discount_Code__c(
                Coupon_Code__c = '12321',
                Discount_Amount__c = 20,
                Discount_Product__c = [SELECT Id FROM Product2 WHERE Family = 'Discount' LIMIT 1].Id,
                Start_date__c = Date.today().addDays(-1),
                End_date__c = Date.today().addDays(3),
                Valid_for_Stores__c = ''
        );
        insert discountCode;

        insert newBasket;

        OnlineStoreSettingsManager.storeSettings = TestDataFactory.getOnlineStoreSettings();
        OnlineStoreSettingsManager.storeSettings.Default_AccountId__c = [SELECT Id FROM Account LIMIT 1].Id;
        ServiceAppointment serviceAppointment = [SELECT Id, ServiceTerritoryId, WorkTypeId FROM ServiceAppointment LIMIT 1];
        WorkTypeGroupMember workTypeGrMember = [SELECT Id, WorkTypeGroupId FROM WorkTypeGroupMember WHERE WorkTypeId = :serviceAppointment.WorkTypeId];

        PricebookEntry covidPbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Work_Type_Group__c = :workTypeGrMember.WorkTypeGroupId LIMIT 1];
        PricebookEntry productPbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Requires_scheduling__c = FALSE AND Product2.Family != 'Discount' LIMIT 1];

        String oppUUID = onl_CheckoutCtrl.createOrder(orderJSONNoCoupon.replace('{0}', covidPbEntry.Product2Id).replace('{1}', productPbEntry.Product2Id).replace('{2}', newBasket.Session_Id__c));

        COVID_Test__c cTest = [SELECT Id, Work_Type_Group__c FROM COVID_Test__c LIMIT 1];

        Test.startTest();
        String response = onl_CheckoutCtrl.validateCouponAndAddToBasket(discountCode.Coupon_Code__c, null, null);
        Test.stopTest();

        System.assert(response != null);
    }

    @IsTest static void test_calculateCouponForBasket() {
        Uuid newUuid = new Uuid();
        String basketSession = newUuid.getValue();
        Basket__c newBasket = new Basket__c(
                Session_Id__c = basketSession,
                Basket_JSON__c = basketJSONNoCoupon
        );

        Discount_Code__c discountCode = new Discount_Code__c(
                Coupon_Code__c = '12321',
                Discount_Amount__c = 20,
                Discount_Product__c = [SELECT Id FROM Product2 WHERE Family = 'Discount' LIMIT 1].Id,
                Start_date__c = Date.today().addDays(-1),
                End_date__c = Date.today().addDays(3),
                Valid_for_Stores__c = ''
        );
        insert discountCode;

        insert newBasket;

        OnlineStoreSettingsManager.storeSettings = TestDataFactory.getOnlineStoreSettings();
        OnlineStoreSettingsManager.storeSettings.Default_AccountId__c = [SELECT Id FROM Account LIMIT 1].Id;
        ServiceAppointment serviceAppointment = [SELECT Id, ServiceTerritoryId, WorkTypeId FROM ServiceAppointment LIMIT 1];
        WorkTypeGroupMember workTypeGrMember = [SELECT Id, WorkTypeGroupId FROM WorkTypeGroupMember WHERE WorkTypeId = :serviceAppointment.WorkTypeId];

        PricebookEntry covidPbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Work_Type_Group__c = :workTypeGrMember.WorkTypeGroupId LIMIT 1];
        PricebookEntry productPbEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Requires_scheduling__c = FALSE AND Product2.Family != 'Discount' LIMIT 1];

        String oppUUID = onl_CheckoutCtrl.createOrder(orderJSONNoCoupon.replace('{0}', covidPbEntry.Product2Id).replace('{1}', productPbEntry.Product2Id).replace('{2}', newBasket.Session_Id__c));

        COVID_Test__c cTest = [SELECT Id, Work_Type_Group__c FROM COVID_Test__c LIMIT 1];

        String response = onl_CheckoutCtrl.validateCouponAndAddToBasket(discountCode.Coupon_Code__c, null, null);
        Test.startTest();
        response = onl_CheckoutCtrl.calculateCouponForBasket(response);
        Test.stopTest();

        System.assert(response != null);
    }

    @IsTest static void test_removeProductFromOpportunity() {
        Default_COVID_Test__c defaultCOVIDTest = [SELECT Id FROM Default_COVID_Test__c LIMIT 1];
        Uuid newUuid = new Uuid();
        String basketSession = newUuid.getValue();
        Basket__c newBasket = new Basket__c(
                Session_Id__c = basketSession,
                Basket_JSON__c = basketJSONNoCoupon
        );

        Discount_Code__c discountCode = new Discount_Code__c(
                Coupon_Code__c = '12321',
                Discount_Amount__c = 20,
                Discount_Product__c = [SELECT Id FROM Product2 WHERE Family = 'Discount' LIMIT 1].Id,
                Start_date__c = Date.today().addDays(-1),
                End_date__c = Date.today().addDays(3),
                Valid_for_Stores__c = ''
        );
        insert discountCode;

        insert newBasket;

        OnlineStoreSettingsManager.storeSettings = TestDataFactory.getOnlineStoreSettings();
        OnlineStoreSettingsManager.storeSettings.Default_AccountId__c = [SELECT Id FROM Account LIMIT 1].Id;
        ServiceAppointment serviceAppointment = [SELECT Id, ServiceTerritoryId, WorkTypeId FROM ServiceAppointment LIMIT 1];

        Map<String, onl_CheckoutCtrlTest.MockConfig> mockConfigs = new Map<String, onl_CheckoutCtrlTest.MockConfig>{
                '/services/Soap/u/51.0' => new MockConfig(TestDataFactory.LOGIN_RESPONSE, 'OK', 200, false),
                '/scheduling/service-territories?workTypeGroupId' => new MockConfig(TestDataFactory.SEARCH_PRODUCTS_RESPONSE, 'OK', 200, false),
                '/scheduling/available-territory-slots' => new MockConfig(TestDataFactory.GET_AVAILABLE_TERRITORY_SLOTS_RESPONSE, 'OK', 201, false),
                '/scheduling/service-appointments' => new MockConfig(TestDataFactory.BOOK_APPOINTMENT_RESPONSE.replace('08p3H000000ASeQQAW', serviceAppointment.Id), 'OK', 201, false)
        };


        Test.setMock(HttpCalloutMock.class, new onl_CheckoutCtrlTest_ServiceMock(mockConfigs));

        onl_CheckoutCtrl.ScheduleAppointment scheduleAppointment = new onl_CheckoutCtrl.ScheduleAppointment();
        scheduleAppointment.defaultCovidTestId = defaultCOVIDTest.Id;
        scheduleAppointment.startTime = JSON.serialize(Datetime.now()).replace('"', '');
        System.debug(LoggingLevel.ERROR, 'test_scheduleAppointmentAndAddToBasket - scheduleAppointment.startTime: ' + scheduleAppointment.startTime);
        scheduleAppointment.endTime = JSON.serialize(Datetime.now()).replace('"', '');
        scheduleAppointment.serviceCenterId = serviceAppointment.ServiceTerritoryId;
        scheduleAppointment.store = 'My Healthcare';
        scheduleAppointment.personalDetails = (onl_CheckoutCtrl.PersonalDetails) JSON.deserialize('{"firstName": "Some","lastName": "One","email": "someone@example.com","phone": "9234567896"}', onl_CheckoutCtrl.PersonalDetails.class);
        scheduleAppointment.resourceId = [SELECT Id From ServiceResource LIMIT 1].Id;
        Test.startTest();
        String response = onl_CheckoutCtrl.scheduleAppointmentAndAddToBasket(JSON.serialize(scheduleAppointment));
        System.debug(LoggingLevel.ERROR, 'test_removeProductFromOpportunity - response: ' + response);
        Test.stopTest();
        response = onl_CheckoutCtrl.validateCouponAndAddToBasket(discountCode.Coupon_Code__c, null, response);
        System.debug(LoggingLevel.ERROR, 'test_removeProductFromOpportunity - response: ' + response);

        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem WHERE Opportunity.UUID__c = :response LIMIT 1];
        response = onl_CheckoutCtrl.removeProductFromOpportunity(oli.Id);
    }

    @IsTest static void test_validateCoupon() {
        Uuid newUuid = new Uuid();
        String basketSession = newUuid.getValue();
        Basket__c newBasket = new Basket__c(
                Session_Id__c = basketSession,
                Basket_JSON__c = basketJSONNoCoupon
        );

        Discount_Code__c discountCode = new Discount_Code__c(
                Coupon_Code__c = '12321',
                Discount_Amount__c = 20,
                Discount_Product__c = [SELECT Id FROM Product2 WHERE Family = 'Discount' LIMIT 1].Id,
                Start_date__c = Date.today().addDays(-1),
                End_date__c = Date.today().addDays(3),
                Valid_for_Stores__c = ''
        );
        insert discountCode;

        Test.startTest();
        String response = onl_CheckoutCtrl.validateCoupon(discountCode.Coupon_Code__c, '');
        Test.stopTest();

        System.assert(response != null);
    }

    @IsTest static void test_closeOrder() {

        Uuid newUuid = new Uuid();
        String basketSession = newUuid.getValue();
        Basket__c newBasket = new Basket__c(
                Session_Id__c = basketSession,
                Basket_JSON__c = basketJSONNoCoupon
        );

        insert newBasket;

        System.assertEquals(basketJSONNoCoupon, onl_CheckoutCtrl.getBasket(basketSession));

        Account acc = [SELECT Id FROM Account];
        Opportunity opp = new Opportunity(AccountId = acc.Id);
        opp.StageName = 'Qualification';
        opp.CloseDate = Date.today();
        opp.Name = 'Test';

        insert opp;

        opp = [
                SELECT Id,
                        StageName,
                        UUID__c
                FROM Opportunity
        ];

        Test.startTest();

        System.assert(opp != null);
        onl_CheckoutCtrl.closeOrder(opp.UUID__c);
        opp = [
                SELECT Id,
                        StageName
                FROM Opportunity
        ];
        System.assert(opp != null);
        System.assert(opp.StageName == 'Closed Won');

        Test.stopTest();
    }

    @IsTest
    static void test_getReservationHeldTime() {
        Integer ret = onl_CheckoutCtrl.getReservationHeldTime();
        System.assert(ret >= 0);
    }

    @IsTest
    static void test_classCtors() {

        onl_CheckoutCtrl.CreateOrderRequest cor = new onl_CheckoutCtrl.CreateOrderRequest();
        onl_CheckoutCtrl.DefaultLocation dl = new onl_CheckoutCtrl.DefaultLocation('1', 'pc');
        onl_CheckoutCtrl.getStripePublicKey();
    }

    @IsTest
    static void test_getCustomSettings() {
        onl_CheckoutCtrl.getCustomSettings();
    }

    @IsTest
    static void test_getDeliveryOptions() {
        onl_CheckoutCtrl.getDeliveryOptions('My Healthcare');

        List<Product2> products = [SELECT Id, Description, Is_Delivery_Option__c, Delivery_Class__c, Delivery_Product_Within_Days__c, Delivery_Product_By_Hours__c FROM Product2];
        for (Product2 p : products) {
            onl_CheckoutCtrl.getDescriptiveDateForDeliveryProduct(p, null);
        }
    }

    @IsTest
    static void test_addDeliveryToBasket() {
        OnlineStoreSettingsManager.storeSettings = TestDataFactory.getOnlineStoreSettings();
        OnlineStoreSettingsManager.storeSettings.Default_AccountId__c = [SELECT Id FROM Account LIMIT 1].Id;

        onl_CheckoutCtrl.ScheduleAppointment params = new onl_CheckoutCtrl.ScheduleAppointment();
        params.store = 'My Healthcare';
        params.productId = [SELECT Id FROM Product2 WHERE Is_Delivery_Option__c = TRUE LIMIT 1].Id;
        params.quantity = 1;

        String uuid = onl_CheckoutCtrl.addDeliveryToBasket(JSON.serialize(params));
        System.assert(uuid != null);

        Opportunity opp = [SELECT Id FROM Opportunity WHERE UUID__c = :uuid LIMIT 1];

        OpportunityLineItem deliveryOli = onl_CheckoutCtrl.getCurrentDeliveryOli(opp.Id);
        System.assertEquals(params.productId, deliveryOli.Product2.Id);

    }

    @IsTest
    static void test_newAuraHandledException() {
        Exception ex = onl_CheckoutCtrl.newAuraHandledException('testex');
        System.assert(ex.getMessage() == 'testex');
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
    global class onl_CheckoutCtrlTest_ServiceMock implements HttpCalloutMock {

        public Map<String, MockConfig> mockConfigs;

        global onl_CheckoutCtrlTest_ServiceMock(Map<String, MockConfig> mockConfigs) {
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

    @IsTest static void test_getFindByTestTypeOptions() {
        Online_Store_Lists_Config__c cfg = new Online_Store_Lists_Config__c();
        cfg.BookTestInClinicOptions__c = 'Fit to Fly;Day 2 Test;UK Entry Test';
        insert cfg;

        String result = onl_CheckoutCtrl.getFindByTestTypeOptions();

        List<onl_CheckoutCtrl.ValueLabelPair> pairs = (List<onl_CheckoutCtrl.ValueLabelPair>) JSON.deserialize(result, List<onl_CheckoutCtrl.ValueLabelPair>.class);

        System.assert(pairs.size() == 3);

    }




    @IsTest
    public static void schedulerPolicyNameIdMap_test() {
        System.debug(onl_CheckoutCtrl.schedulerPolicyNameIdMap());
    }

    @IsTest
    public static void getServiceCenters_test() {
        System.debug(onl_CheckoutCtrl.getServiceCenters());
    }

    @IsTest
    public static void getPickupLocations_test() {
        System.debug(onl_CheckoutCtrl.getPickupLocations());
    }

    @IsTest
    public static void checkIsHoliday_test() {

        List<Holiday> hList = new List<Holiday>();
        hList.add(new Holiday(ActivityDate=Date.today()));
        hList.add(new Holiday(ActivityDate=Date.today().addDays(5)));
        System.assert(onl_CheckoutCtrl.checkIsHoliday(Date.today(), hList));
    }



    @IsTest
    public static void getAvailableSlots_ex_test() {
        COVID_Test__c ctest = new COVID_Test__c(
                Test_Type__c = 'PCR Test'
        );
        insert ctest;
        String ctid = ctest.Id;
        try {
            onl_CheckoutCtrl.getAvailableSlots(ctid, null, Date.today());
        }
        catch (Exception ignore) {

        }
    }

    @IsTest
    public static void getAvailableSlotsByWorkTypeGroupAtMultipleLocations_ex_test() {
        try {
            onl_CheckoutCtrl.getAvailableSlotsByWorkTypeGroupAtMultipleLocations(
                    [SELECT Id FROM WorkTypeGroup LIMIT 1].Id
                    , null, Date.today());
        }
        catch (Exception ignore) {

        }
    }




}