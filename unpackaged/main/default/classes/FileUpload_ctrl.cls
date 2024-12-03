public without sharing class FileUpload_ctrl {

    @AuraEnabled
    public static Id saveFile(Id parentId, String fileName, String base64Data, String contentType, String fileDescription )  { 
        
        ContentVersion contentToInsert = new ContentVersion(); 
        contentToInsert.Title = fileDescription + ' - ' + fileName; 
        contentToInsert.VersionData = EncodingUtil.base64Decode(EncodingUtil.urlDecode(base64Data, 'UTF-8'));
        contentToInsert.PathOnClient = '/' + fileName ;
        contentToInsert.Description = fileDescription;
        contentToInsert.IsMajorVersion = false;
        insert contentToInsert; 
        
        contentToInsert = [select id, ContentDocumentId from ContentVersion WHERE Id =: contentToInsert.Id];
        ContentDocumentLink cl = new ContentDocumentLink();
        cl.ContentDocumentId = contentToInsert.ContentDocumentId;
        cl.LinkedEntityId = parentId; 
        cl.ShareType = 'V';
        cl.Visibility = 'AllUsers';
        insert cl;
        
        return contentToInsert.id;
    }
}