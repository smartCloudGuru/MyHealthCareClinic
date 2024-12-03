public without sharing class PatientMatcher {

    public static final Id PERSON_ACCOUNT_RECORD_TYPE_ID = Cache.recordTypeId(AccountManager.RT_PERSON_ACCOUNT);

    private List<String> emails;
    private List<String> externalIds;
    private Schema.SObjectField externalIdField;

    public PatientMatcher() {
        this.emails = new List<String>();
        this.externalIds = new List<String>();
    }

    public void setExternalIdField(Schema.SObjectField externalIdField) {
        this.externalIdField = externalIdField;
    }

    public void addEmail(String email) {
        this.emails.add(email);
    }

    public void addEmails(List<String> emailAddresses) {
        this.emails.addAll(emailAddresses);
    }

    public void addExternalId(String externalId) {
        this.externalIds.add(externalId);
    }

    public void addExternalIds(List<String> externalIds, Schema.SObjectField externalIdField) {
        this.externalIdField = externalIdField;
        this.externalIds.addAll(externalIds);
    }

    public Map<String, Account> getPatients() {
        Map<String, Account> matchedPatients = new Map<String, Account>();

        List<String> queryEmails = this.emails;
        List<String> queryExternalIds = this.externalIds;

        String queryExternalIdField = this.externalIdField?.getDescribe().getName();

        String queryFieldsToken = 'Id, PersonEmail, PersonMobilePhone, Phone, PersonBirthdate, Date_of_Birth__c, CreatedDate ';
        String queryWhereClause = '(PersonEmail IN: queryEmails';

        if (queryExternalIdField != null) {
            queryFieldsToken += ', ' + queryExternalIdField;
            queryWhereClause += ' OR ' + queryExternalIdField + ' IN :queryExternalIds)';
        } else {
            queryWhereClause += ')';
        }

        List<String> queryTokens = new List<String>{
            'SELECT',
            queryFieldsToken,
            'FROM Account',
            'WHERE',
            queryWhereClause,
            'AND RecordTypeId =: PERSON_ACCOUNT_RECORD_TYPE_ID',
            'ORDER BY CreatedDate DESC'
        };

        List<Account> queryResults = Database.query(String.join(queryTokens, ' '));

        for (Account matchedPatient : queryResults) {
            String externalId = (String) matchedPatient.get(queryExternalIdField);
            String email = matchedPatient.PersonEmail;

            matchedPatients.put(email, matchedPatient);

            if (externalId != null) {
                matchedPatients.put(externalId, matchedPatient);
            }
        }

        return matchedPatients;
    }
}