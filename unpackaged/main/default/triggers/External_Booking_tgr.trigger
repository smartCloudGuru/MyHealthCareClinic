/**
 * Created by Matija on 12.9.2023..
 */

trigger External_Booking_tgr on External_Booking__c (after insert, after update) {

    External_Booking_Trigger.handle();
}