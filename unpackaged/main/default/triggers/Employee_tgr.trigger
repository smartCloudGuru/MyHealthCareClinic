trigger Employee_tgr on Employee__c (after update) {

    if (trigger.isUpdate) {
        
        EmployeeContract_ctrl.sendEmployeeContract(trigger.new, trigger.oldMap);
    }
}