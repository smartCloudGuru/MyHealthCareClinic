@isTest
private class AddMember_ctrl_Test{
    private static testMethod void testApc(){
        Test.StartTest();
        Account acc = new Account( 
        FirstName='Test FName',
        LastName='Test LName',
        Membership_Level__c='Adult - Main Payer',
        Patient_Type__c='Member',
        Membership_Type__c='2019 MHC GP',
        Payment_Frequency__c='Monthly',
        PersonMailingStreet='mark@yahoo.com',
        PersonMailingPostalCode='12345',
        PersonMailingCity='SFO',
        PersonEmail='test@yahoo.com',
        PersonHomePhone='753601522',
        Home_Clinic__c = 'Fulham',
        Membership_Add_On__c = 'Advanced Healthscreen',
        Relation_With_Payer__c = 'Wife',
        PersonMobilePhone='3652999'); 
        insert acc; 
         
        ApexPages.currentPage().getParameters().put('ml','Family'); 
        ApexPages.currentPage().getParameters().put('mt','2019 MHC GP');
        ApexPages.currentPage().getParameters().put('id',acc.id);
        ApexPages.currentPage().getParameters().put('action','sc'); 
        Account act = new Account( 
        FirstName='Tonny',
        LastName='Ali',
        Membership_Level__c='Adult - Main Payer',
        Patient_Type__c='Member',
        Membership_Type__c='2019 MHC GP',
        Payment_Frequency__c='Monthly',
        PersonMailingStreet='Tonny@yahoo.com',
        PersonMailingPostalCode='244221',
        PersonMailingCity='SFO',
        PersonEmail='Ali@yahoo.com',
        PersonHomePhone='987456666',
        PersonMobilePhone='631797',
        Membership_Add_On__c = 'Advanced Healthscreen',
        Home_Clinic__c = 'Fulham',
        Relation_With_Payer__c = 'Wife',
        Member_Group__c = acc.id);  
        insert act;
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(act);
        AddMember_ctrl objAdd;
        objAdd = new AddMember_ctrl (stdController);
        //AddMember_ctrl objAdd = new AddMember_ctrl();
        objAdd.patIndex = 1;
        List<Account> acco = [SELECT Total_Monthly_Membership_Fee__c,Relation_With_Payer__c,Membership_Add_On__c ,Home_Clinic__c ,Member_Status__c,Id,Name,Membership_Level__c,Membership_Type__c,Member_Group__c, 
                              Date_of_Birth__c,FirstName,lastName,PersonMobilePhone,PersonEmail,Patient_Type__c,(select id,Total_Monthly_Membership_Fee__c from Member_Group__r) 
                              From Account];
        objAdd.selectedPatients = acco;
        
        objAdd.queryFilter();
        AddMember_ctrl.getMemberDetails(acc,'acc.id');
        AddMember_ctrl.addAnotherMembership(acc.id,'2019 MHC GP');
        AddMember_ctrl.rerenderTbl(acc.id,act.id,True);
        objAdd.addAccount('Family'); 
        objAdd.addMore();  
        objAdd.quickRemove();
        objAdd.updateMembership();
        //objAdd.isValidateMembersContract();
        objAdd.next();
        objAdd.onSave();
        objAdd.removePatient();
        Test.StopTest(); 
        }
    private static testMethod void testApc1(){
        Test.StartTest();
        Account acc = new Account( 
        FirstName='Vihaan',
        LastName='Singh',
        Membership_Level__c='Adult - Main Payer',
        Patient_Type__c='Member',
        Membership_Type__c='2019 MHC GP',
        Payment_Frequency__c='Monthly',
        PersonMailingStreet='Vihaan@yahoo.com',
        PersonMailingPostalCode='36255',
        PersonMailingCity='SFO',
        Home_Clinic__c = 'Fulham',
        PersonEmail='Singh@gmail.com',
        PersonHomePhone='1234567',
        Relation_With_Payer__c = 'Wife',
        Membership_Add_On__c = 'Advanced Healthscreen',
        PersonMobilePhone='9658458547'); 
        insert acc; 
        
        Opportunity objOpp = new Opportunity();
        objOpp.Name = 'Vihaan Singh';  
        objOpp.AccountId = acc.id;
        objOpp.StageName = 'Closed Won';
        objOpp.CloseDate = System.Today(); 
        objOpp.Membership_Level__c = 'Adult - Main Payer';
        objOpp.Payment_Frequency__c = 'Monthly';   
        insert objOpp;
        
        Pricebook2 pricePB = new Pricebook2();
        pricePB.Name = 'Standard Price Book';
        pricePB.IsActive = true; 
        insert pricePB;
        
        Pricebook2 pricePBE = new Pricebook2();
        pricePBE.Name = '2019 MHC GP';
        pricePBE.IsActive = true; 
        insert pricePBE;
        
        Product2 prod = new Product2();
        prod.Name='Adult - Main Payer';
        prod.Family = 'Membership_Plan';
        prod.isActive=true; 
        insert prod;

        PricebookEntry pbe2 = new PricebookEntry();
        pbe2.unitprice=0;
        pbe2.Product2Id = prod.Id;
        pbe2.Pricebook2Id = Test.getStandardPricebookId();
        pbe2.isActive=true;
        //pbe2.UseStandardPrice = false;
        insert pbe2;

        PricebookEntry pbe3 = new PricebookEntry();
        pbe3.unitprice=0;
        pbe3.Product2Id = prod.Id;
        pbe3.Pricebook2Id = pricePBE.id;//Test.getStandardPricebookId();
        pbe3.isActive=true;
        //pbe3.UseStandardPrice = false;
        insert pbe3;

        OpportunityLineItem OPplineitem2 = new OpportunityLineItem();   
        OPplineitem2.OpportunityId=objOpp.Id;
        OPplineitem2.UnitPrice=0.01;
        OPplineitem2.PriceBookEntryId=pbe2.Id;
        OPplineitem2.Member_Price__c= 0;
        OPplineitem2.Quantity = 1;
        insert OPplineitem2;
         
        ApexPages.currentPage().getParameters().put('ml','Joint Adult'); 
        ApexPages.currentPage().getParameters().put('mt','2019 MHC GP');
        ApexPages.currentPage().getParameters().put('id',acc.id);
        ApexPages.currentPage().getParameters().put('action','sc'); 
        Account act = new Account( 
        FirstName='bill',
        LastName='sapoof',
        Membership_Level__c='Adult - Main Payer',
        Patient_Type__c='Member',
        Membership_Type__c='2019 MHC GP',
        Payment_Frequency__c='Monthly',
        PersonMailingStreet='bill@yahoo.com',
        PersonMailingPostalCode='985999',
        PersonMailingCity='SFO',
        PersonEmail='Spoof@gmail.com',
        PersonHomePhone='954885669',
        Home_Clinic__c = 'Fulham',
        PersonMobilePhone='65422998',
        Relation_With_Payer__c = 'Wife',
        Membership_Add_On__c = 'Advanced Healthscreen', 
        Member_Group__c = acc.id);   
        insert act;
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(act);
        AddMember_ctrl objAdd;
        objAdd = new AddMember_ctrl (stdController); 
        //AddMember_ctrl objAdd = new AddMember_ctrl();
        objAdd.patIndex = 1;
        List<Account> acco = [SELECT Total_Monthly_Membership_Fee__c,Home_Clinic__c,Membership_Add_On__c,Relation_With_Payer__c ,Member_Status__c,Id,Name,Membership_Level__c,Membership_Type__c,Member_Group__c, 
                              Date_of_Birth__c,FirstName,lastName,PersonMobilePhone,PersonEmail,Patient_Type__c,(select id,Total_Monthly_Membership_Fee__c from Member_Group__r) 
                              From Account];
        objAdd.selectedPatients = acco;
        
        objAdd.queryFilter();
        AddMember_ctrl.getMemberDetails(acc,'acc.id');
        AddMember_ctrl.addAnotherMembership(acc.id,'2019 MHC GP');
        AddMember_ctrl.rerenderTbl(acc.id,act.id,True);
        objAdd.resetNewPatForm();
        objAdd.addAccount('Family'); 
        objAdd.addMore();  
        objAdd.selectDuplicatePat();
        objAdd.quickRemove();
        objAdd.updateMembership(); 
        //objAdd.isValidateMembersContract();
        objAdd.next(); 
        
        Account aacco = [SELECT Total_Monthly_Membership_Fee__c,Home_Clinic__c,Membership_Add_On__c,Relation_With_Payer__c ,Member_Status__c,Id,Name,Membership_Level__c,Membership_Type__c,Member_Group__c, 
                              Date_of_Birth__c,FirstName,lastName,PersonMobilePhone,PersonEmail,Patient_Type__c,(select id,Total_Monthly_Membership_Fee__c from Member_Group__r) 
                              From Account limit 1];
        objAdd.objAccount = aacco;
        objAdd.onSave();                      
        objAdd.removePatient();
        AddMember_ctrl.getPriceByMembershipLevel('2019 MHC GP',prod.id);
        Test.StopTest();  
    }
  }