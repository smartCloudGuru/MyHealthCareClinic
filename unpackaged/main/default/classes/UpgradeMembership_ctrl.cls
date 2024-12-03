public without sharing class UpgradeMembership_ctrl {
    @AuraEnabled
    public static Account getAccount(String accountId) {
        list<Account> objAccount = new list<Account>();
        try {
            objAccount.add([
                    SELECT Member_Group__r.Name, Age_In_Number__c, Member_Group__c, Id, Member_Status__c, Membership_Level__c, Membership_Type__c, Receptionist__c,
                            Clinician__c, Billing_Address__c, Payment_Frequency__c, Home_Clinic__c,
                            PersonEmail, Total_Monthly_Membership_Fee__c, Name, Contract_Sent_Date__c, Signature_Date__c
                    FROM Account
                    WHERE Id = :accountId
                    LIMIT 1
            ]);
            if (!objAccount.IsEmpty()) {
                updateSignatureFields(objAccount.get(0));
            }
        }
        catch (QueryException e) {

            throw newAuraHandledException(e.getMessage());
        }
        catch (Exception e) {

            throw newAuraHandledException(e.getMessage());
        }
        return objAccount.get(0);
    }

    public static void updateSignatureFields(Account objAcc) {
        if (objAcc.Member_Status__c == 'Member') {
            Account objAccount = new Account(Id = objAcc.Id);
            objAccount.Contract_Sent_Date__c = System.today();
            objAccount.Signature_Date__c = null;
            objAccount.Signature__c = null;
            objAccount.Membership_Start_Date__c = null;
            objAccount.Membership_Change_Dates__c = System.today();
            objAccount.Direct_Debit_Setup__c = false;
            List<Opportunity> listOpp = [
                    SELECT Id, Membership_Cancelled__c, (
                            SELECT Id
                            FROM OpportunityLineItems
                            WHERE Product2.Family = 'Membership_Plan'
                    )
                    FROM Opportunity
                    WHERE AccountId = :objAccount.Id
            ];
            for (Opportunity o : listOpp) {
                o.Membership_Cancelled__c = true;
            }
            update listOpp;
            update objAccount;
        }
    }

    public static Exception newAuraHandledException(String msg) {
        AuraHandledException aEx = new AuraHandledException(msg);
        aEx.setMessage(msg);
        return aEx;
    }
}