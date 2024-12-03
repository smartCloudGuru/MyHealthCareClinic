/**
* @author Zoran Zunko
* @date 3/26/21
*
*/
public inherited sharing class RandoxAuthProviderManager {
    @TestVisible
    static private Randox_Auth_Provider__mdt randoxAuthProvider;

    public static Randox_Auth_Provider__mdt getRandoxAuthProvider() {
        if(randoxAuthProvider == null) {
            List<Randox_Auth_Provider__mdt> randoxAuthProviders = [
                    SELECT
                            Client_Id__c,
                            DeveloperName,
                            Grant_Type__c,
                            Id,
                            Label,
                            Language,
                            MasterLabel,
                            NamespacePrefix,
                            Password__c,
                            QualifiedApiName,
                            Response_Type__c,
                            Scope__c,
                            Token_Endpoint__c,
                            Username__c,
                            API_Url__c
                    FROM Randox_Auth_Provider__mdt WHERE Active__c = TRUE];
                if(!randoxAuthProviders.isEmpty()) {
                    randoxAuthProvider  =randoxAuthProviders[0];
                }
        }
        return randoxAuthProvider;
    }
}