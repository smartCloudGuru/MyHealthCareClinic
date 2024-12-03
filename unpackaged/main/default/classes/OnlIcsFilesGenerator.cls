/**
 * Created 15.9.2021..
 */

public without sharing class OnlIcsFilesGenerator {


    public static List<Messaging.EmailFileAttachment> generateIcsFiles(Id whatId) {

        if (whatId == null) return new List <Messaging.EmailFileAttachment>();

        // 2023-03 - checks first if whatId is opportunity or ServiceAppointment. Opportunity was used for COVID tests, SA as whatId is used for Booking

        List<ServiceAppointment> appointments = [
                SELECT
                        Id,
                        Heydoc_Appointment_Id__c,
                        Aerona_Id__c,
                        SchedStartTime,
                        SchedEndTime,
                        ServiceTerritory.Name,
                        ServiceTerritory.City,
                        ServiceTerritory.Street,
                        ServiceTerritory.PostalCode,
                        Opportunity_Product__r.Product2.Name,
                        Opportunity_Product__r.Product2.Store_Subtitle__c,
                        Opportunity_Product__r.Product2.Store_Title__c
                FROM ServiceAppointment
                WHERE Id = :whatId
        ];

        if (!appointments.isEmpty()) {
            return generateForServiceAppointment(appointments[0]);
        }

        return new List<Messaging.EmailFileAttachment>();
    }

    public static List<Messaging.EmailFileAttachment> generateForServiceAppointment(ServiceAppointment sa) {
        List <Messaging.EmailFileAttachment> efas = new List <Messaging.EmailFileAttachment>();

        if (sa == null) return efas;

        String icsContent;
        String title;


        //make an appointment name from Product Data
        if (
                String.isNotBlank(sa.Opportunity_Product__r?.Product2?.Store_Title__c) && String.isNotBlank(sa.Opportunity_Product__r?.Product2?.Store_Subtitle__c)
        ) {
            title = sa.Opportunity_Product__r?.Product2?.Store_Title__c + ' - ' + sa.Opportunity_Product__r?.Product2?.Store_Subtitle__c;
        }
        else if (
                String.isNotBlank(sa.Opportunity_Product__r?.Product2?.Store_Title__c)
        ) {
            title = sa.Opportunity_Product__r?. Product2?. Store_Title__c;
        }
        else {
            title = sa.Opportunity_Product__r?.Product2?.Name;
        }
        //title

        if (String.isBlank(title)) title = 'MyHealthcare Clinic';
        else title = 'MyHealthcare Clinic ' + title;


        //location
        String location = '';
        String locationEncoded;

        Boolean isVideoOrTel = false;

        if (sa.Opportunity_Product__r?.Product2?.Name != null) {
            if (sa.Opportunity_Product__r.Product2.Name .toLowerCase().contains('video')
                    || sa.Opportunity_Product__r.Product2.Name .toLowerCase().contains('telephone')) {
                isVideoOrTel = true;
            }
        }

        if (sa.ServiceTerritory != null && !isVideoOrTel) {
            location = sa.ServiceTerritory.Name;
            if (sa.ServiceTerritory.Street != null) {
                location = location + ', ' + sa.ServiceTerritory.Street;
                location = location + ', ' + sa.ServiceTerritory.PostalCode;
                location = location + ', ' + sa.ServiceTerritory.City;
            }
        }
        else {
            location = '';
        }

        location = location.replace('\n', ' ');
        locationEncoded = EncodingUtil.urlEncode(location, 'UTF-8');

        icsContent = 'BEGIN:VCALENDAR'
                + '\nVERSION:2.0'
                + '\nCALSCALE:GREGORIAN'
                + '\nBEGIN:VTIMEZONE'
                + '\nTZID:Europe/London'
                + '\nTZURL:http://tzurl.org/zoneinfo-outlook/Europe/London'
                + '\nX-LIC-LOCATION:Europe/London'
                + '\nBEGIN:DAYLIGHT'
                + '\nTZNAME:BST'
                + '\nTZOFFSETFROM:+0000'
                + '\nTZOFFSETTO:+0100'
                + '\nDTSTART:19701025T020000'
                + '\nRRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU'
                + '\nEND:DAYLIGHT'
                + '\nBEGIN:STANDARD'
                + '\nTZNAME:GMT'
                + '\nTZOFFSETFROM:+0100'
                + '\nTZOFFSETTO:+0000'
                + '\nDTSTART:19701025T020000'
                + '\nRRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU'
                + '\nEND:STANDARD'
                + '\nEND:VTIMEZONE'
                + '\nBEGIN:VEVENT'
                + '\nDTSTART;TZID=Europe/London:' + formatTime(sa.SchedStartTime)
                + '\nDTEND;TZID=Europe/London:' + formatTime(sa.SchedEndTime)
                + '\nSUMMARY:' + title
                + '\nLOCATION:' + location
                + '\nEND:VEVENT'
                + '\nEND:VCALENDAR';
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName(title + ' at ' + prettyDate(sa.SchedEndTime) + '.ics');
        efa.setBody(Blob.valueOf(icsContent));
        efa.setContentType('text/calendar');

        System.debug('::onlicsgen:adding efa:' + efa.fileName);
        efas.add(efa);


        return efas;
    }

    private static String formatTime(Datetime dt) {
        if (dt == null) return '';
        return dt.format('yyyyMMdd\'T\'HHmm00', 'Europe/London');
    }

    private static String prettyDate(Datetime dt) {
        if (dt == null) return '';
        return dt.format('dd-MM-YYYY HH-mm', 'Europe/London');
    }


}