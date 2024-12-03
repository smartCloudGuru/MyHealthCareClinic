/**
 * Created 8.12.2022..
 */

public without sharing class ExternalSyncPatientsToAerona {
    public static String createPatientOnAerona(Account patient) {

        if (patient.Date_of_Birth__c == null) {
            System.debug(LoggingLevel.WARN, 'AE: unable to create patient without DOB: ' + patient.Id);
            return null;
        }

        //[2023-05] Before doing create, check if a patient with same email and DOB already exists

        try {
            List<AeronaServiceOASApi.OASDuplicatePatient> existingPatients = AeronaService.searchPatient(patient.PersonEmail?.trim(), patient.Date_of_Birth__c);

            if (existingPatients != null && existingPatients.size() > 0 && existingPatients[0] != null && existingPatients[0].patientId != null) {
                String ret = String.valueOf(existingPatients[0].patientId);
                System.debug(LoggingLevel.INFO, '**dbg AE: returning: ' + ret);
                return ret;
            }
        }
        catch (Exception ex) {
            System.debug(LoggingLevel.WARN, 'AE: patient search threw: ' + ex.getMessage());
        }

        // create on aerona
        AeronaServiceOASApi.OASCreatePatientRequest request = new AeronaServiceOASApi.OASCreatePatientRequest();
        request.forename = patient.FirstName;
        request.surname = patient.LastName;
        request.dob = patient.Date_of_Birth__c;
        request.emailAddress = patient.PersonEmail?.trim();
        request.genderId = mapToAeronaGender(patient.Gender__c); //1 - Male, 2 - Female
        request.forceCreate = true;

        if (String.isNotBlank(patient.BillingStreet)) {
            ExternalSyncPatientsToAerona.AddressPair ap = streetToAeronaAddressPair(patient.BillingStreet);
            request.address1 = ap.address1;
            request.address2 = ap.address2;
        }

        if (String.isNotBlank(patient.BillingCity)) request.address3 = patient.BillingCity;
        if (String.isNotBlank(patient.BillingState)) request.address4 = patient.BillingState;
        if (String.isNotBlank(patient.BillingPostalCode)) request.code = patient.BillingPostalCode;
        request.mobileNumber = patient.PersonMobilePhone;
        request.patientTypeId = 1;

        AeronaServiceOASApi.OASCreatePatientResponse resp = AeronaService.createPatient(request);

        if (resp != null) {
            // [2023-03-30 removed this as it's causing using incorrect patientIds
            //            if (resp.hasDuplicates()) {
            //                patient.Aerona_Id__c = '' + resp.duplicatePatients[0].patientId;
            //            }
            //            else
            if (resp.id != null) {
                patient.Aerona_Id__c = '' + resp.id;
            }
        }

        return patient.Aerona_Id__c;
    }

    public static String updatePatientOnAerona(Account patient) {

        AeronaServiceOASApi.OASUpdatePatientRequest request = new AeronaServiceOASApi.OASUpdatePatientRequest();

        // update on aerona
        request.forename = patient.FirstName;
        request.surname = patient.LastName;
        request.dob = patient.Date_of_Birth__c;
        request.emailAddress = patient.PersonEmail?.trim();
        request.genderId = mapToAeronaGender(patient.Gender__c); //1 - Male, 2 - Female

        if (String.isNotBlank(patient.BillingStreet)) {
            ExternalSyncPatientsToAerona.AddressPair ap = streetToAeronaAddressPair(patient.BillingStreet);
            request.address1 = ap.address1;
            request.address2 = ap.address2;
        }

        if (String.isNotBlank(patient.BillingCity)) request.address3 = patient.BillingCity;
        if (String.isNotBlank(patient.BillingState)) request.address4 = patient.BillingState;
        if (String.isNotBlank(patient.BillingPostalCode)) request.code = patient.BillingPostalCode;
        request.mobileNumber = patient.PersonMobilePhone;
        if (patient.Aerona_PatientTypeId__c != null) request.patientTypeId = (Long) patient.Aerona_PatientTypeId__c;
        if (request.patientTypeId == null) request.patientTypeId = 1;
        if (patient.Aerona_Practice_Id__c != null) request.practiceId = Long.valueOf(patient.Aerona_Practice_Id__c);

        Boolean resp = AeronaService.updatePatient(patient.Aerona_Id__c, request);

        if (resp == null || resp == false) return null;

        return patient.Aerona_Id__c;
    }


    public static Long mapToAeronaGender(String gender) {
        if (String.isNotBlank(gender)) {
            if (gender == 'Male') return 1;
            if (gender == 'Female') return 2;
        }
        return null;
    }

    public static String mapFromAeronaGender(String gender) {
        if (String.isNotBlank(gender)) {
            if (gender == '1') return 'Male';
            if (gender == '2') return 'Female';
        }
        return null;
    }

    public class AddressPair {
        public String address1;
        public String address2;

        public AddressPair() {

        }
        public AddressPair(String address1, String address2) {
            this.address1 = address1;
            this.address2 = address2;
        }
    }

    public static AddressPair streetToAeronaAddressPair(String street) {
        if (street == null) return new AddressPair(null, null);

        AddressPair ret = new AddressPair();

        if (street.indexOf(';') >= 0) {
            ret.address1 = street.substring(0, street.indexOf(';'));
            ret.address2 = street.substring(street.indexOf(';') + 1);
        }
        else {
            String st = street.replaceFirst(',', '!#!');
            List<String> addParts = st.split('!#!');

            if (addParts.size() > 0) ret.address1 = addParts.get(0);
            if (addParts.size() > 1) ret.address2 = addParts.get(1);
        }

        ret.address1 = sanitizeStreet(ret.address1);
        ret.address2 = sanitizeStreet(ret.address2);

        if (ret.address1 != null && ret.address1.length() > 45) ret.address1 = ret.address1.substring(0, 44).trim();
        if (ret.address2 != null && ret.address2.length() > 45) ret.address2 = ret.address2.substring(0, 44).trim();

        if (ret.address1 != null && ret.address2 != null && ret.address1.length() > 0 && ret.address2.length() > 0) {
            if (ret.address1.indexOf(ret.address2) >= 0) ret.address2 = null;
        }

        if (ret.address1 != null && ret.address2 != null && ret.address1.length() > 0 && ret.address2.length() > 0) {
            if (ret.address2.indexOf(ret.address1) >= 0) {
                ret.address1 = ret.address2;
                ret.address2 = null;
            }
        }
        return ret;
    }

    public static String addressPairToStreet(String address1, String address2) {
        address1 = sanitizeStreet(address1);
        address2 = sanitizeStreet(address2);

        if (String.isNotBlank(address1) && String.isNotBlank(address2)) {
            return address1 + '; ' + address2;
        }
        else if (String.isNotBlank(address1)) {
            return address1;
        }
        else if (String.isNotBlank(address2)) {
            return address2;
        }

        return null;
    }


    public static String sanitizeStreet(String street) {
        if (String.isBlank(street)) return null;
        street = street.replace(', London', '');
        street = street.replace(', United Kingdom', '');
        street = street.replace('  ', ' ');
        street = street.replace(' , ', ', ');
        street = street.trim();
        return street;
    }

}