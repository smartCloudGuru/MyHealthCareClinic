global with sharing class MeddbaseStdBtnCallout {
    webservice static string getAnonAppointmentTypes(){ 
        AppointmentTypeData fatchATD = MeddbaseCalloutUtility.getAnonAppointmentTypes();
        return DatabaseUtility.createApointmentType(fatchATD);  
    }
    
    webservice static string getAnonSites(){ 
        Id batchJobId = Database.executeBatch(new AnonSitesUpdateBatch(), 1);
        return 'SUCCESS';
    }
    
    webservice static string getAnonClinicians(){
    	Id batchJobId = Database.executeBatch(new AnonClinicianUpdateBatch(), 1);
        return 'SUCCESS'; 
        /*ClinicianData fatchATD = MeddbaseCalloutUtility.getAnonClinicians('appointment type','payer type');
        return DatabaseUtility.createClinicians(fatchATD,'00000000ee324830');*/
    }
    
    webservice static string getAnonProposedAppointment(){ 
    	Id batchJobId = Database.executeBatch(new AnonProposedAppointmentUpdateBatch(), 1);
        return 'SUCCESS'; 
    }
    
    webservice static string syncAppointmentsByIntegrationUser(){ 
    	Id batchJobId = Database.executeBatch(new SyncAppointmentsByIntegrationUserBatch(), 1);
        return 'SUCCESS'; 
    }
}