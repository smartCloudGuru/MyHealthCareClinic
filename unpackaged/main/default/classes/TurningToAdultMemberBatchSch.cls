global class TurningToAdultMemberBatchSch implements Schedulable {
   global void execute(SchedulableContext SC) { 
      Database.executeBatch(new TurningToAdultMemberBatch(), 1);  
   }
}