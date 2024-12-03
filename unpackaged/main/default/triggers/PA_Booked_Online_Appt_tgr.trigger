trigger PA_Booked_Online_Appt_tgr on Proposed_Appointment__c (before insert,before update){
    for(Proposed_Appointment__c pa:trigger.new) {
        Boolean flag = false;
        if(trigger.isInsert){
            if(pa.State__c == 'Booked'){
                pa.Booking_DateTime__c = System.Now();
            }
        }else{
            if(pa.State__c == 'Booked' && trigger.oldMap.get(pa.id).State__c != 'Booked'){
                pa.Booking_DateTime__c = System.Now();
            }            
        } 
    }
}