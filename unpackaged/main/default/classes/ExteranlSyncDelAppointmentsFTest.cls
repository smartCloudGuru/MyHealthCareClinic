/**
 * Created 3.6.2022..
 */

@IsTest
private class ExteranlSyncDelAppointmentsFTest {
    @IsTest
    static void testBehavior() {
        List<ServiceAppointment> sas = new List<ServiceAppointment>();
        sas.add(new ServiceAppointment(Heydoc_Appointment_Id__c = 'aaa'));
        sas.add(new ServiceAppointment(Aerona_Id__c = '111'));
        System.debug('calling ExternalSyncDelAppointmentsF');
        ExternalSyncDelAppointmentsF.syncAppointments(sas);
    }
}