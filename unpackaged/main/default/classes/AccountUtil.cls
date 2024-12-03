/**
 * Created by mo on 5/14/2019.
 */

public without sharing class AccountUtil {

    public static void populateDateOfBirthAsText(List<Account> newAccounts, Map<Id, Account> oldAccountMap, Boolean isInsert) {
        for (Account a : newAccounts) {
            if (a.Date_of_Birth__c != null)
            {
                a.Date_Of_Birth_As_Text__c =
                        a.Date_of_Birth__c.year()
                        + '-' + (a.Date_of_Birth__c.month()<10 ? '0' : '') +
                        a.Date_of_Birth__c.month()
                        + '-' + + (a.Date_of_Birth__c.day()<10 ? '0' : '') +
                        a.Date_of_Birth__c.day();
            }
        }
    }

    public static void populateListMemberHandler(List<Account> newAccounts, Map<Id, Account> oldAccountMap, Boolean isInsert) {
        for (Account a : newAccounts) {
            Boolean flag = false;
            if (isInsert) {
                flag = a.Patient_Type__c == 'Member';
            } else {
                flag = a.Patient_Type__c == 'Member' && oldAccountMap.get(a.Id).Patient_Type__c != a.Patient_Type__c;
            }
            if (flag) {
                a.List_Of_Members_Covered_By_The_Contract__c = '1- ' + ((a.FirstName != null && a.FirstName != '')
                        ? a.FirstName : '') + ' ' + ((a.LastName != null && a.LastName != '') ? a.LastName : '') + '\n';
            }
        }
    }
    public static void updateCorporateDiscount(List<Account> newAcc, List<Account> oldAcc, Map<Id, Account> newAccMap,
            Map<Id, Account> oldAccMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete,
            Boolean isAfter) {
        if (RunOnceTgr.runOnce()) {
            Set<Id> accountIds = new Set<Id>();
            if (isInsert || isUpdate) {
                for (Account an : newAcc) {
                    //accountIds.add(an.Id);
                    String mgId = an.Member_Group__c;
                    if ((mgId == null || mgId == '') && oldAccMap != null) {
                        mgId = oldAccMap.get(an.Id).Member_Group__c;
                    } else {
                        mgId = an.Member_Group__c;
                    }
                    if (mgId != null && mgId != '') {
                        accountIds.add(mgId);
                    } else {
                        accountIds.add(an.Id);
                    }
                }
            } else if (isDelete) {
                for (Account ao : oldAcc) {
                    //accountIds.add(ao.Id);
                    if (ao.Member_Group__c != null) {
                        accountIds.add(ao.Member_Group__c);
                    }
                }
            }
            if ((isInsert || isUpdate) && isAfter) {
                List<Opportunity> insertMembershipOpp = new List<Opportunity>();
                System.debug('>>>>>>>>>>>>>>>>>IN after Updated>>>>>>>>>>>>>>');
                /*map<String,Id> oppByName = new map<String, Id>();
                for(Account a: [SELECT Id,(SELECT Id, Name, Membership_Level__c FROM Opportunities) FROM Account WHERE Id IN: newAccMap.keySet()]){
                    for(Opportunity o:a.Opportunities){
                        oppByName.put(o.Name, o.Id);
                    }
                }*/
                for (Account a : newAcc) {
                    if (oldAccMap != null) {
                        if (a.Patient_Type__c == 'Member'
                                && (oldAccMap.get(a.Id).Membership_Level__c != a.Membership_Level__c
                                && a.Membership_Level__c != null) || (oldAccMap.get(a.Id).Membership_Type__c != a.Membership_Type__c
                                && a.Membership_Type__c != null) || (oldAccMap.get(a.Id).Membership_Add_On__c != a.Membership_Add_On__c)) {
                            System.debug(a.Id + '>>>>>>' + ((oldAccMap.get(a.Id).FirstName != null && oldAccMap.get(a.Id).FirstName != '') ? oldAccMap.get(a.Id).FirstName + ' ' : ' ') + oldAccMap.get(a.Id).LastName + ' - ' + oldAccMap.get(a.Id).Membership_Level__c);
                            List<Opportunity> objOpportunities = [SELECT Id FROM Opportunity WHERE AccountId = :a.Id AND Name = :(((oldAccMap.get(a.Id).FirstName != null && oldAccMap.get(a.Id).FirstName != '') ? oldAccMap.get(a.Id).FirstName + ' ' : ' ') + oldAccMap.get(a.Id).LastName + ' - ' + oldAccMap.get(a.Id).Membership_Level__c).trim()];
                            System.debug('--------' + objOpportunities);
                            delete objOpportunities;
                            Opportunity objOpp = new Opportunity();//Id = (objOpportunities.size() > 0)?objOpportunities.get(0).Id:null);
                            objOpp.Name = ((a.FirstName != null && a.FirstName != '') ? a.FirstName + ' ' : ' ') + a.LastName + ' - ' + newAccMap.get(a.Id).Membership_Level__c;
                            objOpp.AccountId = a.Id;
                            objOpp.StageName = 'Closed Won';
                            objOpp.CloseDate = System.today();
                            objOpp.Membership_Type__c = a.Membership_Type__c;
                            objOpp.Membership_Level__c = a.Membership_Level__c;
                            objOpp.Payment_Frequency__c = a.Payment_Frequency__c;
                            insertMembershipOpp.add(objOpp);
                        }
                    } else {
                        if (a.Patient_Type__c == 'Member' && a.Membership_Level__c != null && a.Membership_Type__c != null) {
                            Opportunity objOpp = new Opportunity();
                            objOpp.Name = ((a.FirstName != null && a.FirstName != '') ? a.FirstName + ' ' : ' ') + a.LastName + ' - ' + newAccMap.get(a.Id).Membership_Level__c;
                            objOpp.AccountId = a.Id;
                            objOpp.StageName = 'Closed Won';
                            objOpp.CloseDate = System.today();
                            objOpp.Membership_Type__c = a.Membership_Type__c;
                            objOpp.Membership_Level__c = a.Membership_Level__c;
                            objOpp.Payment_Frequency__c = a.Payment_Frequency__c;
                            insertMembershipOpp.add(objOpp);
                        }
                    }
                }
                if (!insertMembershipOpp.isEmpty()) {
                    upsert insertMembershipOpp;
                    Map<Id, Opportunity> oppsMap = new Map<Id, Opportunity>([
                            SELECT Name,Account.Membership_Add_On__c,Account.Corporate_Discount__c,
                                    Id,Account.Membership_Level__c, Account.Membership_Type__c
                            FROM Opportunity
                            WHERE Id IN :insertMembershipOpp
                    ]);
                    Map<String, Product2> productCodeMap = new Map<String, Product2>();
                    List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
                    for (Product2 objProd : [SELECT Name FROM Product2 WHERE (Family = 'Membership_Plan' ) AND IsActive = TRUE]) {
                        productCodeMap.put(objProd.Name, objProd);
                    }
                    List<String> addONProducts = new List<String>();
                    if (String.isNotBlank(oppsMap.get(insertMembershipOpp[0].Id).Account.Membership_Add_On__c)) {
                        addONProducts = oppsMap.get(insertMembershipOpp[0].Id).Account.Membership_Add_On__c.split(';');
                    }
                    Set<String> memberTypes = new Set<String>();
                    for (Opportunity objOppty : oppsMap.values()) {
                        memberTypes.add(objOppty.Account.Membership_Type__c);
                    }
                    Map<Id, PricebookEntry> pbeMap = new Map<Id, PricebookEntry>([
                            SELECT ProductCode, UnitPrice,
                                    Product2Id, Product2.Name, Pricebook2Id
                            FROM PricebookEntry
                            WHERE (Product2.Name IN :productCodeMap.keySet() OR Name IN:addONProducts)
                            AND Pricebook2.Name IN:memberTypes
                    ]);
                    for (Opportunity objOppty : oppsMap.values()) {
                        for (PricebookEntry pbe : pbeMap.values()) {
                            System.debug('-----' + pbe);
                            if (null != objOppty.Account.Membership_Level__c &&
                                    (pbe.Product2.Name.equalsIgnoreCase(objOppty.Account.Membership_Level__c) ||
                                            (String.isNotBlank(objOppty.Account.Membership_Add_On__c)
                                                    && objOppty.Account.Membership_Add_On__c.toLowerCase().contains(pbe.Product2.Name.toLowerCase())))) {
                                System.debug(pbe.Product2Id + '>>>>>>>>>----->>>>>>>' + objOppty.Account.Membership_Level__c);
                                PricebookEntry objPricebookEntry = AddMember_ctrl.getPriceByMembershipLevel(objOppty.Account.Membership_Type__c, pbe.Product2Id);
                                System.debug('-----------------------' + objPricebookEntry);
                                if (objPricebookEntry != null) {
                                    OpportunityLineItem oli = new OpportunityLineItem();
                                    oli.OpportunityId = objOppty.Id;
                                    oli.PricebookEntryId = objPricebookEntry.Id;
                                    oli.Quantity = 1;
                                    oli.UnitPrice = objPricebookEntry.UnitPrice;
                                    oli.Member_Price__c = objPricebookEntry.UnitPrice - (objPricebookEntry.UnitPrice * objOppty.Account.Corporate_Discount__c) / 100;
                                    oliList.add(oli);
                                    //break;
                                }
                            }
                        }
                    }
                    if (!oliList.isEmpty()) upsert oliList;
                }
            }
            if ((isInsert || isDelete || isUpdate) && isAfter) {
                List<Account> toUpdateAccounts = new List<Account>();
                List<Opportunity> toCreateOpportunity = new List<Opportunity>();
                //list<Account> accountMemberGroupIds = new list<Account>();
                List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
                Decimal totalMemberFees = 0;
                System.debug('>>-------------' + accountIds);
                List<Account> lstAcc = [SELECT FirstName,LastName,Total_Monthly_Membership_Fee__c,List_Of_Members_Covered_By_The_Contract__c, Id,Membership_Type__c, (SELECT Total_Monthly_Membership_Fee__c,Payment_Frequency__c,Membership_Level__c,Membership_Type__c,LastName, FirstName FROM Member_Group__r) FROM Account WHERE Id IN:accountIds AND IsPersonAccount = TRUE];
                for (Account acc : lstAcc) {
                    Account a = new Account(Id = acc.Id);
                    String relatedMember = '1- ' + ((acc.FirstName != null && acc.FirstName != '') ? acc.FirstName : '') + ' ' + ((acc.LastName != null && acc.LastName != '') ? acc.LastName : '') + (String.isNotBlank(acc.Membership_Type__c) ? ' - ' + acc.Membership_Type__c : '') + '\n'; //acc.List_Of_Members_Covered_By_The_Contract__c+'\n';//'1- '+((acc.FirstName != null && acc.FirstName != '')?acc.FirstName:'')+' '+((acc.LastName != null && acc.LastName != '')?acc.LastName:'')+ '\n';

                    totalMemberFees = acc.Total_Monthly_Membership_Fee__c != null ? acc.Total_Monthly_Membership_Fee__c : 0.0;
                    System.debug('>>>>>>>>>>>>' + totalMemberFees);
                    Integer i = 2;
                    //accountMemberGroupIds = acc.Member_Group__r;
                    for (Account ac : acc.Member_Group__r) {
                        String pName = ((ac.FirstName != null && ac.FirstName != '') ? ac.FirstName : '') + ' ' + ((ac.LastName != null && ac.LastName != '') ? ac.LastName : '');
                        if (!relatedMember.contains(pName)) {
                            relatedMember += i + '- ' + pName + (String.isNotBlank(ac.Membership_Type__c) ? ' - ' + ac.Membership_Type__c : '') + '\n';
                            i++;
                            totalMemberFees += ac.Total_Monthly_Membership_Fee__c != null ? ac.Total_Monthly_Membership_Fee__c : 0.0;
                        }
                    }
                    /*for(Opportunity o:[SELECT Id,X1st_Appointment_Kept__c,X1st_Appointment_Made__c,Account_Name_Formula__c,Appointment_Date__c,Appointment_Outcome__c,Budget_Confirmed__c,Cancelled__c,Cash_Received__c,Cash_Sale__c,Clinician__c,Date_Appointment_Made__c,Discovery_Completed__c,DNA__c,First_Membership_payment__c,List_or_member__c,Loss_Reason__c,Member_Price__c,Member_Price_Chosen__c,Member_Price_Chosen_Formula__c,Membership_Contract_Signed__c,Membership_Details_Correct__c,Membership_Level__c,Membership_Type__c,Mode__c,Monthly_Payment__c,Monthly_Payment_formula__c,Next_Payment_Date__c,Next_Payment_Date_Formula__c,Non_Member_Price_Chosen__c,Number_of_Dental_Products__c,Number_of_Implants_Products__c,Number_of_Ortho_Products__c,Opportunity_Type__c,Opportunity_Value__c,Payment_Frequency__c,Payments_Made__c,Payments_Outstanding__c,Product_Family_for_Product_Search__c,PSM__c,Reason_for_non_conversion__c,ROI_Analysis_Completed__c,Sale_from_1st_Appointment__c,Site__c,Business_Unit__c,AccountId,Name,StageName,CloseDate,Account.Member_Group__r.Id,(SELECT Id,OpportunityId,PricebookEntryId,Product2Id,Member_Price__c,UnitPrice FROM OpportunityLineItems WHERE Product2.Family = 'Membership_Plan') FROM Opportunity WHERE AccountId IN:acc.Member_Group__r]){
                        if(o.OpportunityLineItems.size() > 0){
                            CommonUtility.OpporunityDeepClone(o,o.Account.Member_Group__r.Id);
                        }
                    }*/
                    a.Total_Monthly_Membership_Fees__c = totalMemberFees;
                    a.List_Of_Members_Covered_By_The_Contract__c = relatedMember;
                    toUpdateAccounts.add(a);
                }
                /*if(totalMemberFees == 0 && newAcc != null){
                    for(Account ac:[Select Total_Monthly_Membership_Fee__c,Id, (Select Id From Member_Group__r) From Account WHERE Id IN:newAccMap.KeySet() AND IsPersonAccount = true]){
                        if(ac.Member_Group__r.size() == 0){
                            Account a = new Account(id=ac.id);
                            a.Total_Monthly_Membership_Fees__c = ac.Total_Monthly_Membership_Fee__c ;
                            toUpdateAccounts.add(a);
                        }
                    }
                }*/
                if (!toUpdateAccounts.isEmpty()) update toUpdateAccounts;
            }

        }
    }
}