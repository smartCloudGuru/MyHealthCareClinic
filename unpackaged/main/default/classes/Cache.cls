/**
* used for fetching record types based on developer names
* @author Zoran Zunko
* @date 2/19/21
*
*/
public class Cache {
    /**
     * fetches record type id based on developer name
     * @param recordTypeName record type developer name - SObjectAPIName.RecordTypeDeveloperName
     *
     * @return Record Type Id
     */
    public static String recordTypeId(String recordTypeName) {
        String result = '';
        try {
            List<String> recordTypeParts = recordTypeName.split('\\.');
            String sobjectName = recordTypeParts[0];
            String recordTypeDevName = recordTypeParts[1];

            result = Schema.getGlobalDescribe().get(sobjectName).getDescribe().getRecordTypeInfosByDeveloperName().get(recordTypeDevName).recordTypeId;
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, ex.getMessage() + ' - ' + ex.getStackTraceString());
        }
        return result;
    }
}