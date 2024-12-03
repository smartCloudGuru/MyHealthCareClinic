@isTest
private class WeeklyEnquiryReport_ctrl_Test{
    
    private static testMethod void myunitTest (){
        test.startTest();
        Lead objLead = new Lead();
        objLead.LastName = 'test';
        objLead.LeadSource = 'Local';
        objLead.Status = 'New';
        objLead.Business_Unit__c = 'Implants';
        objLead.Mode__c = 'Form';
        objLead.Site__c = 'Wandsworth';
        insert objLead; 
        ApexPages.currentPage().getParameters().put('dtoken', 'MjAxOC0wOC0wNCAwMDowMDowMA==');
        ApexPages.currentPage().getParameters().put('stoken','V2FuZHN3b3J0aA==');       
        WeeklyEnquiryReport_ctrl objCWR = new WeeklyEnquiryReport_ctrl(); 
        //date.valueof(EncodingUtil.base64Decode(ApexPages.currentPage().getParameters().get('dtoken')).toString())
        //objCWR.outputdate = System.Today().addDays(-2);
        //objCWR.siteName = 'Wandsworth';
        AggregateResult[] groupedRes = [select  count(Id) cnt,Business_Unit__c, DAY_ONLY(createdDate) cd from lead where id =:objLead.id and Business_Unit__c != null group by Business_Unit__c, DAY_ONLY(createdDate)];
        system.assertEquals(1,groupedRes.size());
        objCWR.searchEnquire(); 
        test.stopTest();
    }
     private static testMethod void myunitTestNegative (){
        test.startTest(); 
        Lead objLead = new Lead();
        objLead.LastName = 'test';
        objLead.LeadSource = 'Local';
        objLead.Status = 'New';
        objLead.Business_Unit__c = 'Implants';
        objLead.Mode__c = 'Form';
        objLead.Site__c = 'Wandsworth';
        insert objLead; 
        
        Account objAcct = new Account();
        objAcct.LastName = 'test';
        objAcct.PersonEmail = 'nizam.sfdc@gmail.com';
        objAcct.BU_of_First_Opportunity__c = 'Implants';
        objAcct.Patient_Type__c = 'Member';
        objAcct.Home_Clinic__c = 'Wandsworth';
        insert objAcct;
         
        Opportunity objOppt = new Opportunity();
        objOppt.Name = 'test opp';
        objOppt.AccountId = objAcct.id;
        objOppt.CloseDate = system.today();
        objOppt.StageName = 'Qualification';
        objOppt.Business_Unit__c = 'Implants';
        objOppt.Site__c = 'Wandsworth';        
        insert objOppt;  
        ApexPages.currentPage().getParameters().put('dtoken', 'MjAxOC0wOC0wNCAwMDowMDowMA==');
        ApexPages.currentPage().getParameters().put('stoken','V2FuZHN3b3J0aA==');
        WeeklyEnquiryReport_ctrl objCWR = new WeeklyEnquiryReport_ctrl ();
        objCWR.outputdate = System.Today().addDays(-2);
        objCWR.siteName = 'Wandsworth'; 
        AggregateResult[] groupedRes = [select  count(Id) cnt,Business_Unit__c, DAY_ONLY(createdDate) cd from lead where id =:objLead.id and Business_Unit__c != null group by Business_Unit__c, DAY_ONLY(createdDate)]; 
        system.assertEquals(1,groupedRes.size());
        objCWR.searchEnquire(); 
        test.stopTest();
    }
    private static testMethod void NewPatientSeen(){
         
        Account objAcct = new Account();
        objAcct.LastName = 'test';
        objAcct.PersonEmail = 'nizam.sfdc@gmail.com';
        objAcct.BU_of_First_Opportunity__c = 'Implants';
        objAcct.Patient_Type__c = 'New';
        objAcct.Home_Clinic__c = 'Wandsworth'; 
        insert objAcct;  
        
        Opportunity objOppt = new Opportunity();
        objOppt.Name = 'test opp';
        objOppt.AccountId = objAcct.id;
        objOppt.CloseDate = system.today();
        objOppt.StageName = 'Qualification';
        objOppt.Business_Unit__c = 'Implants';
        objOppt.Site__c = 'Wandsworth';         
        insert objOppt;
        
        Opportunity objOppt2 = new Opportunity();
        objOppt2.Name = 'test opp';
        objOppt2.AccountId = objAcct.id;
        objOppt2.CloseDate = system.today();
        objOppt2.StageName = 'Closed Won';
        objOppt2.Business_Unit__c = 'Ortho';        
        objOppt2.Membership_Level__c = 'Child';
        objOppt2.Site__c = 'Wandsworth';
        insert objOppt2;
        
        Opportunity objGP_EnqTo1st_Appt = new Opportunity();
        objGP_EnqTo1st_Appt.Name = 'test opp';
        objGP_EnqTo1st_Appt.AccountId = objAcct.id;
        objGP_EnqTo1st_Appt.CloseDate = system.today();
        objGP_EnqTo1st_Appt.StageName = 'Closed Lost';
        objGP_EnqTo1st_Appt.Business_Unit__c = 'GP & Nurse';         
        objGP_EnqTo1st_Appt.Membership_Level__c = 'Child';
        objGP_EnqTo1st_Appt.Reason_for_non_conversion__c = 'Could not contact';
        objGP_EnqTo1st_Appt.Site__c = 'Wandsworth';
        insert objGP_EnqTo1st_Appt;
        
        Opportunity objDentist_EnqTo1st_Appt = new Opportunity();
        objDentist_EnqTo1st_Appt.Name = 'test opp';
        objDentist_EnqTo1st_Appt.AccountId = objAcct.id;
        objDentist_EnqTo1st_Appt.CloseDate = system.today();
        objDentist_EnqTo1st_Appt.StageName = 'Closed Lost';
        objDentist_EnqTo1st_Appt.Business_Unit__c = 'Dentist & Hygiene';        
        objDentist_EnqTo1st_Appt.Membership_Level__c = 'Child';
        objDentist_EnqTo1st_Appt.Reason_for_non_conversion__c = 'Could not contact';
        objDentist_EnqTo1st_Appt.Site__c = 'Wandsworth';
        insert objDentist_EnqTo1st_Appt;
        
        Opportunity objImplant_EnqTo1st_Appt = new Opportunity();
        objImplant_EnqTo1st_Appt.Name = 'test opp';
        objImplant_EnqTo1st_Appt.AccountId = objAcct.id;
        objImplant_EnqTo1st_Appt.CloseDate = system.today();
        objImplant_EnqTo1st_Appt.StageName = 'Closed Lost';
        objImplant_EnqTo1st_Appt.Business_Unit__c = 'Implants';         
        objImplant_EnqTo1st_Appt.Membership_Level__c = 'Child';
        objImplant_EnqTo1st_Appt.Reason_for_non_conversion__c = 'Could not contact';
        objImplant_EnqTo1st_Appt.Site__c = 'Wandsworth';
        insert objImplant_EnqTo1st_Appt;
        
        Opportunity objOrtho_EnqTo1st_Appt = new Opportunity();
        objOrtho_EnqTo1st_Appt.Name = 'test opp';
        objOrtho_EnqTo1st_Appt.AccountId = objAcct.id;
        objOrtho_EnqTo1st_Appt.CloseDate = system.today();
        objOrtho_EnqTo1st_Appt.StageName = 'Closed Lost';
        objOrtho_EnqTo1st_Appt.Business_Unit__c = 'Ortho';         
        objOrtho_EnqTo1st_Appt.Membership_Level__c = 'Child';
        objOrtho_EnqTo1st_Appt.Reason_for_non_conversion__c = 'Could not contact';
        objOrtho_EnqTo1st_Appt.Site__c = 'Wandsworth';
        insert objOrtho_EnqTo1st_Appt; 
         
        Opportunity objPathology_EnqTo1st_Appt = new Opportunity();
        objPathology_EnqTo1st_Appt.Name = 'test opp';
        objPathology_EnqTo1st_Appt.AccountId = objAcct.id;
        objPathology_EnqTo1st_Appt.CloseDate = system.today();
        objPathology_EnqTo1st_Appt.StageName = 'Closed Lost';
        objPathology_EnqTo1st_Appt.Business_Unit__c = 'Pathology & Vaccines';         
        objPathology_EnqTo1st_Appt.Membership_Level__c = 'Child';
        objPathology_EnqTo1st_Appt.Reason_for_non_conversion__c = 'Could not contact';
        objPathology_EnqTo1st_Appt.Site__c = 'Wandsworth';
        insert objPathology_EnqTo1st_Appt;
         
        Opportunity objFertility_EnqTo1st_Appt = new Opportunity();
        objFertility_EnqTo1st_Appt.Name = 'test opp';
        objFertility_EnqTo1st_Appt.AccountId = objAcct.id;
        objFertility_EnqTo1st_Appt.CloseDate = system.today();
        objFertility_EnqTo1st_Appt.StageName = 'Closed Lost';
        objFertility_EnqTo1st_Appt.Business_Unit__c = 'Fertility';         
        objFertility_EnqTo1st_Appt.Membership_Level__c = 'Child';
        objFertility_EnqTo1st_Appt.Reason_for_non_conversion__c = 'Could not contact';
        objFertility_EnqTo1st_Appt.Site__c = 'Wandsworth';
        insert objFertility_EnqTo1st_Appt;

        Opportunity objMedical_EnqTo1st_Appt = new Opportunity();
        objMedical_EnqTo1st_Appt.Name = 'test opp';
        objMedical_EnqTo1st_Appt.AccountId = objAcct.id;
        objMedical_EnqTo1st_Appt.CloseDate = system.today();
        objMedical_EnqTo1st_Appt.StageName = 'Closed Lost';
        objMedical_EnqTo1st_Appt.Business_Unit__c = 'Medical consultants';         
        objMedical_EnqTo1st_Appt.Membership_Level__c = 'Child';
        objMedical_EnqTo1st_Appt.Reason_for_non_conversion__c = 'Could not contact';
        objMedical_EnqTo1st_Appt.Site__c = 'Wandsworth';
        insert objMedical_EnqTo1st_Appt;
        
        Opportunity objTherapists_EnqTo1st_Appt = new Opportunity();
        objTherapists_EnqTo1st_Appt.Name = 'test opp';
        objTherapists_EnqTo1st_Appt.AccountId = objAcct.id;
        objTherapists_EnqTo1st_Appt.CloseDate = system.today();
        objTherapists_EnqTo1st_Appt.StageName = 'Closed Lost';
        objTherapists_EnqTo1st_Appt.Business_Unit__c = 'Therapists';         
        objTherapists_EnqTo1st_Appt.Membership_Level__c = 'Child';
        objTherapists_EnqTo1st_Appt.Reason_for_non_conversion__c = 'Could not contact';
        objTherapists_EnqTo1st_Appt.Site__c = 'Wandsworth';
        insert objTherapists_EnqTo1st_Appt;
        
        Opportunity objPhysio_EnqTo1st_Appt = new Opportunity();
        objPhysio_EnqTo1st_Appt.Name = 'test opp';
        objPhysio_EnqTo1st_Appt.AccountId = objAcct.id;
        objPhysio_EnqTo1st_Appt.CloseDate = system.today();
        objPhysio_EnqTo1st_Appt.StageName = 'Closed Lost';
        objPhysio_EnqTo1st_Appt.Business_Unit__c = 'Physio & Podiatry';         
        objPhysio_EnqTo1st_Appt.Membership_Level__c = 'Child';
        objPhysio_EnqTo1st_Appt.Reason_for_non_conversion__c = 'Could not contact';
        objPhysio_EnqTo1st_Appt.Site__c = 'Wandsworth';
        insert objPhysio_EnqTo1st_Appt;
        
        Opportunity objMother_EnqTo1st_Appt = new Opportunity();
        objMother_EnqTo1st_Appt.Name = 'test opp';
        objMother_EnqTo1st_Appt.AccountId = objAcct.id;
        objMother_EnqTo1st_Appt.CloseDate = system.today();
        objMother_EnqTo1st_Appt.StageName = 'Closed Lost';
        objMother_EnqTo1st_Appt.Business_Unit__c = 'Mother & Baby';         
        objMother_EnqTo1st_Appt.Membership_Level__c = 'Child';
        objMother_EnqTo1st_Appt.Reason_for_non_conversion__c = 'Could not contact';
        objMother_EnqTo1st_Appt.Site__c = 'Wandsworth';
        insert objMother_EnqTo1st_Appt;
        
        Opportunity objSkin_EnqTo1st_Appt = new Opportunity();
        objSkin_EnqTo1st_Appt.Name = 'test opp';
        objSkin_EnqTo1st_Appt.AccountId = objAcct.id;
        objSkin_EnqTo1st_Appt.CloseDate = system.today();
        objSkin_EnqTo1st_Appt.StageName = 'Closed Lost';
        objSkin_EnqTo1st_Appt.Business_Unit__c = 'Skin';         
        objSkin_EnqTo1st_Appt.Membership_Level__c = 'Child';
        objSkin_EnqTo1st_Appt.Reason_for_non_conversion__c = 'Could not contact';
        objSkin_EnqTo1st_Appt.Site__c = 'Wandsworth';
        insert objSkin_EnqTo1st_Appt;
        
        Opportunity objDiagnostics_EnqTo1st_Appt = new Opportunity();
        objDiagnostics_EnqTo1st_Appt.Name = 'test opp';
        objDiagnostics_EnqTo1st_Appt.AccountId = objAcct.id;
        objDiagnostics_EnqTo1st_Appt.CloseDate = system.today();
        objDiagnostics_EnqTo1st_Appt.StageName = 'Closed Lost';
        objDiagnostics_EnqTo1st_Appt.Business_Unit__c = 'Diagnostics & OP Procedures';         
        objDiagnostics_EnqTo1st_Appt.Membership_Level__c = 'Child';
        objDiagnostics_EnqTo1st_Appt.Reason_for_non_conversion__c = 'Could not contact';
        objDiagnostics_EnqTo1st_Appt.Site__c = 'Wandsworth';
        insert objDiagnostics_EnqTo1st_Appt;
        
        Opportunity objOccupational_EnqTo1st_Appt = new Opportunity();
        objOccupational_EnqTo1st_Appt.Name = 'test opp';
        objOccupational_EnqTo1st_Appt.AccountId = objAcct.id;
        objOccupational_EnqTo1st_Appt.CloseDate = system.today();
        objOccupational_EnqTo1st_Appt.StageName = 'Closed Lost';
        objOccupational_EnqTo1st_Appt.Business_Unit__c = 'Occupational Health';        
        objOccupational_EnqTo1st_Appt.Membership_Level__c = 'Child';
        objOccupational_EnqTo1st_Appt.Reason_for_non_conversion__c = 'Could not contact';
        insert objOccupational_EnqTo1st_Appt; 
        
        Opportunity objMembership_EnqTo1st_Appt = new Opportunity();
        objMembership_EnqTo1st_Appt.Name = 'test opp';
        objMembership_EnqTo1st_Appt.AccountId = objAcct.id;
        objMembership_EnqTo1st_Appt.CloseDate = system.today();
        objMembership_EnqTo1st_Appt.StageName = 'Closed Lost';
        objMembership_EnqTo1st_Appt.Business_Unit__c = 'Membership';        
        objMembership_EnqTo1st_Appt.Membership_Level__c = 'Child';
        objMembership_EnqTo1st_Appt.Reason_for_non_conversion__c = 'Could not contact';
        objMembership_EnqTo1st_Appt.Site__c = 'Wandsworth';
        insert objMembership_EnqTo1st_Appt;
        
        dsfs__DocuSign_Status__c objDSS = new dsfs__DocuSign_Status__c();
        objDSS.dsfs__Opportunity__c = objOppt2.id;
        objDSS.dsfs__Envelope_Status__c = 'completed';
        objDSS.dsfs__Company__c = objAcct.id;
        objDSS.Site__c = 'Wandsworth';
        insert objDSS;
        
        test.startTest();
        ApexPages.currentPage().getParameters().put('dtoken', 'MjAxOC0wOC0wNCAwMDowMDowMA==');
        ApexPages.currentPage().getParameters().put('stoken','V2FuZHN3b3J0aA==');
        WeeklyEnquiryReport_ctrl objCWR = new WeeklyEnquiryReport_ctrl();
        objCWR.outputdate = System.Today().addDays(-2); 
        objCWR.siteName = 'Wandsworth';
        objCWR.searchEnquire(); 
        MainWrapper objMW = new MainWrapper();
        MainWrapper.WrapperForTotal objTotal = new MainWrapper.WrapperForTotal();
        objMW.objWFT = objTotal ;
        objCWR.objWFTForApp = objTotal;
        MainWrapper.WrapperForHeader objWFH = new MainWrapper.WrapperForHeader();
        objWFH.headerItem = 'header';
        objWFH.headerTotal = 'header Total'; 
        test.stopTest();
    }
    Public static testMethod void sitePicklist(){
        test.startTest();
        ApexPages.currentPage().getParameters().put('dtoken', 'MjAxOC0wOC0wNCAwMDowMDowMA==');
        ApexPages.currentPage().getParameters().put('stoken','V2FuZHN3b3J0aA==');
        WeeklyEnquiryReport_ctrl objPIC = new WeeklyEnquiryReport_ctrl ();
        objPIC.siteName = 'Wandsworth';
        objPIC.getBusinessUnit();
        test.stopTest();
   }
}