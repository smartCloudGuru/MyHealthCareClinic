trigger Status_tgr on dsfs__DocuSign_Status__c (after insert,after update) {     
    list<Account> acconts2Update = new list<Account>();
    list<Messaging.SingleEmailMessage> messagingList = new List<Messaging.SingleEmailMessage>();
    boolean isMember = false;
    for(dsfs__DocuSign_Status__c dc:[Select dsfs__Opportunity__c,dsfs__Company__c,dsfs__Company__r.Name,dsfs__Company__r.PersonEmail,dsfs__Company__r.Member_Status__c ,dsfs__Envelope_Status__c,dsfs__Sender_Email__c From dsfs__DocuSign_Status__c Where Id IN : trigger.newMap.keySet()]){
        Account acc = new Account(Id=dc.dsfs__Company__c);
        if('Sent'.equalsIgnoreCase(dc.dsfs__Envelope_Status__c) || 'Delivered'.equalsIgnoreCase(dc.dsfs__Envelope_Status__c)){
                    acc.Member_Status__c = 'Pending';
              System.debug('--------------'+dc.dsfs__Envelope_Status__c);
        }
        
        else if('Completed'.equalsIgnoreCase(dc.dsfs__Envelope_Status__c)){
        System.debug('--------------'+dc.dsfs__Envelope_Status__c);
            //acc.Member_Status__c = 'Member';
            acc.Membership_Start_Date__c = System.Today();
            isMember = true;
            Messaging.SingleEmailMessage mail =  new Messaging.SingleEmailMessage();  
            list<String> toAddresses = new list <string>{dc.dsfs__Company__r.PersonEmail};
            list<String> ccAddresses = System.Label.GoCardless_CC_Email_Address.split(',');
            mail.setCcAddresses(ccAddresses);
            mail.setToAddresses(toAddresses); 
            mail.setSubject(String.Format(System.Label.GoCardless_Email_Subject, new list<String>{dc.dsfs__Company__r.Name}));
            mail.setHtmlBody(String.Format(System.Label.GoCardless_Email_Body, new list<String>{dc.dsfs__Company__r.Name}));
            messagingList.add(mail);             
        }
        acconts2Update.add(acc);
   }
   if(!messagingList.isEmpty()){
        Messaging.sendEmail(messagingList);
    }
   if(!acconts2Update.isEmpty()){
        update acconts2Update;
        /*if(isMember == true){
            Account objAcc = [Select PersonEmail, Id From Account a Where Id =: acconts2Update.get(0).Id];
            list<string> names = CommonUtility.objMeddBaseSettings.Membership_Plan_Names__c.split(',');
            string planName = '';             
            for(Opportunity op:[Select Id, AccountId, (Select Id,Product2.Name, Product2Id 
                                        From OpportunityLineItems WHERE Product2.Name IN: names order by CreatedDate DESC limit 1) 
                                        From Opportunity WHERE AccountId =:objAcc.Id order by lastModifiedDate DESC limit 1]){
                if(!op.OpportunityLineItems.isEmpty()){
                    planName = op.OpportunityLineItems.get(0).Product2.Name;
                }       
            }
            if(planName != null && planName != ''){
                MeddbaseCalloutUtility.subscribeStripe(objAcc.PersonEmail,planName);
            }
        }*/
   }
}