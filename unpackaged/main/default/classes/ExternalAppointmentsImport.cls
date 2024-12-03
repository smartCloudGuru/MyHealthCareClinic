/**
 * Created by Matija on 10.8.2023..
 */

public without sharing class ExternalAppointmentsImport {

    public static List<External_Booking__c> getAllAppointmentsForPatient(Account acc)
    {
        List<External_Booking__c> ret = new List<External_Booking__c>();

        List<External_Booking__c> aeronas = getAllAeronaAppointmentsForPatient(acc);
        List<External_Booking__c> sembles = getAllSembleAppointmentsForPatient(acc);

        if (aeronas!=null) ret.addAll(aeronas);
        if (sembles!=null) ret.addAll(sembles);

        return ret;
    }


    public static List<External_Booking__c> getAllAeronaAppointmentsForPatient(Account acc)
    {
        List<External_Booking__c> ret = new List<External_Booking__c>();

        if (String.isBlank(acc?.Aerona_Id__c)) return ret;

        AeronaServiceOASApi.OASRetrievePatientResponse response = AeronaService.getPatient(acc.Aerona_Id__c);

        if (response?.appointments != null)
        {
            for (AeronaServiceOASApi.OASAPIAppointmentDetails oasapiAppointmentDetails : response.appointments) {
                ret.add(externalBookingFromAerona(acc, oasapiAppointmentDetails));
            }
        }
        return ret;
    }

    public static List<External_Booking__c> getAllSembleAppointmentsForPatient(Account acc)
    {
        List<External_Booking__c> ret = new List<External_Booking__c>();

        if (String.isBlank(acc?.HeyDoc_Id__c)) return ret;

        HeyDocService.Patient response = HeyDocService.getPatientBookings(acc.HeyDoc_Id__c, Date.today().addYears(-10), Date.today().addYears(3));

        if (response?.bookings != null)
        {
            for (HeyDocService.Booking booking : response.bookings) {
                ret.add(externalBookingFromSemble(acc, booking));
            }
        }
        return ret;
    }

    public static External_Booking__c externalBookingFromAerona(Account acc, AeronaServiceOASApi.OASAPIAppointmentDetails oasapiAppointmentDetails)
    {
        External_Booking__c ret = new External_Booking__c();
        ret.External_System__c = 'Aerona';
        ret.Account__c = acc.Id;
        ret.Appointment_Time__c = oasapiAppointmentDetails.appointmentTime;
        ret.Appointment_Type__c = String.valueOf(oasapiAppointmentDetails.appointmentTypeId);
        ret.External_Id__c = String.valueOf(oasapiAppointmentDetails.appointmentId);
        ret.Status__c = AeronaWebhookResource.mapAppointmentStatusIdToStatus(oasapiAppointmentDetails.appointmentStatusId);

        return ret;
    }

    public static External_Booking__c externalBookingFromSemble(Account acc, HeyDocService.Booking booking)
    {
        External_Booking__c ret = new External_Booking__c();
        ret.External_System__c = 'Semble';
        ret.Account__c = acc.Id;
        ret.Appointment_Time__c = booking.start;
        ret.Appointment_Type__c = booking.appointment?.id;
        ret.External_Id__c = booking.id;
        String status = 'Scheduled';
        if (booking.deleted!=null && booking.deleted==true) status = 'Canceled';
        ret.Status__c = status;

        return ret;
    }

}