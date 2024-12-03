public without sharing class AppointmentTypeMatcher {
    private static IntegrationErrorReporter errorReporter = new IntegrationErrorReporter();

    private List<String> appointmentTypes;

    public AppointmentTypeMatcher() {
        this.appointmentTypes = new List<String>();
    }

    public void addAppointmentType(String type) {
        this.appointmentTypes.add(type.trim());
    }

    public void addAppointmentTypes(List<String> types) {
        for (String type : types) {
            this.addAppointmentType(type);
        }
    }

    public Map<String, Id> getAppointmentTypeIds() {
        Map<String, Id> appointmentTypesById = new Map<String, Id>();

        List<Appointment_Type__c> existingTypes = [
            SELECT Id, Name
            FROM Appointment_Type__c
            WHERE Name IN :this.appointmentTypes
        ];

        for (Appointment_Type__c type : existingTypes) {
            appointmentTypesById.put(type.Name, type.Id);
        }

        System.debug(existingTypes);

        Set<String> resultTypes = new Set<String>(this.appointmentTypes);
        System.debug(resultTypes);
        resultTypes.removeAll(appointmentTypesById.keySet());
        System.debug(resultTypes);

        if (!resultTypes.isEmpty()) {
            errorReporter.addWarning(
                'Missing Appointment Types',
                null,
                null,
                null,
                resultTypes.toString()
            );

            List<Appointment_Type__c> newTypes = createMissingAppoinmentTypes(resultTypes);

            for (Appointment_Type__c type : newTypes) {
                if (type.Id != null) {
                    appointmentTypesById.put(type.Name, type.Id);
                }
            }
        }

        return appointmentTypesById;
    }

    private List<Appointment_Type__c> createMissingAppoinmentTypes(Set<String> types) {
        List<Appointment_Type__c> newTypes = new List<Appointment_Type__c>();

        for (String typeName : types) {
            newTypes.add(new Appointment_Type__c(Name = typeName.trim()));
        }

        List<Database.SaveResult> saveResults = Database.insert(newTypes, false);

        for (Integer i = 0; i < saveResults.size(); i++) {
                Database.SaveResult result = saveResults[i];

                if (!result.isSuccess()) {
                    Appointment_Type__c failedRecord = newTypes[i];

                    errorReporter.addError(
                        'Create Appointment Types',
                        null,
                        result.getErrors()[0].getMessage(),
                        null,
                        JSON.serialize(failedRecord)
                    );
                }
        }

        return newTypes;
    }
}