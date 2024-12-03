/**
 * @description       : This is a utility class to manage the content by replace merge fields with it's respective values.
 * @author            : Mo
 * @last modified on  : 03-04-2022
 * @last modified by  : Mo
**/
public without sharing class ContractDocumentUtil {

    private static final String OPEN_EXPRESSION = '{!';
    private static final String CLOSE_EXPRESSION = '}';
    private static final String DATE_FORMAT = 'dd/MM/yyyy';
    private static final String PAGE_BREAK = '<div style="page-break-after: always"/>';
    private static final String PAGE_BREAK_None_PDF = '<div style="height:10px;background-color: #D2D3D0;margin: 25px -100%;">&nbsp;</div>';
    private static final String PAGE_BREAK_KEYWORD = '<<break>>';
    private static final String PAGE_BREAK_KEYWORD_1 = '&lt;&lt;break&gt;&gt;';

    public static String processedMergeFieldsContractDocument(String contentToBeParsed, Id recordId, Boolean isPDF){
        
        String sObjName = recordId.getSObjectType().getDescribe().getName();
        SObject record = getRecordWithAllFieldsById(recordId, sObjName);

        Pattern p = Pattern.compile('\\{!.+?\\}');
        Matcher m = p.matcher(contentToBeParsed);

        if (isPDF) {
            
            contentToBeParsed = contentToBeParsed.replaceAll(PAGE_BREAK_KEYWORD, PAGE_BREAK).replaceAll(PAGE_BREAK_KEYWORD_1, PAGE_BREAK);
        } else {
            
            contentToBeParsed = contentToBeParsed.replaceAll(PAGE_BREAK_KEYWORD, PAGE_BREAK_None_PDF).replaceAll(PAGE_BREAK_KEYWORD_1, PAGE_BREAK_None_PDF);
        }
        
        while(m.find()) {
            
            contentToBeParsed = contentToBeParsed.replace(m.group(0), getFieldMappingValue(record, m.group(0), sObjName));
        }
        
        return contentToBeParsed;
    }

    public static SObject getRecordWithAllFieldsById(Id recordId, String sObjName) {
        
        if (recordId != null) {            
            
            Set<String> SobjectFields = Schema.getGlobalDescribe().get(sObjName).getDescribe().fields.getMap().keySet();        
            SObject record = Database.query('SELECT ' + String.join(new List<String>(SobjectFields), ',') + ' FROM ' + sObjName + ' WHERE Id = \'' + recordId + '\'');
            System.debug('record '+record);
            return record;
        }

        return null;
    }

    public static String getFieldMappingValue(sObject record, String mergeField, String sObjName){

        try {
            
            if (record != null && String.isNotBlank(mergeField)) {
                
                Object fieldAPIName = record.get(normalizeMergeField(mergeField));
                Schema.DisplayType FldType = Schema.getGlobalDescribe().get(sObjName).getDescribe().fields.getMap().get(normalizeMergeField(mergeField)).getDescribe().getType();

                if (FldType == Schema.DisplayType.DATE || FldType == Schema.DisplayType.DATETIME) {
                
                    return fieldAPIName != null ? ((DatetIme)fieldAPIName).format(DATE_FORMAT) : '';
                }

                return fieldAPIName != null ? String.valueOf(fieldAPIName) : '';
            }

            return mergeField;
        }
        catch (Exception ex) {
            
            return mergeField;
        }
    }

    public static String normalizeMergeField(String mergeField){

        if (String.isNotBlank(mergeField)) {  
            
            return mergeField.replace(OPEN_EXPRESSION,'').replace(CLOSE_EXPRESSION,'');
        }

        return null;
    }
}