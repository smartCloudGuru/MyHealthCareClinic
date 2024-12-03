/**
 * Created 18.5.2022..
 */

@RestResource(UrlMapping='/m/account/*')
global without sharing class AccountRestResource {

    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        res.headers.put('Content-Type', 'application/json');

        try {
            System.debug(LoggingLevel.INFO, '::M:AccountRestResource:POST:requestBody: ' + req?.requestBody?.toString());

            Account acc = (Account) JSON.deserialize(RestContext.request.requestBody.toString(), Account.class);

            acc.RecordTypeId = Cache.recordTypeId(AccountManager.RT_PERSON_ACCOUNT);
            if (acc.Id == null) {
                acc.Patient_Type__c = 'New';
                acc.Store_UUID__c = new Uuid().getValue();
            }

            upsert acc;

            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(new MHCAPIResponse(200, acc.Id)));
            System.debug(LoggingLevel.INFO, '::M:AccountRestResource:POST:responseBody: ' + acc.Id);

        }
        catch (System.JSONException ex) {
            resFromMHCApiResponse(res, 400, 'Malformed JSON input');
            System.debug(LoggingLevel.INFO, '::M:AccountRestResource:POST:responseBody:Malformed JSON input');

        }
        catch (Exception ex) {

            res.statusCode = 500;
            if (ex.getMessage() != null) {
                if (ex.getMessage().contains('DUPLICATES_DETECTED')
                        || ex.getMessage().contains('INVALID_EMAIL_ADDRESS')
                ) {
                    res.statusCode = 400;
                }
            }
            res.responseBody = Blob.valueOf(JSON.serializePretty(new MHCAPIResponse(res.statusCode, ex.getMessage())));
            System.debug(LoggingLevel.INFO, '::M:AccountRestResource:POST:responseBody:' + ex.getMessage());
        }
    }


    /**
     * Retrieves related (can book for) accounts
     * expected ULR request: GET /m/account/accid/related
     *
     * @return
     */
    @HttpGet
    global static List<Account> getRelatedRecords() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {

            System.debug(LoggingLevel.INFO, '::M:AccountRestResource:GET:requestURI: ' + req?.requestURI);

            // grab the caseId from the end of the URL
            List<String> parts = req.requestURI.split('/');

            List<Account> ret = new List<Account>();

            String accId = parts.get(parts.size() - 2);

            List<Account> mainAccs = [
                    SELECT Id, FirstName, LastName, Member_Status__c, Membership_Level__c, Date_of_Birth__c, PersonEmail, PersonMailingPostalCode, Membership_Contract__c
                    FROM Account
                    WHERE Id = :accId
                    LIMIT 1
            ];

            if (mainAccs.isEmpty()) return ret;

            Account mainAcc = mainAccs[0];

            if ('related'.equalsIgnoreCase(parts.get(parts.size() - 1))) {
                Map<Id, Account> map_combinedRelatedAccounts = new Map<Id, Account>();

                // ADD ALL FROM MEMBER GROUP
                List<Account> relatedsInMemberGroup = [
                        SELECT Id, FirstName, LastName, Member_Status__c, Membership_Level__c, Date_of_Birth__c, PersonEmail, PersonMailingPostalCode
                        FROM Account
                        WHERE Member_Group__c = :mainAcc.Id
                ];
                for (Account account : relatedsInMemberGroup) {
                    map_combinedRelatedAccounts.put(account.Id, account);
                }

                // ADD ALL FROM MEMBERSHIP CONTRACT, IF EXISTS
                if (String.isNotBlank(mainAcc.Membership_Contract__c)) {
                    List<Account> relatedsInMemberContract = [
                            SELECT Id, FirstName, LastName, Member_Status__c, Membership_Level__c, Date_of_Birth__c, PersonEmail, PersonMailingPostalCode
                            FROM Account
                            WHERE Membership_Contract__c = :mainAcc.Membership_Contract__c
                    ];

                    for (Account account : relatedsInMemberContract) {
                        map_combinedRelatedAccounts.put(account.Id, account);
                    }
                }

                // ADD ALL BY PERSONAL EMAIL, IF ITS POPULATED
                if (String.isNotBlank(mainAccs.get(0).PersonEmail)) {
                    List<Account> relatedsByEmail = [
                            SELECT Id, FirstName, LastName, Member_Status__c, Membership_Level__c, Date_of_Birth__c, PersonEmail, PersonMailingPostalCode
                            FROM Account
                            WHERE PersonEmail = :mainAccs.get(0).PersonEmail
                    ];
                    for (Account account : relatedsByEmail) {
                        map_combinedRelatedAccounts.put(account.Id, account);
                    }
                }

                //ADD ANY EXPLICETLY ADDED IN Family/Related relationship, but not ignored
                List<Related_Accounts__c> relatedsInRelatedAccounts = [
                        SELECT Id,
                                Related_Account__r.FirstName,
                                Related_Account__r.LastName,
                                Related_Account__r.Member_Status__c,
                                Related_Account__r.Membership_Level__c,
                                Related_Account__r.Date_of_Birth__c,
                                Related_Account__r.PersonEmail,
                                Related_Account__r.PersonMailingPostalCode,
                                Ignored__c
                        FROM Related_Accounts__c
                        WHERE Main_Account__c = :accId
                ];

                for (Related_Accounts__c relatedAccount : relatedsInRelatedAccounts) {
                    if (!relatedAccount.Ignored__c)
                    {
                        map_combinedRelatedAccounts.put(relatedAccount.Id, relatedAccount.Related_Account__r);
                    }
                }

                //REMOVE anyone marked as "ignored" and also the main account
                for (Related_Accounts__c relatedAccount : relatedsInRelatedAccounts) {
                    if (relatedAccount.Ignored__c)
                    {
                        map_combinedRelatedAccounts.put(relatedAccount.Id, null);
                    }
                }

                for (Id key : map_combinedRelatedAccounts.keySet()) {
                    if ((map_combinedRelatedAccounts.get(key) !=null) && (key!=mainAcc.Id)) ret.add(map_combinedRelatedAccounts.get(key));
                }

            }
            else {
                ret.addAll(mainAccs);
            }

            System.debug(LoggingLevel.INFO, '::M:AccountRestResource:GET:ret:' + JSON.serialize(ret));
            return ret;
        }
        catch (Exception ex) {
            System.debug(LoggingLevel.INFO, '::M:AccountRestResource:GET:ret:null');
            return null;
        }
    }

    @HttpPatch
    global static void doPatch() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        res.headers.put('Content-Type', 'application/json');

        try {
            System.debug(LoggingLevel.INFO, '::M:AccountRestResource:PATCH:requestBody: ' + req?.requestBody?.toString());

            Account acc = (Account) JSON.deserialize(req.requestBody.toString(), Account.class);

            if (acc.Id == null) {
                resFromMHCApiResponse(res, 400, 'Account Id Required');
                return;
            }

            //filter only some updates
            Account acc2 = [SELECT Id, Online_Registration_Date__c FROM Account WHERE Id = :acc.Id];
            if (acc.Store_password__c != null) {
                acc2.Store_password__c = acc.Store_password__c;
                if (acc2.Online_Registration_Date__c == null) acc2.Online_Registration_Date__c = Date.today();
            }

            update acc2;

            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(new MHCAPIResponse(200, acc.Id)));

            System.debug(LoggingLevel.INFO, '::M:AccountRestResource:PATCH:responseBody: ' + acc.Id);

        }
        catch (System.JSONException ex) {
            resFromMHCApiResponse(res, 400, 'Malformed JSON input');
            System.debug(LoggingLevel.INFO, '::M:AccountRestResource:PATCH:responseBody: ' + 'Malformed JSON input');
        }
        catch (Exception ex) {
            resFromMHCApiResponse(res, 500, ex.getMessage());
            System.debug(LoggingLevel.INFO, '::M:AccountRestResource:PATCH:responseBody: ' + ex.getMessage());
        }


    }

    public static void resFromMHCApiResponse(RestResponse res, Integer code, String msg) {
        res.statusCode = code;
        res.responseBody = Blob.valueOf(JSON.serialize(new MHCAPIResponse(code, msg), true));
    }

    public class MHCAPIResponse {
        public Integer code;
        public String message;
        public Boolean error;

        public MHCAPIResponse() {
        }

        public MHCAPIResponse(Integer code, String message) {
            this.code = code;
            this.message = message;
            error = (code>299);
        }
    }
}