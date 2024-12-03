/**
* @author Zoran Zunko
* @date 4/1/21
*
*/
public inherited sharing class StoreConfigMetadataManager {
    @TestVisible static Map<String, Online_Store_Config__mdt> onlineStoreConfigs;

    public static Online_Store_Config__mdt getOnlineStoreConfig(String storeConfig) {
        if(onlineStoreConfigs == null) {
            onlineStoreConfigs = new Map<String, Online_Store_Config__mdt>();
            List<Online_Store_Config__mdt> storeConfigs = [
                    SELECT
                            Id,
                            Store_Site_URL__c,
                            Label
                    FROM Online_Store_Config__mdt];
            for (Online_Store_Config__mdt onlineStoreConfig : storeConfigs) {
                onlineStoreConfigs.put(onlineStoreConfig.Label, onlineStoreConfig);
            }
        }
        return onlineStoreConfigs.get(storeConfig);
    }
}