/**
 * Created 2.5.2024..
 */

public without sharing class BookingBusinessRules {

    /**
     * Calculates any eventual override to a duration of a given appointment.
     *
     * The method will first assess if the appointment belongs to an Opportunity record where 'Member_Benefit_Applicable__c' field is checked.
     * If so, it will attempt to find a custom duration set in the related WorkType record, specified by 'Membership_Duration__c' field.
     * If such custom duration exists and is positive, it will set it as the calculated duration for the given appointment.
     *
     * Furthermore, it will only apply this custom duration if there has been a non-cancelled appointment with the same WorkType
     * for the same account within the last 7 months of the new appointment.
     *
     * If there are no conditions met to use the custom duration or if there have been cancellations in the mentioned time-frame,
     * the method defaults to the original appointment duration.
     *
     * @param opp Opportunity The opportunity associated with the appointment
     * @param appointment ServiceAppointment The service appointment for which the duration will be evaluated
     *
     * @return Integer The duration of the appointment in minutes or null if the default duration should be used
     */
    public static Integer calcAppointmentDuration(Opportunity opp, ServiceAppointment appointment) {

        Integer overrideDuration = null;

        //[MHC-623] if Member_Benefit_Applicable__c and the work type has a different duration for this cases, change the duration
        if (opp.Member_Benefit_Applicable__c && appointment.WorkTypeId != null && appointment.SchedStartTime != null) {

            //check if there's a different membership duration setup for this WT
            List<WorkType> wts = [SELECT Id, Membership_Duration__c FROM WorkType WHERE Id = :appointment.WorkTypeId];
            if (!wts.isEmpty() && wts[0].Membership_Duration__c != null && wts[0].Membership_Duration__c > 0) {
                overrideDuration = Integer.valueOf(wts[0].Membership_Duration__c);
            }

            //[TMHC-40] apply member duration only if there was a non-canceled appointment for that work type in the last 6 months
            if (opp.AccountId != null) {
                Datetime dt_7months_prior = appointment.SchedStartTime.addMonths(-7);
                List<ServiceAppointment> prevApps = [
                        SELECT Id
                        FROM ServiceAppointment
                        WHERE ParentRecordId = :opp.AccountId
                        AND WorkTypeId = :appointment.WorkTypeId
                        AND StatusCategory != 'Canceled'
                        AND SchedStartTime >= :dt_7months_prior
                        AND SchedStartTime < :appointment.SchedStartTime
                        AND Id <> :appointment.Id
                ];
                if (prevApps.isEmpty()) return null; // null means no change needed, revert to default duration
            }
        }

        return overrideDuration;
    }

}