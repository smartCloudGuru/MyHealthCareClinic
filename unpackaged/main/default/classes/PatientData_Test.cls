@isTest
private class PatientData_Test{    
    public static testMethod void testPatientData(){ 
        PatientData objPatientData = new PatientData();
          list<PatientData.ContactOptions> obConlist = new list<PatientData.ContactOptions>();
        
        
        PatientData.ContactOptions obCO = new PatientData.ContactOptions();
        obCO.Subject = 'testSub';
        obCO.Email = false;
        obCO.SMS = true;
        obCO.Key = 'testKey';
        obConlist.add(obCO); 
        
        PatientData.Address obPDA = new PatientData.Address(); 
        obPDA.County = 'test';
        obPDA.City = 'testCity';
        obPDA.Address3 = 'testAdd';
        obPDA.PostCode = '001';
        obPDA.Address2 = 'add2';
        obPDA.Country = 'testCountr';
        obPDA.Address1 = 'add1';
        
        PatientData.result objPD = new PatientData.result();
        objPD.Address = obPDA; 
        objPD.ContactOptions = obConlist;
        objPD.EmployeeNumber = '8889';
        objPD.EmailAddress = 'test@test.com';
        objPD.DateOfBirth = '1st Jan';
        objPD.SexType = 1;
        objPD.Mobile = '9999999999';
        objPD.Surname = 'test';
        objPD.Name = 'testName';
        objPD.TermsAndConditionsAccepted = true;
        objPD.Title = 'test title';
        objPD.StatisticalProcessingAccepted = true;
        objPD.Key = 'kkek';
        
        PatientData objP = new PatientData();
        objP.result = objPD;
        
        system.assert(objPatientData.status == null);
        /*system.assert(objPatientData.result.Address == null);
        system.assert(objPatientData.result.EmployeeNumber == null);
        system.assert(objPatientData.result.EmailAddress == null);
        system.assert(objPatientData.result.DateOfBirth == null);
        system.assert(objPatientData.result.SexType == null);
        system.assert(objPatientData.result.Mobile == null);
        system.assert(objPatientData.result.Surname == null);
        system.assert(objPatientData.result.ContactOptions == null);
        system.assert(objPatientData.result.Name == null);
        system.assert(objPatientData.result.TermsAndConditionsAccepted == null);
        system.assert(objPatientData.result.Title == null);
        system.assert(objPatientData.result.StatisticalProcessingAccepted== null);
        system.assert(objPatientData.result.Key == null);  */
    }
}