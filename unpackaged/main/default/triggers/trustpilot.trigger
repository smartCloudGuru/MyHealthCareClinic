trigger trustpilot on Opportunity (after insert,after update) {
    /*if(trigger.isInsert){
        list<Trustpilot__c> toInsertTP = new list<Trustpilot__c>();
        for(Opportunity o: [SELECT Id,Account.PersonEmail,Account.Name,X1st_Appointment_Kept__c FROM Opportunity WHERE Id IN:trigger.newMap.keyset()]){
            if(o.X1st_Appointment_Kept__c == true){
                Trustpilot__c objTP = new Trustpilot__c();
                objTP.Name = o.Account.Name;
                objTP.Trustpilot_Email__c = o.Account.PersonEmail;
                toInsertTP.add(objTP);
            }        
        }  
        if(!toInsertTP.isEmpty()) insert toInsertTP;
    }else{         
        list<Trustpilot__c> toInsertTP = new list<Trustpilot__c>();
        for(Opportunity o: [SELECT Id,Account.PersonEmail,Account.Name,X1st_Appointment_Kept__c FROM Opportunity WHERE Id IN:trigger.newMap.keyset()]){
            if(trigger.oldMap.get(o.Id).X1st_Appointment_Kept__c == false && o.X1st_Appointment_Kept__c == true){
                Trustpilot__c objTP = new Trustpilot__c();
                objTP.Name = o.Account.Name;
                objTP.Trustpilot_Email__c = o.Account.PersonEmail;
                toInsertTP.add(objTP);
            }        
        }  
        if(!toInsertTP.isEmpty()) insert toInsertTP;
    }*/
}