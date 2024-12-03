/**
 * Created by Atlas on 27.01.2021.
 */

public class AeronaAppointment {

    public class login {
        public string username {get; set;}
        public string password {get; set;}
        public string pin {get; set;}
    }

    public class Response {

        public string status { get; set; }
        public string result { get ; set; }
        public string errorResult { get; set; }
        //public string errorcode { get; set;}

    }

    public class AppointmentTypeRequest {
        public string practiceId { get; set; }
    }

    public class AppointmentTypeResult{
        public string status { get; set;}
        public List<AppointmentType> result {get; set;}
        public string errorResult {get; set;}
        public string errorCode {get; set;}
    }

    public class AppointmentType {
        public string id { get; set;}
        public string type { get; set;}
        public string duration {get; set;}
        public string enabled {get; set;}
    }


    public class Appointment {
        public string appointmentId {get; set; }
        public string siteName { get; set; }
        public string practiceId { get; set; }
        public string patientId { get; set; }
        public string userId { get; set; }
        public string AppointmentTypename { get; set; }
        public string appointmentTypeId{ get; set; }
        public string appointmentStatus {get; set; }
        public string appointmentStatusId {get; set; }
        public String appointmentTime {get; set;}
        public string appointmentNotes {get; set; }
        public string emergency {get; set; }
        public string duration {get; set; }

        public Appointment(String appointmentStatusId){

            switch on appointmentStatusId {
                when  '1' {
                    this.appointmentStatus = 'Unconfirmed';
                }
                when '2'{
                    this.appointmentStatus = 'Confirmed';
                }
                when '3'{
                    this.appointmentStatus = 'Arrived';
                }
                when '4'{
                    this.appointmentStatus = 'Failed to Attend';
                }
                when '5'{
                    this.appointmentStatus = 'Cancelled by Practice';
                }
                when '6'{
                    this.appointmentStatus= 'In Clinic';
                }
                when '7'{
                    this.appointmentStatus = 'Completed';
                }
                when '8'{
                    this.appointmentStatus = 'Online Booking Request';
                }
                when '9'{
                    this.appointmentStatus = 'Reminder Sent';
                }
                when '10'{
                    this.appointmentStatus = 'Scheduled';
                }
                when '11'{
                    this.appointmentStatus = 'Unscheduled';
                }
                when '12'{
                    this.appointmentStatus =  'Cancelled By Patient';
                }
                when '13'{
                    this.appointmentStatus = 'Deleted';
                }
                when '14'{
                    this.appointmentStatus = 'Late Cancellation';
                }
            }
        }
    }
}