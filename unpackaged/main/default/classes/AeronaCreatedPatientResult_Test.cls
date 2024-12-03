@isTest
public class AeronaCreatedPatientResult_Test {
private static testmethod void AeronaCreatedPatientTest(){
list<AeronaCreatedPatientResult.result> wrapperList = new list<AeronaCreatedPatientResult.result>();
AeronaCreatedPatientResult aeronaClassInstance = new AeronaCreatedPatientResult();
aeronaClassInstance.errorCode = 1;
aeronaClassInstance.errorResult = 'testStringResult';
aeronaClassInstance.status = 'test';
aeronaClassInstance.result = wrapperList;


AeronaCreatedPatientResult.result wrapperobj = new AeronaCreatedPatientResult.result();
wrapperobj.dob = 10.1;
wrapperobj.patientFullAddress = 'test1';
wrapperobj.patientFullName = 'testfullname';
wrapperobj.patientId = 10;



}
}