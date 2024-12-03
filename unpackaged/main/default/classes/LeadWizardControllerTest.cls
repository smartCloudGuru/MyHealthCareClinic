/**
 * Created by Matija on 26.9.2023..
 */

@IsTest
private class LeadWizardControllerTest {
    @IsTest
    static void testBehavior() {

        Lead ld = new Lead();
        ld.FirstName = 'T1';
        ld.LastName = 'T1';

        insert ld;

        List<LeadWizardController.ProcessLeadRequest> requests = new List<LeadWizardController.ProcessLeadRequest>();

        LeadWizardController.ProcessLeadRequest req = new LeadWizardController.ProcessLeadRequest();

        req.leadId = ld.Id;
        req.doConversion = true;
        req.convertToAccountId = 'new';


        requests.add(req);

        List<LeadWizardController.ProcessLeadResponse> resp = LeadWizardController.processLeadOutcome(requests);

        System.assert(resp != null && !resp.isEmpty() && resp[0].success == true);
    }

    @IsTest
    static void testCopyFromAccount() {

        Lead ld = new Lead();
        ld.FirstName = 'T1';
        ld.LastName = 'T1';

        insert ld;

        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
        accounts[0].PersonEmail = 'emai@example.com';
        update accounts[0];

        String ret = LeadWizardController.copyFromAccount(ld.Id, accounts[0].Id);

        System.debug(ret);
        System.assert(ret == ld.Id);

    }
}