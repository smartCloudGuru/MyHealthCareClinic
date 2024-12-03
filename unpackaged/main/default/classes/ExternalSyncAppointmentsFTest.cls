/**
 * Created 8.9.2022..
 */

@IsTest
private class ExternalSyncAppointmentsFTest {

    @IsTest
    static void testFutureBehavior() {
        List<ServiceAppointment> sas = new List<ServiceAppointment>();
        ExternalSyncAppointmentsF.syncAppointments(sas);
    }
}