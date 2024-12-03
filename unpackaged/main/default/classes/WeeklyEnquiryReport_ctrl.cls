public with sharing class WeeklyEnquiryReport_ctrl { 
    public Date outputdate { get; set; }
    public String siteName {get;set;}
    public String startDate {get;set;}
    public MainWrapper objMWrap {get;set;}
    public MainWrapper objMWrapForApp {get;set;}
    public MainWrapper objMWrapTotal {get;set;}
    public MainWrapper objEnqTotal {get;set;} 
    public MainWrapper objMWEnqToAppt {get;set;} 
    public MainWrapper objAllAppnts {get;set;}
    public MainWrapper objNewPatents {get;set;}
    public MainWrapper objImp_Ortho {get;set;}
    public MainWrapper objNewMemberSigned {get;set;} 
    public MainWrapper salesInvoiced {get;set;} 
    public MainWrapper GP_EnqTo1st_Appt {get;set;} 
    public MainWrapper Dentist_EnqTo1st_Appt {get;set;} 
    public MainWrapper Implant_EnqTo1st_Appt {get;set;} 
    public MainWrapper Ortho_EnqTo1st_Appt {get;set;}
    public MainWrapper Pathology_EnqTo1st_Appt {get;set;}
    public MainWrapper Fertility_EnqTo1st_Appt {get;set;} 
    public MainWrapper Medical_EnqTo1st_Appt {get;set;}
    public MainWrapper Therapists_EnqTo1st_Appt {get;set;}
    public MainWrapper Physio_EnqTo1st_Appt {get;set;} 
    public MainWrapper Mother_EnqTo1st_Appt {get;set;} 
    public MainWrapper Skin_EnqTo1st_Appt {get;set;}
    public MainWrapper Diagnostics_EnqTo1st_Appt {get;set;} 
    public MainWrapper Occupational_EnqTo1st_Appt {get;set;}
    public MainWrapper Membership_EnqTo1st_Appt {get;set;} 
    public MainWrapper totalNonConvReason {get;set;}
    public MainWrapper objCoreResults {get;set;} 
    public MainWrapper.WrapperForTotal objWFTForApp {get;set;}  
    MainWrapper.WrapperForHeader objCR; 
    
    public WeeklyEnquiryReport_ctrl(){ 
        outputdate =  date.valueof(EncodingUtil.base64Decode(ApexPages.currentPage().getParameters().get('dtoken')).toString()); 
        siteName = string.valueof(EncodingUtil.base64Decode(ApexPages.currentPage().getParameters().get('stoken')).toString()); 
        objMWrap = new MainWrapper();
        objMWrapForApp = new MainWrapper();  
        objMWrapTotal  = new MainWrapper();
        objEnqTotal =  new MainWrapper();
        objAllAppnts = new MainWrapper();
        objNewPatents = new MainWrapper();
        objImp_Ortho = new MainWrapper();
        objNewMemberSigned = new MainWrapper();
        salesInvoiced = new MainWrapper();
        GP_EnqTo1st_Appt = new MainWrapper(); 
        Dentist_EnqTo1st_Appt = new MainWrapper();  
        Implant_EnqTo1st_Appt = new MainWrapper();
        Ortho_EnqTo1st_Appt = new MainWrapper();  
        Pathology_EnqTo1st_Appt = new MainWrapper(); 
        Fertility_EnqTo1st_Appt = new MainWrapper();
        Medical_EnqTo1st_Appt = new MainWrapper();
        Therapists_EnqTo1st_Appt = new MainWrapper();
        Physio_EnqTo1st_Appt = new MainWrapper();
        Mother_EnqTo1st_Appt = new MainWrapper();
        Skin_EnqTo1st_Appt = new MainWrapper();
        Diagnostics_EnqTo1st_Appt = new MainWrapper();  
        Occupational_EnqTo1st_Appt = new MainWrapper();
        Membership_EnqTo1st_Appt = new MainWrapper();
        totalNonConvReason = new MainWrapper();
        objCoreResults = new MainWrapper();  
        searchEnquire();  
    }
    public void headerValue(){  
        objCR = new MainWrapper.WrapperForHeader(); 
        objCR.HeaderDay1  = string.valueOf(ConvertDateFormat(outputdate)) ;   
        objCR.HeaderDay2 = ConvertDateFormat(outputdate.addDays(1));
        objCR.HeaderDay3 = ConvertDateFormat(outputdate.addDays(2));
        objCR.HeaderDay4 = ConvertDateFormat(outputdate.addDays(3));
        objCR.HeaderDay5 = ConvertDateFormat(outputdate.addDays(4));
        objCR.HeaderDay6 = ConvertDateFormat(outputdate.addDays(5));
        objCR.HeaderDay7 = ConvertDateFormat(outputdate.addDays(6));  
        objMWrap.objWPH = objCR;
    }
    public  string ConvertDateFormat(Date objDate){
        return DateTime.newInstance(objDate.year(),objDate.month(),objDate.day()).format('d-MMM-YY');
    }
    public void searchEnquire(){ 
        headerValue(); 
        map<string,MainWrapper.WrapperForDetail> objWFDs = new map<string,MainWrapper.WrapperForDetail>();  
        AggregateResult[] groupedResults = [select  count(Id) cnt,Business_Unit__c, DAY_ONLY(createdDate) cd, calendar_month(createdDate) ,calendar_year(createdDate)  
                                            from lead where CreatedDate >:outputdate and CreatedDate <: outputdate.addDays(7) and Business_Unit__c != null  AND site__c=:siteName AND site__c != null group by Business_Unit__c, 
                                            calendar_month(createdDate) ,calendar_year(createdDate) ,DAY_ONLY(createdDate)]; 
        For(selectOption so : getBusinessUnit()){
            MainWrapper.WrapperForDetail objWFD = new MainWrapper.WrapperForDetail();
            if(groupedResults.size() == 0){
                objWFD.detailItem = so.getLabel();             
                objWFDs.put(so.getLabel(),objWFD); 
            }else{
                For(AggregateResult objAR : groupedResults){ 
                    if(so.getLabel() == ''+objAR.get('Business_Unit__c') &&  objCR.HeaderDay1 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){ 
                        objWFD.detailDay1 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay2 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFD.detailDay2 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay3 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFD.detailDay3 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay4 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFD.detailDay4 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay5 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFD.detailDay5 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay6 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFD.detailDay6 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay7 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFD.detailDay7 = ''+objAR.get('cnt'); 
                    }   
                    objWFD.detailItem = so.getLabel();             
                    objWFDs.put(so.getLabel(),objWFD); 
                } 
            }
        }
        objMWrap.objlstWFDs = objWFDs.values(); 
        firstAppointmentBooked();
        conversionOfEnqToAppt(); 
        allAppointmentSeen();
        newPatientsSeen();
        implantsAndOrthoSale();
        newMemberSigned();
        salesInvoiced();
        NonConversionReason_GP_EnqTo1st_Appt();
        NonConversionReason_Dentist_EnqTo1st_Appt();
        NonConversionReason_Implant_EnqTo1st_Appt();
        NonConversionReason_Ortho_EnqTo1st_Appt();
        NonConversionReason_Pathology_EnqTo1st_Appt();
        NonConversionReason_Fertility_EnqTo1st_Appt();
        NonConversionReason_Medical_EnqTo1st_Appt();
        NonConversionReason_Therapists_EnqTo1st_Appt(); 
        NonConversionReason_Physio_EnqTo1st_Appt();
        NonConversionReason_Mother_EnqTo1st_Appt();
        NonConversionReason_Skin_EnqTo1st_Appt();
        NonConversionReason_Diagnostics_EnqTo1st_Appt();
        NonConversionReason_Occupational_EnqTo1st_Appt();
        NonConversionReason_Membership_EnqTo1st_Appt();
        TotalNonConversionReason();
        CoreResults(); 
    }
    public void firstAppointmentBooked(){  
        map<string,MainWrapper.WrapperForDetail> objWFDs = new map<string,MainWrapper.WrapperForDetail>();  
        AggregateResult[] groupedResults = [select  count(Id) cnt,BU_of_First_Opportunity__c, DAY_ONLY(createdDate) cd, calendar_month(createdDate) ,calendar_year(createdDate)  
                                            from Account where CreatedDate >:outputdate and CreatedDate <: outputdate.addDays(7) and BU_of_First_Opportunity__c != null AND Home_Clinic__c =:siteName AND Home_Clinic__c != null group by BU_of_First_Opportunity__c, 
                                            calendar_month(createdDate) ,calendar_year(createdDate) ,DAY_ONLY(createdDate)]; 
        For(selectOption so : getBusinessUnit()){ 
            MainWrapper.WrapperForDetail objWFDApp = new MainWrapper.WrapperForDetail();
            if(groupedResults.size() == 0){
                objWFDApp.detailItem = so.getLabel();             
                objWFDs.put(so.getLabel(),objWFDApp); 
            }else{
                For(AggregateResult objAR : groupedResults){  
                    if(so.getLabel() == ''+objAR.get('BU_of_First_Opportunity__c') && objCR.HeaderDay1 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){ 
                        objWFDApp.detailDay1 = ''+objAR.get('cnt');                     
                    }
                    if(so.getLabel() == ''+objAR.get('BU_of_First_Opportunity__c') && objCR.HeaderDay2 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay2 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('BU_of_First_Opportunity__c') && objCR.HeaderDay3 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay3 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('BU_of_First_Opportunity__c') && objCR.HeaderDay4 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay4 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('BU_of_First_Opportunity__c') && objCR.HeaderDay5 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay5 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('BU_of_First_Opportunity__c') && objCR.HeaderDay6 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay6 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('BU_of_First_Opportunity__c') && objCR.HeaderDay7 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay7 = ''+objAR.get('cnt'); 
                    }   
                    objWFDApp.detailItem = so.getLabel();             
                    objWFDs.put(so.getLabel(),objWFDApp); 
                } 
            }
        }
        objMWrapForApp.objlstWFDs = objWFDs.values(); 
    }
    public void conversionOfEnqToAppt(){  
        objMWEnqToAppt = new  MainWrapper(); 
        list<MainWrapper.WrapperForDetail> objWFDs = new list<MainWrapper.WrapperForDetail>(); 
        For(selectOption so : getBusinessUnit()){ 
            MainWrapper.WrapperForDetail objPrcnt = new MainWrapper.WrapperForDetail(); 
            objPrcnt.detailItem = so.getLabel();             
            objWFDs.add(objPrcnt);  
        }
        objMWEnqToAppt.objlstWFDs = objWFDs;
        
    }
    public void allAppointmentSeen(){  
        map<string,MainWrapper.WrapperForDetail> allAppnt = new map<string,MainWrapper.WrapperForDetail>(); 
        AggregateResult[] groupedResults = [select count(id) cnt,  Business_Unit__c,DAY_ONLY(createdDate) cd, calendar_month(createdDate) ,calendar_year(createdDate),
                                                   Account.Patient_Type__c from Opportunity where CreatedDate >:outputdate and CreatedDate <:outputdate.addDays(7) and 
                                                   Business_Unit__c != null and Account.Patient_Type__c = 'Member' AND site__c=:siteName AND site__c != null group by Business_Unit__c,calendar_month(createdDate),
                                                   calendar_year(createdDate) ,DAY_ONLY(createdDate),Account.Patient_Type__c];
        For(selectOption so : getBusinessUnit()){  
            MainWrapper.WrapperForDetail objWFDApp = new MainWrapper.WrapperForDetail(); 
            if(groupedResults.size() == 0){
                objWFDApp.detailItem = so.getLabel();           
                allAppnt.put(so.getLabel(),objWFDApp);
            }else{
                For(AggregateResult objAR : groupedResults){  
                    if(so.getLabel() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay1 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){ 
                        objWFDApp.detailDay1 = ''+objAR.get('cnt');                      
                    }
                    if(so.getLabel() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay2 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay2 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay3 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay3 = ''+objAR.get('cnt');    
                    }            
                    if(so.getLabel() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay4 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay4 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay5 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay5 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay6 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay6 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay7 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay7 = ''+objAR.get('cnt'); 
                    }  
                    objWFDApp.detailItem = so.getLabel();          
                    allAppnt.put(so.getLabel(),objWFDApp); 
                } 
            }            
        } 
        objAllAppnts.objlstWFDs = allAppnt.values(); 
    }
    public void newPatientsSeen(){  
        map<string,MainWrapper.WrapperForDetail> allAppnt = new map<string,MainWrapper.WrapperForDetail>(); 
        AggregateResult[] groupedResults = [select count(id) cnt,  Business_Unit__c,DAY_ONLY(createdDate) cd, Account.Patient_Type__c from Opportunity 
                                                   where CreatedDate >:outputdate and CreatedDate <:outputdate.addDays(7) and Business_Unit__c != null and 
                                                   Account.Patient_Type__c = 'New' AND site__c=:siteName AND site__c != null group by Business_Unit__c, DAY_ONLY(createdDate),Account.Patient_Type__c];
        For(selectOption so : getBusinessUnit()){  
            MainWrapper.WrapperForDetail objWFDApp = new MainWrapper.WrapperForDetail(); 
            if(groupedResults.size() == 0){
                objWFDApp.detailItem = so.getLabel();           
                allAppnt.put(so.getLabel(),objWFDApp);
            }else{
                For(AggregateResult objAR : groupedResults){  
                    if(so.getLabel() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay1 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){ 
                        objWFDApp.detailDay1 = ''+objAR.get('cnt');                      
                    }
                    if(so.getLabel() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay2 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay2 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay3 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay3 = ''+objAR.get('cnt');    
                    }            
                    if(so.getLabel() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay4 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay4 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay5 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay5 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay6 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay6 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay7 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay7 = ''+objAR.get('cnt'); 
                    }  
                    objWFDApp.detailItem = so.getLabel();          
                    allAppnt.put(so.getLabel(),objWFDApp); 
                } 
            }            
        } 
        objNewPatents.objlstWFDs = allAppnt.values(); 
    }
    public void implantsAndOrthoSale(){  
        map<string,MainWrapper.WrapperForDetail> allAppnt = new map<string,MainWrapper.WrapperForDetail>(); 
        AggregateResult[] groupedResults = [select count(id) cnt, Business_Unit__c,DAY_ONLY(createdDate) cd from Opportunity where CreatedDate >:outputdate and 
                                                   CreatedDate <:outputdate.addDays(7) and StageName = 'Closed Won'  and (Business_Unit__c = 'Ortho' OR 
                                                   Business_Unit__c = 'Implants') AND site__c=:siteName AND site__c != null group by Business_Unit__c,DAY_ONLY(createdDate)];
        list<string> objLst = new list<string>{'Implants - No. of Sales (consent <br/> signed / deposit received)','Ortho - No. of Sales (consent <br/> signed / deposit received)','Implant: 1st Appt. > Sale conv. %','Ortho: 1st Appt. > Sale conv. %'};
        system.debug('--------228 : '+groupedResults.size());
        For(integer i=0; i<objlst.size(); i++){  
            //integer i=0;
            MainWrapper.WrapperForDetail objWFDApp = new MainWrapper.WrapperForDetail(); 
            if(groupedResults.size() == 0){
                objWFDApp.detailItem = objLst[i];           
                allAppnt.put(objLst[i],objWFDApp);
            }else{
                For(AggregateResult objAR : groupedResults){ 
                    if(objLst[i].split('-')[0].trim() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay1 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){ 
                        objWFDApp.detailDay1 = ''+objAR.get('cnt');                   
                    }
                    if(objLst[i].split('-')[0].trim() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay2 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay2 = ''+objAR.get('cnt'); 
                    }
                    if(objLst[i].split('-')[0].trim() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay3 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay3 = ''+objAR.get('cnt');    
                    }            
                    if(objLst[i].split('-')[0].trim() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay4 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay4 = ''+objAR.get('cnt'); 
                    }
                    if(objLst[i].split('-')[0].trim() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay5 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){ 
                        objWFDApp.detailDay5 = ''+objAR.get('cnt'); 
                    }
                    if(objLst[i].split('-')[0].trim() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay6 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay6 = ''+objAR.get('cnt'); 
                    }
                    if(objLst[i].split('-')[0].trim() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay7 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay7 = ''+objAR.get('cnt'); 
                    }  
                    objWFDApp.detailItem = objLst[i];          
                    allAppnt.put(objLst[i],objWFDApp); 
                } 
            }            
        } 
        objImp_Ortho.objlstWFDs = allAppnt.values(); 
    }
    public void newMemberSigned(){  
        map<string,MainWrapper.WrapperForDetail> allAppnt = new map<string,MainWrapper.WrapperForDetail>(); 
        AggregateResult[] groupedResults = [select count(id) cnt, DAY_ONLY(dsfs__Opportunity__r.createdDate) cd, dsfs__Opportunity__r.Membership_Level__c ml from dsfs__DocuSign_Status__c
                                            where dsfs__Opportunity__r.createdDate >:outputdate AND dsfs__Opportunity__r.createdDate <:outputdate.addDays(7) AND 
                                            dsfs__Envelope_Status__c = 'completed' AND dsfs__Opportunity__r.id != null AND dsfs__Opportunity__r.Membership_Level__c != null AND site__c=:siteName AND site__c != null
                                            group by dsfs__Opportunity__r.Membership_Level__c, DAY_ONLY(dsfs__Opportunity__r.createdDate)];
                                            
        list<string> objLst = new list<string>{'Adult','Child'};
        list<string> objNewMemrs = new list<string>{'Adults','Children'}; 
        For(integer i=0; i<objlst.size(); i++){ 
            MainWrapper.WrapperForDetail objWFDApp = new MainWrapper.WrapperForDetail(); 
            if(groupedResults.size() == 0){
                objWFDApp.detailItem = objNewMemrs[i];           
                allAppnt.put(objLst[i],objWFDApp);
            }else{
                For(AggregateResult objAR : groupedResults){  
                    if(objLst[i] == objAR.get('ml') && objCR.HeaderDay1 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){ 
                        objWFDApp.detailDay1 = ''+objAR.get('cnt');                     
                    }
                    if(objLst[i] == ''+objAR.get('ml') && objCR.HeaderDay2 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay2 = ''+objAR.get('cnt'); 
                    }
                    if(objLst[i] == ''+objAR.get('ml') && objCR.HeaderDay3 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay3 = ''+objAR.get('cnt');    
                    }            
                    if(objLst[i] == ''+objAR.get('ml') && objCR.HeaderDay4 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay4 = ''+objAR.get('cnt'); 
                    }
                    if(objLst[i] == ''+objAR.get('ml') && objCR.HeaderDay5 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){ 
                        objWFDApp.detailDay5 = ''+objAR.get('cnt'); 
                    }
                    if(objLst[i] == ''+objAR.get('ml') && objCR.HeaderDay6 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay6 = ''+objAR.get('cnt'); 
                    }
                    if(objLst[i] == ''+objAR.get('ml') && objCR.HeaderDay7 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay7 = ''+objAR.get('cnt'); 
                    }  
                    objWFDApp.detailItem = objNewMemrs[i];          
                    allAppnt.put(objLst[i],objWFDApp); 
                }  
            }            
        } 
        objNewMemberSigned.objlstWFDs = allAppnt.values(); 
    }
    public void salesInvoiced(){  
        map<string,MainWrapper.WrapperForDetail> allAppnt = new map<string,MainWrapper.WrapperForDetail>(); 
        AggregateResult[] groupedResults = [select count(id) cnt, sum(Amount) amt,  Business_Unit__c, DAY_ONLY(createdDate) cd, StageName from Opportunity where StageName ='Closed Won' AND
                                                createdDate >: outputdate AND createdDate <: outputdate.addDays(7) AND site__c=:siteName AND site__c != null group by Business_Unit__c, DAY_ONLY(createdDate), 
                                                StageName]; 
        For(selectOption so : getBusinessUnit()){  
            MainWrapper.WrapperForDetail objWFDApp = new MainWrapper.WrapperForDetail(); 
            if(groupedResults.size() == 0){
                objWFDApp.detailItem = so.getLabel();           
                allAppnt.put(so.getLabel(),objWFDApp);
            }else{
                For(AggregateResult objAR : groupedResults){  
                    if(so.getLabel() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay1 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){ 
                        if(objAR.get('amt') != null && objAR.get('amt') != ''){
                            objWFDApp.detailDay1 = ''+objAR.get('amt');            
                        }else{
                            objWFDApp.detailDay1 = '0';
                        }       
                    }
                    if(so.getLabel() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay2 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        if(objAR.get('amt') != null && objAR.get('amt') != ''){
                            objWFDApp.detailDay2 = ''+objAR.get('amt');            
                        }else{
                            objWFDApp.detailDay2 = '0';
                        }  
                    }
                    if(so.getLabel() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay3 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        if(objAR.get('amt') != null && objAR.get('amt') != ''){
                            objWFDApp.detailDay3 = ''+objAR.get('amt');            
                        }else{
                            objWFDApp.detailDay3 = '0';
                        }    
                    }            
                    if(so.getLabel() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay4 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        if(objAR.get('amt') != null && objAR.get('amt') != ''){
                            objWFDApp.detailDay4 = ''+objAR.get('amt');            
                        }else{
                            objWFDApp.detailDay4 = '0';
                        } 
                    }
                    if(so.getLabel() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay5 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        if(objAR.get('amt') != null && objAR.get('amt') != ''){
                            objWFDApp.detailDay5 = ''+objAR.get('amt');            
                        }else{
                            objWFDApp.detailDay5 = '0';
                        }  
                    }
                    if(so.getLabel() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay6 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        if(objAR.get('amt') != null && objAR.get('amt') != ''){
                            objWFDApp.detailDay6 = ''+objAR.get('amt');            
                        }else{
                            objWFDApp.detailDay6 = '0';
                        } 
                    }
                    if(so.getLabel() == ''+objAR.get('Business_Unit__c') && objCR.HeaderDay7 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        if(objAR.get('amt') != null && objAR.get('amt') != ''){
                            objWFDApp.detailDay7 = ''+objAR.get('amt');            
                        }else{
                            objWFDApp.detailDay7 = '0';
                        } 
                    }  
                    objWFDApp.detailItem = so.getLabel();          
                    allAppnt.put(so.getLabel(),objWFDApp); 
                } 
            }            
        } 
        salesInvoiced.objlstWFDs = allAppnt.values(); 
    } 
    public void NonConversionReason_GP_EnqTo1st_Appt(){ 
        map<string,MainWrapper.WrapperForDetail> allAppnt = new map<string,MainWrapper.WrapperForDetail>();
        AggregateResult[] groupedResults = [select count(id) cnt,  Reason_for_non_conversion__c rnc, Day_Only(createdDate) cd from Opportunity where createdDate >: outputdate AND createdDate <: outputdate.addDays(7) AND Business_Unit__c = 'GP & Nurse' AND StageName = 'Closed Lost' AND site__c=:siteName AND site__c != null group by Reason_for_non_conversion__c, Day_Only(createdDate)]; 
        For(selectOption so : getReasonForNonConversion()){  
            MainWrapper.WrapperForDetail objWFDApp = new MainWrapper.WrapperForDetail();  
                if(groupedResults.size() == 0){
                objWFDApp.detailItem = so.getLabel();           
                allAppnt.put(so.getLabel(),objWFDApp);
            }else{
                For(AggregateResult objAR : groupedResults){  
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay1 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){ 
                        objWFDApp.detailDay1 = ''+objAR.get('cnt');                      
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay2 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay2 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay3 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay3 = ''+objAR.get('cnt');    
                    }            
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay4 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay4 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay5 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay5 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay6 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay6 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay7 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay7 = ''+objAR.get('cnt'); 
                    }  
                    objWFDApp.detailItem = so.getLabel();          
                    allAppnt.put(so.getLabel(),objWFDApp); 
                } 
            }          
        }  
        GP_EnqTo1st_Appt.objlstWFDs = allAppnt.values(); 
    }
    public void NonConversionReason_Dentist_EnqTo1st_Appt(){ 
        map<string,MainWrapper.WrapperForDetail> allAppnt = new map<string,MainWrapper.WrapperForDetail>(); 
        AggregateResult[] groupedResults = [select count(id) cnt,  Reason_for_non_conversion__c rnc, Day_Only(createdDate) cd from Opportunity where createdDate >: outputdate AND createdDate <: outputdate.addDays(7) AND Business_Unit__c = 'Dentist & Hygiene' AND StageName = 'Closed Lost' AND site__c=:siteName AND site__c != null group by Reason_for_non_conversion__c, Day_Only(createdDate)]; 
        For(selectOption so : getReasonForNonConversion()){  
            MainWrapper.WrapperForDetail objWFDApp = new MainWrapper.WrapperForDetail();  
                if(groupedResults.size() == 0){
                objWFDApp.detailItem = so.getLabel();           
                allAppnt.put(so.getLabel(),objWFDApp);
            }else{
                For(AggregateResult objAR : groupedResults){  
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay1 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){ 
                        objWFDApp.detailDay1 = ''+objAR.get('cnt');                      
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay2 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay2 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay3 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay3 = ''+objAR.get('cnt');    
                    }            
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay4 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay4 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay5 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay5 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay6 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay6 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay7 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay7 = ''+objAR.get('cnt'); 
                    }  
                    objWFDApp.detailItem = so.getLabel();          
                    allAppnt.put(so.getLabel(),objWFDApp); 
                } 
            }           
        }       
        Dentist_EnqTo1st_Appt.objlstWFDs = allAppnt.values();  
    }  
    public void NonConversionReason_Implant_EnqTo1st_Appt(){ 
        map<string,MainWrapper.WrapperForDetail> allAppnt = new map<string,MainWrapper.WrapperForDetail>();  
        AggregateResult[] groupedResults = [select count(id) cnt,  Reason_for_non_conversion__c rnc, Day_Only(createdDate) cd from Opportunity where createdDate >: outputdate AND createdDate <: outputdate.addDays(7) AND Business_Unit__c = 'Implants' AND StageName = 'Closed Lost' AND site__c=:siteName AND site__c != null group by Reason_for_non_conversion__c, Day_Only(createdDate)];
        For(selectOption so : getReasonForNonConversion()){  
            MainWrapper.WrapperForDetail objWFDApp = new MainWrapper.WrapperForDetail();  
               if(groupedResults.size() == 0){
                objWFDApp.detailItem = so.getLabel();           
                allAppnt.put(so.getLabel(),objWFDApp);
            }else{
                For(AggregateResult objAR : groupedResults){  
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay1 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){ 
                        objWFDApp.detailDay1 = ''+objAR.get('cnt');                      
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay2 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay2 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay3 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay3 = ''+objAR.get('cnt');    
                    }            
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay4 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay4 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay5 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay5 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay6 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay6 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay7 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay7 = ''+objAR.get('cnt'); 
                    }  
                    objWFDApp.detailItem = so.getLabel();          
                    allAppnt.put(so.getLabel(),objWFDApp); 
                } 
            }            
        }       
        Implant_EnqTo1st_Appt.objlstWFDs = allAppnt.values();  
    }
    
    public void NonConversionReason_Ortho_EnqTo1st_Appt(){ 
        map<string,MainWrapper.WrapperForDetail> allAppnt = new map<string,MainWrapper.WrapperForDetail>();  
        AggregateResult[] groupedResults = [select count(id) cnt,  Reason_for_non_conversion__c rnc, Day_Only(createdDate) cd from Opportunity where createdDate >: outputdate AND createdDate <: outputdate.addDays(7) AND Business_Unit__c = 'Ortho' AND StageName = 'Closed Lost' AND site__c=:siteName AND site__c != null group by Reason_for_non_conversion__c, Day_Only(createdDate)];
        
        For(selectOption so : getReasonForNonConversion()){  
            MainWrapper.WrapperForDetail objWFDApp = new MainWrapper.WrapperForDetail(); 
            if(groupedResults.size() == 0){
                objWFDApp.detailItem = so.getLabel();           
                allAppnt.put(so.getLabel(),objWFDApp);
            }else{
                For(AggregateResult objAR : groupedResults){  
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay1 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){ 
                        objWFDApp.detailDay1 = ''+objAR.get('cnt');                      
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay2 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay2 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay3 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay3 = ''+objAR.get('cnt');    
                    }            
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay4 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay4 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay5 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay5 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay6 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay6 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay7 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay7 = ''+objAR.get('cnt'); 
                    }  
                    objWFDApp.detailItem = so.getLabel();          
                    allAppnt.put(so.getLabel(),objWFDApp); 
                } 
            }          
        }       
        Ortho_EnqTo1st_Appt.objlstWFDs = allAppnt.values(); 
    } 
    public void NonConversionReason_Pathology_EnqTo1st_Appt(){  
        map<string,MainWrapper.WrapperForDetail> allAppnt = new map<string,MainWrapper.WrapperForDetail>();  
        AggregateResult[] groupedResults = [select count(id) cnt,  Reason_for_non_conversion__c rnc, Day_Only(createdDate) cd from Opportunity where createdDate >: outputdate AND createdDate <: outputdate.addDays(7) AND Business_Unit__c = 'Pathology & Vaccines' AND StageName = 'Closed Lost' AND site__c=:siteName AND site__c != null group by Reason_for_non_conversion__c, Day_Only(createdDate)];
        
        For(selectOption so : getReasonForNonConversion()){  
            MainWrapper.WrapperForDetail objWFDApp = new MainWrapper.WrapperForDetail(); 
            if(groupedResults.size() == 0){
                objWFDApp.detailItem = so.getLabel();           
                allAppnt.put(so.getLabel(),objWFDApp);
            }else{
                For(AggregateResult objAR : groupedResults){  
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay1 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){ 
                        objWFDApp.detailDay1 = ''+objAR.get('cnt');                      
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay2 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay2 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay3 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay3 = ''+objAR.get('cnt');    
                    }            
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay4 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay4 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay5 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay5 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay6 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay6 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay7 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay7 = ''+objAR.get('cnt'); 
                    }  
                    objWFDApp.detailItem = so.getLabel();          
                    allAppnt.put(so.getLabel(),objWFDApp); 
                } 
            }          
        }       
        Pathology_EnqTo1st_Appt.objlstWFDs = allAppnt.values(); 
    }
    public void NonConversionReason_Fertility_EnqTo1st_Appt(){  
        map<string,MainWrapper.WrapperForDetail> allAppnt = new map<string,MainWrapper.WrapperForDetail>();  
        AggregateResult[] groupedResults = [select count(id) cnt,  Reason_for_non_conversion__c rnc, Day_Only(createdDate) cd from Opportunity where createdDate >: outputdate AND createdDate <: outputdate.addDays(7) AND Business_Unit__c = 'Fertility' AND StageName = 'Closed Lost' AND site__c=:siteName AND site__c != null group by Reason_for_non_conversion__c, Day_Only(createdDate)];
        
        For(selectOption so : getReasonForNonConversion()){  
            MainWrapper.WrapperForDetail objWFDApp = new MainWrapper.WrapperForDetail(); 
            if(groupedResults.size() == 0){
                objWFDApp.detailItem = so.getLabel();           
                allAppnt.put(so.getLabel(),objWFDApp);
            }else{
                For(AggregateResult objAR : groupedResults){  
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay1 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){ 
                        objWFDApp.detailDay1 = ''+objAR.get('cnt');                      
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay2 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay2 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay3 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay3 = ''+objAR.get('cnt');    
                    }            
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay4 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay4 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay5 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay5 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay6 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay6 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay7 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay7 = ''+objAR.get('cnt'); 
                    }  
                    objWFDApp.detailItem = so.getLabel();          
                    allAppnt.put(so.getLabel(),objWFDApp); 
                } 
            }          
        }       
        Fertility_EnqTo1st_Appt.objlstWFDs = allAppnt.values(); 
    }
    public void NonConversionReason_Medical_EnqTo1st_Appt(){  
        map<string,MainWrapper.WrapperForDetail> allAppnt = new map<string,MainWrapper.WrapperForDetail>();  
        AggregateResult[] groupedResults = [select count(id) cnt,  Reason_for_non_conversion__c rnc, Day_Only(createdDate) cd from Opportunity where createdDate >: outputdate AND createdDate <: outputdate.addDays(7) AND Business_Unit__c = 'Medical consultants' AND StageName = 'Closed Lost' AND site__c=:siteName AND site__c != null group by Reason_for_non_conversion__c, Day_Only(createdDate)];
        
        For(selectOption so : getReasonForNonConversion()){  
            MainWrapper.WrapperForDetail objWFDApp = new MainWrapper.WrapperForDetail(); 
            if(groupedResults.size() == 0){
                objWFDApp.detailItem = so.getLabel();           
                allAppnt.put(so.getLabel(),objWFDApp);
            }else{
                For(AggregateResult objAR : groupedResults){  
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay1 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){ 
                        objWFDApp.detailDay1 = ''+objAR.get('cnt');                      
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay2 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay2 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay3 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay3 = ''+objAR.get('cnt');    
                    }            
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay4 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay4 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay5 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay5 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay6 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay6 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay7 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay7 = ''+objAR.get('cnt'); 
                    }  
                    objWFDApp.detailItem = so.getLabel();          
                    allAppnt.put(so.getLabel(),objWFDApp); 
                } 
            }          
        }       
        Medical_EnqTo1st_Appt.objlstWFDs = allAppnt.values(); 
    }
    public void NonConversionReason_Therapists_EnqTo1st_Appt(){  
        map<string,MainWrapper.WrapperForDetail> allAppnt = new map<string,MainWrapper.WrapperForDetail>();  
        AggregateResult[] groupedResults = [select count(id) cnt,  Reason_for_non_conversion__c rnc, Day_Only(createdDate) cd from Opportunity where createdDate >: outputdate AND createdDate <: outputdate.addDays(7) AND Business_Unit__c = 'Therapists' AND StageName = 'Closed Lost' AND site__c=:siteName AND site__c != null group by Reason_for_non_conversion__c, Day_Only(createdDate)];
        
        For(selectOption so : getReasonForNonConversion()){  
            MainWrapper.WrapperForDetail objWFDApp = new MainWrapper.WrapperForDetail(); 
            if(groupedResults.size() == 0){
                objWFDApp.detailItem = so.getLabel();           
                allAppnt.put(so.getLabel(),objWFDApp);
            }else{
                For(AggregateResult objAR : groupedResults){  
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay1 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){ 
                        objWFDApp.detailDay1 = ''+objAR.get('cnt');                      
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay2 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay2 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay3 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay3 = ''+objAR.get('cnt');    
                    }            
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay4 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay4 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay5 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay5 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay6 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay6 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay7 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay7 = ''+objAR.get('cnt'); 
                    }  
                    objWFDApp.detailItem = so.getLabel();          
                    allAppnt.put(so.getLabel(),objWFDApp); 
                } 
            }          
        }       
        Therapists_EnqTo1st_Appt.objlstWFDs = allAppnt.values(); 
    }
    public void NonConversionReason_Physio_EnqTo1st_Appt(){  
        map<string,MainWrapper.WrapperForDetail> allAppnt = new map<string,MainWrapper.WrapperForDetail>();  
        AggregateResult[] groupedResults = [select count(id) cnt,  Reason_for_non_conversion__c rnc, Day_Only(createdDate) cd from Opportunity where createdDate >: outputdate AND createdDate <: outputdate.addDays(7) AND Business_Unit__c = 'Physio & Podiatry' AND StageName = 'Closed Lost' AND site__c=:siteName AND site__c != null group by Reason_for_non_conversion__c, Day_Only(createdDate)];
        
        For(selectOption so : getReasonForNonConversion()){  
            MainWrapper.WrapperForDetail objWFDApp = new MainWrapper.WrapperForDetail(); 
            if(groupedResults.size() == 0){
                objWFDApp.detailItem = so.getLabel();           
                allAppnt.put(so.getLabel(),objWFDApp);
            }else{
                For(AggregateResult objAR : groupedResults){  
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay1 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){ 
                        objWFDApp.detailDay1 = ''+objAR.get('cnt');                      
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay2 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay2 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay3 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay3 = ''+objAR.get('cnt');    
                    }            
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay4 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay4 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay5 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay5 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay6 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay6 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay7 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay7 = ''+objAR.get('cnt'); 
                    }  
                    objWFDApp.detailItem = so.getLabel();          
                    allAppnt.put(so.getLabel(),objWFDApp); 
                } 
            }          
        }       
        Physio_EnqTo1st_Appt.objlstWFDs = allAppnt.values(); 
    }
    public void NonConversionReason_Mother_EnqTo1st_Appt(){  
        map<string,MainWrapper.WrapperForDetail> allAppnt = new map<string,MainWrapper.WrapperForDetail>();  
        AggregateResult[] groupedResults = [select count(id) cnt,  Reason_for_non_conversion__c rnc, Day_Only(createdDate) cd from Opportunity where createdDate >: outputdate AND createdDate <: outputdate.addDays(7) AND Business_Unit__c = 'Mother & Baby' AND StageName = 'Closed Lost' AND site__c=:siteName AND site__c != null group by Reason_for_non_conversion__c, Day_Only(createdDate)];
        
        For(selectOption so : getReasonForNonConversion()){  
            MainWrapper.WrapperForDetail objWFDApp = new MainWrapper.WrapperForDetail(); 
            if(groupedResults.size() == 0){
                objWFDApp.detailItem = so.getLabel();           
                allAppnt.put(so.getLabel(),objWFDApp);
            }else{
                For(AggregateResult objAR : groupedResults){  
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay1 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){ 
                        objWFDApp.detailDay1 = ''+objAR.get('cnt');                      
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay2 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay2 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay3 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay3 = ''+objAR.get('cnt');    
                    }            
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay4 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay4 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay5 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay5 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay6 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay6 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay7 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay7 = ''+objAR.get('cnt'); 
                    }  
                    objWFDApp.detailItem = so.getLabel();          
                    allAppnt.put(so.getLabel(),objWFDApp); 
                } 
            }          
        }       
        Mother_EnqTo1st_Appt.objlstWFDs = allAppnt.values(); 
    }
    public void NonConversionReason_Skin_EnqTo1st_Appt(){  
        map<string,MainWrapper.WrapperForDetail> allAppnt = new map<string,MainWrapper.WrapperForDetail>();  
        AggregateResult[] groupedResults = [select count(id) cnt,  Reason_for_non_conversion__c rnc, Day_Only(createdDate) cd from Opportunity where createdDate >: outputdate AND createdDate <: outputdate.addDays(7) AND Business_Unit__c = 'Skin' AND StageName = 'Closed Lost' AND site__c=:siteName AND site__c != null group by Reason_for_non_conversion__c, Day_Only(createdDate)];
        
        For(selectOption so : getReasonForNonConversion()){  
            MainWrapper.WrapperForDetail objWFDApp = new MainWrapper.WrapperForDetail(); 
            if(groupedResults.size() == 0){
                objWFDApp.detailItem = so.getLabel();           
                allAppnt.put(so.getLabel(),objWFDApp);
            }else{
                For(AggregateResult objAR : groupedResults){  
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay1 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){ 
                        objWFDApp.detailDay1 = ''+objAR.get('cnt');                      
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay2 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay2 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay3 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay3 = ''+objAR.get('cnt');    
                    }            
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay4 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay4 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay5 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay5 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay6 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay6 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay7 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay7 = ''+objAR.get('cnt'); 
                    }  
                    objWFDApp.detailItem = so.getLabel();          
                    allAppnt.put(so.getLabel(),objWFDApp); 
                } 
            }          
        }       
        Skin_EnqTo1st_Appt.objlstWFDs = allAppnt.values(); 
    }
    public void NonConversionReason_Diagnostics_EnqTo1st_Appt(){  
        map<string,MainWrapper.WrapperForDetail> allAppnt = new map<string,MainWrapper.WrapperForDetail>();  
        AggregateResult[] groupedResults = [select count(id) cnt,  Reason_for_non_conversion__c rnc, Day_Only(createdDate) cd from Opportunity where createdDate >: outputdate AND createdDate <: outputdate.addDays(7) AND Business_Unit__c = 'Diagnostics & OP Procedures' AND StageName = 'Closed Lost' AND site__c=:siteName AND site__c != null group by Reason_for_non_conversion__c, Day_Only(createdDate)];
        
        For(selectOption so : getReasonForNonConversion()){  
            MainWrapper.WrapperForDetail objWFDApp = new MainWrapper.WrapperForDetail(); 
            if(groupedResults.size() == 0){
                objWFDApp.detailItem = so.getLabel();           
                allAppnt.put(so.getLabel(),objWFDApp);
            }else{
                For(AggregateResult objAR : groupedResults){  
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay1 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){ 
                        objWFDApp.detailDay1 = ''+objAR.get('cnt');                      
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay2 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay2 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay3 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay3 = ''+objAR.get('cnt');    
                    }            
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay4 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay4 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay5 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay5 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay6 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay6 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay7 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay7 = ''+objAR.get('cnt'); 
                    }  
                    objWFDApp.detailItem = so.getLabel();          
                    allAppnt.put(so.getLabel(),objWFDApp); 
                } 
            }          
        }       
        Diagnostics_EnqTo1st_Appt.objlstWFDs = allAppnt.values(); 
    }
    public void NonConversionReason_Occupational_EnqTo1st_Appt(){  
        map<string,MainWrapper.WrapperForDetail> allAppnt = new map<string,MainWrapper.WrapperForDetail>();  
        AggregateResult[] groupedResults = [select count(id) cnt,  Reason_for_non_conversion__c rnc, Day_Only(createdDate) cd from Opportunity where createdDate >: outputdate AND createdDate <: outputdate.addDays(7) AND Business_Unit__c = 'Occupational Health' AND StageName = 'Closed Lost' AND site__c=:siteName AND site__c != null group by Reason_for_non_conversion__c, Day_Only(createdDate)];
        
        For(selectOption so : getReasonForNonConversion()){  
            MainWrapper.WrapperForDetail objWFDApp = new MainWrapper.WrapperForDetail(); 
            if(groupedResults.size() == 0){
                objWFDApp.detailItem = so.getLabel();           
                allAppnt.put(so.getLabel(),objWFDApp);
            }else{
                For(AggregateResult objAR : groupedResults){  
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay1 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){ 
                        objWFDApp.detailDay1 = ''+objAR.get('cnt');                      
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay2 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay2 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay3 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay3 = ''+objAR.get('cnt');    
                    }            
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay4 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay4 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay5 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay5 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay6 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay6 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay7 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay7 = ''+objAR.get('cnt'); 
                    }  
                    objWFDApp.detailItem = so.getLabel();          
                    allAppnt.put(so.getLabel(),objWFDApp); 
                } 
            }          
        }       
        Occupational_EnqTo1st_Appt.objlstWFDs = allAppnt.values(); 
    }
     public void NonConversionReason_Membership_EnqTo1st_Appt(){  
        map<string,MainWrapper.WrapperForDetail> allAppnt = new map<string,MainWrapper.WrapperForDetail>();  
        AggregateResult[] groupedResults = [select count(id) cnt,  Reason_for_non_conversion__c rnc, Day_Only(createdDate) cd from Opportunity where createdDate >: outputdate AND createdDate <: outputdate.addDays(7) AND Business_Unit__c = 'Membership' AND StageName = 'Closed Lost' AND site__c=:siteName AND site__c != null group by Reason_for_non_conversion__c, Day_Only(createdDate)];
        
        For(selectOption so : getReasonForNonConversion()){  
            MainWrapper.WrapperForDetail objWFDApp = new MainWrapper.WrapperForDetail(); 
            if(groupedResults.size() == 0){
                objWFDApp.detailItem = so.getLabel();           
                allAppnt.put(so.getLabel(),objWFDApp);
            }else{
                For(AggregateResult objAR : groupedResults){  
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay1 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){ 
                        objWFDApp.detailDay1 = ''+objAR.get('cnt');                      
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay2 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay2 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay3 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay3 = ''+objAR.get('cnt');    
                    }            
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay4 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay4 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay5 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay5 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay6 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay6 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay7 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay7 = ''+objAR.get('cnt'); 
                    }  
                    objWFDApp.detailItem = so.getLabel();          
                    allAppnt.put(so.getLabel(),objWFDApp); 
                } 
            }          
        }       
        Membership_EnqTo1st_Appt.objlstWFDs = allAppnt.values(); 
    }
    public void TotalNonConversionReason(){  
        map<string,MainWrapper.WrapperForDetail> allAppnt = new map<string,MainWrapper.WrapperForDetail>();  
        AggregateResult[] groupedResults = [select count(id) cnt,  Reason_for_non_conversion__c rnc, Day_Only(createdDate) cd from Opportunity where createdDate >: outputdate AND createdDate <: outputdate.addDays(7) AND StageName = 'Closed Lost' AND site__c=:siteName AND site__c != null group by Reason_for_non_conversion__c, Day_Only(createdDate)];
        
        For(selectOption so : getReasonForNonConversion()){  
            MainWrapper.WrapperForDetail objWFDApp = new MainWrapper.WrapperForDetail(); 
            if(groupedResults.size() == 0){
                objWFDApp.detailItem = so.getLabel();           
                allAppnt.put(so.getLabel(),objWFDApp);
            }else{
                For(AggregateResult objAR : groupedResults){  
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay1 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){ 
                        objWFDApp.detailDay1 = ''+objAR.get('cnt');                      
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay2 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay2 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay3 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay3 = ''+objAR.get('cnt');    
                    }            
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay4 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay4 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay5 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay5 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay6 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay6 = ''+objAR.get('cnt'); 
                    }
                    if(so.getLabel() == ''+objAR.get('rnc') && objCR.HeaderDay7 == ConvertDateFormat(Date.valueOf((''+objAR.get('cd')).substring(0,10)))){
                        objWFDApp.detailDay7 = ''+objAR.get('cnt'); 
                    }  
                    objWFDApp.detailItem = so.getLabel();          
                    allAppnt.put(so.getLabel(),objWFDApp); 
                } 
            }          
        }       
        totalNonConvReason.objlstWFDs = allAppnt.values(); 
    }
    public void CoreResults(){
        map<string,MainWrapper.WrapperForDetail> allAppnt = new map<string,MainWrapper.WrapperForDetail>();
        list<string> objLst = new list<string>{'Core BU Enquiries','1st appts Booked','Non-converted'}; 
        For(integer i=0; i<objlst.size(); i++){  
            MainWrapper.WrapperForDetail objWFDApp = new MainWrapper.WrapperForDetail(); 
                objWFDApp.detailItem = objLst[i];           
                allAppnt.put(objLst[i],objWFDApp); 
        } 
        objCoreResults.objlstWFDs = allAppnt.values(); 
    }
    public List<SelectOption> getBusinessUnit(){
        List<SelectOption> options = new List<SelectOption>(); 
        Schema.DescribeFieldResult fieldResult = Lead.Business_Unit__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues(); 
        for( Schema.PicklistEntry f : ple)
        {
          options.add(new SelectOption(f.getLabel(), f.getValue()));
        }       
        return options;
    }
    public list<SelectOption> getReasonForNonConversion(){
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = Opportunity.Reason_for_non_conversion__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        For(Schema.PicklistEntry f : ple){
           options.add(new SelectOption(f.getLabel(),f.getValue())); 
        }
        return options;
    } 
}