trigger Opportunity_tgr on Opportunity (before insert, after update, after insert) {

    OpportunityTrigger.handle();


}