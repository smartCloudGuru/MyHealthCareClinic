public without sharing class TH_CovidTest_CalculateDates extends AnthologyTriggerHandler.DelegateBase {

    Map<Id, ServiceAppointment> serviceAppointmentsMap;

    public TH_CovidTest_CalculateDates(AnthologyTriggerHandler.AnthologyTriggerContext anthTriggerContext) {
        this.anthTriggerContext = anthTriggerContext;
        name = 'TH_CovidTest_CalculateDates';
        skipLoop = false;
    }

    public override void prepareBefore() {
        serviceAppointmentsMap = new Map<Id, ServiceAppointment>();

        if (anthTriggerContext != null) {
            List<Id> scheduledAppointmentIds = new List<Id>();

            // if before insert or update
            if (anthTriggerContext.triggerOperation == TriggerOperation.BEFORE_INSERT || anthTriggerContext.triggerOperation == TriggerOperation.BEFORE_UPDATE) {
                if (anthTriggerContext.newList != null) {
                    for (SObject o : anthTriggerContext.newList) {
                        COVID_Test__c ctest = (COVID_Test__c) (o);
                        if (ctest.Scheduled_Appointment__c != null) {
                            scheduledAppointmentIds.add(ctest.Scheduled_Appointment__c);
                        }
                    }
                }
            }

            if (scheduledAppointmentIds.size() > 0) {
                List <ServiceAppointment> serviceAppointments = [SELECT Id, SchedStartTime FROM ServiceAppointment WHERE Id IN :scheduledAppointmentIds];
                for (ServiceAppointment sc : serviceAppointments) {
                    serviceAppointmentsMap.put(sc.Id, sc);
                }
            }
        }
    }

    public override void beforeInsert(SObject o) {
        calculateResultsDue(o);
    }
    public override void beforeUpdate(SObject old, SObject o) {
        calculateResultsDue(o);
    }

    @TestVisible
    private Datetime calculateResultsDue(SObject o) {
        COVID_Test__c ctest = (COVID_Test__c) (o);

        if (ctest.Scheduled_Appointment__c != null) {

            if (serviceAppointmentsMap != null && serviceAppointmentsMap.get(ctest.Scheduled_Appointment__c) != null) {
                Datetime dt = serviceAppointmentsMap.get(ctest.Scheduled_Appointment__c).SchedStartTime;
                if (dt != null && ctest.Turnaround_Time_Global__c != null) {
                    if (ctest.Turnaround_Time_Global__c.toLowerCase() == '4 hour') {
                        ctest.Results_Due__c = dt.addHours(4);
                    }
                    else if (ctest.Turnaround_Time_Global__c.toLowerCase() == 'same day') {
                        //cutoff is at 22:00
                        ctest.Results_Due__c = dt.addHours(21 - dt.hour()).addMinutes(59 - dt.minute());
                    }
                    else if (ctest.Turnaround_Time_Global__c.toLowerCase() == 'next day') {
                        //cutoff is at 22:00
                        ctest.Results_Due__c = dt.addDays(1).addHours(21 - dt.hour()).addMinutes(59 - dt.minute());
                    }
                }
            }
        }

        return null;

    }

}