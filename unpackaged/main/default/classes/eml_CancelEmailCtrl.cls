/**
* @author Zoran Zunko
* @date 5/13/21
*
*/

public without sharing class eml_CancelEmailCtrl {
    public Id recId {
        get;
        set {
            this.recId = value;
            loadRecord();
        }

    }

    public String dateAndTime { get; set; }
    public String location { get; set; }
    public String patientName { get; set; }
    public String nowDateAndTime { get; set; }

    private String formatTime(Datetime dt) {
        if (dt == null) return '';
        return dt.format('HH:mm \'on\' dd MMMM yyyy', 'Europe/London');
    }

    public void loadRecord() {

        if (recId != null) {
            ServiceAppointment app =
            [
                    SELECT Id,
                            Account.Name,
                            ServiceTerritory.Name,
                            SchedStartTime

                    FROM ServiceAppointment
                    WHERE Id = :recId
            ];

            dateAndTime = formatTime(app.SchedStartTime);
            location = app.ServiceTerritory.Name;
            patientName = app.Account.Name;
            nowDateAndTime = formatTime(Datetime.now());
        }

    }
}