trigger Lead_tgr on Lead (after update, before insert, before update) {
    LeadTriggerHandler.handle();
}