/**
 * Created 27.5.2024..
 */

public without sharing class OpportunityManager {

    //    public static final String RT_Opportunity = 'Opportunity.Opportunity';
    //    public static final String RT_DentalTracker = 'Opportunity.Dental_Tracker';

    static RecordType cache_rt_dental_tracker = null;
    static Id cache_rt_dental_tracker_id = null;

    static RecordType cache_rt_dtp = null;
    static Id cache_rt_dtp_id = null;

    public static RecordType getDental_Tracker_RT() {
        if (cache_rt_dental_tracker == null) {

            List<RecordType> ret = [SELECT Id FROM RecordType WHERE Name = 'Dental Tracker' AND SobjectType = 'Opportunity' LIMIT 1];

            if (ret.isEmpty()) {
                cache_rt_dental_tracker = null;
                cache_rt_dental_tracker_id = null;
                return null;
            }
            else {
                cache_rt_dental_tracker = ret[0];
                cache_rt_dental_tracker_id = ret[0].Id;
            }

        }
        return cache_rt_dental_tracker;
    }

    public static Id getDental_Tracker_RT_Id() {
        if (cache_rt_dental_tracker == null) {
            getDental_Tracker_RT();
        }
        return cache_rt_dental_tracker_id;
    }


    public static RecordType getDental_TreatmentPlan_RT() {
        if (cache_rt_dtp == null) {

            List<RecordType> ret = [SELECT Id FROM RecordType WHERE Name = 'Dental Treatment Plan' AND SobjectType = 'Opportunity' LIMIT 1];

            if (ret.isEmpty()) {
                cache_rt_dtp = null;
                cache_rt_dtp_id = null;
                return null;
            }
            else {
                cache_rt_dtp = ret[0];
                cache_rt_dtp_id = ret[0].Id;
            }

        }
        return cache_rt_dtp;
    }

    public static Id getDental_TreatmentPlan_RT_Id() {
        if (cache_rt_dtp == null) {
            getDental_TreatmentPlan_RT();
        }
        return cache_rt_dtp_id;
    }


}