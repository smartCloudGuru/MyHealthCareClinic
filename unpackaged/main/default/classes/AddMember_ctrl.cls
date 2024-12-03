public with sharing class AddMember_ctrl {  
    public String membershipType{ get; set; }
    public String membershipLevel{ get; set; }
    public list<Account> selectedPatients{get;set;}
    public list<Account> existingPatient{get;set;}
    public Integer enforceInsertDuplicatePat{get;set;}
    public String selectPatientId{get;set;}
    public Account objAccount {get;set;}
    public Opportunity objOpportunity {get;set;} 
    public Integer patIndex{get;set;}
    public string selectedRemoveAccId{get;set;}
    public string memberGroupPayer{get;set;}
    public string memberDetails{get;set;}
    public string whereClause{get;set;}
    public string listId2NotInclude{get;set;}
    public Boolean IsUserHaveRemovePermission{get;set;}
    public AddMember_ctrl(ApexPages.StandardController controller) {
        init();
    }
    public void init(){        
        membershipType = ApexPages.currentPage().getParameters().get('mt');
        membershipLevel = ApexPages.currentPage().getParameters().get('ml');
        memberGroupPayer = ApexPages.currentPage().getParameters().get('id');
        existingPatient = new List<Account>();
        IsUserHaveRemovePermission();
        objAccount = addAccount(membershipLevel);
        objOpportunity = new Opportunity();
        selectedPatients = new list<Account>();
        selectedPatients.add([SELECT Total_Monthly_Membership_Fee__c,Membership_Add_On__c ,Member_Status__c,Id,Name,Membership_Level__c,Membership_Type__c,Member_Group__c, 
                                Date_of_Birth__c,FirstName,lastName,PersonMobilePhone,PersonEmail,Patient_Type__c,(select id,Total_Monthly_Membership_Fee__c from Member_Group__r) 
                                From Account WHERE Id=:memberGroupPayer limit 1]);
        membershipType = selectedPatients.get(0).Membership_Type__c;
        memberDetails = getMemberDetails(selectedPatients.get(0),memberGroupPayer);
        selectedPatients.addAll([SELECT Id,Name,Member_Status__c,Membership_Add_On__c,Membership_Level__c,Membership_Type__c,Member_Group__c,Total_Monthly_Membership_Fee__c,
                                Date_of_Birth__c,FirstName,lastName,PersonMobilePhone,PersonEmail,Patient_Type__c 
                                From Account WHERE Member_Group__c=:memberGroupPayer order by LastModifiedDate]);
        if(membershipLevel == 'Family'){
            Integer listSize = selectedPatients.size();
            if(listSize < 4){
                for(Integer i=0;i<4-listSize;i++){
                    if(i<1){
                        selectedPatients.add(addAccount('Family Adult'));
                    }else{
                        selectedPatients.add(addAccount('Family Child'));
                    }
                }
            }                       
        }
        if(membershipLevel == 'Joint Adult'){ 
            Integer listSize = selectedPatients.size();
            if(listSize < 2){
                for(Integer i=0;i<2-listSize;i++){
                    selectedPatients.add(addAccount('Adult'));
                }
            } 
        }
        queryFilter();
    }
    public void queryFilter(){
        listId2NotInclude = '';
        for(Account a:selectedPatients){
            if(a.Id != null){
               listId2NotInclude +=',\\\''+a.Id+'\\\''; 
            }
        }
        listId2NotInclude  = ' AND Id NOT IN ('+listId2NotInclude .replaceFirst(',','')+')';
        whereClause = ' WHERE Membership_Level__c '+(membershipLevel == 'Family'?(' IN (\\\'Family Adult\\\',\\\'Family Child\\\')'):('=\\\'Adult\\\''));
    }
    @RemoteAction
    public static string getMemberDetails(Account objAcc,string memberGroupPayer){
        Decimal totalMemberPrice = 0.0;
        if(null == objAcc){        
            objAcc = [SELECT Member_Status__c,Total_Monthly_Membership_Fee__c ,Id,Name,Membership_Level__c,Membership_Type__c,Member_Group__c,
                         Date_of_Birth__c,FirstName,lastName,PersonMobilePhone,PersonEmail,Patient_Type__c,Membership_Add_On__c,
                         (select id,Total_Monthly_Membership_Fee__c from Member_Group__r) From Account WHERE Id=:memberGroupPayer limit 1];
            totalMemberPrice += objAcc.Total_Monthly_Membership_Fee__c;
            /*set<String> addOns = new set<String>();
            for(Account a:objAcc.Member_Group__r) {
                if(a.Membership_Add_On__c!=null) {
                    addOns.addAll(a.Membership_Add_On__c.split(';'));
                }
            }
            map<String, PricebookEntry> mapAddOnPrice = getAddOnPrice(addOns);*/
            for(Account a:objAcc.Member_Group__r){
                totalMemberPrice += a.Total_Monthly_Membership_Fee__c;
                /*for(PricebookEntry p:mapAddOnPrice.values()){
                    totalMemberPrice += (a.Membership_Add_On__c!=null?mapAddOnPrice.get(p.Name).UnitPrice:0);
                }*/
            }
        }
        return 'Total Membership Price is <b style="color: #f9f571fc;">£'+totalMemberPrice+'</b> for <b style="color: #f9f571fc;">'+(objAcc.Member_Group__r.size()+1)+'</b> members.'; 
    }
    /*public static map<String, PricebookEntry> getAddOnPrice(set<String> memberAddOn){
        map<String, PricebookEntry> peMap = new map<String, PricebookEntry>();
        for(PricebookEntry p:[Select ProductCode, UnitPrice, Product2Id, Product2.Name, priceBook2Id From PricebookEntry Where Name IN:memberAddOn]){
            peMap.put(p.Name,p);
        }
        return peMap;
    }*/
    @RemoteAction
    public static string addAnotherMembership(String accountId,string membershipType){   
        Account a = [SELECT Id,FirstName,LastName,Membership_Type__c,Membership_Level__c,Payment_Frequency__c FROM Account WHERE id=:accountId limit 1];     
        Opportunity objOpp = new Opportunity();
        objOpp.Name = ((a.FirstName!= null && a.FirstName!= '')?a.FirstName+' ':' ')+a.LastName+' - '+a.Membership_Level__c;  
        objOpp.AccountId = a.id;
        objOpp.StageName = 'Closed Won';
        objOpp.CloseDate = System.Today();
        objOpp.Membership_Type__c = membershipType;
        objOpp.Membership_Level__c = a.Membership_Level__c;
        objOpp.Payment_Frequency__c = a.Payment_Frequency__c; 
        insert objOpp;
        Map<string, Product2> productCodeMap = new Map<string, Product2>();   
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();         
        for(Product2 objProd : [Select Name from Product2 Where Family = 'Membership_Plan' AND IsActive=True]){
            productCodeMap.put(objProd.Name, objProd);
        }
        map<Id,Opportunity> oppsMap = new map<Id, Opportunity>([SELECT Name,Id,Account.Membership_Level__c,Account.Membership_Type__c
                                                                FROM Opportunity WHERE Id =: objOpp.Id]);
        set<String> memberTypes = new set<String>();
        for(Opportunity objOppty : oppsMap.values()){
            memberTypes.add(objOppty.Account.Membership_Type__c);
        }
        map<Id,PricebookEntry> pbeMap = new map<Id,PricebookEntry>([SELECT ProductCode, UnitPrice,
                Product2Id, Product2.Name, priceBook2Id FROM PricebookEntry
        WHERE (Product2.Name IN : productCodeMap.keySet())
        AND Pricebook2.Name IN: memberTypes]);
        /*map<Id,PricebookEntry> pbeMap = new map<Id,PricebookEntry>([SELECT ProductCode, UnitPrice, Product2Id, Product2.Name, priceBook2Id
                                                                    FROM PricebookEntry WHERE Product2.Name IN : productCodeMap.keySet()]);*/
        for(Opportunity objOppty : oppsMap.values()){  
            for(PricebookEntry pbe: pbeMap.values()){
                if(null != objOppty.Account.Membership_Level__c && pbe.Product2.Name.endsWithIgnoreCase(objOppty.Account.Membership_Level__c)){
                    System.debug(pbe.Product2Id+'>>>>>>>>>----->>>>>>>'+objOppty.Account.Membership_Level__c);
                    PricebookEntry objPricebookEntry = getPriceByMembershipLevel(objOppty.Account.Membership_Type__c,pbe.Product2Id);
                    System.debug('-----------------------'+objPricebookEntry);
                    if(objPricebookEntry != null) {
                        OpportunityLineItem oli = new OpportunityLineItem();
                        oli.OpportunityId = objOppty.id;
                        oli.PricebookEntryId = objPricebookEntry.id;
                        oli.Quantity = 1;
                        oli.UnitPrice = objPricebookEntry.UnitPrice;//pbe.UnitPrice;
                        oli.Member_Price__c = objPricebookEntry.UnitPrice;//pbe.UnitPrice;
                        oliList.add(oli);
                        break;
                    }
                } 
            }
        }
        if(!oliList.IsEmpty()) insert oliList;
        return objOpp.Id;
    }
    @RemoteAction
    public static Account rerenderTbl(string accId,string memberGroupPayerId,boolean isSelectedPat){
        if(accId != null && accId != ''){
            Account accToRerender = [SELECT Member_Status__c,Id,Name,Membership_Level__c,Membership_Type__c,Member_Group__c,Total_Monthly_Membership_Fee__c ,
                Date_of_Birth__c,FirstName,lastName,PersonMobilePhone,PersonEmail,Patient_Type__c,Membership_Add_On__c  From Account WHERE Id=:accId limit 1];
            string memberId = accToRerender.Member_Group__c;    
            if(isSelectedPat == true){    
                Account a2Update = new Account(Id=accId);
                a2Update.Member_Group__c = memberGroupPayerId;
                a2Update.Relation_With_Payer__c = 'Unknown';
                update a2Update;
            }
            return accToRerender;
        }
        return null;
    }
    public Account addAccount(string membershipLevel){
        return new Account(Payment_Frequency__c='Monthly',Patient_Type__c='Member',Membership_Level__c=membershipLevel ,Membership_Type__c=membershipType);
    }
    public void resetNewPatForm(){
        enforceInsertDuplicatePat = 0;
        objAccount = new Account();
        existingPatient = new List<Account>();
    }
    public void onSave() {
        try {
            if (String.IsBlank(objAccount.Lastname) && objAccount.Lastname.trim() == '') {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Last Name is required!'));
                return;
            }
            if (String.IsBlank(objAccount.Relation_With_Payer__c)) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Relation With payer is required!'));
                return;
            }
            if (String.IsBlank(objAccount.Home_Clinic__c)) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Home Clinic is required!'));
                return;
            }
            if (null == objAccount.Date_of_Birth__c) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Date Of Birth is required!'));
                return;
            }
            existingPatient = new List<Account>();
            system.debug(objAccount.LastName + '>>>>' + objAccount.FirstName + '>>>>>' + objAccount.PersonEmail);
            existingPatient.addAll([
                    SELECT Id,Name,PersonEmail,Phone
                    FROM Account
                    WHERE FirstName = :objAccount.FirstName
                    AND LastName = :objAccount.LastName
                    AND PersonEmail = :objAccount.PersonEmail
            ]);
            if (existingPatient.size() > 0) {
                if (enforceInsertDuplicatePat == 0) {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.warning, 'Duplicate patient(s) exist, please select an existing Patient or click on save if you still want to create a brand new Patient.'));
                    ++enforceInsertDuplicatePat;
                    return;
                }
            }
            objAccount.Member_Group__c = memberGroupPayer;
            upsert objAccount;
            if (null != patIndex) {
                Integer i = patIndex - 1;
                selectedPatients.add(i, objAccount);
                selectedPatients.remove(i + 1);
                patIndex = null;
            } else {
                selectedPatients.add(objAccount);
            }
            objAccount = new Account();
            existingPatient = new List<Account>();
            memberDetails = getMemberDetails(null, memberGroupPayer);
        }/*catch (ListException l){
            objAccount = new Account();
            existingPatient = new List<Account>();
            memberDetails = getMemberDetails(null, memberGroupPayer);
        }*/catch(Exception e){
            String errorMessage = e.getMessage();
            if(errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') ){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,(e.getMessage().split('FIELD_CUSTOM_VALIDATION_EXCEPTION')[1]).replaceFirst(',','').replace('[','').replace(']','').replace(':',''));
                ApexPages.addMessage(myMsg);
            }else{
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage());
                ApexPages.addMessage(myMsg);
            }
            /*ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()
            .replace('Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION,','')
            .replace(': []','')));*/
        }
    }
    public void addMore() {
        IsUserHaveRemovePermission();
        queryFilter();
        selectedPatients.add(addAccount(membershipLevel));
        objAccount = new Account();
    }
    public void selectDuplicatePat(){
        if(String.IsNotBlank(selectPatientId)) {
            Account acc = [SELECT Member_Status__c,Id,Membership_Level__c,Membership_Type__c,Member_Group__c,
                            Total_Monthly_Membership_Fee__c, Date_of_Birth__c,FirstName,lastName,PersonMobilePhone,
                            PersonEmail,Patient_Type__c,Membership_Add_On__c
                    From Account
                    WHERE Id = :selectPatientId
                    limit 1
            ];
            acc.Member_Group__c = memberGroupPayer;
            update acc;
            selectedPatients.add(acc);
        }
    }
    public void removePatient() {
        try{
            Account tempAcc = selectedPatients.get(patIndex-1);
            string aId = ''+tempAcc.id; 
            if(aid != null && aid != ''){            
                Account acc2Update = new Account(Id=tempAcc.Id);
                acc2Update.Member_Group__c = null;
                update acc2Update;
                memberDetails = getMemberDetails(null,memberGroupPayer);
            }  
            queryFilter();      
            selectedPatients.remove(patIndex-1);
            patIndex = null;
        }catch(Exception e){
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
        }
    }
    public void quickRemove(){        
        if(selectedRemoveAccId != null && selectedRemoveAccId != ''){            
            Account acc2Update = new Account(Id=selectedRemoveAccId);
            acc2Update.Member_Group__c = null;
            update acc2Update;
            memberDetails = getMemberDetails(null,memberGroupPayer);
        } 
        queryFilter(); 
    }
    public void updateMembership(){        
        list<Account> accToUpdateList  = new list<Account>();//selectedPatients.get(0);     
        Integer i = 0;
        boolean isValid = true;
        for(Account a:selectedPatients){ 
            string aId = a.id;  
            if(aId != null && aId != ''){     
                Account objA = new Account(Id=a.Id);
                objA.Patient_Type__c = selectedPatients.get(0).Patient_Type__c;
                objA.Member_Status__c = selectedPatients.get(0).Member_Status__c;
                objA.Membership_Add_On__c = selectedPatients.get(0).Membership_Add_On__c;
                objA.Membership_Type__c = selectedPatients.get(0).Membership_Type__c;
                accToUpdateList.add(objA);
            }else{
                selectedPatients.get(i).Patient_Type__c = selectedPatients.get(0).Patient_Type__c;
                selectedPatients.get(i).Member_Status__c = selectedPatients.get(0).Member_Status__c;
                selectedPatients.get(i).Membership_Add_On__c = selectedPatients.get(0).Membership_Add_On__c;
                selectedPatients.get(i).Membership_Type__c = selectedPatients.get(0).Membership_Type__c;
            }
            i++;
        }
        if(!accToUpdateList.IsEmpty()) 
            try{    
                update accToUpdateList;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Confirm,'Membership Updated Successfully!'));
            }
            catch (Exception e){ 
                String errorMessage = e.getMessage();
                if(errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') ){ 
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,(e.getMessage().split('FIELD_CUSTOM_VALIDATION_EXCEPTION')[1]).replaceFirst(',','').replace('[','').replace(']','').replace(':',''));
                    ApexPages.addMessage(myMsg);
                }
                else{
                     ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage());
                     ApexPages.addMessage(myMsg);
                }
            } 
    }
    /*public boolean isValidateMembersContract(){
        Integer adult = 0;
        Integer child = 0;
        if(membershipLevel == 'Family'){
            for(Account a:selectedPatients){
                string aId = ''+a.id; 
                if(a.Membership_Level__c == 'Family Adult' && aId != ''){
                    ++adult;        
                }
                if(a.Membership_Level__c == 'Family Child' && aId != ''){
                    ++child;        
                }
            }
            if(adult == 1 && child == 2){                
                return true;
            }
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Family contract must have 2 Family Adult and 2 Family Child members.'));
            return false;
        }else if(membershipLevel == 'Joint Adult'){
            for(Account a:selectedPatients){
                string aId = ''+a.id; 
                if(a.Membership_Level__c == 'Joint Adult' && aId != ''){
                    ++adult;        
                }
            }
            if(adult == 2){                
                return true;
            }
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Joint contract must have 2 Adults.'));
            return false;
        } 
        return true;
    }*/
    public pageReference next(){
        //if(isValidateMembersContract()){
            pageReference pr;
            if(ApexPages.currentPage().getParameters().get('action') == 'sc'){
                Account acc = new Account(Id=ApexPages.currentPage().getParameters().get('id'));
                acc.Cancellation_Date__c = null;
                acc.Cancelled_membership__c = false;
                acc.Cancellation_Reason__c = null;
                update acc;
                pr = new pageReference('/apex/MembershipContractPreview?action=sc&token='+ApexPages.currentPage().getParameters().get('id')+'&ml='+ApexPages.currentPage().getParameters().get('ml')+'&mt='+ApexPages.currentPage().getParameters().get('mt'));
            }else{
                Account acc = new Account(Id=ApexPages.currentPage().getParameters().get('id'));
                acc.Member_Status__c = 'Pending';
                acc.Contract_Sent_Date__c = System.Today();
                update acc;
                pr = new pageReference('/apex/MembershipInPersonContract?action=ip&token='+ApexPages.currentPage().getParameters().get('id')+'&ml='+ApexPages.currentPage().getParameters().get('ml')+'&mt='+ApexPages.currentPage().getParameters().get('mt'));
            }
            pr.setRedirect(true);
            return pr;
        //} 
        //return null;       
    }
    public void IsUserHaveRemovePermission(){
        if(String.IsNotBlank(System.Label.Member_Remove_Permission)) {
            for (String m : System.Label.Member_Remove_Permission.split(',')) {
                if (m.contains(UserInfo.getUserId().substring(0, 15))) {
                    IsUserHaveRemovePermission = true;
                    break;
                } else {
                    IsUserHaveRemovePermission = false;
                }
            }
        }else{
            IsUserHaveRemovePermission = false;
        }
    }
    public static PricebookEntry getPriceByMembershipLevel(String membershipLevel, String productId){
        List<PricebookEntry> objPricebookEntry = [SELECT Id, Name,UnitPrice From PricebookEntry
                                                    WHERE Product2Id =:productId
                                                    AND Pricebook2.Name =:membershipLevel ];
        system.debug('>>>>>>>>>>>>>>>>'+objPricebookEntry);
        if(!objPricebookEntry.IsEmpty()){
            return objPricebookEntry.get(0);
        }
        return null;
    }
}