/**
 * Created 28.3.2022..
 */

@IsTest
public class ExternalSyncPatientsTest {

    @TestSetup
    static void dataSetup() {

        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
    }

    @IsTest
    static void testSyncPatientToHD_create() {
        HeyDocServiceMock.setAsMock();
        List<Account> accounts = [SELECT Id FROM Account];
        Test.startTest();
        ExternalSyncPatients.syncPatient(accounts);
        Test.stopTest();
        accounts = [SELECT Id, HeyDoc_Id__c FROM Account];
        System.debug(accounts[0].HeyDoc_Id__c);
        System.assert(accounts[0].HeyDoc_Id__c == HeyDocServiceMock.MOCK_HEYDOC_PATIENT_ID);
    }

    @IsTest
    static void testSyncPatientToHD_update() {
        HeyDocServiceMock.setAsMock();
        List<Account> accounts = [SELECT Id FROM Account];
        accounts[0].HeyDoc_Id__c = HeyDocServiceMock.MOCK_HEYDOC_PATIENT_ID;
        update accounts[0];
        Test.startTest();
        ExternalSyncPatients.syncPatient(accounts);
        Test.stopTest();
        accounts = [SELECT Id, HeyDoc_Id__c FROM Account];
        System.debug(accounts[0].HeyDoc_Id__c);
        System.assert(accounts[0].HeyDoc_Id__c == HeyDocServiceMock.MOCK_HEYDOC_PATIENT_ID);
    }

    @IsTest
    static void testSyncPatientToHD_update_removePhoneNo() {
        HeyDocServiceMock.setAsMock();
        List<Account> accounts = [SELECT Id FROM Account];
        accounts[0].HeyDoc_Id__c = HeyDocServiceMock.MOCK_HEYDOC_PATIENT_ID;
        accounts[0].PersonMobilePhone = null;
        update accounts[0];
        Test.startTest();
        ExternalSyncPatients.syncPatient(accounts);
        Test.stopTest();
        accounts = [SELECT Id, HeyDoc_Id__c FROM Account];
        System.debug(accounts[0].HeyDoc_Id__c);
        System.assert(accounts[0].HeyDoc_Id__c == HeyDocServiceMock.MOCK_HEYDOC_PATIENT_ID);
    }

    @IsTest
    static void testSyncPatientToAE_create() {
        AeronaServiceMock.setAsMock();
        List<Account> accounts = [SELECT Id FROM Account];
        Test.startTest();
        ExternalSyncPatients.syncPatient(accounts);
        Test.stopTest();
        accounts = [SELECT Id, Aerona_Id__c FROM Account];
        System.debug(accounts[0].Aerona_Id__c);
        System.assert(accounts[0].Aerona_Id__c!=null);
    }

    @IsTest
    static void testSyncPatientToAE_create_long_address() {
        AeronaServiceMock.setAsMock();
        List<Account> accounts = [SELECT Id FROM Account];
        accounts[0].BillingStreet = '4123 Jasmine House, Battersea Reach, Juniper Drive, Wandsworth';
        update accounts;
        Test.startTest();
        ExternalSyncPatients.syncPatient(accounts);
        Test.stopTest();
        accounts = [SELECT Id, Aerona_Id__c FROM Account];
        System.debug(accounts[0].Aerona_Id__c);
        System.assert(accounts[0].Aerona_Id__c!=null);
    }

    @IsTest
    static void testSyncPatientToAE_update() {
        AeronaServiceMock.setAsMock();
        List<Account> accounts = [SELECT Id FROM Account];
        accounts[0].Aerona_Id__c = '1222';
        update accounts[0];
        Test.startTest();
        ExternalSyncPatients.syncPatient(accounts);
        Test.stopTest();
        accounts = [SELECT Id, Aerona_Id__c FROM Account];
        System.debug(accounts[0].Aerona_Id__c);
        System.assert(accounts[0].Aerona_Id__c == '1222');
    }
    @IsTest
    static void testSyncPatientToAE_update_long_address() {
        AeronaServiceMock.setAsMock();
        List<Account> accounts = [SELECT Id FROM Account];
        accounts[0].Aerona_Id__c = '1222';
        accounts[0].BillingStreet = '4123 Jasmine House, Battersea Reach, Juniper Drive, Wandsworth';
        update accounts[0];
        Test.startTest();
        ExternalSyncPatients.syncPatient(accounts);
        Test.stopTest();
        accounts = [SELECT Id, Aerona_Id__c FROM Account];
        System.debug(accounts[0].Aerona_Id__c);
        System.assert(accounts[0].Aerona_Id__c == '1222');
    }


    @IsTest
    static void aerona_street_address_tests()
    {
        String orig1 = '18 Mable Street';
        ExternalSyncPatientsToAerona.AddressPair ap = ExternalSyncPatientsToAerona.streetToAeronaAddressPair(orig1);
        System.debug(ap);
        System.assert(ap.address1 == orig1);
        System.assert(ap.address2 == null);
        String street = ExternalSyncPatientsToAerona.addressPairToStreet(ap.address1, ap.address2);
        System.debug(street);
        System.assert(street == orig1);


        String orig2 = '18 Mable Street, Baron Court';
        ap = ExternalSyncPatientsToAerona.streetToAeronaAddressPair(orig2);
        System.debug(ap);
        System.assert(ap.address1 == '18 Mable Street');
        System.assert(ap.address2 == 'Baron Court');
        street = ExternalSyncPatientsToAerona.addressPairToStreet(ap.address1, ap.address2);
        System.debug(street);
        System.assert(street == '18 Mable Street; Baron Court');


        String orig3 = '18 Mable Street,Baron Court';
        ap = ExternalSyncPatientsToAerona.streetToAeronaAddressPair(orig3);
        System.debug(ap);
        System.assert(ap.address1 == '18 Mable Street');
        System.assert(ap.address2 == 'Baron Court');
        street = ExternalSyncPatientsToAerona.addressPairToStreet(ap.address1, ap.address2);
        System.debug(street);
        System.assert(street == '18 Mable Street; Baron Court');

        String orig4 = '18 Mable Street and a very long add ,  Baron Court with another very loing arafsad';
        ap = ExternalSyncPatientsToAerona.streetToAeronaAddressPair(orig4);
        System.debug(ap);
        System.assert(ap.address1 == '18 Mable Street and a very long add');
        System.assert(ap.address2 == 'Baron Court with another very loing arafsad');
        street = ExternalSyncPatientsToAerona.addressPairToStreet(ap.address1, ap.address2);
        System.debug(street);
        System.assert(street == '18 Mable Street and a very long add; Baron Court with another very loing arafsad');

        String orig5 = '18 Mable Street and a very long add very over 45,  Baron Court with another very loing arafsad very over 45';
        ap = ExternalSyncPatientsToAerona.streetToAeronaAddressPair(orig5);
        System.debug(ap);
        System.assert(ap.address1 == '18 Mable Street and a very long add very ove');
        System.assert(ap.address2 == 'Baron Court with another very loing arafsad');
        street = ExternalSyncPatientsToAerona.addressPairToStreet(ap.address1, ap.address2);
        System.debug(street);
        System.assert(street == '18 Mable Street and a very long add very ove; Baron Court with another very loing arafsad');


        String orig6 = '18 Mable Street, Baron Court, Some region';
        ap = ExternalSyncPatientsToAerona.streetToAeronaAddressPair(orig6);
        System.debug(ap);
        System.assert(ap.address1 == '18 Mable Street');
        System.assert(ap.address2 == 'Baron Court, Some region');
        street = ExternalSyncPatientsToAerona.addressPairToStreet(ap.address1, ap.address2);
        System.debug(street);
        System.assert(street == '18 Mable Street; Baron Court, Some region');

        String orig7 = '18 Mable Street; 18 Mable Street Baron Court';
        ap = ExternalSyncPatientsToAerona.streetToAeronaAddressPair(orig7);
        System.debug(ap);
        street = ExternalSyncPatientsToAerona.addressPairToStreet(ap.address1, ap.address2);
        System.debug(street);
    }

    @IsTest
    static void publishIntegrationLog_test() {
        ExternalSyncPatients.publishIntegrationLog(true, '00326000014mOFsAAM', 'test operation', 'request json', 'response json', 201);
    }

}