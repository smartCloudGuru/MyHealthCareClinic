global class AggregateResultIterator implements Iterator<AggregateResult> {
   AggregateResult [] results {get;set;} 
   // tracks which result item is returned
   Integer index {get; set;} 
         
   global AggregateResultIterator() {
      index = 0;
      // Fire query here to load the results
      String query = 'SELECT count(Id),Day_Only(Start__c) st,Appointment_type__r.Meddbase_Key__c key FROM Proposed_Appointment__c WHERE Day_Only(start__c) <> null AND Appointment_type__r.Meddbase_Key__c <> null AND Start__c >= Today group by Day_Only(Start__c),Appointment_type__r.Meddbase_Key__c order by Day_Only(start__c) ASC';
      results = Database.query(query);            
   } 
   
   global boolean hasNext(){ 
      return results != null && !results.isEmpty() && index < results.size(); 
   }    
   
   global AggregateResult next(){        
      return results[index++];            
   }       
}