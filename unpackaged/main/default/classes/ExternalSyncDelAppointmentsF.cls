/**
 * Created 22.11.2021..
 */

/** Wraps ExternalSyncAppointments syncing into a future method */
public without sharing class ExternalSyncDelAppointmentsF {

    @InvocableMethod(Category='Service Appointment' Label='External Sync - sync Delete Bookings as FUTURE' Description='Sync DELETE bookings to eternal systems(s)')
    public static void syncAppointments(List<ServiceAppointment> appointments) {

        System.debug('::ExternalSyncDelAppointmentsF:syncAppointments:' + appointments);
        List<ExternalSyncAppointments.IdsByExternalSystemRequest> ids = new List<ExternalSyncAppointments.IdsByExternalSystemRequest>();
        for (ServiceAppointment serviceAppointment : appointments) {
            if (String.isNotEmpty(serviceAppointment.Heydoc_Appointment_Id__c)) {
                ids.add(new ExternalSyncAppointments.IdsByExternalSystemRequest(ExternalSyncAppointments.HEYDOC, serviceAppointment.Heydoc_Appointment_Id__c));
            }
            if (String.isNotEmpty(serviceAppointment.Aerona_Id__c)) {
                ids.add(new ExternalSyncAppointments.IdsByExternalSystemRequest(ExternalSyncAppointments.AERONA, serviceAppointment.Aerona_Id__c));
            }
            ExternalSyncAppointments.deleteAppointmentsFuture(JSON.serialize(ids));
        }
    }
}