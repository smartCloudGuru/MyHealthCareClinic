public class HeyDocBooking {
    private static final String DID_NOT_ARRIVE_STATUS = 'DNA';
    private static final String DEPARTED_STATUS = 'Discharged';
    private static final String ARRIVED_STATUS = 'Arrived';
    private static final String DEFAULT_STATUS = 'NotArrived';

    public String id;
    public String cancellationReason;
    public String doctorName;
    public String doctorId;
    public Appointment appointment;
    public Journey bookingJourney;
    public Location location;
    public DateTime start;
    public DateTime endTime;
    public Patient patient;
    public String patientId;
    public DateTime createdAt;
    public List<Phone> phones;
    public String comments;
    public String bookingType;
    public String videoUrl;

    /*
    public Account getPatient(Id patientId) {
        Account patient = new Account(
            Id = patientId,
            HeyDoc_Id__c = this.patientId,
            PersonEmail = this.patient.email,
            Date_of_Birth__c = this.patient?.dob?.date(),
            PersonBirthdate = this.patient?.dob?.date()
        );

        if (this.patient?.phones != null && !this.patient?.phones.isEmpty()) {
            for (Phone phoneDetail : this.patient.phones) {
                if (phoneDetail.phoneType == 'Mobile') {
                    patient.PersonMobilePhone = phoneDetail.phoneNumber;
                } else {
                    patient.Phone = phoneDetail.phoneNumber;
                }
            }
        }

        return patient;
    }
*/
    /*
    public Account getPatient() {
        Account patient = new Account(
            HeyDoc_Id__c = this.patientId,
            FirstName = this.patient.firstName,
            LastName = this.patient.lastName,
            PersonEmail = this.patient.email,
            Date_of_Birth__c = this.patient?.dob?.date(),
            PersonBirthdate = this.patient?.dob?.date(),
            BillingStreet = this.patient?.address?.address,
            BillingCity = this.patient?.address?.city,
            BillingPostalCode = this.patient?.address?.postcode,
            BillingCountry = this.patient?.address?.country,
            RecordTypeId = PatientMatcher.PERSON_ACCOUNT_RECORD_TYPE_ID
        );

        if (this.patient?.phones != null && !this.patient?.phones.isEmpty()) {
            for (Phone phoneDetail : this.patient.phones) {
                if (phoneDetail.phoneType == 'Mobile') {
                    patient.PersonMobilePhone = phoneDetail.phoneNumber;
                } else {
                    patient.Phone = phoneDetail.phoneNumber;
                }
            }
        }

        return patient;
    }
    */

/*
    public Proposed_Appointment__c getAppointment() {
        Proposed_Appointment__c appointment = new Proposed_Appointment__c(
            HeyDoc_Id__c = this.id,
            Start__c = this.start,
            Finish__c = this.endTime,
            Patient__r = new Account(HeyDoc_Id__c = this.patientId),
            ArrivalTime__c = this.bookingJourney?.arrived,
            DepatureTime__c = this.bookingJourney?.departed,
            DnaTime__c = this.bookingJourney?.dna
        );

        if (this.bookingJourney?.dna != null) {
            appointment.State__c = DID_NOT_ARRIVE_STATUS;
        } else if (this.bookingJourney?.departed != null) {
            appointment.State__c = DEPARTED_STATUS;
        } else if (this.bookingJourney?.arrived != null) {
            appointment.State__c = ARRIVED_STATUS;
        } else {
            appointment.State__c = DEFAULT_STATUS;
        }

        return appointment;
    }
    */


//    public static List<HeyDocBooking> parseBookings(String jsonString) {
//        jsonString = jsonString.replaceAll('end', 'endTime');
//        JSONParser parser = JSON.createParser(jsonString);
//
//        List<HeyDocBooking> bookings = new List<HeyDocBooking>();
//
//        while (parser.nextToken() != null) {
//            if (
//                parser.getCurrentName() == 'data' &&
//                parser.getCurrentToken() == JSONToken.START_ARRAY
//            ) {
//                while (parser.nextToken() != JSONToken.END_ARRAY) {
//                    HeyDocBooking parsedBooking = (HeyDocBooking) parser.readValueAs(
//                        HeyDocBooking.class
//                    );
//
//                    if (parsedBooking.patient != null) {
//                        bookings.add(parsedBooking);
//                    }
//                }
//            }
//        }
//
//        return bookings;
//    }

    public class Patient {
        public String id;
        public String status;
        public String firstName;
        public String lastName;
        public DateTime dob;
        public String gender;
        public String sex;
        public String email;
        public List<Phone> phones;
        public String occupation;
        public Address address;
        public String membershipName;
        public Date membershipStartDate;
        public String accountNumber;
    }

    public class Appointment {
        public String title;
        public Integer duration;
        public Decimal price;
    }

    public class Phone {
        public String phoneType;
        public String phoneNumber;
    }

    public class Address {
        public String address;
        public String city;
        public String postcode;
        public String country;
    }

    public class Journey {
        public Datetime arrived;
        public Datetime consultation;
        public Datetime departed;
        public Datetime dna;
    }

    public class Location {
        public String id;
        public String name;
    }
}