@isTest
public class  TurningToAdultMemberBatch_Test {
    @testSetup 
    public static void setUpMockData(){
    Account acc = new Account(
           FirstName='Test FName',
           LastName='Test LName',   
           PersonMailingStreet='test@yahoo.com',
           PersonMailingPostalCode='12345',
           PersonMailingCity='SFO',
           PersonEmail='test@yahoo.com',
           PersonHomePhone='1234567',
           PersonMobilePhone='12345678', 
           Patient_Type__c='Member',
           Membership_Level__c='Child',
           Membership_Type__c='2019 MHC GP',
           Payment_Frequency__c='Monthly',
           Phone='122333333',
           Date_of_Birth__c = system.Today().addyears(-17).addmonths(-9).adddays(-1),
           Relation_With_Payer__c='Brother',
           //Turning_18_Year_Old__c = true,
           Home_Clinic__c='Wandsworth'
           
       ); 
       insert acc; 
       }     
       static testMethod void unitTest() {
        Test.startTest();              
           try{ TurningToAdultMemberBatch obj = new TurningToAdultMemberBatch();
            
           // TurningToAdultMemberUtil.pushNotification('emailBody');
             DataBase.executeBatch(obj); 
            }
            catch(Exception e){}
        Test.stopTest();
    } 
}