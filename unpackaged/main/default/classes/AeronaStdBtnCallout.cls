global with sharing class AeronaStdBtnCallout {
    /*webservice static string getAnonAppointmentTypes(){ 
        AppointmentTypeData fatchATD = MeddbaseCalloutUtility.getAnonAppointmentTypes();
        return DatabaseUtility.createApointmentType(fatchATD);  
    }*/
    
    webservice static string getAeronaSites(){ 
        return AeronaCalloutUtility.getListByName('Practice',null);
    }
    webservice static string getPatientSearch(){ 
        return AeronaCalloutUtility.getPatientSearch(null);
    }
    
    /*webservice static string getAeronaClinicians(){
        Id batchJobId = Database.executeBatch(new AnonClinicianUpdateBatch(), 1);
        return 'SUCCESS';         
    }
    */
    webservice static string getAeronaAppointment(){ 
      Id batchJobId = Database.executeBatch(new AeronaFindSlotsBatch(),1);
        return 'SUCCESS'; 
    }
}