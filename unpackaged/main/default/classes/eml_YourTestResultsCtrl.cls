/**
* @author Zoran Zunko
* @date 5/13/21
*
*/

public without sharing class eml_YourTestResultsCtrl {
    public Id recId {
        get;
        set {
            this.recId = value;
            loadRecord();
        }

    }

    public Boolean isPcrAndUnclear  { get; set; }
    public Boolean isAntigenAndUnclear  { get; set; }
    public String patientName { get; set; }
    public String birthDate { get; set; }
    public String resultStatus { get; set; }
    public COVID_Test__c ctest { get; set; }

    private String formatTime(Datetime dt) {
        if (dt == null) return '';
        return dt.format('dd MMMM yyyy', 'Europe/London');
    }

    public void loadRecord() {

        if (recId != null) {
            ctest =
            [
                    SELECT Id,
                            Provided_Date_of_Birth__c,
                            Provided_First_Name__c,
                            Provided_Last_Name__c,
                            COVID_Test_Status__c,
                            Test_Type__c,
                            Turnaround_Time_Global__c,
                            COVID_Test_Method__c
                    FROM COVID_Test__c
                    WHERE Id = :recId
            ];

            birthDate = formatTime(ctest.Provided_Date_of_Birth__c);
            patientName = ctest.Provided_First_Name__c + ' ' + ctest.Provided_Last_Name__c;
            resultStatus = ctest.COVID_Test_Status__c;


            isPcrAndUnclear = (ctest.COVID_Test_Method__c == 'PCR') && (resultStatus == 'Unclear');
            isAntigenAndUnclear = (ctest.COVID_Test_Method__c == 'Antigen') && (resultStatus == 'Unclear');
        }


    }
}