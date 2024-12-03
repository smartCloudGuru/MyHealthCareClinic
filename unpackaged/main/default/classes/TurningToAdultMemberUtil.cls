public class TurningToAdultMemberUtil{
    public static void pushNotification(String emailBody){
        if(String.IsNotBlank(System.Label.Notification_ToAddress)){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            list<String> toAddresses = System.Label.Notification_ToAddress.split(',');
            mail.setSaveAsActivity(false);
            mail.setToAddresses(toAddresses);
            mail.setSubject('Upgrade Membership');
            mail.setBccSender(false);
            mail.setUseSignature(false);
            mail.setHtmlBody(emailBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
    public static String prepareEmailBody(list<Account> accounts){
        String emailBody = '<table border="1"><tr><td>Name</td><td>PersonEmail</td><td>Mobile</td>';
        for(Account a :accounts){
            emailBody += '<tr>'
                      + '<td><a href="'+System.Label.Salesforce_Instance_Url+a.Id+'">' + a.Name+'</a></td>'
                      + '<td>' + (String.IsNotBlank(a.PersonEmail)?a.PersonEmail:'NA')+ '</td>'
                      + '<td>' + (String.IsNotBlank(a.PersonMobilePhone)?a.PersonMobilePhone:'NA') + '</td>'
                      + '</tr>';
        }
        emailBody += '</table>';
        return emailBody;
    }
}