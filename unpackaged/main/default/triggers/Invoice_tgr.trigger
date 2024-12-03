trigger Invoice_tgr on Invoice__c (after insert) {
    set<string> pIds = new set<string>();
    list<Proposed_Appointment__c> pa2update = new list<Proposed_Appointment__c>();
    for(Invoice__c inv:trigger.new){
        if(inv.Meddbase_Key__c != null && inv.Meddbase_Key__c != ''){
        pIds.add(inv.Meddbase_Key__c.split('-')[0]);
        }
    }
    map<string,Proposed_Appointment__c> paMap = new map<string,Proposed_Appointment__c>();  
    for(Proposed_Appointment__c pa:[SELECT Id, Invoice__c FROM Proposed_Appointment__c WHERE Id IN:pIds]){
        paMap.put(pa.Id, pa);
    }
    for(Invoice__c inv:trigger.new){
        if(inv.Meddbase_Key__c != null && inv.Meddbase_Key__c != ''){
            Proposed_Appointment__c p = paMap.get(inv.Meddbase_Key__c.split('-')[0]);
            p.Invoice__c = inv.Id;
            pa2update.add(p);
        }
    }
    if(!pa2update.isEmpty()){
        update pa2update;
    } 
}