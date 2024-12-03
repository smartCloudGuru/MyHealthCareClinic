/**
 * Created 28.9.2021..
 */

public with sharing class Covid_Test_Certificate_Controller {

    private final COVID_Test__c ctest;

    public Covid_Test_Certificate_Controller(ApexPages.StandardController controller) {
        //this.ctest = (COVID_Test__c) controller.getRecord();
        if (controller != null) {
            this.ctest = [
                    SELECT Id,
                            Swab_Collection_Date__c,
                            Scheduled_Appointment__r.SchedStartTime
                    FROM COVID_Test__c
                    WHERE Id = :controller.getRecord().Id
            ];
        }

    }

    public String getFormattedSwabDateTime() {
        if (this.ctest.Swab_Collection_Date__c != null) {
            return formatAsLondonTime(this.ctest.Swab_Collection_Date__c);
        }
        else if (this.ctest?.Scheduled_Appointment__r?.SchedStartTime != null) {
            return formatAsLondonTime(this.ctest.Scheduled_Appointment__r.SchedStartTime);
        }
        else {
            return formatAsLondonTime(Datetime.now());
        }
    }

    public Boolean getLivingWithCovid()
    {
        return (Date.today()>=Date.newInstance(2022,2,24));
    }

    private String formatAsLondonTime(Datetime dt) {
        return dt.format('dd-MMM-yyy \'at\' HH:mm', 'Europe/London');
    }


}