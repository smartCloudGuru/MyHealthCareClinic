/**
* @author Zoran Zunko
* @date 5/13/21
*
*/

public without sharing class eml_ConfEmailCtrl {
    public Id recId {
        get;
        set {
            this.recId = value;
            setAllItems();
        }
    }

    public Boolean hasTests { get; set; }
    public Boolean hasHomeTestProducts { get; set; }

    public Boolean icClickCollect { get; set; }
    public ServiceTerritory pickupLocation { get; set; }

    public Opportunity customerOrder { get; set; }
    public List<OpportunityLineItem> customerOrderItems { get; set; }
    public List<OpportunityLineItemWrapper> oliCovidTestItems { get; set; }
    public List<OpportunityLineItemWrapper> oliHomeKitItems { get; set; }

    public void setAllItems() {
        if (recId != null) {
            customerOrder = [
                    SELECT
                            Id,
                            Account.Name,
                            Account.PersonEmail,
                            CloseDate,
                            Amount,
                            Store_Site_URL__c,
                            Online_Order_Number__c,
                            Click_and_Collect__c,
                            Pickup_Location__c,
                            UUID__c
                    FROM Opportunity
                    WHERE Id = :recId
            ];
            if (customerOrder.Amount<0) customerOrder.Amount = 0;
            customerOrderItems = [
                    SELECT
                            Id,
                            Quantity,
                            Product2.Name,
                            Product2.Is_Home_Test__c,
                            Product2.Requires_scheduling__c,
                            UnitPrice,
                            Name, (
                            SELECT
                                    Id,
                                    Test_Type__c,
                                    Booking_Reference__c,
                                    Home_Test_Result_URL__c,
                                    Turnaround_Time_Global__c,
                                    Appointment_Date__c,
                                    Scheduled_Appointment__r.SchedStartTime,
                                    Scheduled_Appointment__r.SchedEndTime,
                                    Scheduled_Appointment__r.ServiceTerritory.Name,
                                    Scheduled_Appointment__r.ServiceTerritory.City,
                                    Scheduled_Appointment__r.ServiceTerritory.Street,
                                    Scheduled_Appointment__r.ServiceTerritory.PostalCode,
                                    Scheduled_Appointment__r.ServiceTerritory.State,
                                    Scheduled_Appointment__r.ServiceTerritory.Patient_Instructions__c,
                                    Provided_First_Name__c,
                                    Provided_Last_Name__c,
                                    Test_Schedule_Link__c,
                                    Test_Details_Link__c,
                                    Name
                            FROM COVID_Tests__r
                            ORDER BY Booking_Reference__c ASC
                    )
                    FROM OpportunityLineItem
                    WHERE OpportunityId = :recId
                    ORDER BY Product2.Name
            ];

            // C&C section
            if (customerOrder.Click_and_Collect__c)
            {
                icClickCollect = true;

                try {
                    pickupLocation = [
                            SELECT Id, Street,
                                    City,
                                    Name,
                                    PostalCode,
                                    State
                            FROM ServiceTerritory
                            WHERE Id = :customerOrder.Pickup_Location__c
                    ];
                    if (pickupLocation.Street !=null) pickupLocation.Street = pickupLocation.Street.replaceAll('\n','<br/>');
                }
                catch (Exception ex) {
                    icClickCollect = false;
                }
            }

            oliCovidTestItems = new List<OpportunityLineItemWrapper>();
            oliHomeKitItems = new List<OpportunityLineItemWrapper>();

            for (OpportunityLineItem oli : customerOrderItems) {
                if (oli.Product2 != null && oli.Product2.Is_Home_Test__c)
                {
                    this.hasHomeTestProducts = true;
                    oliHomeKitItems.add(new OpportunityLineItemWrapper(oli));
                }
                else if (oli.Product2 != null && oli.Product2.Requires_scheduling__c)
                {
                    this.hasTests = true;
                    oliCovidTestItems.add(new OpportunityLineItemWrapper(oli));
                }
            }
        }

    }

    public eml_ConfEmailCtrl() {
        setAllItems();
    }

    public class OpportunityLineItemWrapper {
        public Boolean isCovidTest { get; set; }
        public Boolean isProduct { get; set; }
        public Boolean isHomeTestKit { get; set; }
        public Boolean isAppointment { get; set; }
        public OpportunityLineItem item { get; set; }
        public List<TestWrapper> testWrapper { get; set; }
        public OpportunityLineItemWrapper(OpportunityLineItem oli) {

            this.item = oli;
            this.testWrapper = new List<TestWrapper>();
            for (COVID_Test__c test : oli.COVID_Tests__r) {
                testWrapper.add(new TestWrapper(test));
            }

            this.isCovidTest = false;
            this.isAppointment = false;
            this.isHomeTestKit = false;
            this.isProduct = false;

            if (testWrapper.size()>0 && oli.Product2 != null && oli.Product2.Is_Home_Test__c)
            {
                this.isHomeTestKit = true;
            }
            else if (testWrapper.size()>0 && oli.Product2 != null && oli.Product2.Requires_scheduling__c)
            {
                 this.isCovidTest = true;
            }
            else
            {
                this.isProduct = true;
            }
        }
    }

    public class TestWrapper {
        public COVID_Test__c test { get; set; }
        public String formattedSchedStartTime { get; set; }
        public String calendarUrlGoogle { get; set; }
        public String calendarUrlYahoo { get; set; }
        public Boolean isScheduled { get; set; }

        public TestWrapper(COVID_Test__c test) {
            this.test = test;
            String title = EncodingUtil.urlEncode((this.test.Test_Type__c != null ? this.test.Test_Type__c : 'COVID Test'), 'UTF-8');
            String startTime;
            String endTime;
            String location = '';
            String locationEncoded = '';

            this.isScheduled = (test != null && test.Scheduled_Appointment__r != null && test.Scheduled_Appointment__r.SchedStartTime != null);

            if (test != null && test.Scheduled_Appointment__r != null && test.Scheduled_Appointment__r.SchedStartTime != null) {
                this.formattedSchedStartTime = test.Scheduled_Appointment__r.SchedStartTime.format('HH:mm MMMM d, yyyy', 'Europe/London');

                //start time
                startTime = this.formatTime(this.test.Scheduled_Appointment__r.SchedStartTime);
                endTime = this.formatTime(this.test.Scheduled_Appointment__r.SchedEndTime);

                try {
                    if (this.test.Scheduled_Appointment__r.ServiceTerritory != null) {
                        location = this.test.Scheduled_Appointment__r.ServiceTerritory.Name;
                        if (this.test.Scheduled_Appointment__r.ServiceTerritory.Street != null) {
                            location = location + ', ' + this.test.Scheduled_Appointment__r.ServiceTerritory.Street;
                            location = location + ', ' + this.test.Scheduled_Appointment__r.ServiceTerritory.PostalCode;
                            location = location + ', ' + this.test.Scheduled_Appointment__r.ServiceTerritory.City;
                        }

                        locationEncoded = EncodingUtil.urlEncode(location, 'UTF-8');
                    }
                }
                catch (Exception ignore) {
                }
            }

            this.calendarUrlGoogle =
                    'https://www.google.com/calendar/render?action=TEMPLATE'
                            + '&text=' + title
                            + '&dates=' + startTime + '%2F' + endTime
                            + '&location=' + locationEncoded;

            // yahoo times, remove timezone
            this.calendarUrlYahoo = 'https://calendar.yahoo.com/?v=60'
                    + '&et=' + formatTime(test?.Scheduled_Appointment__r?.SchedEndTime)
                    + '&st=' + formatTime(test?.Scheduled_Appointment__r?.SchedStartTime)
                    + '&in_loc=' + locationEncoded
                    + '&title=' + title;

        }

        private String formatTime(Datetime dt) {
            if (dt == null) return '';
            return dt.format('yyyyMMdd\'T\'HHmm00', 'Europe/London');
        }
    }


}