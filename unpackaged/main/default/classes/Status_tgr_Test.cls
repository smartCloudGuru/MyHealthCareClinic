@isTest
private class Status_tgr_Test
{
   Private static testMethod void docstate()
   {
     boolean isMember = false;
     list<account> objList = new list<account>();
     Test.startTest(); 
          Account acc = new Account();
              acc.FirstName='Test FName';
              acc.LastName='Test LName';
              acc.PersonEmail = 'laxmi@gmail.com';
              acc.Date_of_Birth__c = System.Today();
              acc.Gender__c = 'Male';
              acc.Patient_Type__c = 'Member';
          objList.add(acc);
       insert objList; 
       update objList;  
       isMember = true;
         dsfs__DocuSign_Status__c dcc = new dsfs__DocuSign_Status__c();
              dcc.dsfs__Envelope_Status__c='Sent';
              dcc.dsfs__Company__c=acc.id;       
              acc.Member_Status__c ='sent';
          try{
          insert dcc;
          }catch(exception e){
      }     
          Opportunity opp = new Opportunity();
              opp.Name = 'Surdas';
              opp.CloseDate = system.Today();
              opp.StageName = 'Closed Won';
              opp.AccountId = acc.id;
          insert opp;
          Id pricebookId = Test.getStandardPricebookId();
    
    //Create your product
          Product2 prod = new Product2(
              Name = 'Product X',
              ProductCode = 'Pro-X',
              isActive = true
              );
          insert prod;        
    //Create your pricebook entry
          PricebookEntry pbEntry = new PricebookEntry(
              Pricebook2Id = pricebookId,
              Product2Id = prod.Id,
              UnitPrice = 100.00,
              IsActive = true
              );
          insert pbEntry;
        
        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
         OpportunityLineItem oli = new OpportunityLineItem(
              OpportunityId = opp.Id,
              Quantity = 5,
              PricebookEntryId = pbEntry.Id
              );
          insert oli;       
     Test.stopTest();    
   }
    Private static testMethod void docstatePos()
  {
       boolean isMember = false;
       list<account> objList = new list<account>();
     Test.startTest(); 
         Account acc = new Account();
           acc.FirstName='Test FName';
           acc.LastName='Test LName';
           acc.PersonEmail = 'laxmi@gmail.com';
           acc.Date_of_Birth__c = System.Today();
           acc.Gender__c = 'Male';
           acc.Patient_Type__c = 'Member';
         objList.add(acc);
         insert objList; 
         update objList;  
         isMember = true;
        dsfs__DocuSign_Status__c dcc = new dsfs__DocuSign_Status__c();
           dcc.dsfs__Envelope_Status__c='Sent';
           dcc.dsfs__Company__c=acc.id;
           dcc.dsfs__Envelope_Status__c = 'Completed';   
           acc.Member_Status__c ='sent';
       try{
       insert dcc;
       }catch(exception e){
      }      
        Opportunity opp = new Opportunity();
           opp.Name = 'Surdas';
           opp.CloseDate = system.Today();
           opp.StageName = 'Closed Won';
           opp.AccountId = acc.id;
      insert opp; 
        Id pricebookId = Test.getStandardPricebookId();
    
    //Create your product
        Product2 prod = new Product2(
           Name = 'Product X',
           ProductCode = 'Pro-X',
           isActive = true
           );
      insert prod;
        
    //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(
           Pricebook2Id = pricebookId,
           Product2Id = prod.Id,
           UnitPrice = 100.00,
           IsActive = true
           );
      insert pbEntry;        
    //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli = new OpportunityLineItem(
           OpportunityId = opp.Id,
           Quantity = 5,
           PricebookEntryId = pbEntry.Id
           );
      insert oli;       
   Test.stopTest();
    
 }
}