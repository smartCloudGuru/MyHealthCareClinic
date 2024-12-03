@IsTest
private class MembershipContract_ctrl_Test{

    @IsTest
    static void membercontract(){
       Test.startTest();     
       
       Account objacc = new Account();
      
         objacc.Patient_Type__c = 'Member';
         objacc.FirstName = 'Member'; 
         objacc.LastName = 'Member'; 
         objacc.List_Of_Members_Covered_By_The_Contract__c = 'Member';
         objacc.Membership_Start_Date__c  = system.Today();
         objacc.Membership_Change_Dates__c = system.Today(); 
         objacc.Home_Clinic__c = 'Home';
         objacc.Membership_Level__c = 'Child';
         objacc.Membership_Type__c = '2019 MHC GP' ;
         objacc.Quantity__c = '1';
         objacc.Payment_Frequency__c = 'Monthly';
         //objacc.Billing_Address__c = 'Member';
         //objacc.ContactId__c = cont.id; 
         objacc.Contract_Sent_Date__c = system.Today();
         //objacc.Total_Monthly_Membership_Fee__c = 1000;
         objacc.Membership_Change_Dates__c = system.Today();
         objacc.LastName = 'fulham'; 
         objacc.Date_of_Birth__c = system.Today();
         objacc.Gender__c = 'Male' ;
         objacc.Patient_Type__c = 'Member';
         objacc.Signature_Date__c = system.Today();
         objacc.Signature__c = 'Male' ;
         insert objacc ;  
         
            
         
         /* Contact cont = new Contact();
        cont.Email ='huria.99.anuj@gmail.com';
        cont.lastName ='Test Contact';
        cont.firstName ='Test';
        cont.accountid =objacc.id;
        insert cont; */

         
          ApexPages.currentPage().getParameters().put('token', objacc.id);
          MembershipContract_ctrl memC = new MembershipContract_ctrl();
        
        
        ContentVersion ContentVer = new ContentVersion();
        ContentVer.Title = 'My Doc';
        ContentVer.ContentUrl= 'test.com';
        Insert ContentVer;
        // Create a ContentDocumentLink
        ContentDocumentLink ContentDL = new ContentDocumentLink();
        ContentDL.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: ContentVer.Id].ContentDocumentId;
        ContentDL.LinkedEntityId = objacc.id;
        ContentDL.ShareType='I';
        Insert ContentDL;
        // Retrieve ?
        ContentDL = [SELECT Id,ShareType FROM ContentDocumentLink WHERE Id =:ContentDL.Id];
        System.debug('Troll ' + ContentDL.ShareType);
        // Verify the share type is = i
        System.assertEquals('I',ContentDL.ShareType);PageReference pageRef = Page.MembershipContractPreview;
         pageRef.getParameters().put('token',objacc.id);
         ApexPages.StandardController sc = new ApexPages.StandardController(objacc);
         
         memC.init();
         memC.onUpdate();
         memC.sendAndUploadContract(); 
         map<INteger,String> M_YMap = MembershipContract_ctrl.getMonthByNumber; 
         memC.onSend();
         memC.updateStatusToPending();
         memC.sendMailMethod();
         try{
         String obj = objacc.id;
         String text = obj.substring(0,15);
         List<Document> objDocs = [SELECT Id FROM Document WHERE Name=:text OR Name=:obj];
         memC.createSignatureInDoc('objacc.Signature_Date__c','text');
         }catch(Exception e){} 
        Test.stopTest();
   }

    @IsTest
    static void test_http_req()
    {
        MembershipContract_ctrl.getHTTPRequest('','','POST');
    }

   
 }