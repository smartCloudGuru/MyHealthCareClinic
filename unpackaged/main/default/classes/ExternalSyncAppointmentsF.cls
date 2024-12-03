/**
 * Created 22.11.2021..
 */

/** Wraps ExternalSyncAppointments syncing into a future method */
public without sharing class ExternalSyncAppointmentsF {

    @InvocableMethod(Category='Service Appointment' Label='External Sync - sync Bookings as FUTURE' Description='Sync bookings to eternal systems(s)')
    public static void syncAppointments(List<ServiceAppointment> appointments) {
        Set<String> extIds = new Set<String>();
        for (ServiceAppointment serviceAppointment : appointments) {
            extIds.add(serviceAppointment.Id);
        }
        ExternalSyncAppointments.syncAppointmentsFuture(JSON.serialize(extIds));
    }


}