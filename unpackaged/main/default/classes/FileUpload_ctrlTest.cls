@isTest
private class FileUpload_ctrlTest {
    @isTest
    static void itShouldUploadFile()  {
        //Given
        Account Acc = new Account ();
        Acc.Name = 'Test Account';
        insert Acc;
        Id parentId = Acc.Id; 
        String fileName = 'TestFile';
        String base64Data = EncodingUtil.urlDecode('Test base64Data For testing', 'UTF-8');
        String contentType = 'jpg'; 
        String fileDescription = 'Testing File';

        Id contentVersionId = null;

        Test.startTest();

            contentVersionId = FileUpload_ctrl.saveFile(parentId, fileName, base64Data, contentType, fileDescription );
        Test.stopTest();

        Account account = [select name from account where id=:acc.id];
        System.assertEquals('Test Account', account.name);        
        System.assertNotEquals(null, contentVersionId);
    }
}