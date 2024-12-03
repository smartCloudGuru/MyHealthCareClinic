/**
 * Online store settings holder. Created and used to ease the unit testing of the entire module.
* @author Zoran Zunko
* @date 3/11/21
*
*/
public inherited sharing class OnlineStoreSettingsManager {
    @TestVisible static OnlineStoreSettings__c storeSettings;
    public static OnlineStoreSettings__c getStoreSettings() {
        if(storeSettings == null) {
            storeSettings = OnlineStoreSettings__c.getInstance();
        }
        return storeSettings;
    }

    //todo - read from settings
    public static List<Integer> getEndDateList() {
        return new List<Integer>{
                1, 3, 7, 10
        };
    }

    //todo - calculate
    public static Integer getDayQueried() {
        List<Integer> endDateList = getEndDateList();
        return endDateList[endDateList.size() - 1];
    }

    public static Integer getCancellationWindow() {
        OnlineStoreSettings__c storeSettingsLoc = getStoreSettings();
        if(storeSettingsLoc.Test_Cancellation_Window__c == null) {
            return 60;
        }
        else {
            return storeSettingsLoc.Test_Cancellation_Window__c.intValue();
        }
    }

    public static String getRegistrationEmail() {
        OnlineStoreSettings__c storeSettingsLoc = getStoreSettings();
        if(storeSettingsLoc.Test_Registration_Email__c == null) {
            return 'results@myhealthcareclinic.com';
        }
        else {
            return storeSettingsLoc.Test_Registration_Email__c;
        }
    }

    public static String getRegistrationPhone() {
        OnlineStoreSettings__c storeSettingsLoc = getStoreSettings();
        if(storeSettingsLoc.Test_Registration_Phone__c == null) {
            return '+44 20 7099 5555';
        }
        else {
            return storeSettingsLoc.Test_Registration_Phone__c;
        }
    }

    public static String getDefaultAccount() {
        OnlineStoreSettings__c storeSettingsLoc = getStoreSettings();
        return storeSettingsLoc.Default_AccountId__c;
    }
}