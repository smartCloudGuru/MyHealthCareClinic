/**
 * Created 13.9.2022..
 */

public without sharing class memSignUpCtrl {

    public static final String LEVEL_ADULT_PAYER = 'Adult - Main Payer';
    public static final String LEVEL_ADULT = 'Adult';
    public static final String LEVEL_CHILD = 'Child';

    @AuraEnabled(Cacheable=true)
    public static String getCustomSettings() {
        return OnlineStoreSettingsManager.getStoreSettings().IdealPostcodes_API_Key__c;
    }

    @AuraEnabled(Cacheable=true)
    public static String aura_getPrices() {

        List<Membership_Tier__c> membershipTiers = getCurrentMembershipTiers();
        Map<String, PricesPerType> m_tier_prices = getPrices(membershipTiers);
        return JSON.serializePretty(m_tier_prices, true);
    }

    @AuraEnabled(Cacheable=true)
    public static String aura_getAccount(String id, String pid) {

        List<Account> accounts = [SELECT Id, FirstName, LastName, PersonEmail, Gender__c, Phone, Date_of_Birth__c, BillingStreet, BillingCity, BillingPostalCode FROM Account WHERE Patient_Id__c = :pid];
        if (accounts.isEmpty()) return null;
        if (obfuscateId(accounts[0].Id) == id) {
            return JSON.serialize(accounts[0], true);
        }

        return null;
    }

    @AuraEnabled(Cacheable=true)
    public static String generateMembershipSignupUrl(String id) {
        if (id != null) {
            List<Account> accounts = [SELECT Id, Patient_Id__c FROM Account WHERE Id = :id];
            if (accounts.isEmpty()) return null;

            GoCardless_Integration_Setting__mdt INTEGRATIONS_SETTINGS = [
                    SELECT Redirect_URL__c
                    FROM GoCardless_Integration_Setting__mdt
                    LIMIT 1
            ];

            return INTEGRATIONS_SETTINGS.Redirect_URL__c + '?a=' + obfuscateId(accounts[0].Id) + '&b=' + accounts[0].Patient_Id__c;
        }
        return null;
    }
    public static String obfuscateId(String id) {
        Blob requestBlob = Blob.valueOf(id);
        Blob hash = Crypto.generateDigest('MD5', requestBlob);
        return EncodingUtil.convertToHex(hash);
    }

    public static List<Membership_Tier__c> getCurrentMembershipTiers() {
        return [
                SELECT Id, Name, Price_Book__c, Tier_Level__c
                FROM Membership_Tier__c
                WHERE Available_From__c <= :Date.today()
                AND
                (
                        Available_To__c = NULL OR Available_To__c >= :Date.today()
                )
                ORDER BY Available_From__c
        ];
    }

    public static Membership_Tier__c getCurrentMembershipTierForPriceBookId(Id priceBookId) {
        List <Membership_Tier__c> tiers = [
                SELECT Id, Price_Book__c, Tier_Level__c
                FROM Membership_Tier__c
                WHERE Available_From__c <= :Date.today()
                AND Price_Book__c = :priceBookId
                AND
                (
                        Available_To__c = NULL OR Available_To__c >= :Date.today()
                )
                ORDER BY Available_From__c
                LIMIT 1
        ];

        if (tiers.size() == 0) return null;
        else return tiers[0];
    }

    public static Map<String, PricesPerType> getPrices(List<Membership_Tier__c> membershipTiers) {

        Set<Id> priceBookIds = new Set<Id>();
        for (Membership_Tier__c tier : membershipTiers) {
            priceBookIds.add(tier.Price_Book__c);
        }

        List<PricebookEntry> pricebookEntries = [
                SELECT Id, Pricebook2Id, UnitPrice, Product2.Name, Pricebook2.Name
                FROM PricebookEntry
                WHERE Pricebook2Id IN :priceBookIds
                AND Product2.Name IN (:LEVEL_ADULT_PAYER, :LEVEL_ADULT, :LEVEL_CHILD)
        ];
        System.debug('::memCtrl:getPrices:pricebookEntries ' + pricebookEntries.size());

        Map<String, PricesPerType> m_tier_prices = new Map<String, memSignUpCtrl.PricesPerType>();

        for (Membership_Tier__c tier : membershipTiers) {
            if (m_tier_prices.get(tier.Tier_Level__c) == null) {

                PricesPerType ppt = new PricesPerType();

                for (PricebookEntry pricebookEntry : pricebookEntries) {
                    if (pricebookEntry.Pricebook2Id == tier.Price_Book__c) {
                        ppt.priceBookId = pricebookEntry.Pricebook2Id;
                        ppt.priceBookName = pricebookEntry.Pricebook2.Name;
                        if (pricebookEntry.Product2.Name == LEVEL_ADULT) ppt.adult = pricebookEntry.UnitPrice;
                        else if (pricebookEntry.Product2.Name == LEVEL_ADULT_PAYER) ppt.adultPayer = pricebookEntry.UnitPrice;
                        else if (pricebookEntry.Product2.Name == LEVEL_CHILD) ppt.child = pricebookEntry.UnitPrice;
                    }
                }

                if (tier.Tier_Level__c != null) m_tier_prices.put(tier.Tier_Level__c, ppt);
            }
        }

        return m_tier_prices;
    }


    @AuraEnabled(Cacheable=false)
    public static String processSignupRequest(String params) {
        try {

            ProcessSignupResponse ret = raw_processSignupRequest(params);

            return JSON.serializePretty(ret);
        }
        catch (Exception ex) {
            throw newAuraHandledException(ex.getMessage());
        }
    }

    public static ProcessSignupResponse raw_processSignupRequest(String params) {
        ProcessSignupResponse ret = new ProcessSignupResponse();

        ret.uid = new Uuid().getValue();

        MemSignUpRequest req = (MemSignUpRequest) JSON.deserialize(params, MemSignUpRequest.class);

        Membership_Tier__c corporateTier = null;
        if (String.isNotEmpty(req.corporate)) {
            List<Membership_Tier__c> memTiers = [
                    SELECT Id,
                            Price_Book__c,
                            CreatedDate,
                            Monthly_Price__c,
                            Tier_Level__c
                    FROM Membership_Tier__c
                    WHERE Signup_Code__c = :req.corporate.trim()
                    AND Available_From__c < :Date.today()
                    AND Is_Corporate_Tier__c = TRUE
                    ORDER BY CreatedDate DESC
                    LIMIT 1
            ];
            if (memTiers.isEmpty()) throw new MHCException('The membership you are requesting is not available. Please contact us.');
            corporateTier = memTiers.get(0);
        }

        //if online DD was requested, first try to create a redirectFlow
        GoCardlessService.RedirectFlowEntity res = null;

        //direct debit flow enabled by default
        if (req.ddselected == null || req.source == 'MOBILEAPP') req.ddselected = '1';

        Account specifiedAccount = null;

        //prirotize accountId, if it was provided in the request, for the main payer
        if (!String.isBlank(req.accountId)) {
            List<Account> accs = [SELECT Id, FirstName, LastName, PersonEmail, Patient_Type__c FROM Account WHERE Id = :req.accountId];
            if (accs.isEmpty()) {
                throw new MHCException('No such Account by ID ' + req.accountId);
            }
            else {
                if (accs[0].Patient_Type__c == 'Member') {
                    throw new MHCException('Main payer Patient is already a Member!');
                }
                else {
                    specifiedAccount = accs[0];
                }
            }

            req.lastName = specifiedAccount.LastName;
            req.firstName = specifiedAccount.FirstName;
            req.email = specifiedAccount.PersonEmail;
        }

        //we need to to the a callout before any updates :/
        if (req.ddselected == '1') {

            GoCardlessService.RedirectFlowEntity gcReq = new GoCardlessService.RedirectFlowEntity();
            gcReq.prefilled_customer.email = req.email;
            gcReq.prefilled_customer.given_name = req.firstName;
            gcReq.prefilled_customer.family_name = req.lastName;
            gcReq.description = 'MHC Membership';
            gcReq.session_token = ret.uid;

            try {
                res = GoCardlessService.createRedirectFlow(gcReq, req.directDebitSuccessUrl);
            }
            catch (Exception e) {
                res = null;
                ret.errorMsg = e.getMessage();
            }

            if (res == null) {
                ret.errorCode = 'ERROR_DD_CRF';
            }
            else {
                ret.redirectUrl = res.redirect_url;
            }
        }

        List<Note> notesToInsert = new List<Note>();
        MembershipSignupForm__c form = new MembershipSignupForm__c();

        form.Session_Id__c = ret.uid;
        form.GC_RedirectFlow_Id__c = res?.id;
        if (corporateTier != null) {
            form.Membership_Tier_Level__c = corporateTier.Tier_Level__c;
        }
        else {
            form.Membership_Tier_Level__c = req.tier;
        }
        form.Provided_First_Name__c = req.firstName;
        form.Provided_Last_Name__c = req.lastName;
        form.Provided_Email__c = req.email;
        form.Provided_Phone__c = req.phone;
        form.Provided_DOB__c = req.getDOB();

        form.Provided_Address_Line_1__c = req.address1;
        form.Provided_Address_Line_2__c = req.address2;
        form.Provided_Address_Line_3__c = req.address3;
        form.Provided_City__c = req.city;
        form.Provided_Postal_Code__c = req.postalCode;
        form.Requested_Contact_For_DD__c = req.ddselected == '0';
        form.Signed_Up_For_Offers__c = (req.checkNews == true) ? true : false;
        form.Referral_Code__c = req.refCode;
        form.Provided_Gender__c = req.gender;

        if (corporateTier != null) {
            form.Membership_PriceBook__c = corporateTier.Price_Book__c;
            form.Subscription_Amount__c = corporateTier.Monthly_Price__c;
            if (form.Subscription_Amount__c == null) form.Subscription_Amount__c = 0;
        }
        else {

            List<Membership_Tier__c> membershipTiers = getCurrentMembershipTiers();
            Map<String, PricesPerType> map_prices = getPrices(membershipTiers);
            form.Membership_PriceBook__c = map_prices.get(form.Membership_Tier_Level__c)?.priceBookId;
            form.Subscription_Amount__c = calculateTotalAmount(map_prices.get(form.Membership_Tier_Level__c), req.adultMembers, req.childMembers);
        }

        if (form.Membership_PriceBook__c == null) throw newAuraHandledException('ERR_CFG_NO_PRICES');


        if (form.Subscription_Amount__c == null) throw newAuraHandledException('ERR_CFG_NO_PRICES');

        insert form;


        //store linked/additional members
        List<Additional_Member__c> additionalMembersToInsert = new List<Additional_Member__c>();
        for (AdditionalMember am : req.adultMembers) {
            Additional_Member__c amc = new Additional_Member__c();
            amc.Membership_Signup_Form__c = form.Id;
            amc.Membership_Level__c = LEVEL_ADULT;
            amc.Provided_First_Name__c = am.firstName;
            amc.Provided_Last_Name__c = am.lastName;
            amc.Provided_DOB__c = am.getDOB();
            amc.Provided_Email__c = am.email;
            amc.Provided_Phone__c = am.phone;
            amc.Provided_Address_Line_1__c = am.address1;
            amc.Provided_Address_Line_2__c = am.address2;
            amc.Provided_Address_Line_3__c = am.address3;
            amc.Provided_City__c = am.city;
            amc.Provided_Postal_Code__c = am.postalCode;
            amc.Provided_Gender__c = am.gender;
            additionalMembersToInsert.add(amc);
        }

        for (AdditionalMember am : req.childMembers) {
            Additional_Member__c amc = new Additional_Member__c();
            amc.Membership_Signup_Form__c = form.Id;
            amc.Membership_Level__c = LEVEL_CHILD;
            amc.Provided_First_Name__c = am.firstName;
            amc.Provided_Last_Name__c = am.lastName;
            amc.Provided_DOB__c = am.getDOB();
            amc.Provided_Email__c = am.email;
            amc.Provided_Phone__c = am.phone;
            amc.Provided_Address_Line_1__c = am.address1;
            amc.Provided_Address_Line_2__c = am.address2;
            amc.Provided_Address_Line_3__c = am.address3;
            amc.Provided_City__c = am.city;
            amc.Provided_Postal_Code__c = am.postalCode;
            amc.Provided_Gender__c = am.gender;
            additionalMembersToInsert.add(amc);
        }

        Boolean successfullyCreatedAllAccounts = true;

        Account accMainPayer;

        if (specifiedAccount != null) {
            accMainPayer = specifiedAccount;
            form.Patient__c = specifiedAccount.Id;
        }
        else {
            try {
                accMainPayer = AccountMatcher.findMatch(
                        form.Provided_First_Name__c,
                        form.Provided_Last_Name__c,
                        form.Provided_DOB__c,
                        form.Provided_Email__c);

                if (accMainPayer == null) {
                    accMainPayer = new Account();
                    accMainPayer.Patient_Type__c = 'New';
                    accMainPayer.RecordTypeId = Cache.recordTypeId(AccountManager.RT_PERSON_ACCOUNT);
                    System.debug(':processSignupRequest:creating new main payer account');
                }
                else {
                    System.debug(':processSignupRequest:matched main payer account to ' + accMainPayer.Id);
                }

                //if error, already a member
                if (accMainPayer.Patient_Type__c == 'Member') {
                    String err = 'Main payer Patient is already a Member!';
                    notesToInsert.add(createNewNote('Unable to automatically assign Main Payer', err, form.Id));

                    System.debug(LoggingLevel.WARN, err);
                    successfullyCreatedAllAccounts = false;
                }
                else {
                    accMainPayer.FirstName = form.Provided_First_Name__c;
                    accMainPayer.LastName = form.Provided_Last_Name__c;
                    accMainPayer.PersonEmail = form.Provided_Email__c;
                    if (form.Provided_Phone__c != null) accMainPayer.Phone = form.Provided_Phone__c;
                    accMainPayer.Date_of_Birth__c = form.Provided_DOB__c;
                    accMainPayer.BillingStreet = form.Provided_Address_Line_1__c;
                    accMainPayer.Gender__c = form.Provided_Gender__c;
                    if (!String.isBlank(form.Provided_Address_Line_2__c)) accMainPayer.BillingStreet += ', ' + form.Provided_Address_Line_2__c;
                    if (!String.isBlank(form.Provided_Address_Line_3__c)) accMainPayer.BillingStreet += ', ' + form.Provided_Address_Line_3__c;
                    accMainPayer.BillingPostalCode = form.Provided_Postal_Code__c;
                    accMainPayer.BillingCity = form.Provided_City__c;

                    upsert accMainPayer;
                }
                form.Patient__c = accMainPayer.Id;
            }
            catch (Exception ex) {
                successfullyCreatedAllAccounts = false;

                Note n2 = createNewNote('Unable to automatically assign Main Payer', null, form.Id);

                if (ex.getMessage() != null && ex.getMessage().contains('DUPLICATES_DETECTED')) {
                    System.debug(LoggingLevel.WARN, 'Unable to create main payer Account due to potential DUPLICATE Patient'); n2.Body = 'Unable to create a new Account due to potential DUPLICATE Patient';
                }
                else {
                    System.debug(LoggingLevel.WARN, 'Unable to match main payer Account due to:' + ex.getMessage()); n2.Body = 'Unable to match main payer Account due to:' + ex.getMessage();
                }
                notesToInsert.add(n2);
            }
        }

        //accounts for each additional  member
        Account accAdditional;
        for (Additional_Member__c member : additionalMembersToInsert) {

            try {
                accAdditional = AccountMatcher.findMatch(
                        member.Provided_First_Name__c,
                        member.Provided_Last_Name__c,
                        member.Provided_DOB__c,
                        member.Provided_Email__c);

                if (accAdditional == null) {
                    accAdditional = new Account();
                    accAdditional.Patient_Type__c = 'New';
                    accAdditional.RecordTypeId = Cache.recordTypeId(AccountManager.RT_PERSON_ACCOUNT);
                    System.debug(':processSignupRequest:creating new additional account');
                }
                else {
                    System.debug(':processSignupRequest:matched additional account to ' + accAdditional.Id);
                }

                if (accAdditional.Patient_Type__c == 'Member') {

                    notesToInsert.add(createNewNote('Unable to automatically assign an additional member', 'Additional account is already a Member. (' + member.Provided_First_Name__c + ' ' + member.Provided_Last_Name__c + ', ' + member.Provided_Email__c, form.Id));
                    System.debug(LoggingLevel.WARN, 'Additional account is already a Member!');
                    successfullyCreatedAllAccounts = false;
                }
                else {
                    accAdditional.FirstName = member.Provided_First_Name__c;
                    accAdditional.LastName = member.Provided_Last_Name__c;
                    accAdditional.PersonEmail = member.Provided_Email__c;
                    accAdditional.Gender__c = member.Provided_Gender__c;
                    if (member.Provided_Phone__c != null) accAdditional.Phone = member.Provided_Phone__c;
                    accAdditional.Date_of_Birth__c = member.Provided_DOB__c;

                    accAdditional.BillingStreet = member.Provided_Address_Line_1__c;
                    if (!String.isBlank(member.Provided_Address_Line_2__c)) accAdditional.BillingStreet += ', ' + member.Provided_Address_Line_2__c;
                    if (!String.isBlank(member.Provided_Address_Line_3__c)) accAdditional.BillingStreet += ', ' + member.Provided_Address_Line_3__c;
                    accAdditional.BillingPostalCode = member.Provided_Postal_Code__c;
                    accAdditional.BillingCity = member.Provided_City__c;

                    upsert accAdditional;
                }
                member.Patient__c = accAdditional.Id;
            }
            catch (Exception ex) {
                successfullyCreatedAllAccounts = false;

                Note n2 = createNewNote('Unable to automatically assign an additional member', null, form.Id);

                if (ex.getMessage() != null && ex.getMessage().contains('DUPLICATES_DETECTED')) {
                    String err = 'Unable to create additional member Account for ' + member.Provided_First_Name__c + ' ' + member.Provided_Last_Name__c + ' due to potential DUPLICATE Patient'; System.debug(LoggingLevel.WARN, err);
                    n2.Body = err;
                }
                else {
                    ret.errorCode = 'ERROR_DD_CRF';
                }
                notesToInsert.add(n2);
            }
        }


        insert additionalMembersToInsert;

        System.debug(':processSignupRequest:successfullyCreatedAllAccounts ' + successfullyCreatedAllAccounts);
        form.All_Accounts_Provisioned__c = successfullyCreatedAllAccounts;

        if (!form.All_Accounts_Provisioned__c) {
            Note n2 = new Note();
            n2.Body = 'This request can not be automatically processed, as there were errors creating or matching Member Accounts';
            n2.ParentId = form.Id;
            n2.Title = 'Request needs additional manual processing';
            notesToInsert.add(n2);
        }

        update form;
        insert notesToInsert;

        System.debug(':processSignupRequest:redirectUrl ' + ret.redirectUrl);

        ret.formAcceptable = form.All_Accounts_Provisioned__c && String.isNotBlank(ret.redirectUrl) && String.isBlank(ret.errorCode);
        ret.flowId = form.GC_RedirectFlow_Id__c;
        if (!ret.formAcceptable) {
            ret.redirectUrl = null;
            ret.flowId = null;
        }
        ret.formSaved = true;
        ret.mainAccount = accMainPayer.Id;

        //[2024-01-15] if it's a corporate membership, and free, activate it now
        if (corporateTier != null && form.Subscription_Amount__c == 0) {
            Membership_Contract__c membershipContract = null;
            try {
                membershipContract = activateMembershipFromSignupForm(form.Id);
            }
            catch (Exception ex) {
                ret.errorCode = 'ERROR_ACT_FAIL';
            }

            if (membershipContract != null) sendActivationEmail(accMainPayer.Id, membershipContract);
        }


        return ret;
    }

    public static void sendActivationEmail(Id accountId, Membership_Contract__c membershipContract) {
        try {
            Membership_Contract__c contract = [SELECT Id, Membership_Tier__c, Membership_Tier__r.Welcome_Email_Template__c FROM Membership_Contract__c WHERE Id = :membershipContract.Id];

            Account account = [SELECT Id, PersonEmail FROM Account WHERE Id = :accountId];

            //no template defined
            if (String.isEmpty(contract?.Membership_Tier__r?.Welcome_Email_Template__c)) return;

            EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :contract.Membership_Tier__r.Welcome_Email_Template__c];

            List<String> toAddress = new List<String>();
            toAddress.add(account.PersonEmail);
            Contact con = [SELECT Id, Email FROM Contact WHERE AccountId = :accountId];

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTemplateId(et.Id);
            mail.setToAddresses(toAddress);
            mail.setTargetObjectId(con.Id);
            mail.setWhatId(accountId);
            mail.setSaveAsActivity(true);
            mail.setUseSignature(false);
            mail.setOrgWideEmailAddressId([SELECT Id FROM OrgWideEmailAddress WHERE Address =:OnlineStoreSettingsManager.getStoreSettings().Default_Org_Wide_Address__c].Id);

            List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
            allmsg.add(mail);

            System.debug('sending email..');
            List<Messaging.SendEmailResult> res = Messaging.sendEmail(allmsg, false);
            for (Messaging.SendEmailResult sendEmailResult : res) {
                System.debug(sendEmailResult.success);
                System.debug(sendEmailResult.errors);
            }

        }
        catch (Exception e) {
            //ignore
            System.debug(e.getMessage());
        }
    }

    //    @AuraEnabled(Cacheable=true)
    //    public static String aura_getMembershipSignupForm(Id recordId) {
    //        MembershipSignupForm__c ret = [SELECT Id,
    //                All_Accounts_Provisioned__c,
    //                Requested_Contact_For_DD__c,
    //                Mandate_Created__c,
    //                Subscription_Created__c
    //        FROM MembershipSignupForm__c WHERE Id = :recordId];
    //        return JSON.serializePretty(ret);
    //    }

    public static Note createNewNote(String title, String body, Id parentId) {
        Note ret = new Note();
        ret.Body = body;
        ret.ParentId = parentId;
        ret.Title = title;
        return ret;
    }

    public static Decimal calculateTotalAmount(PricesPerType pricesPerType, List<AdditionalMember> adults, List<AdditionalMember> children) {
        try {
            if (pricesPerType == null) return null;

            return (1 * pricesPerType.adultPayer)
                    + (adults != null ? adults.size() : 0) * pricesPerType.adult
                    + (children != null ? children.size() : 0) * pricesPerType.child;
        }
        catch (Exception e) {
            System.debug('::msC:calculateTotalAmount:ex:' + e.getMessage());
        }
        return null;
    }

    @AuraEnabled(Cacheable=false)
    public static String aura_completeRedirectFlow(String flowId) {
        try {
            return completeRedirectFlow(flowId);
            //return null;
        }
        catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, ex.getMessage());
            throw newAuraHandledException(ex.getMessage());
        }
    }

    /**
     * creates mandata via api. creates subscription via api. stores mandate, subscription, updates form.
     *
     * @param flowId flow id (MembershipSignupForm__c.GC_RedirectFlow_Id__c)
     *
     * @return
     */
    public static String completeRedirectFlow(String flowId) {
        System.debug('::memCtrl:completeRedirectFlow:' + flowId);

        List<MembershipSignupForm__c> mReqs = [
                SELECT
                        Id,
                        All_Accounts_Provisioned__c,
                        Subscription_Amount__c,
                        Membership_Tier_Level__c,
                        Session_Id__c,
                        Patient__c,
                        Membership_PriceBook__c,
                        Membership_PriceBook__r.Name
                FROM MembershipSignupForm__c
                WHERE GC_RedirectFlow_Id__c = :flowId
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        if (mReqs.size() == 0) return ('ERR_INVALID_FLOW_ID');

        MembershipSignupForm__c form = mReqs[0];

        if (!form.All_Accounts_Provisioned__c) {
            return ('ERR_NOTALLACCOUNTS');
        }

        GoCardlessService.RedirectFlowEntity flowResponse = GoCardlessService.completeRedirectFlow(flowId, form.Session_Id__c);

        System.debug('::completeRedirectFlow:flowResponse:' + flowResponse);

        if (flowResponse == null) {
            return ('ERR_EXT');
        }

        GoCardless_Mandate__c mandate = new GoCardless_Mandate__c();
        if (flowResponse.links != null && String.isNotBlank(flowResponse.links.mandate)) {

            GoCardless_Subscription__c subscription = createSubscription(form.Id, flowResponse.links.mandate);

            if (subscription != null) {
                //create mandate
                mandate.Mandate__c = flowResponse.links.mandate;
                mandate.Mandate_Reference__c = flowResponse.mandate_reference;
                mandate.Creditor__c = flowResponse.links.creditor;
                mandate.Customer__c = flowResponse.links.customer;
                mandate.Customer_Bank_Account__c = flowResponse.links.customer_bank_account;
                insert mandate;

                subscription.GoCardless_Mandate__c = mandate.Id;
                insert subscription;

                form.GoCardless_Mandate__c = mandate.Id;
                form.GoCardless_Subscription__c = subscription.Id;

                update form;

            }
            else {

                //create mandate
                mandate.Mandate__c = flowResponse.links.mandate;
                mandate.Mandate_Reference__c = flowResponse.mandate_reference;
                mandate.Creditor__c = flowResponse.links.creditor;
                mandate.Customer__c = flowResponse.links.customer;
                mandate.Customer_Bank_Account__c = flowResponse.links.customer_bank_account;
                insert mandate;

                form.GoCardless_Mandate__c = mandate.Id;
                update form;

                if (flowResponse != null) return ('ERR_NO_SUBSCRIPTION ' + JSON.serializePretty(flowResponse));
                else return ('ERR_NO_SUBSCRIPTION 1 ' + null);
            }
        }
        else {
            if (flowResponse != null) return ('ERR_NO_MANDATE 2 ' + JSON.serializePretty(flowResponse));
            else return ('ERR_NO_MANDATE 2 ' + null);
        }

        return JSON.serializePretty(flowResponse);

    }

    public static Membership_Contract__c activateMembershipFromSignupForm(Id formId) {
        List<MembershipSignupForm__c> forms = [
                SELECT
                        Id,
                        All_Accounts_Provisioned__c,
                        Subscription_Amount__c,
                        Membership_Tier_Level__c,
                        Session_Id__c,
                        Patient__c,
                        Membership_PriceBook__c,
                        Membership_PriceBook__r.Name,
                        GoCardless_Subscription__c,
                        GoCardless_Mandate__c
                FROM MembershipSignupForm__c
                WHERE Id = :formId
                LIMIT 1
        ];

        if (forms.size() == 0) throw new MHCException('No such signup form');

        MembershipSignupForm__c form = forms[0];

        if (!form.All_Accounts_Provisioned__c) throw new MHCException('Not all accounts provisioned for the signup form ' + JSON.serialize(form));
        if (form.Subscription_Amount__c != 0 && form.Subscription_Amount__c != null) {
            if (form.GoCardless_Subscription__c == null) throw new MHCException('There is no Direct Debit subscription for that form');
            if (form.GoCardless_Mandate__c == null) throw new MHCException('There is no Direct Debit mandate for that form');
        }

        //create Contract
        Contract contract = createContract(form.Patient__c, Date.today());

        //find applicable membership Tier
        Membership_Tier__c memTier = getCurrentMembershipTierForPriceBookId(form.Membership_PriceBook__c);
        if (memTier == null) throw new MHCException('No Membership Tier found applicable to this request');

        //create Membership Contract
        Membership_Contract__c memContract = createMembershipContract(contract.Id, memTier.Id);

        //assign this membership Contract to all accounts in contract

        addMembershipContractToAccount(memContract, form.Patient__c, LEVEL_ADULT_PAYER, form.Membership_PriceBook__r.Name);

        List<Additional_Member__c> additionalMembers = [SELECT Id, Patient__c, Membership_Level__c FROM Additional_Member__c WHERE Membership_Signup_Form__c = :formId];

        for (Additional_Member__c additionalMember : additionalMembers) {
            if (additionalMember.Patient__c != null) {
                addMembershipContractToAccount(memContract, additionalMember.Patient__c, additionalMember.Membership_Level__c, form.Membership_PriceBook__r.Name);
            }
        }

        return memContract;

    }

    public static Membership_Contract__c createMembershipContract(Id contractId, Id membershipTierId) {
        Membership_Contract__c memContract = new Membership_Contract__c();
        memContract.Contract__c = contractId;
        memContract.Membership_Tier__c = membershipTierId;
        insert memContract;

        System.debug('::createMembershipContract:done for contractId:' + contractId);
        return memContract;
    }
    public static Contract createContract(Id mainAccountId, Date startDate) {
        Contract contract = new Contract();
        contract.AccountId = mainAccountId;
        contract.StartDate = startDate;
        insert contract;

        System.debug('::createContract:done for account:' + mainAccountId);
        return contract;
    }

    public static List<Account> addMembershipContractToAccount(Membership_Contract__c memContract, Id accountId, String membershipLevel, String membershipPriceBookName) {

        System.debug('::addMembershipContractToAccounts:done for memContractId:' + memContract.Id);

        List<Account> accsUpdate2 = [
                SELECT
                        Id,
                        Membership_Change_Dates__c,
                        Membership_Start_Date__c,
                        Member_Since__c,
                        Membership_Level__c,
                        Home_Clinic__c
                FROM Account
                WHERE Id = :accountId
        ];

        for (Account account : accsUpdate2) {
            account.Membership_Level__c = membershipLevel;
            account.Membership_Contract__c = memContract.Id;
            account.Membership_Tier__c = memContract.Membership_Tier__c;
            account.Patient_Type__c = 'Member';
            account.Member_Status__c = 'Member';
            if (account.Member_Since__c == null) account.Member_Since__c = Date.today();
            account.Membership_Start_Date__c = Date.today();
            account.Membership_Change_Dates__c = Date.today();
            //account.Membership_Type__c = membershipPriceBookName;
            account.Payment_Frequency__c = 'Monthly';
            if (account.Home_Clinic__c == null) account.Home_Clinic__c = 'Fulham';
        }

        update accsUpdate2;

        return accsUpdate2;
    }


    public static GoCardless_Subscription__c createSubscription(String formId, String mandateExtId) {

        String errorMsg = null;
        try {

            MembershipSignupForm__c form = [
                    SELECT Id,
                            Name,
                            GoCardless_Mandate__c,
                            Subscription_Amount__c,
                            Membership_Tier_Level__c,
                            Opportunity__c,
                            Patient__c,
                            Membership_PriceBook__r.Name,
                            Referral_Code__c
                    FROM MembershipSignupForm__c
                    WHERE Id = :formId
            ];

            Integer nMonthFree = checkDiscountCodeForMonths(form.Referral_Code__c);

            GoCardlessService.SubscriptionEntity gcSubscription = new GoCardlessService.SubscriptionEntity();
            gcSubscription.metadata = new GoCardlessService.Metadata();
            gcSubscription.metadata.order_no = form.Name;
            gcSubscription.links = new GoCardlessService.Links();
            gcSubscription.links.mandate = mandateExtId;
            gcSubscription.amount = '' + (form.Subscription_Amount__c * 100).intValue();
            gcSubscription.currency_jsonsafe = 'GBP';
            gcSubscription.interval_unit = 'monthly';
            if (nMonthFree != null) {
                gcSubscription.start_date = Date.today().addMonths(nMonthFree).addDays(1);
            }

            gcSubscription.name = 'MHC ' + form.Membership_Tier_Level__c + ' Plan';


            GoCardlessService.SubscriptionEntity ret = GoCardlessService.createSubscription(gcSubscription);
            if (ret == null) {
                errorMsg = 'System error communicating to GoCardless during subscription creation (ERR_RET_NULL)';
            }
            else {
                GoCardless_Subscription__c goCardlessSubscription = new GoCardless_Subscription__c();
                goCardlessSubscription.GoCardless_Id__c = ret.id;
                goCardlessSubscription.Amount__c = Decimal.valueOf(ret.amount) / 100;
                goCardlessSubscription.Start_Date__c = ret.start_date;
                goCardlessSubscription.End_Date__c = ret.end_date;

                return goCardlessSubscription;
            }
        }
        catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, ex.getStackTraceString());
            System.debug(LoggingLevel.ERROR, '' + ex.getMessage());
            errorMsg = ex.getMessage();
        }

        if (errorMsg != null) {
            Note n2 = new Note();
            n2.Body = 'This request can not be automatically processed, as there was an error creating the GoCardless subscription:' + errorMsg;
            n2.ParentId = formId;
            n2.Title = 'Request needs additional manual processing';
            insert n2;
        }

        return null;

    }
    public static Exception newAuraHandledException(String msg) {
        AuraHandledException aEx = new AuraHandledException(msg);
        aEx.setMessage(msg);
        return aEx;
    }


    public virtual class SignupException extends Exception {
    }

    public class ProcessSignupResponse {
        public String uid; // equals Session_Id on the form
        public String flowId;
        public String redirectUrl;
        public String mainAccount;
        public Boolean formSaved;
        public Boolean formAcceptable;
        public String errorCode;
        public String errorMsg;
    }

    public class PricesPerType {
        public Decimal adultPayer = 9999;
        public Decimal adult = 9999;
        public Decimal child = 9999;
        public Id priceBookId;
        public String priceBookName;
    }

    public class MemSignUpRequest {

        public String source;
        public String tier;
        public String refCode;

        public String accountId;

        public String firstName;
        public String lastName;

        public String email;
        public String phone;
        public String gender;

        public String address1;
        public String address2;
        public String address3;
        public String city;
        public String postalCode;

        public String ddselected;
        public String dob_d;
        public String dob_m;
        public String dob_y;

        public String corporate;

        public List<AdditionalMember> adultMembers;
        public List<AdditionalMember> childMembers;

        public Boolean checkNews;
        public Boolean checkToc;

        public String directDebitSuccessUrl;

        public Date getDOB() {
            if (String.isBlank(dob_d) || String.isBlank(dob_m) || String.isBlank(dob_y)) return null;
            return Date.newInstance(Integer.valueOf(dob_y), Integer.valueOf(dob_m), Integer.valueOf(dob_d));
        }
    }

    public class AdditionalMember {
        public String firstName;
        public String lastName;

        public String email;
        public String phone;
        public String gender;

        public String address1;
        public String address2;
        public String address3;
        public String city;
        public String postalCode;

        public String dob_d;
        public String dob_m;
        public String dob_y;

        public Boolean isAdult;

        public Date getDOB() {
            if (String.isBlank(dob_d) || String.isBlank(dob_m) || String.isBlank(dob_y)) return null;
            return Date.newInstance(Integer.valueOf(dob_y), Integer.valueOf(dob_m), Integer.valueOf(dob_d));
        }
    }

    //    public static String checkReferralCode(String refCode) {
    //        if (String.isNotBlank(refCode)) {
    //            refCode = refCode.trim();
    //            List<Referral_Code__c> codes = [SELECT Id, Instruction__c FROM Referral_Code__c WHERE Code__c = :refCode and Active__c = true];
    //            if (codes.size() > 0) return codes[0].Instruction__c;
    //        }
    //        return null;
    //    }

    public static Integer checkDiscountCodeForMonths(String code) {
        if (String.isNotBlank(code)) {
            code = code.trim();
            List<Discount_Code__c> codes = [
                    SELECT Id, Months_Free__c
                    FROM Discount_Code__c
                    WHERE Coupon_Code__c = :code
                    AND Active__c = TRUE
            ];
            if (codes.size() == 0 || (codes[0].Months_Free__c == null)) return null;
            return codes[0].Months_Free__c.intValue();
        }
        return null;
    }


    @AuraEnabled(Cacheable=false)
    public static String aura_checkDiscountCodeForMonths(String code) {
        Integer chk = checkDiscountCodeForMonths(code);
        if (chk != null) {
            return '✓ ' + chk + ' ';
        }
        else {
            return 'Not a valid code';
        }
    }

}