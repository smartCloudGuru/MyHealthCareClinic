/**
 * Created 24.4.2023..
 */

public without sharing class AccountWarningsController {

    @AuraEnabled(Cacheable=false)
    public static String getPatientWarnings(String patientId) {

        List<String> ret = new List<String>();

        List<Patient_Warning__c> warns = [
                SELECT Id, CreatedDate, Note_Warning__c
                FROM Patient_Warning__c
                WHERE Patient__c = :patientId
                ORDER BY CreatedDate DESC
        ];

        for (Patient_Warning__c patientWarning : warns) {
            ret.add(patientWarning.Note_Warning__c);
        }

        //2024-04-25 Sid: semble notes are not needed
        //        List<String> sembleNotes = getSembleNote(patientId);
        //
        //        if (sembleNotes!=null && sembleNotes.size()>0)
        //        {
        //            for (String str : sembleNotes) {
        //                ret.add(str + ' (from Semble)');
        //            }
        //        }

        return JSON.serialize(ret);
    }


    //    public static List<String> getSembleNote(String patientId) {
    //
    //        List<Account> accs = [SELECT Id, HeyDoc_Id__c FROM Account WHERE Id = :patientId LIMIT 1];
    //        if (accs.isEmpty()) return null;
    //        if (accs[0].HeyDoc_Id__c == null) return null;
    //
    //        try {
    //            HeyDocService.Patient pat = HeyDocService.getPatient(accs[0].HeyDoc_Id__c);
    //
    //            return sembleCommentsToList(pat?.comments);
    //
    //        }
    //        catch (Exception ex) {
    //            return null;
    //        }
    //    }

    public static String getAeronaNotes(String patientId) {

        return '[]';
    }

    public static List<String> sembleCommentsToList(String comments) {
        if (String.isNotBlank(comments)) {
            List<String> parts = comments.split('\n');

            List<String> retParts = new List<String>();
            for (String str : parts) {
                if (String.isNotBlank(str)) retParts.add(str);
            }
            return retParts;
        }
        else {
            return null;
        }
    }

    public static Exception newAuraHandledException(String msg) {
        AuraHandledException aEx = new AuraHandledException(msg);
        aEx.setMessage(msg);
        return aEx;
    }
}