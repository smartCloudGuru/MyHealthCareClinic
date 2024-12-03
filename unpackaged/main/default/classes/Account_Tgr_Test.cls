@isTest
private class Account_Tgr_Test{  
    @testSetup 
    public static void setUpMockData(){
       User u = [select name, Id  FROM user Where Profile.Name ='System Administrator' AND isActive=true LIMIT 1];
       RecordType personAccountRecordType =  AccountManager.getPatientRecordType();
       Account acc = new Account(
           RecordTypeID=personAccountRecordType.id,
           FirstName='Test FName',
           LastName='Test LName',   
           PersonMailingStreet='test@yahoo.com',
           PersonMailingPostalCode='12345',
           PersonMailingCity='SFO',
           PersonEmail='test@yahoo.com',
           PersonHomePhone='1234567',
           PersonMobilePhone='12345678',
           Relation_With_Payer__c='Brother',
           Membership_Level__c='Child',
           Patient_Type__c='Member',
           Membership_Type__c='2022Sep MHC Premium',
           Payment_Frequency__c='Monthly',
           Home_Clinic__c='Wandsworth'
           
       ); 
       insert acc; 
       Account acm = new Account(
           RecordTypeID=personAccountRecordType.id,
           Member_Group__c=[SELECT Id FROM Account WHERE FirstName='Test FName'].id,
           FirstName='Noha',
           LastName='Verma',
           Membership_Level__c='Child',
           Patient_Type__c='Member',
           Membership_Type__c='2022Sep MHC Premium',
           Payment_Frequency__c='Monthly',
           PersonMailingStreet='test@yahoo.com',
           PersonMailingPostalCode='201301',
           PersonMailingCity='SFO',
           PersonEmail='noha@gmail.com',
           PersonHomePhone='1234567',
           PersonMobilePhone='12345678',
           Relation_With_Payer__c='Sister',
           Home_Clinic__c='Wandsworth'
        );
        insert acm; 
        
        Opportunity objOpp = new Opportunity();
                            objOpp.Name = 'test1';  
                            objOpp.AccountId = acm.id;
                            objOpp.StageName = 'lost';
                            objOpp.CloseDate = System.Today(); 
                            objOpp.Membership_Level__c = 'Child';
                            objOpp.Payment_Frequency__c = 'Monthly';   
                            insert objOpp; 
                            
        Pricebook2 pricePB = new Pricebook2();
            pricePB.Name = 'Standard Price Book';
            pricePB.IsActive = true; 
            insert pricePB;
            
            Pricebook2 pricePBE = new Pricebook2();
            pricePBE.Name = '2022Sep MHC Premium';
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
    }  
    public static testMethod void testUpdateAcc(){ 
        User u = [select name, Id  FROM user Where Profile.Name ='System Administrator' AND isActive=true LIMIT 1];  
        system.runAs(u){                        
            Account acm = [SELECT Membership_Level__c, Patient_Type__c,Payment_Frequency__c,Membership_Add_On__c,Relation_With_Payer__c,Home_Clinic__c, Id FROM Account WHERE FirstName='Noha' limit 1];         
            acm.Membership_Level__c='Child';
            acm.Patient_Type__c='Member';
            acm.Membership_Add_On__c='Advanced Healthscreen';
            acm.Relation_With_Payer__c='Brother';
            acm.Home_Clinic__c='Wandsworth';
            acm.Payment_Frequency__c='Monthly';
            update acm; 
                      
        }
    }
    public static testMethod void testDeleteAcc(){ 
        User u = [select name, Id  FROM user Where Profile.Name ='System Administrator' AND isActive=true LIMIT 1];  
        system.runAs(u){ 
            delete [SELECT Membership_Level__c, Payment_Frequency__c, Relation_With_Payer__c, Patient_Type__c, Id, Membership_Add_On__c  FROM Account WHERE FirstName='Noha' limit 1];
        }
    }
     
    public static testMethod void testNewAcc(){ 
        User u = [select name, Id  FROM user Where Profile.Name ='System Administrator' AND isActive=true LIMIT 1];  
        System.runAs(u){
            Test.startTest();
            RecordType personAccountRecordType = AccountManager.getPatientRecordType();
            Account acm = new Account(
               RecordTypeID=personAccountRecordType.Id,
               Member_Group__c=[SELECT Id FROM Account WHERE FirstName='Test FName'].id,
               FirstName='Terian',
               LastName='Lannister',
               Membership_Level__c='Child',
               Patient_Type__c='Member',
               Membership_Type__c='2022Sep MHC Premium',
               Payment_Frequency__c='Monthly',
               PersonMailingStreet='Chil@yahoo.com',
               PersonMailingPostalCode='501456',
               PersonMailingCity='SFO',
               PersonEmail='Terian@yahoo.com',
               PersonHomePhone='9412699558',
               PersonMobilePhone='99125887744',
               Membership_Add_On__c='Advanced Healthscreen',
               Relation_With_Payer__c='Daughter',
               Home_Clinic__c='Wandsworth'
           
            );
            insert acm; 
            Opportunity objOpp = new Opportunity();
                            objOpp.Name = 'test1';  
                            objOpp.AccountId = acm.id;
                            objOpp.StageName = 'Closed Won';
                            objOpp.CloseDate = System.Today(); 
                            objOpp.Membership_Level__c = 'Child';
                            objOpp.Payment_Frequency__c = 'Monthly';   
                            insert objOpp;                 
           Test.stopTest();                    
        }
    } 
     
}