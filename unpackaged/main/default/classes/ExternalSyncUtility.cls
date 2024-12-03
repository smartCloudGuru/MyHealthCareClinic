/**
 * Created 10.12.2021..
 */

public without sharing class ExternalSyncUtility {

    // utility func to manipulate multipicklist as string
    public static String removeItemFromMultiPicklist(String picklist, String item) {
        if (item == null || picklist == null) return picklist;
        picklist = picklist.replaceAll(item + ';', '').replaceAll(item, '').trim();
        if (picklist.endsWith(';')) picklist = picklist.substringBeforeLast(';');
        if (String.isBlank(picklist)) picklist = null;
        return picklist;
    }

    // utility func to manipulate multipicklist as string
    public static String addItemToMultiPicklist(String picklist, String item) {
        if (item == null || picklist == null) return picklist;
        if (String.isBlank(picklist)) {
            picklist = item;
        }
        else {
            picklist += ';' + item;
        }
        return picklist;
    }

}