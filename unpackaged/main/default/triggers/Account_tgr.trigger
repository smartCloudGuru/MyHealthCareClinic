trigger Account_tgr on Account (before insert, before update, after update, after insert, after delete) {

    if (Trigger.isBefore) {
        AccountUtil.populateListMemberHandler(Trigger.new, Trigger.oldMap, Trigger.isInsert);
        AccountUtil.populateDateOfBirthAsText(Trigger.new, Trigger.oldMap, Trigger.isInsert);
    }
    else {
        AccountUtil.updateCorporateDiscount(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap, Trigger.IsInsert, Trigger.IsUpdate, Trigger.IsDelete, Trigger.IsAfter);

        if (Trigger.isInsert || Trigger.isUpdate) {
            try {
                AccountManager.generateUniqueFriendReferralCodes(Trigger.new);
            }
            catch (Exception ex) {
                System.debug(LoggingLevel.WARN, ex);
            }
        }
    }
}