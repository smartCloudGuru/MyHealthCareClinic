/**
     Author:        Paul Lucas
     Company:       Salesforce
     Description:   qsyd_InvocableEmailTemplateAction - Lightning Flow and Process Builder invocable action calling the Messaging.sendEmail API enabling a template based messages.
                    Optionally allows tracking of sent emails.

     Date:          25-Apr-2018
     Reference:     https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_email_outbound_single.htm
     Test Class:    qsyd_InvocableEmailTemplateActionTest

     Usage:         Refer to qsyd_InvocableEmailTemplateActionTest methods
     History:
     When           Who                 What

     TODO:
        - Use custom labels for error messages
 */

global without sharing class qsyd_InvocableEmailTemplateAction extends qsyd_InvocableEmailBase {

    /**
     * Send Email using a Template
     *
     * @param params
     *
     * @return
     */
    @InvocableMethod(Label='QSyd - Invocable Email Template Action' Description='Invoke Messaging.sendEmail to send a template based message')
    public static List<qsyd_InvocableEmailResult> sendEmail(List<InvocableEmailParam> params) {
        List<qsyd_InvocableEmailResult> results = new List<qsyd_InvocableEmailResult>();

        for (InvocableEmailParam invocableEmailParameters : params) {

            // Construct an email message instance, establish if send exceptions should be thrown to caller.
            newEmailMessage(invocableEmailParameters.throwException);

            // Set recipients
            setTargetObjectId(invocableEmailParameters.targetObject);
            setToAddresses(invocableEmailParameters.toAddresses);
            setCcAddresses(invocableEmailParameters.ccAddresses);
            setBccAddresses(invocableEmailParameters.bccAddresses);

            // Set message properties
            try {
                setTemplateId(invocableEmailParameters.emailTemplateId);
            }
            catch (Exception ex) {
                throw new InvocableEmailException('failed to retrieve template by id ' + ex.getMessage());
            }
            setCharset(invocableEmailParameters.characterSet);
            setEntityAttachments(invocableEmailParameters.attachments);
            setTreatBodiesAsTemplate(invocableEmailParameters.treatAsTemplate);
            setTreatTargetObjectAsRecipient(invocableEmailParameters.treatAsRecipient);

            // Set email properties
            setWhatId(invocableEmailParameters.what);

            //todo
            setICSAttachments(invocableEmailParameters.generateICS);

            setInReplyTo(invocableEmailParameters.parentMessages);
            setOptOutPolicy(invocableEmailParameters.optOutPolicy);
            try {
                setOrgWideEmailAddressId(invocableEmailParameters.orgWideEmailAddressId);
            }
            catch (Exception ex) {
                throw new InvocableEmailException('failed to retrieve org wide email');
            }
            saveAsActivity(invocableEmailParameters.saveEmailAsActivity);
            setUseSignature(invocableEmailParameters.useUserSignature);
        }

        try {
            results = send(false);
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            throw new InvocableEmailException('>>> qsyd_InvocableEmailTemplateAction.sendEmail failed with exception: ' + e.getMessage());
        }

        return results;
    }

    /**
     * Extend invocable email parameters
     */
    global with sharing class InvocableEmailParam extends InvocableEmailParamBase {
        @InvocableVariable(Label='Recipient To Addresses, Max 100, Comma Delimited' Description='Recipient To addresses' Required=false)
        global String toAddress;

        @InvocableVariable(Label='Recipient Cc Addresses, Max 25, Comma Delimited' Description='Recipient Cc addresses' Required=false)
        global String ccAddress;

        @InvocableVariable(Label='Recipient Bcc Addresses, Max 25, Comma Delimited' Description='Recipient Bcc addresses' Required=false)
        global String bccAddress;

        @InvocableVariable(Label='Email Character Set' Description='Email character set' Required=false)
        global String charSet;

        @InvocableVariable(Label='Attachment Ids' Description='Comma delimited list of ids of Document, ContentVersion, or Attachment' Required=false)
        global String attachmentIds;

        @InvocableVariable(Label='Email Template Id or Name' Description='Id, Name, or Developer Name of Email Template' Required=true)
        global String emailTemplate;

        @InvocableVariable(Label='Target Object Id - Contact, Lead or User Id' Description='The Id of the contact, lead, or user to which the email will be sent.' Required=true)
        global String targetObjectId;

        @InvocableVariable(Label='What Id - If you specify a Contact Id, either an Account, Asset, Campaign, Case, Contract, Opportunity, Order, Product, Solution, Custom' Description='If you specify a contact for the targetObjectId field, you can specify an optional whatId as well. Must be either a Account, Asset, Campaign, Case, Contract, Opportunity, Order, Product, Solution, Custom' Required=false)
        global String whatId;

        @InvocableVariable(Label='Parent Message Id ' Description='This field identifies the email or emails to which this email is a reply (parent emails).' Required=false)
        global String parentMessageIds;

        @InvocableVariable(Label='Email Opt Out Policy' Description='If you added recipients by ID instead of email address and the Email Opt Out option is set, this method determines the behavior of the sendEmail() call.' Required=false)
        global String emailOptOutPolicy;

        @InvocableVariable(Label='Org Wide Email Address' Description='The associated org wide email address set up in Organization-Wide Addresses' Required=false)
        global String orgWideEmailAddress;

        @InvocableVariable(Label='Save as Activity?' Description='This argument only applies if the recipient list is based on targetObjectId or targetObjectIds. If HTML email tracking is enabled for the organization, you will be able to track open rates.' Required=false)
        global Boolean saveAsActivity;

        @InvocableVariable(Label='Use Signature?' Description='Indicates whether the email includes an email signature if the user has one configured.' Required=false)
        global Boolean useSignature;

        @InvocableVariable(Label='Treat Bodies as Template?' Description='The subject, plain text, and HTML text bodies of the email are treated as template data. The merge fields are resolved using the renderEmailTemplate method.' Required=false)
        global Boolean treatBodiesAsTemplate;

        @InvocableVariable(Label='Treat Target Object as Recipient?' Description='If set to true, the targetObjectId (a contact, lead, or user) is the recipient of the email. If set to false, the targetObjectId is supplied as the WhoId field for template rendering but isn’t a recipient of the email.' Required=false)
        global Boolean treatTargetObjectAsRecipient;

        @InvocableVariable(Label='Throw an Exception for Send Errors?' Description='Throw an exception containing any send results errors. The default is true.' Required=false)
        global Boolean throwExceptionForSendErrors;

        @InvocableVariable(Label='Generate ICS attachments?' Description='Generate ICS Attachments/files from WhatId record. The default is false.' Required=false)
        global Boolean generateICSAttachments;

        /**
         * To addresses property
         */
        public List<String> toAddresses {
            get {
                return stringToList(this.toAddress);
            }
        }

        /**
         * Cc addresses property
         */
        public List<String> ccAddresses {
            get {
                return stringToList(this.ccAddress);
            }
        }

        /**
         * Bcc addresses property
         */
        public List<String> bccAddresses {
            get {
                return stringToList(this.bccAddress);
            }
        }

        /**
         * Character set property
         */
        public String characterSet {
            get {
                return nullOrTrim(this.charSet);
            }
        }

        /**
         * Attachments property
         */
        public List<String> attachments {
            get {
                System.debug(LoggingLevel.ERROR, 'get - stringToList(this.attachmentIds): ' + stringToList(this.attachmentIds));
                return stringToList(this.attachmentIds);
            }
        }

        /**
         * Email template id property
         */
        public String emailTemplateId {
            get {
                throwIfBlank(this.emailTemplate, 'An email template id or name must be provided.');

                return this.isIdInstanceOfSObjectType(this.emailTemplate, Schema.EmailTemplate.SObjectType) ? emailTemplate.trim() : this.getTemplateId();
            }
        }

        /**
         * Target object property
         */
        public String targetObject {
            get {
                return nullOrTrim(this.targetObjectId);
            }
        }

        /**
         * What property
         */
        public String what {
            get {
                return nullOrTrim(this.whatId);
            }
        }

        /**
         * Parent messages property
         */
        public String parentMessages {
            get {
                return nullOrTrim(this.parentMessageIds);
            }
        }

        /**
         * Opt out policy property
         */
        public String optOutPolicy {
            get {
                return nullOrTrim(this.emailOptOutPolicy);
            }
        }

        /**
         * Organization-wide email address id
         */
        public String orgWideEmailAddressId {
            get {
                return this.getOrgWideAddressId(nullOrTrim(this.orgWideEmailAddress));
            }
        }

        /**
         * Save as activity property
         */
        public Boolean saveEmailAsActivity {
            get {
                return (this.isIdInstanceOfSObjectType(this.targetObjectId, Schema.User.SObjectType)) ? false : (this.saveAsActivity == null) ? true : this.saveAsActivity;
            }
        }

        /**
         * Use signature property
         */
        public Boolean useUserSignature {
            get {
                return (this.useSignature == null) ? true : this.useSignature;
            }
        }

        /**
         * Treat bodies as template property
         */
        public Boolean treatAsTemplate {
            get {
                return (this.treatBodiesAsTemplate == null) ? false : this.treatBodiesAsTemplate;
            }
        }

        /**
         * targetObjectId source property
         */
        public Boolean treatAsRecipient {
            get {
                return (this.treatTargetObjectAsRecipient == null) ? true : this.treatTargetObjectAsRecipient;
            }
        }

        /**
         * Throw exception for send errors property
         */
        public Boolean throwException {
            get {
                return (this.throwExceptionForSendErrors == null) ? true : this.throwExceptionForSendErrors;
            }
        }

        /**
         * Generate ICS Attachements
         */
        public Boolean generateICS {
            get {
                return (this.generateICSAttachments == null) ? false : this.generateICSAttachments;
            }
        }

        /**
         * Find the most recently updated, active email template by either developer or display name
         *
         * @return
         */
        private String getTemplateId() {
            List<EmailTemplate> templates;
            String emailTemplateName = this.emailTemplate.trim();

            // Find a template
            templates = [
                    SELECT Id
                    FROM EmailTemplate
                    WHERE IsActive = TRUE
                    AND (DeveloperName = :emailTemplateName
                    OR Name = :emailTemplateName)
                    //WITH SECURITY_ENFORCED
                    ORDER BY LastModifiedDate DESC
                    LIMIT 1
            ];

            // Error if no matching record was found
            if (templates.isEmpty()) {

                throw new InvocableEmailException(String.format('{0}{1}{2}', new List<String>{
                        '\'', emailTemplateName, '\' template does not exist.'
                }));
            }

            return templates[0].Id;
        }
    }
}