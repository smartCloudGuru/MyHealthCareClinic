/**
 * Created 8.2.2022..
 */

public without sharing class OnlBookUI {

    public static final String chars = '123456789ABCDEFGHJKLMNPQRSTUVWXYZ';

    public static final String SERVICE_TYPE_MEDICAL = 'Medical';
    public static final String SERVICE_TYPE_DENTAL = 'Dental';
    public static final String VIDEO = 'VIDEO';
    public static final String TELEPHONE = 'TELEPHONE';


    public static final HeyDoc_Integration_Setting__mdt INTEGRATIONS_SETTINGS = [
            SELECT Reservation_Patient_Id__c, Reservation_Product_Id__c
            FROM HeyDoc_Integration_Setting__mdt
            LIMIT 1
    ];

    // get custom settings (in aura enabled function to pass to LWC)
    @AuraEnabled(Cacheable=true)
    public static String getCustomSettings() {
        return OnlineStoreSettingsManager.getStoreSettings().IdealPostcodes_API_Key__c;
    }


    public class OptionWrapper {
        public String label;
        public String value;
        public String wtgId;
        public String wtId;
        public Boolean isVideoOrTel;

        public OptionWrapper() {

        }

        public OptionWrapper(String label, String value) {
            this.label = label;
            this.value = value;
            this.wtgId = null;
            this.wtId = null;
            this.isVideoOrTel = false;
        }
        public OptionWrapper(String label, String value, String wtgId, String wtId, Boolean isVideoOrTel) {
            this.label = label;
            this.value = value;
            this.wtgId = wtgId;
            this.wtId = wtId;
            this.isVideoOrTel = isVideoOrTel;
        }

        public OptionWrapper(String label, String value, Id wtgId, Id wtId) {
            this.label = label;
            this.value = value;
            this.wtgId = wtgId;
            this.wtId = wtId;
            this.isVideoOrTel = null;
        }
    }


    /**
     * Gets available categories of products based on given store and division. It does that by querying products,
     * filtering them and returning JSON-serialized version of categories set.
     *
     * @param store
     * @param division
     *
     * @return
     */
    @AuraEnabled(Cacheable=true)
    public static String getAvailableCategories(String store, String division) {
        Set<String> categories = new Set<String>();
        List<Product2> products = loadProductsByDivision(division);

        if (products != null) for (Product2 prod : products) {
            if (prod.Available_in_Stores__c != null && prod.Available_in_Stores__c.contains(store)) {
                gatherCategories(categories, prod);
            }
        }

        return JSON.serialize(sortCategories(categories));
    }

    /**
     * This function is used to load a list of 'Product2' records from the database based on specific criteria.
     * It filters the records where 'Include_in_Store__c' is TRUE, 'IsActive' is TRUE and 'Hide_In_Store_Browsing__c' is FALSE.
     * If the division parameter is not null, it also filters the records where 'Work_Type_Group__r.Service_Type__c' matches the division value.
     * The function returns a list of 'Product2' filtered records.
     *
     * @param division A String parameter representing the division category by which the records should be filtered. "Medical" or "Dental".
     *                  If it is not null, then 'Work_Type_Group__r.Service_Type__c' should match this division value.
     *
     * @return List<Product2> A list of 'Product2' records that meet the specified criteria.
     *
     * @example List<Product2> result = loadProductsByDivision(division);
     */
    private static List<Product2> loadProductsByDivision(String division) {
        String filter = ' WHERE Include_in_Store__c = TRUE AND IsActive = TRUE AND Hide_In_Store_Browsing__c = FALSE';

        if (division != null) {
            filter += ' AND Work_Type_Group__r.Service_Type__c = :division';
        }

        List<Product2> products = Database.query('SELECT Id, Store_Categories__c, Available_in_Stores__c FROM Product2' + filter);
        return products;
    }

    private static void gatherCategories(Set<String> categorySet, Product2 prod) {
        String[] SKIPPED_CATEGORIES = new String[]{'appointments', 'promoted'};
        List<String> productCategories = prod.Store_Categories__c?.split(';');

        if (productCategories != null) {
            for (String category : productCategories) {
                if (String.isNotEmpty(category) && !SKIPPED_CATEGORIES.contains(category.toLowerCase())) {
                    categorySet.add(category);
                }
            }
        }
    }

    private static Set<String> sortCategories(Set<String> categories) {
        List<String> sortedList = new List<String>(categories);
        sortedList.sort();

        String[] PRIORITY_CATEGORIES = new String[]{'GP Consultation', 'Health Screens', 'Sexual Health Tests', 'Blood Test'};
        Set<String> sortedSet = new Set<String>();

        for (String category : PRIORITY_CATEGORIES) {
            if (sortedList.contains(category)) {
                sortedSet.add(category);
            }
        }

        for (String category : sortedList) {
            if (!sortedSet.contains(category)) {
                sortedSet.add(category);
            }
        }

        return sortedSet;
    }

    @AuraEnabled(Cacheable=true)
    public static String getMedicalProducts() {

        List<Product2> products = [
                SELECT Id, Name, Work_Type_Group__c, Work_Type_Group__r.Appointment_Type__c
                FROM Product2
                WHERE Work_Type_Group__c != NULL
                AND Work_Type_Group__r.Service_Type__c = :SERVICE_TYPE_MEDICAL
                AND Work_Type_Group__r.Heydoc_Id__c != NULL
                AND Appointment__c = TRUE
                AND IsActive = TRUE
                AND Hide_In_Store_Browsing__c = FALSE
                ORDER BY Name
        ];

        Set<Id> wtgIds = new Set<Id>();
        for (Product2 product : products) {
            wtgIds.add(product.Work_Type_Group__c);
        }

        List<WorkTypeGroupMember> workTypeGroupMembers = [SELECT Id, WorkTypeGroupId, WorkTypeId FROM WorkTypeGroupMember WHERE WorkTypeGroupId IN :wtgIds];

        Map<String, String> map_wtgId_wtId = new Map<String, String>();
        for (WorkTypeGroupMember workTypeGroupMember : workTypeGroupMembers) {
            map_wtgId_wtId.put(workTypeGroupMember.WorkTypeGroupId, workTypeGroupMember.WorkTypeId);
        }

        List<OnlBookUI.OptionWrapper> ret = new List<OnlBookUI.OptionWrapper>();
        for (Product2 product : products) {
            ret.add(
                    new OnlBookUI.OptionWrapper(
                            product.Name,
                            product.Id,
                            product.Work_Type_Group__c,
                            map_wtgId_wtId.get(product.Work_Type_Group__c),
                            (product.Work_Type_Group__r?.Appointment_Type__c == 'VIDEO' || product.Work_Type_Group__r?.Appointment_Type__c == 'TELEPHONE')

                    ));
        }

        return JSON.serialize(ret);
    }


    @AuraEnabled(Cacheable=true)
    public static String getAppointmentProducts() {

        List<Product2> products = [
                SELECT Id, Name, Work_Type_Group__c, Work_Type_Group__r.Appointment_Type__c
                FROM Product2
                WHERE Work_Type_Group__c != NULL
                //AND ((Work_Type_Group__r.Service_Type__c = 'Dental' AND Work_Type_Group__r.Aerona_Id__c != NULL) OR (Work_Type_Group__r.Service_Type__c = 'Medical' AND Work_Type_Group__r.Heydoc_Id__c != NULL))
                AND Work_Type_Group__r.Appointment_Type__c != NULL
                AND Appointment__c = TRUE
                AND IsActive = TRUE
                ORDER BY Name
        ];

        Set<Id> wtgIds = new Set<Id>();
        for (Product2 product : products) {
            wtgIds.add(product.Work_Type_Group__c);
        }

        List<WorkTypeGroupMember> workTypeGroupMembers = [SELECT Id, WorkTypeGroupId, WorkTypeId FROM WorkTypeGroupMember WHERE WorkTypeGroupId IN :wtgIds];

        Map<String, String> map_wtgId_wtId = new Map<String, String>();
        for (WorkTypeGroupMember workTypeGroupMember : workTypeGroupMembers) {
            map_wtgId_wtId.put(workTypeGroupMember.WorkTypeGroupId, workTypeGroupMember.WorkTypeId);
        }

        List<OnlBookUI.OptionWrapper> ret = new List<OnlBookUI.OptionWrapper>();
        for (Product2 product : products) {
            ret.add(new OnlBookUI.OptionWrapper(
                    product.Name, product.Id, product.Work_Type_Group__c, map_wtgId_wtId.get(product.Work_Type_Group__c),
                    (product.Work_Type_Group__r?.Appointment_Type__c == VIDEO || product.Work_Type_Group__r?.Appointment_Type__c == TELEPHONE))
            );
        }

        return JSON.serialize(ret);
    }

    @AuraEnabled(Cacheable=true)
    public static String getDentalProducts() {

        List<Product2> products = [
                SELECT Id, Name, Work_Type_Group__c, Work_Type_Group__r.Appointment_Type__c
                FROM Product2
                WHERE Work_Type_Group__c != NULL
                AND Work_Type_Group__r.Service_Type__c = :SERVICE_TYPE_DENTAL
                AND Work_Type_Group__r.Aerona_Id__c != NULL
                AND Appointment__c = TRUE
                AND IsActive = TRUE
                AND Hide_In_Store_Browsing__c = FALSE
                ORDER BY Name
        ];

        Set<Id> wtgIds = new Set<Id>();
        for (Product2 product : products) {
            wtgIds.add(product.Work_Type_Group__c);
        }

        List<WorkTypeGroupMember> workTypeGroupMembers = [SELECT Id, WorkTypeGroupId, WorkTypeId FROM WorkTypeGroupMember WHERE WorkTypeGroupId IN :wtgIds];

        Map<String, String> map_wtgId_wtId = new Map<String, String>();
        for (WorkTypeGroupMember workTypeGroupMember : workTypeGroupMembers) {
            map_wtgId_wtId.put(workTypeGroupMember.WorkTypeGroupId, workTypeGroupMember.WorkTypeId);
        }

        List<OnlBookUI.OptionWrapper> ret = new List<OnlBookUI.OptionWrapper>();
        for (Product2 product : products) {
            ret.add(new OnlBookUI.OptionWrapper(
                    product.Name,
                    product.Id, product.Work_Type_Group__c, map_wtgId_wtId.get(product.Work_Type_Group__c),
                    (product.Work_Type_Group__r?.Appointment_Type__c == VIDEO || product.Work_Type_Group__r?.Appointment_Type__c == TELEPHONE))

            );
        }

        return JSON.serialize(ret);
    }

    @AuraEnabled(Cacheable=true)
    public static String aura_getPatientType(Id pid) {
        return getPatientType(pid);
    }

    /**
     * The `getPatientType` is a static method that determines the patient type
     * in relation to the patient ID provided.
     *
     * @param pid the ID of the account/patient whose type is to be determined.
     *
     * @return String that represents the patient type. Possible return values are 'Member', 'Returning', 'New', and null.
     *
     * - 'Member' is returned if the patient type related to the patient ID is discovered to be a 'Member'.
     * - 'Returning' is returned if the patient is discovered to have one or more associated opportunities with a 'Closed Won' stage.
     * - 'New' is returned if none of the above conditions are met.
     * - null is returned if no account/patient is found with the provided ID.
     *
     * Note:
     * ------
     * This method makes use of Salesforce's SOQL to fetch the account and its related opportunities.
     * The SOQL query fetches the Account ID and Patient Type custom field, as well as the IDs and Stage Names of related opportunities with a 'Closed Won' stage.
     */
    public static String getPatientType(Id pid) {

        List<Account> accs = [
                SELECT Id,
                        Patient_Type__c, (SELECT Id, StageName FROM Opportunities WHERE StageName = 'Closed Won')
                FROM Account
                WHERE Id = :pid
                AND DoNotSync__pc != TRUE
        ];

        if (accs.isEmpty()) return null;

        if (accs[0].Patient_Type__c == 'Member') return 'Member';

        if (accs[0].Opportunities != null && accs[0].Opportunities.size() > 0) return 'Returning';

        return 'New';

    }

    @AuraEnabled(Cacheable=true)
    public static String getSpecialInstructionsForProduct(String pid) {
        List<Product2> retlist = [SELECT Id, Special_Instructions__c FROM Product2 WHERE Id = :pid];
        if (retlist != null && retlist.size() > 0) return retlist.get(0).Special_Instructions__c;
        return null;
    }

    /**
     * Used by "theo" form in online boking. will try to find an existing account, or will create a new account for the given request data
     *
     * @param request JSON string of resolve request (form data)
     *
     * @return accountId (existing or new, or null in case of error
     */
    @AuraEnabled(Cacheable=false)
    public static String resolveAccount(String request) {
        try {
            TheoFormRequest req = (TheoFormRequest) JSON.deserialize(request, TheoFormRequest.class);

            List<Account> accs = [
                    SELECT
                            Id, PersonEmail, Store_UUID__c, Date_of_Birth__c, FirstName, LastName, Gender__c, PersonMobilePhone,
                            BillingStreet,
                            BillingCity,
                            BillingPostalCode,
                            BillingState
                    FROM Account
                    WHERE PersonEmail = :req.theoEmail
                    AND DoNotSync__pc != TRUE
            ];

            Date dob = Date.newInstance(Integer.valueOf(req.dob_y), Integer.valueOf(req.dob_m), Integer.valueOf(req.dob_d));
            Account ret = null;
            for (Account account : accs) {
                if ((account.Date_of_Birth__c != null) && (account.Date_of_Birth__c == dob || account.Date_of_Birth__c == dob.addDays(1) || account.Date_of_Birth__c == dob.addDays(-1))) {
                    ret = account;
                    break;
                }
                if (account.Date_of_Birth__c == null && account.FirstName != null && account.FirstName.equalsIgnoreCase(req.firstName)) {
                    ret = account;
                }
            }


            if (ret == null) {
                ret = new Account();
                ret.Without_Login__c = true;
                ret.RecordTypeId = Cache.recordTypeId(AccountManager.RT_PERSON_ACCOUNT);
                ret.Patient_Type__c = 'New';
            }

            if (ret.Date_of_Birth__c == null) ret.Date_of_Birth__c = dob;
            if (String.isBlank(ret.FirstName)) ret.FirstName = req.firstName;
            if (String.isBlank(ret.LastName)) ret.LastName = req.lastName;
            if (String.isBlank(ret.Store_UUID__c)) ret.Store_UUID__c = new Uuid().getValue();
            if (String.isBlank(ret.Gender__c)) ret.Gender__c = req.gender;
            if (String.isBlank(ret.PersonMobilePhone)) ret.PersonMobilePhone = req.theoPhone;
            if (String.isBlank(ret.PersonEmail)) ret.PersonEmail = req.theoEmail;
            if (String.isBlank(ret.BillingStreet)) {
                ret.BillingStreet = req.address1;
                if (!String.isBlank(req.address2)) ret.BillingStreet += ', ' + req.address2;
                if (!String.isBlank(req.address3)) ret.BillingStreet += ', ' + req.address3;
            }
            if (String.isBlank(ret.BillingPostalCode)) ret.BillingPostalCode = req.postalCode;
            if (String.isBlank(ret.BillingCity)) ret.BillingCity = req.city;
            if (String.isBlank(ret.BillingState)) ret.BillingState = req.county;


            upsert ret;

            return JSON.serialize(ret);
        }
        catch (Exception ex) {
            System.debug('msg' + ex.getMessage());
            throw newAuraHandledException('MISMATCH ' + ex.getMessage());
        }


    }

    @AuraEnabled(Cacheable=true)
    public static String getProducts(String params) {

        ProductFilter filter = (ProductFilter) JSON.deserialize(params, ProductFilter.class);

        List<ProductWrapper> ret = new List<ProductWrapper>();

        Boolean showAll = false;
        Boolean showHidden = false;
        if (filter.dev == 'showall') {
            showAll = true;
        }

        if (filter.showHidden == true) {
            showHidden = true;
        }

        List<Product2> allProducts = [
                SELECT Id,
                        Name,
                        ProductCode,
                        Store_Categories__c,
                        Store_Sub_Category__c,
                        Work_Type_Group__c,
                        Store_Sort_Order__c,
                        Store_Title__c,
                        Store_Subtitle__c,
                        Store_Highlight__c,
                        Store_Image__c,
                        Store_Upsell_Tier__c,
                        Store_Upsell_Description__c,
                        Store_Upsell_Group__c,
                        Store_Hide_Practitioner_List__c,
                        Store_Attachment_Required__c,
                        Store_Attachment_Text__c,
                        Work_Type_Group__r.Service_Type__c,
                        Work_Type_Group__r.Appointment_Type__c,
                        Hide_In_Store_Browsing__c,
                        Description,
                        Price_Description__c,
                        Offer_Price__c,
                        Online_Store_Tags__c,
                        Business_Unit__c,
                        Requirements__c,
                        Store_Info__c, (
                        SELECT Id,
                                Pricebook2.Name,
                                Pricebook2.IsStandard,
                                Pricebook2.IsActive,
                                UnitPrice
                        FROM PricebookEntries
                )
                FROM Product2
                WHERE Work_Type_Group__c != NULL
                AND (Hide_In_Store_Browsing__c = FALSE OR Hide_In_Store_Browsing__c = :showHidden)
                AND Work_Type_Group__r.Appointment_Type__c != NULL
                AND
                (
                        (IsActive = TRUE AND IsActive = :showAll)
                        OR
                        (
                                Appointment__c = TRUE
                                AND IsActive = TRUE
                                AND Include_in_Store__c = TRUE
                                AND Available_in_Stores__c INCLUDES (:filter.storeName)
                        ))
                ORDER BY Store_Sub_Category__c, Store_Sort_Order__c, Name ASC
        ];


        List<Id> productIds = new List<Id>();
        List<Product2> products = new List<Product2>();

        Boolean add = true;
        Map<Id, Id> mapProductId_WTGId = new Map<Id, Id>();
        for (Product2 product : allProducts) {
            if (String.isBlank(product.Store_Title__c)) product.Store_Title__c = product.Name;
            add = false;
            if (filter == null) {
                add = true;
            }
            else {
                Boolean add1 = false;
                Boolean add2 = false;
                Boolean add3 = false;

                if (String.isNotBlank(filter.wtgServiceType)) {
                    add1 = (product.Work_Type_Group__c != null && product.Work_Type_Group__r.Service_Type__c == filter.wtgServiceType);
                }
                else add1 = true;

                if (String.isNotBlank(filter.category) && product.Store_Categories__c != null) {
                    add2 = (product.Store_Categories__c.indexOf(filter.category) >= 0);
                }
                else if (product.Store_Categories__c == null) {
                    add2 = false;
                }
                else add2 = true;

                if (String.isNotBlank(filter.voucherTag)) {
                    if (String.isEmpty(product.Online_Store_Tags__c)) add3 = false;
                    else {
                        String[] tags = product.Online_Store_Tags__c.split(';');
                        for (String tag : tags) {
                            if (filter.voucherTag == tag) add3 = true;
                            break;
                        }
                    }
                }
                else {
                    add3 = true;
                }

                add = add1 && add2 && add3;
            }

            if (add) {
                productIds.add(product.Id);
                products.add(product);
                mapProductId_WTGId.put(product.Id, product.Work_Type_Group__c);
            }
        }

        //get any eventual upsell products for the products retrieved
        List<Product2> upsellProducts = [
                SELECT Id,
                        Name,
                        ProductCode,
                        Store_Categories__c,
                        Work_Type_Group__c,
                        Store_Sort_Order__c,
                        Store_Title__c,
                        Store_Subtitle__c,
                        Store_Highlight__c,
                        Store_Image__c,
                        Store_Upsell_Tier__c,
                        Store_Upsell_Description__c,
                        Store_Upsell_Group__c,
                        Store_Hide_Practitioner_List__c,
                        Work_Type_Group__r.Service_Type__c,
                        Work_Type_Group__r.Appointment_Type__c,
                        Description,
                        Requirements__c,
                        Store_Info__c, (
                        SELECT Id,
                                Pricebook2.Name,
                                Pricebook2.IsStandard,
                                Pricebook2.IsActive,
                                UnitPrice
                        FROM PricebookEntries
                )
                FROM Product2
                WHERE Store_Upsell_Group__c IN :productIds
                AND Work_Type_Group__c != NULL
                AND Work_Type_Group__r.Appointment_Type__c != NULL
                AND
                (
                        (IsActive = TRUE AND IsActive = :showAll)
                        OR
                        (
                                Appointment__c = TRUE
                                AND IsActive = TRUE
                                AND Include_in_Store__c = TRUE
                                AND Available_in_Stores__c INCLUDES (:filter.storeName)
                        ))
                ORDER BY Store_Upsell_Tier__c, Store_Sort_Order__c, Name ASC
        ];

        // put upsells also in the map, so we retrieve their data
        for (Product2 upsellProduct : upsellProducts) {
            mapProductId_WTGId.put(upsellProduct.Id, upsellProduct.Work_Type_Group__c);
        }

        List<WorkTypeGroupMember> workTypeMembers = [
                SELECT
                        Id,
                        WorkTypeGroupId,
                        WorkTypeId,
                        WorkType.Id,
                        WorkType.Appointment_Booking_Available_To__c,
                        WorkType.Appointment_Booking_Available_From__c
                FROM WorkTypeGroupMember
                WHERE WorkTypeGroupId IN :mapProductId_WTGId.values()
        ];

        Map<Id, WorkType> mapProductId_WT = new Map<Id, WorkType>();
        for (WorkTypeGroupMember workTypeGroupMember : workTypeMembers) {
            mapProductId_WT.put(workTypeGroupMember.WorkTypeGroupId, workTypeGroupMember.WorkType);
        }

        Map<Id, PricesByBook> mapPrices = new Map<Id, PricesByBook>();

        for (Product2 product : products) {
            mapPrices.put(product.Id, new PricesByBook());
            for (PricebookEntry pbe : product.PricebookEntries) {
                if (pbe.Pricebook2.IsActive && pbe.Pricebook2.IsStandard) {
                    mapPrices.get(product.Id).standardPrice = pbe.UnitPrice;
                    break;
                }
            }
        }

        for (Product2 product : upsellProducts) {
            mapPrices.put(product.Id, new PricesByBook());
            for (PricebookEntry pbe : product.PricebookEntries) {
                if (pbe.Pricebook2.IsActive && pbe.Pricebook2.IsStandard) {
                    mapPrices.get(product.Id).standardPrice = pbe.UnitPrice;
                    break;
                }
            }
        }


        for (Product2 product : products) {
            product.Name = normalizeProductName(product);
            ProductWrapper pw = new ProductWrapper(product,
                    mapPrices.get(product.Id).standardPrice,
                    mapProductId_WTGId.get(product.Id)
            );

            if (mapProductId_WTGId.get(product.Id) != null) {
                if (mapProductId_WT.get(mapProductId_WTGId.get(product.Id))?.Appointment_Booking_Available_From__c != null) {
                    pw.availableFrom = mapProductId_WT.get(mapProductId_WTGId.get(product.Id)).Appointment_Booking_Available_From__c.date();
                }
            }

            //add wrappers for eventual upsells
            for (Product2 upsellProduct : upsellProducts) {

                upsellProduct.Name = normalizeProductName(upsellProduct);
                if (upsellProduct?.Store_Upsell_Group__c == product.Id) {
                    pw.hasUpsells = true;

                    ProductWrapper pwUpsell = new ProductWrapper(upsellProduct,
                            mapPrices.get(upsellProduct.Id).standardPrice,
                            mapProductId_WTGId.get(upsellProduct.Id)
                    );

                    if (mapProductId_WTGId.get(upsellProduct.Id) != null) {
                        if (mapProductId_WT.get(mapProductId_WTGId.get(upsellProduct.Id)).Appointment_Booking_Available_From__c != null) {
                            pwUpsell.availableFrom = mapProductId_WT.get(mapProductId_WTGId.get(upsellProduct.Id)).Appointment_Booking_Available_From__c.date();
                        }
                    }
                    pw.upsells.add(pwUpsell);
                }
            }

            ret.add(pw);
        }

        return JSON.serialize(ret);
    }


    public static List<ServiceTerritory> getServiceCentersForProduct(String productId) {

        Id wtg = getWTGForProduct(productId);

        if (wtg != null) {
            return getServiceCentersForWTG(wtg);
        }
        return new List<ServiceTerritory>();
    }

    @AuraEnabled(Cacheable=true)
    public static String getServiceCentersWithHeydocId() {
        return JSON.serialize([SELECT Id, Name FROM ServiceTerritory WHERE Heydoc_Id__c != NULL ORDER BY Name]);
    }


    public static Id getWTGForProduct(String productId) {

        List<Product2> products = [SELECT Id, Work_Type_Group__c FROM Product2 WHERE Id = :productId];
        if (products.isEmpty()) return null;
        return products.get(0).Work_Type_Group__c;
    }

    @AuraEnabled(Cacheable=true)
    public static String getServiceCentersForWTGAsJSON(String wtgId) {

        return JSON.serialize(getServiceCentersForWTG(wtgId));
    }

    @TestVisible
    private static HttpRequest getHTTPRequest(String endpoint, String sessionId, String method) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Authorization', 'OAuth ' + sessionId);
        req.setHeader('Content-Type', 'application/json');
        req.setMethod(method);

        return req;
    }


    public static List<ServiceTerritory> getServiceCentersForWTG(String wtgId) {

        try {

            List<WorkTypeGroupMember> wtgms = [SELECT Id, WorkTypeId FROM WorkTypeGroupMember WHERE WorkTypeGroupId = :wtgId];
            List<String> wtIds = new List<String>();
            for (WorkTypeGroupMember workTypeGroupMember : wtgms) {
                wtIds.add(workTypeGroupMember.WorkTypeId);
            }
            List<ServiceTerritoryWorkType> stwts = [SELECT Id, ServiceTerritoryId FROM ServiceTerritoryWorkType WHERE WorkTypeId IN :wtIds];
            List<String> stIds = new List<String>();
            for (ServiceTerritoryWorkType serviceTerritoryWorkType : stwts) {
                stIds.add(serviceTerritoryWorkType.ServiceTerritoryId);
            }


            return [SELECT Id, Name, PostalCode, Street, City, Country, Store_Notice__c, Site__c FROM ServiceTerritory WHERE IsActive = TRUE AND Id IN :stIds ORDER BY Name ASC];
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            return null;
        }
    }


    @AuraEnabled(Cacheable=true)
    public static String getAllServiceResources() {
        List<ServiceResource> ret = [SELECT Id, Name FROM ServiceResource WHERE IsActive = TRUE];
        return JSON.serialize(ret);
    }

    public static Set<Id> getMedicalServiceResourcesIds() {
        List<ServiceResourceSkill> serviceResourceSkills = [SELECT Id, ServiceResourceId FROM ServiceResourceSkill WHERE Skill.DeveloperName != 'In-Clinic' AND ServiceResource.IsActive = TRUE];
        Set<Id> ret = new Set<Id>();
        for (ServiceResourceSkill serviceResourceSkill : serviceResourceSkills) {
            ret.add(serviceResourceSkill.ServiceResourceId);
        }
        return ret;
    }


    @AuraEnabled(Cacheable=true)
    public static String getServiceResourcesForTerritory(String stid) {
        Set<Id> allGPIds = getMedicalServiceResourcesIds();
        List<ServiceResource> ret = new List<ServiceResource>();
        List<ServiceTerritoryMember> stms = [SELECT Id, ServiceResourceId, ServiceResource.Id, ServiceResource.Name FROM ServiceTerritoryMember WHERE ServiceTerritoryId = :stid AND ServiceResource.IsActive = TRUE];
        for (ServiceTerritoryMember serviceTerritoryMember : stms) {
            if (allGPIds.contains(serviceTerritoryMember.ServiceResourceId)) ret.add(serviceTerritoryMember.ServiceResource);
        }
        return JSON.serialize(ret);
    }

    @AuraEnabled(Cacheable=true)
    public static String getServiceResourcesForTerritoryAndWorkTypeSkill(String stid, String wtid) {
        return JSON.serialize(getServiceResourcesForTerritoryAndWorkTypeSkill_asList(stid, wtid));
    }

    public static List<ServiceResource> getServiceResourcesForTerritoryAndWorkTypeSkill_asList(String stid, String wtid) {
        Set<Id> allGPIds = OnlBookDomain.getServiceResourcesIdsForWorTypeSkills(wtid);
        List<ServiceResource> ret = new List<ServiceResource>();
        List<ServiceTerritoryMember> stms = [SELECT Id, ServiceResourceId, ServiceResource.Id, ServiceResource.Name FROM ServiceTerritoryMember WHERE ServiceTerritoryId = :stid AND ServiceResource.IsActive = TRUE];
        for (ServiceTerritoryMember serviceTerritoryMember : stms) {
            if (allGPIds.contains(serviceTerritoryMember.ServiceResourceId)) ret.add(serviceTerritoryMember.ServiceResource);
        }
        return ret;
    }

    @AuraEnabled
    public static String aura_getAvailableSlotsByWorkTypeGroup(String workTypeGroupId, String serviceCenterId, Date slotDate, Boolean ctxInsideSF) {
        OnlBookAvailabilityController.setContextIsInsideSF(ctxInsideSF);
        return getAvailableSlots_raw(workTypeGroupId, serviceCenterId,
                Datetime.newInstance(slotDate, Time.newInstance(0, 0, 0, 0)),
                Datetime.newInstance(slotDate.addDays(1), Time.newInstance(0, 0, 0, 0)));
    }

    @AuraEnabled
    public static String aura_getAvailableSlotsByWorkTypeGroupDateRange(String workTypeGroupId, String serviceCenterId, Date fromDate, Date toDate) {
        return getAvailableSlots_raw(workTypeGroupId, serviceCenterId,
                Datetime.newInstance(fromDate, Time.newInstance(0, 0, 0, 0)),
                Datetime.newInstance(toDate.addDays(1), Time.newInstance(0, 0, 0, 0)));
    }

    @AuraEnabled
    public static String getAvailableSlotsByWorkTypeGroup(String workTypeGroupId, String serviceCenterId, Date slotDate) {
        return getAvailableSlots_raw(workTypeGroupId, serviceCenterId,
                Datetime.newInstance(slotDate, Time.newInstance(0, 0, 0, 0)),
                Datetime.newInstance(slotDate.addDays(1), Time.newInstance(0, 0, 0, 0)));
    }

    // B13 support
    public static String getAvailableSlots_raw(String workTypeGroupId, String serviceCenterIds, Datetime dateFrom, Datetime dateTo) {
        return OnlBookAvailabilityController.getAvailableSlots_raw(workTypeGroupId, serviceCenterIds, dateFrom, dateTo);
    }


    /**
     * Calls doBook by REST API
     *
     * @param request
     *
     * @return
     */
    @AuraEnabled
    public static String doBookByProxy(String request) {
        OnlineStoreSettings__c storeSettings = OnlineStoreSettingsManager.getStoreSettings();
        Login.LoginResponse loginResponse = Login.login(storeSettings.Username__c, storeSettings.Password__c, storeSettings.Login_URL__c);

        String endpoint = loginResponse.salesforceUrl + '/services/apexrest/m/book';

        HttpRequest req = getHTTPRequest(endpoint, loginResponse.sessionId, 'POST');
        //System.debug('::doBookByProxy:setting body: ' + request);
        req.setBody(request);
        req.setTimeout(59000);

        Http callout = new Http();
        HttpResponse res = callout.send(req);

        if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
            return res.getBody();
        }
        else {
            System.debug(LoggingLevel.ERROR, '::doBookByProxy:error: ' + res.getStatusCode() + ' ' + res.getBody());
            return res.getBody();
        }
    }

    /**
     * Used to reserve a time slot with a fixed "Reserved Slot" patient
     *
     * @param request
     *
     * @return
     */
    @AuraEnabled
    public static String doSimpleReservation(String request) {
        BookRequest bookRequest = (BookRequest) JSON.deserialize(request, BookRequest.class);
        // populate request with fixed data
        bookRequest.recordId = INTEGRATIONS_SETTINGS.Reservation_Patient_Id__c;
        bookRequest.productSelected = INTEGRATIONS_SETTINGS.Reservation_Product_Id__c;
        bookRequest.wtgIdSelected = [SELECT Id, Work_Type_Group__c FROM Product2 WHERE Id = :bookRequest.productSelected].Work_Type_Group__c;

        String response = doBookByProxy(JSON.serialize(bookRequest));

        BookResponse bookResponse = (BookResponse) JSON.deserialize(response, BookResponse.class);

        List<Opportunity> opps = [SELECT Id, SBQQ__PrimaryQuote__c, StageName, Mode__c FROM Opportunity WHERE Id = :bookResponse.oppId];
        if (opps.isEmpty()) return null;

        Opportunity opp = opps[0];
        opp.StageName = 'Closed Won';
        opp.CloseDate = Date.today();

        update opp;

        publishAppointmentBooked(opp);

        //sync app
        ExternalSyncAppointments.syncAppointmentFuture(bookResponse.appId);

        return response;
    }

    private static void publishAppointmentBooked(Opportunity opp) {
        try {

            List<ServiceAppointment> apps = [SELECT Id FROM ServiceAppointment WHERE Opportunity_Product__r.OpportunityId = :opp.Id];

            if (!apps.isEmpty()) {
                List<Appointment_Booking_Confirmed__e> events = new List<Appointment_Booking_Confirmed__e>();
                for (ServiceAppointment serviceAppointment : apps) {
                    events.add(new Appointment_Booking_Confirmed__e(Service_Appointment_Id__c = serviceAppointment.Id));
                }

                EventBus.publish(events);
            }

        }
        catch (Exception ex) {
            System.debug(LoggingLevel.WARN, 'Unable to publish Appointment_Booking_Confirmed__e:' + ex.getMessage());
        }
    }

    @AuraEnabled(Cacheable=false)
    public static String aura_checkForOutOfMembershipSurcharge(String accountId, String productId, Date bookingDate) {
        OnlBookPricingController.OOMSurchargeCalcResponse oomResp = OnlBookPricingController.checkForOutOfMembershipSurcharge(accountId, productId, bookingDate);
        if (oomResp == null || oomResp.surchargeData == null) return null;
        else return JSON.serializePretty(oomResp.surchargeData);
    }

    @AuraEnabled(Cacheable=true)
    public static PricebookEntry getPriceBookEntryForAccountAndProduct(Id accId, Id productId) {
        return OnlBookPricingController.getPriceBookEntryForAccountAndProduct(accId, productId);
    }

    @AuraEnabled(Cacheable=true)
    public static PricebookEntry getPriceBookEntryForAccountAndProductAndDate(Id accId, Id productId, Date dt, String discountCodeId) {

        return getPriceBookEntryForAccountAndProduct(accId, productId);

        // [2024-11-01 removing Period Promotions logic, it can now be done with discount codes only
        // if (dt == null) return getPriceBookEntryForAccountAndProduct(accId, productId);

        //        //check if there are promotional periods available
        //        List<Period_Promotion__c> period_promotions_all = [
        //                SELECT
        //                        Id,
        //                        NonMember_Price_Book__c,
        //                        Complete_Member_Price_Book__c,
        //                        GP_Member_Price_Book__c,
        //                        Dental_Member_Price_Book__c,
        //                        Premium_Member_Price_Book__c,
        //                        Base_Offer_Price_Book__c,
        //                        (SELECT Id, Discount_Code__c FROM PeriodPromotion_Code_Members__r)
        //                FROM Period_Promotion__c
        //                WHERE Appointments_Start_Date__c <= :dt
        //                AND Appointments_End_Date__c >= :dt
        //                ORDER BY CreatedDate DESC
        //        ];

        //when no promotions are defined, just return the normal price book calculations;
        // PricebookEntry pbeUsual = getPriceBookEntryForAccountAndProduct(accId, productId);
        // if (period_promotions_all.isEmpty()) return pbeUsual;

        //        //[2013-11-10] adding that some period promotions can be activated only by PeriodPromotion Discount Code
        //        List<Period_Promotion__c> period_promotions = new List<Period_Promotion__c>();
        //
        //        //for each period promotion
        //        for (Period_Promotion__c periodPromotion : period_promotions_all) {
        //            //if it has codes defined
        //            if (periodPromotion.PeriodPromotion_Code_Members__r != null && periodPromotion.PeriodPromotion_Code_Members__r.size() > 0) {
        //                Boolean periodPromotionApplicableByDiscount = false;
        //                for (PeriodPromotion_Code_Member__c periodPromotionCodeMember : periodPromotion.PeriodPromotion_Code_Members__r) {
        //                    if ((discountCodeId != null) && (periodPromotionCodeMember.Discount_Code__c == discountCodeId)) {
        //                        periodPromotionApplicableByDiscount = true;
        //                        break;
        //                    }
        //                }
        //                if (periodPromotionApplicableByDiscount) period_promotions.add(periodPromotion);
        //            }
        //            //else if it not not have codes defined, just add to be considered
        //            else {
        //                period_promotions.add(periodPromotion);
        //            }
        //        }
        //
        //        System.debug('::getPBE_4_APD:Applicable promotions found:' + period_promotions.size());
        //
        //        Account acc = [
        //                SELECT Id,
        //                        Membership_Type__c,
        //                        Member_Status__c,
        //                        Patient_Type__c,
        //                        Membership_Tier__c,
        //                        Membership_Tier__r.Price_Book__c,
        //                        Membership_Tier__r.Tier_Level__c,
        //                        Is_Active_Member__c,
        //                        Is_Active_Corporate_Member__c
        //                FROM Account
        //                WHERE Id = :accId
        //                LIMIT 1
        //        ];
        //        System.debug('::getPBE_4_APD:acc' + acc);
        //        List<Product2> products = [
        //                SELECT Id,
        //                        Name,
        //                        Non_Membership_Price__c, (
        //                        SELECT
        //                                Id,
        //                                Product2Id,
        //                                Pricebook2.Name,
        //                                Pricebook2.IsStandard,
        //                                Pricebook2.IsActive,
        //                                UnitPrice
        //                        FROM
        //                                PricebookEntries
        //                )
        //                FROM Product2
        //                WHERE Id = :productId
        //                LIMIT 1
        //        ];
        //
        //        Product2 product = products.get (0);
        //        System.debug('::getPBE_4_APD:product:' + product);
        //
        //        Boolean isActiveMember = acc.Is_Active_Member__c == true;
        //        Boolean isDental = isActiveMember && (acc.Membership_Tier__r.Tier_Level__c == 'Dental');
        //        Boolean isGP = isActiveMember && (acc.Membership_Tier__r.Tier_Level__c == 'GP');
        //        Boolean isPremium = isActiveMember && (acc.Membership_Tier__r.Tier_Level__c == 'Premium');
        //        Boolean isComplete = isActiveMember && (acc.Membership_Tier__r.Tier_Level__c == 'Complete');
        //
        //
        //        //search all period promotions for eventual price book entry that might override the default one
        //        for (Period_Promotion__c periodPromotion : period_promotions) {
        //            for (PricebookEntry pbe : product.PricebookEntries) {
        //                if (pbe.Pricebook2?.IsActive == true) {
        //                    if (isGP && (periodPromotion.GP_Member_Price_Book__c != null) && pbe.Pricebook2Id == periodPromotion.GP_Member_Price_Book__c) return pbe;
        //                    if (isDental && (periodPromotion.Dental_Member_Price_Book__c != null) && pbe.Pricebook2Id == periodPromotion.Dental_Member_Price_Book__c) return pbe;
        //                    if (isPremium && (periodPromotion.Premium_Member_Price_Book__c != null) && pbe.Pricebook2Id == periodPromotion.Premium_Member_Price_Book__c) return pbe;
        //                    if (isComplete && (periodPromotion.Complete_Member_Price_Book__c != null) && pbe.Pricebook2Id == periodPromotion.Complete_Member_Price_Book__c) return pbe;
        //                    if (!isActiveMember && (periodPromotion.NonMember_Price_Book__c != null) && pbe.Pricebook2Id == periodPromotion.NonMember_Price_Book__c) return pbe;
        //                }
        //            }
        //        }
        //
        //        //now check if the base promotion is there
        //        for (Period_Promotion__c periodPromotion : period_promotions) {
        //            if (periodPromotion.Base_Offer_Price_Book__c != null) {
        //                for (PricebookEntry pbe : product.PricebookEntries) {
        //                    if (pbe.Pricebook2?.IsActive == true) {
        //                        if (pbe.Pricebook2Id == periodPromotion.Base_Offer_Price_Book__c) return pbe;
        //                    }
        //                }
        //            }
        //        }
        //
        //
        //        System.debug('::getPBE_4_APD:returning USUAL:' + pbeUsual);
        //
        //        return pbeUsual;
    }

    public class SingleTimeSlotResponse {
        public Datetime endTime;
        public Datetime startTime;
        public List<String> resources;
        public Map<String, Set <String>> resource_locations;
        public String locationName;
        public Boolean isVideoOrTel;
    }

    @AuraEnabled
    public static String aura_doBook(String request) {
        try {
            return doBooking(request);
        }
        catch (Exception ex) {
            System.debug(LoggingLevel.WARN, '::doBook:exception:' + ex.getMessage());
            throw newAuraHandledException(ex.getMessage());
        }

    }

    private static BookRequest validateBookRequest(BookRequest bookRequest) {
        if (bookRequest.withoutLogin != true) bookRequest.withoutLogin = false;

        List<String> missedFields = new List<String>();
        if (String.isBlank(bookRequest.recordId) && String.isBlank(bookRequest.accountUID)) missedFields.add('recordID or accountUID');
        if (String.isBlank(bookRequest.productSelected)) missedFields.add('productSelected');
        if (String.isBlank(bookRequest.resourceSelected)) missedFields.add('resourceSelected');
        if (String.isBlank(bookRequest.locationSelected)) missedFields.add('locationSelected');
        if (String.isBlank(bookRequest.wtgIdSelected)) missedFields.add('wtgIdSelected');

        if (missedFields.size() > 0) {
            throw new BookingException('Invalid request. The following fields are required ' + String.join(missedFields, ', '));
        }

        if (bookRequest.selectedDate == null) bookRequest.selectedDate = bookRequest.timeSelected?.date();

        return bookRequest;
    }

    private static void checkIfPatientBlocked(Account acc) {
        List<Patient_Block__c> blocked = [SELECT Id, Name FROM Patient_Block__c WHERE Blocked_Email__c = :acc.PersonEmail LIMIT 1];
        if (!blocked.isEmpty()) {
            throw new MHCException('Unable to book due to error ' + blocked[0].Name);
        }
    }

    private static void checkAgeRequirements(Product2 product, Account acc) {
        if (String.isNotBlank(product?.Requirements__c)) {
            Integer age = null;
            if (acc.Date_of_Birth__c != null) {
                age = (Integer) (acc.Date_of_Birth__c.daysBetween(Date.today()) / 365);
            }
            List<String> requirements = product.Requirements__c.split(';');
            for (String requirement : requirements) {
                switch on requirement {
                    when 'Over 18' {
                        if ((age != null) && age < 18) throw new BookingException('Unable to book: Patient is under 18');
                    }
                    when 'Over 12' {
                        if ((age != null) && age < 12) throw new BookingException('Unable to book: Patient is under 12');
                    }
                    when 'Under 18' {
                        if ((age != null) && age >= 18) throw new BookingException('Unable to book: Patient is 18 or older');
                    }
                    when 'Under 12' {
                        if ((age != null) && age >= 12) throw new BookingException('Unable to book: Patient is 12 or older');
                    }
                }
            }
        }
    }


    /**
     * This method is used to insert a campaign member in Salesforce.
     * The method receives the id of a campaign, a lead and an account as arguments and,
     * if both the campaign id and the lead id are not null,
     * it assigns the campaign id, lead id, and contact id of the account to the campaign member,
     * after which the campaign member record is inserted into the database.
     *
     * @param campaignId the ID of the campaign where the member will be inserted
     * @param ld the lead that will be added to the campaign
     * @param acc the account associated with the lead
     *
     * @throws DMLException if the Database.insert operation fails
     */
    private static void insertCampaignMember(String campaignId, Lead ld, Account acc) {
        if (campaignId != null && ld.Id != null) {
            CampaignMember campaignMember = new CampaignMember();
            campaignMember.CampaignId = campaignId;
            campaignMember.LeadId = ld.Id;
            campaignMember.ContactId = acc.ContactId__c;
            Database.insert(campaignMember, false);
        }
    }

    public static String doBooking(String request) {

        System.debug('::doBooking:request:' + request);
        BookRequest bookRequest = (BookRequest) JSON.deserialize(request, BookRequest.class);

        Id appointmentProductId = bookRequest.productSelected;

        bookRequest = validateBookRequest(bookRequest);

        Account acc = null;
        if (bookRequest.recordId != null) {
            acc = [
                    SELECT Id,
                            ContactId__c,
                            PersonEmail,
                            FirstName,
                            LastName,
                            Membership_Type__c,
                            Member_Status__c,
                            Patient_Type__c,
                            Membership_Tier__r.Price_Book__c,
                            Membership_Tier__r.Tier_Level__c,
                            Date_of_Birth__c,
                            Phone,
                            PersonMobilePhone,
                            Billing_Address__c,
                            BillingPostalCode,
                            BillingCity,
                            BillingCountry,
                            Is_Active_Member__c,
                            Is_Active_Corporate_Member__c,
                            Existing_GP_Patient__c,
                            Existing_Dental_Patient__c
                    FROM Account
                    WHERE Id = :bookRequest.recordId
                    AND DoNotSync__pc != TRUE
                    LIMIT 1
            ];
        }
        else if (bookRequest.accountUID != null) {
            acc = [
                    SELECT Id,
                            ContactId__c,
                            PersonEmail,
                            FirstName,
                            LastName,
                            Membership_Type__c,
                            Member_Status__c,
                            Patient_Type__c,
                            Membership_Tier__r.Price_Book__c,
                            Membership_Tier__r.Tier_Level__c,
                            Date_of_Birth__c,
                            Phone,
                            PersonMobilePhone,
                            Billing_Address__c,
                            BillingPostalCode,
                            BillingCity,
                            BillingCountry,
                            Is_Active_Member__c,
                            Is_Active_Corporate_Member__c,
                            Existing_GP_Patient__c,
                            Existing_Dental_Patient__c
                    FROM Account
                    WHERE Store_UUID__c = :bookRequest.accountUID
                    AND DoNotSync__pc != TRUE
                    LIMIT 1
            ];
        }

        checkIfPatientBlocked(acc);

        List<Product2> product2s = [
                SELECT
                        Id, Requirements__c, Name
                FROM Product2
                WHERE Id = :bookRequest.productSelected
        ];

        checkAgeRequirements(product2s[0], acc);

        if (String.isBlank(bookRequest.patientType)) bookRequest.patientType = getPatientType(acc.Id);
        if (String.isBlank(bookRequest.reasonForVisit)) bookRequest.reasonForVisit = '-';

        Referral_Code__c referralCode = null;

        // [MHC-423]
        if (String.isNotBlank(bookRequest.referralCode)) {
            List<Referral_Code__c> rCodes = [SELECT Id, Campaign__c, Discount_Code__c, Code__c FROM Referral_Code__c WHERE Code__c = :bookRequest.referralCode AND Active__c = TRUE];
            if (!rCodes.isEmpty()) referralCode = rCodes[0];
        }

        // REFER A FRIEND - if bookRequest.discountName is a valid refer a friend code, then use the refer a friend discount code for the opportunity
        Id referredBy = DiscountCodeManager.getReferrerAccountIdByRAFCode(bookRequest.discountName);
        if (referredBy != null && referredBy != acc.Id) {
            // cant refer yourself!
            if (Test.isRunningTest()) System.debug('::doBooking:referredBy:' + referredBy);
            bookRequest.discountName = DiscountCodeManager.referAFriendDiscountCode()?.Coupon_Code__c;
        }

        Id campaignId = null;
        //use the referral code discount only if no discount has been specified
        if (referralCode != null && String.isBlank(bookRequest.discountSelected) && String.isBlank(bookRequest.discountName)) {
            bookRequest.discountSelected = referralCode.Discount_Code__c;
            campaignId = referralCode.Campaign__c;
        }

        // [MHC-423]
        Discount_Code__c discountCode = retrieveDiscountByIdOrCode(bookRequest);

        String discountCodeId = discountCode?.Id;

        // we need to establish if discount code is applicable BEFORE we check period promotions
        if (discountCodeId != null) {
            Product2 productToBook = [SELECT Id, Family FROM Product2 WHERE Id = :appointmentProductId LIMIT 1];
            if (!DiscountCodeManager.doesDiscountApply(discountCode, productToBook, bookRequest.locationSelected, acc, bookRequest.timeSelected)
                    || !DiscountCodeManager.isDiscountAvailableForAccount(acc.Id, discountCodeId, productToBook.Id)) {
                discountCodeId = null; // we set it to null if not applicable
            }
        }

        PricebookEntry pbe = getPriceBookEntryForAccountAndProductAndDate(acc.Id, appointmentProductId, bookRequest.selectedDate, discountCodeId);

        if (pbe == null) throw new BookingException('Unable to book a product without a standard price book');


        // [MHC-607]
        Boolean this_is_member_benefit_opportunity = (acc.Is_Active_Member__c == true && pbe.Pricebook2.IsStandard == false && pbe.Pricebook2Id == acc.Membership_Tier__r?.Price_Book__c);


        // The Promo Code Campaign would take precedence over the Query String Campaign
        if (discountCode != null && discountCode.Campaign__c != null) campaignId = discountCode.Campaign__c;

        if (bookRequest.mode == null) bookRequest.mode = 'Online Booking';
        if (bookRequest.mode == 'SF') {
            if (bookRequest.selectedMode != null) {
                bookRequest.mode = bookRequest.selectedMode;
            }
            else bookRequest.mode = 'Call';

        }

        //        if (bookRequest.mode != 'Mobile Application'
        //                && bookRequest.mode != 'Online Booking'
        //                && bookRequest.mode != 'Call') bookRequest.mode = null;

        String site = 'Home';
        try {
            site = [SELECT Id, Site__c FROM ServiceTerritory WHERE Id = :bookRequest.locationSelected].Site__c;
        }
        catch (Exception ignore) {
            site = null;
        }

        // opp's Business Unit defaults to GP unless specified differently on the Product
        String businessUnit = 'GP';
        List<Product2> products = [SELECT Id, Name, Work_Type_Group__c, Work_Type_Group__r.Service_Type__c, Business_Unit__c FROM Product2 WHERE Id = :bookRequest.productSelected];
        if (!products.isEmpty() && String.isNotBlank(products[0].Business_Unit__c)) businessUnit = products[0].Business_Unit__c;

        Boolean isRandox = products[0].Name.contains('RANDOX');

        //[MHC-460] Create Leads for the online store
        String leadOpportunityId;
        //[MHC-478] but only if it's not for an existing opportunity
        if (String.isEmpty(bookRequest.existingOpportunityId)) {

            Lead ld = new Lead();
            ld.Mode__c = 'Call'; //default to Call

            if (String.isNotEmpty(bookRequest.existingLeadId)) {
                try {
                    List<Lead> leads = [SELECT Id, Mode__c, Campaign__c FROM Lead WHERE Id = :bookRequest.existingLeadId AND IsConverted = FALSE];
                    if (!leads.isEmpty()) ld = leads[0];
                }
                catch (Exception ignore) {

                }
            }

            ld.FirstName = acc.FirstName;
            ld.LastName = acc.LastName;
            ld.Email = acc.PersonEmail;
            ld.Date_of_birth__c = acc.Date_of_Birth__c;
            ld.Phone = acc.Phone;
            ld.MobilePhone = acc.PersonMobilePhone;
            ld.Address1__c = acc.Billing_Address__c;
            ld.PostalCode = acc.BillingPostalCode;
            ld.City = acc.BillingCity;
            ld.Country = acc.BillingCountry;
            if (campaignId != null) ld.Campaign__c = campaignId;
            campaignId = ld.Campaign__c;
            ld.Business_Unit__c = businessUnit;
            ld.Site__c = site;
            ld.Online_Store__c = bookRequest.storeName;
            ld.Third_Party_Reference__c = bookRequest.thirdPartyRef;

            if (bookRequest.mode == 'Online Booking' || bookRequest.mode == 'Mobile Application') {
                ld.LeadSource = bookRequest.mode;
                ld.Mode__c = bookRequest.mode;
            }

            if (isRandox) ld.LeadSource = 'Randox';

            if (String.isNotBlank(bookRequest.trackingCookie)) {
                ld.Ruler_Cookie__c = bookRequest.trackingCookie.trim();
            }

            upsert ld;

            // [MHC-423]
            //insert a separate campaign member for lead
            if (ld.Campaign__c != null && ld.Id != null) {
                insertCampaignMember(ld.Campaign__c, ld, acc);
            }

            //convert to opp
            Database.LeadConvert leadConvert = new Database.LeadConvert();
            leadConvert.setLeadId(ld.Id);
            leadConvert.setAccountId(acc.Id);
            leadConvert.setConvertedStatus('Converted');

            Database.LeadConvertResult res = Database.convertLead(leadConvert);
            leadOpportunityId = res.opportunityId;
        }
        else {
            leadOpportunityId = bookRequest.existingOpportunityId;
        }

        Boolean appliedOOMSurcharge = false;
        OnlBookPricingController.OOMSurchargeCalcResponse oomResp = OnlBookPricingController.checkForOutOfMembershipSurcharge(acc.Id, appointmentProductId, bookRequest.selectedDate);
        if (oomResp != null && oomResp.surchargeData != null && oomResp.surchargeData.pricebookEntry != null) // add a new product as surcharge
        {
            System.debug('::doBook:to apply membership surcharge');
            appliedOOMSurcharge = true;
        }

        // create Opportunity
        Opportunity oppExisting = [SELECT Id, Mode__c, Site__c, Amount FROM Opportunity WHERE Id = :leadOpportunityId LIMIT 1];
        //get the mode of the lead for the original opp
        String modeFromLead = null;
        if (bookRequest.existingOpportunityId != null) {
            List<Lead> lds = [SELECT Id, Mode__c FROM Lead WHERE ConvertedOpportunityId = :bookRequest.existingOpportunityId];
            if (!lds.isEmpty()) modeFromLead = lds[0].Mode__c;
        }
        Opportunity opp = new Opportunity();
        opp.Id = leadOpportunityId;
        opp.AccountId = acc.Id;
        opp.StageName = 'Qualification';
        opp.Name = 'Booking ' + acc.FirstName + ' ' + acc.LastName + ' (' + (Datetime.now() + '').left(10) + ' ' + product2s?.get(0)?.Name + ')';
        if (opp.Name.length() > 120) opp.Name = opp.Name.substring(0, 119);
        opp.CloseDate = Date.today();
        opp.Member_Benefit_Applicable__c = this_is_member_benefit_opportunity && !appliedOOMSurcharge;
        if (bookRequest.withoutLogin == true) opp.Without_Login__c = bookRequest.withoutLogin;
        opp.CampaignId = campaignId;

        //if referred by a RAF code AND discount applicable
        if (referredBy != null && discountCodeId != null) opp.Referred_By_Account__c = referredBy;
        System.debug('::doBooking:opp.referredBy:' + opp.Referred_By_Account__c);

        //opp.Online_Session_Id__c = bookRequest.onlineSessionId;

        //if (String.isBlank(oppExisting.Site__c))
        opp.Site__c = site;
        if (String.isBlank(oppExisting.Mode__c)) {
            opp.Mode__c = 'Online Booking';
            if (String.isNotBlank(bookRequest.mode)) opp.Mode__c = bookRequest.mode;
        }
        if (modeFromLead != null) opp.Mode__c = modeFromLead;

        opp.Business_Unit__c = businessUnit;

        Product2 selectedProduct = products[0];

        opp.Date_Appointment_Made__c = Date.today();
        opp.Appointment_Date__c = bookRequest.selectedDate;
        opp.UUID__c = new Uuid().getValue();
        opp.Online_Store__c = 'Appointments';
        opp.Pricebook2Id = pbe.Pricebook2Id;
        if (StoreConfigMetadataManager.getOnlineStoreConfig(opp.Online_Store__c) != null) {
            opp.Store_Site_URL__c = StoreConfigMetadataManager.getOnlineStoreConfig(opp.Online_Store__c).Store_Site_URL__c;
        }

        opp.Patient_comment__c = bookRequest.reasonForVisit;

        //convert to opp

        opp.Online_Store_Product__c = appointmentProductId;

        opp.Online_Store__c = bookRequest.storeName;

        opp.Third_Party_Reference__c = bookRequest.thirdPartyRef;

        update opp;
        System.debug('::doBook:purchase opp updated: ' + opp.Id);

        //if it's a booking from a randox voucher, update that entry
        if (String.isNotBlank(bookRequest.voucherTag) && String.isNotBlank(bookRequest.randoxPID)) {
            RandoxEligibilityCtrl.setOpportunityToVoucher(bookRequest.randoxPID, bookRequest.voucherTag, opp.Id);
        }

        //[2024-01] attach any eventual file to the opportunity
        if (bookRequest.attachments != null && bookRequest.attachments.size() > 0) {
            List<ContentVersion> cvsToInsert = new List<ContentVersion>();
            List<ContentDocumentLink> cdlsToInsert = new List<ContentDocumentLink>();

            for (FileData fileData : bookRequest.attachments) {
                cvsToInsert.add(OnlBookDomain.createContentVersion(fileData.filename, fileData.base64));
            }
            insert cvsToInsert;

            List<Id> insertedCVIds = new List<Id>();

            for (ContentVersion contentVersion : cvsToInsert) {
                insertedCVIds.add(contentVersion.Id);
            }

            List<ContentVersion> contentVersions = [
                    SELECT ContentDocumentId
                    FROM ContentVersion
                    WHERE Id IN :insertedCVIds
            ];

            for (ContentVersion contentVersion : contentVersions) {
                cdlsToInsert.add(OnlBookDomain.createContentDocumentLink(contentVersion.ContentDocumentId, opp.Id));
            }
            insert cdlsToInsert;

        }

        // create SBQQ__Quote__c
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__PricebookId__c = pbe.Pricebook2Id;
        quote.SBQQ__PriceBook__c = pbe.Pricebook2Id;
        //quote.SBQQ__Account__c = acc.Id;
        quote.SBQQ__Opportunity2__c = opp.Id;
        quote.SBQQ__Primary__c = false;

        insert quote;
        System.debug('::doBook:inserted quote ' + quote.Id);

        //add the product via CPQ API

        System.debug('::doBook:adding product to quote:' + quote.Id + ', product:' + appointmentProductId + ', accountPriceBook:' + pbe.Pricebook2Id);
        CPQ_ProductAdder.QuoteModel qModel = CPQ_ProductAdder.addProductToQuote(quote.Id, appointmentProductId, pbe.Pricebook2Id, 'GBP');
        System.debug('::doBook:added product to quote ' + quote.Id);

        // add a new product as surcharge
        if (appliedOOMSurcharge) {
            System.debug('::doBook:added surcharge to quote ' + quote.Id);
            CPQ_ProductAdder.QuoteModel qModel2 = CPQ_ProductAdder.addProductToQuote(quote.Id, oomResp.surchargeData.pricebookEntry.Product2Id, pbe.Pricebook2Id, 'GBP');
        }

        //get quote lines
        List<SBQQ__QuoteLine__c> quoteLines = [
                SELECT Id, SBQQ__Product__c, SBQQ__Product__r.Family, SBQQ__Product__r.Id, SBQQ__ListPrice__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c = :quote.Id
        ];

        ServiceAppointment appointment = new ServiceAppointment();
        appointment.SchedStartTime = bookRequest.timeSelected;
        appointment.SchedEndTime = bookRequest.timeSelectedEnd;

        appointment.WorkTypeId = getWorkTypeIdForLocationAndWTGroup(bookRequest.locationSelected, bookRequest.wtgIdSelected);
        //appointment.Opportunity_Product__c = line.Id;
        appointment.ServiceTerritoryId = bookRequest.locationSelected;
        appointment.ParentRecordId = acc.Id;
        appointment.Treatment__c = opp.Id;

        //benefit counters
        appointment.Membership_Benefit_Counter__c = oomResp?.membershipBenefitCounter;
        appointment.OOM_Surcharge_Applied__c = appliedOOMSurcharge;

        //added 2022-09-06
        appointment.Comments = '';
        if (String.isNotBlank(bookRequest.patientType)) appointment.Comments += bookRequest.patientType.toUpperCase() + ' Patient.\n';
        appointment.Comments += 'Reason provided: ' + bookRequest.reasonForVisit;

        //[MHC-623] [TMHC-40]
        Integer overrideAppointmentDuration = BookingBusinessRules.calcAppointmentDuration(opp, appointment);
        if (overrideAppointmentDuration != null) appointment.SchedEndTime = appointment.SchedStartTime.addMinutes(overrideAppointmentDuration);

        insert appointment;
        System.debug('::doBook:inserted appointment' + appointment.Id);

        List<Discount_Code_Usage__c> discountUsagesToInsert = new List<Discount_Code_Usage__c>();

        //apply discount code on quote line(s)
        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {

            if (discountCode != null
                    && DiscountCodeManager.doesDiscountApply(discountCode, quoteLine.SBQQ__Product__r, bookRequest.locationSelected, acc, bookRequest.timeSelected)
                    && DiscountCodeManager.isDiscountAvailableForAccount(opp.AccountId, discountCode.Id, quoteLine.SBQQ__Product__c)) {

                quoteLine = DiscountCodeManager.applyDiscountToQuoteLine(quoteLine, discountCode, appointmentProductId);

                discountUsagesToInsert.add(new Discount_Code_Usage__c(
                        Product__c = quoteLine.SBQQ__Product__c,
                        Opportunity__c = opp.Id,
                        Discount_Code__c = discountCode.Id
                ));
            }
        }

        insert discountUsagesToInsert;

        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            if (quoteLine.SBQQ__Product__c == appointmentProductId) {
                quoteLine.Service_Appointment__c = appointment.Id;
            }
        }

        update quoteLines;

        quote.SBQQ__Primary__c = true;

        if (referralCode != null) quote.Referral_Code__c = referralCode.Code__c;
        if (discountCode != null) quote.Discount_Code__c = discountCode.Coupon_Code__c;

        update quote;

        System.debug('::doBook:updated quote to primary' + quote.Id);


        AssignedResource ar = new AssignedResource(ServiceAppointmentId = appointment.Id, ServiceResourceId = bookRequest.resourceSelected, IsRequiredResource = true);
        insert ar;
        System.debug('::doBook:inserted assigned resource' + ar.Id);

        BookResponse ret = new BookResponse(opp.Id, appointment.Id, opp.Amount, quote.Id);
        ret.oomSurcharge = oomResp?.surchargeData;
        ret.oomCounter = oomResp?.membershipBenefitCounter;
        ret.serviceType = selectedProduct.Work_Type_Group__r?.Service_Type__c;
        return JSON.serialize(ret, true);

    }

    private static Discount_Code__c retrieveDiscountByIdOrCode(OnlBookUI.BookRequest bookRequest) {

        if (String.isNotBlank(bookRequest.discountSelected)) {
            List<Discount_Code__c> dCodes = [
                    SELECT Id,
                            Percentage_discount__c,
                            Campaign__c,
                            Discount_Amount__c,
                            Coupon_Code__c,
                            Product__c,
                            Active__c,
                            Available_to_Patients_by_Category__c,
                            Max_Number_of_Usages__c,
                            Code_Usages__c,
                            Product_Family__c, (SELECT Id, Product__c, Product__r.Name, Discount_Amount__c, Discount_Percentage__c FROM Discount_Product_Members__r), (SELECT Id, Service_Territory__c FROM Discount_Location_Members__r)
                    FROM Discount_Code__c
                    WHERE Id = :bookRequest.discountSelected
            ];
            if (!dCodes.isEmpty()) return dCodes[0];
        }
        else if (String.isNotBlank(bookRequest.discountName)) {
            List<Discount_Code__c> dCodes2 = [
                    SELECT Id,
                            Percentage_discount__c,
                            Campaign__c,
                            Discount_Amount__c,
                            Coupon_Code__c,
                            Product__c,
                            Active__c,
                            Available_to_Patients_by_Category__c,
                            Max_Number_of_Usages__c,
                            Code_Usages__c,
                            Product_Family__c, (SELECT Id, Product__c, Product__r.Name, Discount_Amount__c, Discount_Percentage__c FROM Discount_Product_Members__r), (SELECT Id, Service_Territory__c FROM Discount_Location_Members__r)
                    FROM Discount_Code__c
                    WHERE Coupon_Code__c = :bookRequest.discountName
            ];
            if (!dCodes2.isEmpty()) return dCodes2[0];
        }

        return null;
    }


    @AuraEnabled
    public static Integer addAttachmentsToOpportunity(String oppId, String serviceType, String[] filenames, String[] base64) {
        try {
            //[2024-02] attach files to the opportunity
            if (filenames != null && filenames.size() > 0) {
                List<ContentVersion> cvsToInsert = new List<ContentVersion>();
                List<ContentDocumentLink> cdlsToInsert = new List<ContentDocumentLink>();

                for (Integer i = 0; i < filenames.size(); i++) {
                    cvsToInsert.add(OnlBookDomain.createContentVersion(filenames[i], base64[i]));
                }
                insert cvsToInsert;

                List<Id> insertedCVIds = new List<Id>();

                for (ContentVersion contentVersion : cvsToInsert) {
                    insertedCVIds.add(contentVersion.Id);
                }

                List<ContentVersion> contentVersions = [
                        SELECT ContentDocumentId
                        FROM ContentVersion
                        WHERE Id IN :insertedCVIds
                ];

                List<External_Document_Sync__c> edsToInsert = new List<External_Document_Sync__c>();
                for (ContentVersion contentVersion : contentVersions) {
                    External_Document_Sync__c ed = new External_Document_Sync__c(
                            External_System__c = 'ext_sys',
                            ContentVersionId__c = contentVersion.Id,
                            Opportunity__c = oppId
                    );
                    if (serviceType == SERVICE_TYPE_MEDICAL) ed.External_System__c = 'HEYDOC';
                    //else if (serviceType==SERVICE_TYPE_DENTAL) ed.External_System__c = 'AERONA'; // no AERONA file upload support atm
                    edsToInsert.add(ed);

                    cdlsToInsert.add(OnlBookDomain.createContentDocumentLink(contentVersion.ContentDocumentId, oppId));
                }
                insert cdlsToInsert;
                insert edsToInsert;
                return cdlsToInsert.size();
            }
        }
        catch (Exception ex) {
            return null;
        }
        return 0;
    }

    @AuraEnabled
    public static String doBook(String request) {
        return aura_doBook(request);
    }


    @AuraEnabled
    public static String closeOpportunity(String oppId, Boolean paidByPos) {
        return closeAndGetOpportunity(oppId, paidByPos)?.Id;
    }

    @AuraEnabled
    public static String aura_closeAndGetOpportunity(String oppId, Boolean paidByPos) {
        return JSON.serializePretty(closeOpportunity(oppId, paidByPos));
    }

    @AuraEnabled
    public static Opportunity closeAndGetOpportunity(String oppId, Boolean paidByPos) {
        List<Opportunity> opps = [
                SELECT
                        Id, SBQQ__PrimaryQuote__c, StageName, Mode__c,
                        Amount, Online_Stripe_Session__c, Paid_By_POS__c, Custom_Invoice__c,
                        (SELECT Id, UnitPrice, Product2Id, ProductCode, Quantity FROM OpportunityLineItems)
                FROM Opportunity
                WHERE Id = :oppId
                FOR UPDATE
        ];

        if (opps.isEmpty()) return null;

        Opportunity opp = opps[0];
        opp.StageName = 'Closed Won';
        opp.CloseDate = Date.today();
        opp.Paid_By_POS__c = paidByPos;

        if (opp.Custom_Invoice__c == null) {
            //create an invoice object
            InvoiceResponseWrapper invoiceResp = createInvoice(oppId, opp.SBQQ__PrimaryQuote__c);

            //queue future update of the appointment
            if (invoiceResp != null && invoiceResp.appId != null) ExternalSyncAppointments.syncAppointmentFuture(invoiceResp.appId);
        }
        if (opp.Mode__c == 'Online Booking') opp.Online_Store_Tracker__c = 'Won';
        update opp;

        //[2024-07] Find any eventual Service Appointment that was DNA or Canceled before within a month, and mark it rebooked
        markEventualDNACancelsAsRebooked(opp.Id);

        publishAppointmentBooked(opp);


        return opp;
    }

    @AuraEnabled
    public static String closeOpportunityIfPaymentPaid(String sessionId) {
        Opportunity opp = closeAndGetOpportunityIfPaymentPaid(sessionId);
        if (opp != null) return opp.Id;
        else return null;
    }

    @AuraEnabled
    public static String aura_closeAndGetOpportunityIfPaymentPaid(String sessionId) {

        Opportunity opp = closeAndGetOpportunityIfPaymentPaid(sessionId);
        if (opp == null) return null;
        return JSON.serializePretty(opp);
    }

    public static Opportunity closeAndGetOpportunityIfPaymentPaid(String sessionId) {

        if (sessionId == null) {
            throw newAuraHandledException('no such session id');
        }
        List<Opportunity> opps = [
                SELECT
                        Id, StageName, Amount, SBQQ__PrimaryQuote__c, Online_Stripe_Session__c, Paid_By_POS__c, Custom_Invoice__c, Mode__c, Business_Unit__c,
                        (SELECT Id, UnitPrice, Product2Id, ProductCode, Quantity, Product2.Name, Product2.ProductCode, Product2.Business_Unit__c FROM OpportunityLineItems),
                        (SELECT Id, ServiceTerritory.Name, Status, CancellationReason, WorkTypeId FROM Service_Appointments__r)
                FROM Opportunity
                WHERE Online_Stripe_Session__c = :sessionId
                FOR UPDATE
        ];

        if (opps.isEmpty()) return null;

        Opportunity opp = opps[0];

        if (opp.StageName == 'Closed Won') return opp;

        Boolean paid = opp.Paid_By_POS__c || onl_CheckoutCtrl.checkStripeSessionPaid(opp.Online_Stripe_Session__c);

        if (!paid) {
            throw newAuraHandledException('not paid');
        }

        opp.StageName = 'Closed Won';
        opp.Reason_for_non_conversion__c = null;
        opp.CloseDate = Date.today();

        if (opp.Custom_Invoice__c == null) {
            //create an invoice object
            InvoiceResponseWrapper invoiceResp = createInvoice(opp.Id, opp.SBQQ__PrimaryQuote__c);

            //queue future update of the appointment
            if (invoiceResp != null && invoiceResp.appId != null) ExternalSyncAppointments.syncAppointmentFuture(invoiceResp.appId);
        }
        if (opp.Mode__c == 'Online Booking') opp.Online_Store_Tracker__c = 'Won';
        update opp;

        //revert service Appointments if needed
        if (opp.Service_Appointments__r != null && opp.Service_Appointments__r.size() > 0) {
            for (ServiceAppointment serviceAppointment : opp.Service_Appointments__r) {
                if (serviceAppointment.Status == 'Canceled') {
                    serviceAppointment.Status = 'Scheduled';
                    serviceAppointment.CancellationReason = null;
                }
            }
        }

        update opp.Service_Appointments__r;

        //[2024-07] Find any eventual Service Appointment that was DNA or Canceled before within a month, and mark it rebooked
        markEventualDNACancelsAsRebooked(opp.Id);

        publishAppointmentBooked(opp);

        return opp;
    }

    //[2024-07] Find any eventual Service Appointment that was DNA or Canceled before within a month, and mark it rebooked
    public static void markEventualDNACancelsAsRebooked(String oppId) {

        List<Opportunity> opps = [
                SELECT
                        Id, CreatedDate, AccountId,
                        (SELECT Id, WorkTypeId FROM Service_Appointments__r)
                FROM Opportunity
                WHERE Id = :oppId
        ];

        if (opps.isEmpty()) return;

        Opportunity opp = opps[0];

        List<Id> workTypeIDs = new List<Id>();
        if (opp.Service_Appointments__r != null && opp.Service_Appointments__r.size() > 0) {
            for (ServiceAppointment serviceAppointment : opp.Service_Appointments__r) {
                workTypeIDs.add(serviceAppointment.WorkTypeId);
            }
        }
        if (workTypeIDs.isEmpty()) return;

        Datetime dtFromStart = opp.CreatedDate.addMonths(-1);

        List<ServiceAppointment> oldAppointments = [
                SELECT Id, Status, Was_Rebooked__c, Treatment__c
                FROM ServiceAppointment
                WHERE AccountId = :opp.AccountId
                AND Opportunity_Won__c = TRUE
                AND WorkTypeId IN :workTypeIDs
                AND SchedStartTime >= :dtFromStart
                AND Status IN ( 'Did Not Arrive', 'Canceled')
                AND Was_Rebooked__c = FALSE
                AND Treatment__c != :opp.Id
        ];

        if (oldAppointments.isEmpty()) return;

        for (ServiceAppointment serviceAppointment : oldAppointments) {
            serviceAppointment.Was_Rebooked__c = true;
        }
        Database.update(oldAppointments, false);
    }

    public class InvoiceResponseWrapper {
        public String invoiceId;
        public String appId;

        public InvoiceResponseWrapper() {

        }

        public InvoiceResponseWrapper(String invoiceId, String appId) {
            this.invoiceId = invoiceId;
            this.appId = appId;
        }
    }

    public static InvoiceResponseWrapper createInvoice(String oppId, Id quoteId) {
        try {

            Custom_Invoice__c invoice = new Custom_Invoice__c();

            SBQQ__Quote__c quote = [
                    SELECT Id,
                            SBQQ__NetAmount__c,
                            SBQQ__BillingCity__c,
                            SBQQ__BillingCountry__c,
                            SBQQ__BillingName__c,
                            SBQQ__BillingPostalCode__c,
                            SBQQ__BillingState__c,
                            SBQQ__BillingStreet__c
                    FROM SBQQ__Quote__c
                    WHERE Id = :quoteId
            ];

            List<SBQQ__QuoteLine__c> quoteLines = [
                    SELECT Id,
                            SBQQ__NetTotal__c,
                            SBQQ__NetPrice__c,
                            SBQQ__Product__c,
                            SBQQ__Product__r.Work_Type_Group__r.Heydoc_Id__c,
                            CreatedDate
                    FROM SBQQ__QuoteLine__c
                    WHERE SBQQ__Quote__c = :quoteId
            ];

            invoice.Quote_JSON__c = JSON.serialize(quote);
            invoice.Quote_Lines_JSON__c = JSON.serialize(quoteLines);

            List<ServiceAppointment> apps = [
                    SELECT Id,
                            WorkTypeId,
                            ServiceTerritoryId,
                            ServiceTerritory.Heydoc_Id__c,
                            ServiceTerritory.Aerona_Id__c,
                            Opportunity_Product__r.Product2.Work_Type_Group__r.Aerona_Id__c, (SELECT Id FROM Custom_Invoices__r)
                    FROM ServiceAppointment
                    WHERE Treatment__c = :oppId
                    LIMIT 1
            ];


            if (!apps.isEmpty()) {
                invoice.Service_Appointment__c = apps[0].Id;
                invoice.Heydoc_Location_Id__c = apps[0].ServiceTerritory?.Heydoc_Id__c;
                invoice.Aerona_Location_Id__c = apps[0].ServiceTerritory?.Aerona_Id__c;
                invoice.Aerona_Item_Id__c = apps[0].Opportunity_Product__r?.Product2.Work_Type_Group__r?.Aerona_Id__c;

                //get resources for Appointment
                List<AssignedResource> aResources = [
                        SELECT
                                Id,
                                ServiceResource.Heydoc_Id__c
                        FROM AssignedResource
                        WHERE ServiceAppointmentId = :apps[0].Id
                        LIMIT 1
                ];

                if (!aResources.isEmpty()) {
                    invoice.Heydoc_Doctor_Id__c = aResources[0].ServiceResource?.Heydoc_Id__c;

                    // aerona doctor ids ar at ServiceTerritoryMember level
                    List<ServiceTerritoryMember> stms = [
                            SELECT Id, Aerona_Clinician_Id__c
                            FROM ServiceTerritoryMember
                            WHERE ServiceTerritoryId = :apps[0].ServiceTerritoryId AND ServiceResourceId = :aResources.get(0).ServiceResourceId
                            LIMIT 1
                    ];

                    if (!stms.isEmpty()) {
                        invoice.Aerona_Doctor_Id__c = stms[0].Aerona_Clinician_Id__c;
                    }
                }

            }
            invoice.Amount__c = quote.SBQQ__NetAmount__c;

            insert invoice;

            Opportunity opp = new Opportunity(Id = oppId);
            opp.Custom_Invoice__c = invoice.Id;
            update opp;

            //wraps because we need both Ids
            return new InvoiceResponseWrapper(invoice.Id, apps[0].Id);

        }
        catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'createInvoice:exception:' + ex.getMessage());
        }

        return null;
    }


    @AuraEnabled
    public static void trackOnlineOpportunity(String oppId, String state) {
        try {
            Opportunity op = new Opportunity();
            op.Id = oppId;
            op.Online_Store_Tracker__c = state;
            Database.upsert(op, false);
        }
        catch (Exception ignore) {
        }
    }

    @AuraEnabled(Cacheable=false)
    public static String checkQuoteCalculated(String quoteId, String appId) {
        SBQQ__Quote__c q = [SELECT Id, SBQQ__Opportunity2__c, SBQQ__NetAmount__c, SBQQ__Uncalculated__c FROM SBQQ__Quote__c WHERE Id = :quoteId];
        CheckQuoteResponse resp = new CheckQuoteResponse();
        resp.quoteCalculated = !q.SBQQ__Uncalculated__c;
        resp.amount = q.SBQQ__NetAmount__c;

        //when the quote has been recalculated, update the product on the service appointment
        if (resp.quoteCalculated) {
            List<OpportunityLineItem> olis = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :q.SBQQ__Opportunity2__c];
            if (!olis.isEmpty()) {
                ServiceAppointment appointment = new ServiceAppointment(Id = appId);
                appointment.Opportunity_Product__c = olis.get(0).Id;
                update appointment;
            }
            else resp.quoteCalculated = false;
        }

        return JSON.serializePretty(resp);

    }

    public static Exception newAuraHandledException(String msg) {
        AuraHandledException aEx = new AuraHandledException(msg);
        aEx.setMessage(msg);
        return aEx;
    }

    public static String getWorkTypeIdForLocationAndWTGroup(String territoryId, String wtgId) {

        //list worktypegroup members for the work type group
        List<WorkTypeGroupMember> wtgms = [
                SELECT Id, WorkTypeId
                FROM WorkTypeGroupMember
                WHERE WorkTypeGroupId = :wtgId
        ];

        //list ServiceTerritoryWorkType for the given Location in the scheduled appointment
        List<ServiceTerritoryWorkType> stwts = [
                SELECT Id, WorkTypeId
                FROM ServiceTerritoryWorkType
                WHERE ServiceTerritoryId = :territoryId
        ];


        for (ServiceTerritoryWorkType stwt : stwts) {
            //System.debug(LoggingLevel.ERROR, '::getWorkTypeIdForLocationAndWTGroup:at stwt ' + stwt.Id + ' with workTypeId: ' + stwt.WorkTypeId);
            for (WorkTypeGroupMember wtgm : wtgms) {
                //System.debug(LoggingLevel.ERROR, '::getWorkTypeIdForLocationAndWTGroup:at wtgm ' + wtgm.Id + ' with workTypeId: ' + wtgm.WorkTypeId);
                if (stwt.WorkTypeId == wtgm.WorkTypeId) {
                    return stwt.WorkTypeId;
                }
            }
        }

        return null;

    }


    @AuraEnabled
    /* finds the latest account with the provided PersonEmail and password used during login */
    public static String checkAccountLogin(String email, String password) {
        if (email == null || password == null) return null;
        List<Account> accs = [
                SELECT Id,
                        PersonEmail,
                        Store_UUID__c,
                        Membership_Type__c,
                        Patient_Type__c,
                        Store_password__c
                FROM Account
                WHERE IsPersonAccount = TRUE AND PersonEmail = :email
                AND DoNotSync__pc != TRUE
                ORDER BY CreatedDate DESC
        ];
        if (accs.isEmpty()) {
            return null;
        }
        else {
            for (Account account : accs) {
                if (account.Store_password__c == password) {
                    if (account.Store_UUID__c == null) {
                        account.Store_UUID__c = new Uuid().getValue();
                        update account;
                    }
                    account.Store_password__c = null;
                    return JSON.serialize(account);
                }
            }
            return null;
        }
    }

    @AuraEnabled
    public static String getContactIdForUUID(String uuid) {
        List<Account> accs = [
                SELECT Id,
                        PersonEmail,
                        ContactId__c,
                        Store_UUID__c,
                        Membership_Type__c,
                        Patient_Type__c
                FROM Account
                WHERE IsPersonAccount = TRUE AND Store_UUID__c = :uuid
                AND DoNotSync__pc != TRUE
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        if (accs.isEmpty()) return null;
        return JSON.serializePretty(accs[0]);
    }

    @AuraEnabled
    /* finds the latest account with the provided identification (Username or PersonEmail) and password used during login */
    public static String checkAccountLoginWithConnectedAccounts(String identification, String password) {
        if (String.isEmpty(identification) || String.isEmpty(password)) return null;

        AccountWithConnectedAccounts ret = new AccountWithConnectedAccounts();

        Date todayMinus18Years = Date.today().addYears(-18);

        List<Account> accs = [
                SELECT Id,
                        PersonEmail,
                        ContactId__c,
                        Store_UUID__c,
                        Membership_Type__c,
                        Patient_Type__c,
                        Store_password__c
                FROM Account
                WHERE IsPersonAccount = TRUE
                AND DoNotSync__pc != TRUE
                AND (
                        (Username__c = :identification)
                        OR
                        (Username__c = NULL AND PersonEmail = :identification)
                )
                ORDER BY CreatedDate DESC
        ];
        if (accs.isEmpty()) {
            System.debug('::checkAccountLoginWithConnectedAccounts:no such identification');
            return null;
        }
        else {
            for (Account account : accs) {
                if (
                        (account.Store_password__c == password) || (account.Store_UUID__c != null && password == account.Store_UUID__c)
                ) {
                    System.debug('::checkAccountLoginWithConnectedAccounts:pass correct');
                    if (account.Store_UUID__c == null) {
                        account.Store_UUID__c = new Uuid().getValue();
                        update account;
                    }
                    account.Store_password__c = null;
                    ret.main = account;

                    List<Account> subaccounts = [
                            SELECT
                                    Store_UUID__c, FirstName, LastName, Date_of_Birth__c
                            FROM Account
                            WHERE PersonEmail = :accs.get (0).PersonEmail
                            AND (Date_of_Birth__c > :todayMinus18Years OR Id = :account.Id)
                            AND DoNotSync__pc != TRUE
                    ];

                    List<Account> accountsToUpdate = new List<Account>();

                    for (Account subaccount : subaccounts) {
                        if (subaccount.Store_UUID__c == null) {
                            subaccount.Store_UUID__c = new Uuid().getValue();
                            accountsToUpdate.add(subaccount);
                        }
                    }
                    update accountsToUpdate;
                    ret.connected = subaccounts;
                    return JSON.serialize(ret);
                }
                else {
                    System.debug('::checkAccountLoginWithConnectedAccounts:pass incorrect');
                }
            }
            return null;
        }
    }

    public class AccountWithConnectedAccounts {
        public Account main;
        public List<Account> connected;
    }


    @AuraEnabled
    /* finds the latest account with the provided PersonEmail and password used during login */
    public static String checkAccountLoginWithDOB(String email, Date dob) {
        if (email == null || dob == null) return null;
        List<Account> accs = [
                SELECT Id,
                        PersonEmail,
                        Store_UUID__c,
                        Membership_Type__c,
                        Member_Status__c,
                        Patient_Type__c,
                        Store_password__c
                FROM Account
                WHERE IsPersonAccount = TRUE
                AND Date_of_Birth__c = :dob
                AND PersonEmail = :email
                AND DoNotSync__pc != TRUE
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];
        if (accs.isEmpty()) {
            return null;
        }
        else {
            if (accs.get (0).Store_UUID__c == null) {
                accs.get (0).Store_UUID__c = new Uuid().getValue();
                update accs.get (0);
            }
            return JSON.serialize(accs.get (0));
        }
    }


    @AuraEnabled
    public static Boolean checkPassCodeValidity(String code, String email) {
        if (String.isBlank(code) || String.isBlank(email)) return false;
        List<Patient_Password_Change__c> ppcs = [SELECT Id, Patient__c, Patient__r.Store_password__c FROM Patient_Password_Change__c WHERE UUID__c = :code AND Patient__r.PersonEmail = :email LIMIT 1];

        if (ppcs.size() != 1) return false;
        if (String.isBlank(ppcs.get (0).Patient__r.Store_password__c)) return false;

        return true;
    }

    @AuraEnabled
    /* password change request that has to be clicked on through the email*/
    public static Boolean changePassword(String code, String email, String newPassword) {

        if (String.isBlank(code) || String.isBlank(email) || String.isBlank(newPassword)) throw newAuraHandledException('INVALID_REQUEST');

        List<Patient_Password_Change__c> ppcs = [SELECT Id, Patient__c, Patient__r.Store_password__c FROM Patient_Password_Change__c WHERE UUID__c = :code AND Patient__r.PersonEmail = :email LIMIT 1];

        if (ppcs.size() != 1) throw newAuraHandledException('INVALID_REQUEST');
        if (String.isBlank(ppcs.get (0).Patient__r.Store_password__c)) throw newAuraHandledException('INVALID_REQUEST');

        Account acc = ppcs.get (0).Patient__r;
        acc.Store_password__c = newPassword;

        update acc;

        delete ppcs;

        return true;
    }

    @AuraEnabled
    /* send password change email if email address found */
    public static String queuePassChange(String email) {

        List<Account> accs = [
                SELECT Id, Store_password__c, ContactId__c
                FROM Account
                WHERE PersonEmail = :email
                AND DoNotSync__pc != TRUE
        ];

        if (accs.size() == 0) return 'ERR_NOT_REGISTERED';

        Account candidate = null;
        for (Account account : accs) {
            if (!String.isBlank(account.Store_password__c)) {
                candidate = account;
                break;
            }
        }

        if (candidate == null) return 'ERR_NOT_REGISTERED';

        Patient_Password_Change__c ppc = new Patient_Password_Change__c();
        ppc.Patient__c = candidate.Id;
        ppc.UUID__c = new Uuid().getValue().replaceAll('-', '');

        insert ppc;

        String baseUrl = OnlineStoreSettingsManager.getStoreSettings().Base_URL__c;
        if (baseUrl == null) {
            List <OnlineStoreSettings__c> sets = [SELECT Id, Name, Base_URL__c FROM OnlineStoreSettings__c WHERE Base_URL__c LIKE '%appointments%'];
            if (sets.size() > 0) baseUrl = sets.get (0).Base_URL__c;
        }
        if (baseUrl == null) baseUrl = 'https://myhealthcareclinic.secure.force.com/appointments';

        String activation_link = baseUrl + '?page=fpwa&a=' + ppc.UUID__c + '&b=' + email;

        qsyd_InvocableEmailAction.InvocableEmailParam qEmail = new qsyd_InvocableEmailAction.InvocableEmailParam();
        qEmail.toAddress = email;
        qEmail.bodyHtml = '<p>To finish changing your password for MyHealthcare Clinic, please follow the link below:<p>';
        qEmail.bodyHtml += '<p><a href="' + activation_link + '">' + activation_link + '</a><p>';

        qEmail.bodyPlainText = 'To finish changing your password for MyHealthcare Clinic, please follow the link below:';
        qEmail.bodyPlainText += '\n' + activation_link;

        qEmail.subject = 'MyHealthcare Clinic Password Change';
        qEmail.saveAsActivity = true;
        //qEmail.whatId = candidate.Id;
        qEmail.targetObjectId = candidate.ContactId__c;

        List<OrgWideEmailAddress> addresses = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address LIKE 'noreply%' OR Address LIKE 'membership%' ORDER BY Address DESC];
        qEmail.orgWideEmailAddress = addresses[0].Address;

        List<qsyd_InvocableEmailAction.InvocableEmailParam> emails = new List<qsyd_InvocableEmailAction.InvocableEmailParam>();
        emails.add(qemail);
        qsyd_InvocableEmailAction.sendEmail(emails);

        return null;
    }

    @AuraEnabled
    /* create a new account and return as if loggedin */
    public static String queueRegister(String request) {

        //store request in db, assign ID and uuid
        //send email with validation link

        try {
            RegisterRequest req = (RegisterRequest) (JSON.deserialize(request, RegisterRequest.class));
            Patient_Registration_Request__c prr = new Patient_Registration_Request__c();


            try {
                validateRegistrationRequest(req.email, req.dob);
            }
            catch (MHCException e) {
                return e.getMessage();
            }

            prr.Password__c = req.password;
            req.password = null;
            prr.Request__c = JSON.serialize(req);
            prr.Request_Hash__c = req.email;
            prr.UUId__c = (new Uuid().getValue().replaceAll('-', '') + prr.Request_Hash__c).substring(0, 32);

            String activationCode = getRandomDigits(4);
            prr.Activation_Code__c = activationCode;

            insert prr;

            if ('dontemail'.equalsIgnoreCase(req.password)) return null;

            qsyd_InvocableEmailAction.InvocableEmailParam email = new qsyd_InvocableEmailAction.InvocableEmailParam();
            email.toAddress = req.email;
            email.bodyHtml = '<p>Thank you for registering with MyHealthcare Clinic. In order to activate your account, please use the following code:<p>';
            email.bodyHtml += '<p><strong>' + activationCode + '<strong></p>';

            email.bodyPlainText = 'Thank you for registering with MyHealthcare Clinic. In order to activate your account, please use the following code:';
            email.bodyPlainText += '\n\n' + activationCode;

            email.subject = 'MyHealthcare Clinic Registration';

            List<OrgWideEmailAddress> addresses = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address LIKE 'noreply%' OR Address LIKE 'membership%' ORDER BY Address DESC];
            email.orgWideEmailAddress = addresses[0].Address;

            List<qsyd_InvocableEmailAction.InvocableEmailParam> emails = new List<qsyd_InvocableEmailAction.InvocableEmailParam>();
            emails.add(email);
            qsyd_InvocableEmailAction.sendEmail(emails);

            // return success
            return null;
        }
        catch (Exception e) {
            return e.getMessage();
        }

    }

    public static String getRandomString(Integer length) {
        String ret = '';
        Integer idx;
        while (ret.length() < length) {
            idx = Math.floor(Math.random() * (chars.length())).intValue();
            ret += chars.substring(idx, idx + 1);
        }
        return ret;
    }

    public static String getRandomDigits(Integer length) {
        return ('' + Math.floor(123456789 + Math.random() * 90000000).intValue()).left(length);
    }

    @AuraEnabled
    public static String activateRegistration(String activationCode, String hashCode) {

        try {
            List<Patient_Registration_Request__c> requests = [SELECT Id, Request__c, Password__c FROM Patient_Registration_Request__c WHERE UUId__c = :activationCode AND Request_Hash__c = :hashCode LIMIT 1];
            if (requests.size() == 0) return 'INVALID REQUEST';

            RegisterRequest req = (RegisterRequest) (JSON.deserialize(requests[0].Request__c, RegisterRequest.class));
            req.password = requests[0].Password__c;

            // validate
            try {
                Account acc = validateRegistrationRequest(req.email, req.dob);

                // NOTE: IF ACCOUNT ALREADY THERE; WILL NOW BE SET WITH NEW VALUES!
                if (acc == null) acc = new Account();

                acc.Store_password__c = req.password;
                acc.RecordTypeId = Cache.recordTypeId(AccountManager.RT_PERSON_ACCOUNT);
                acc.Date_of_Birth__c = req.dob;
                acc.Online_Registration_Date__c = Datetime.now();
                acc.Gender__c = req.gender;
                acc.FirstName = req.firstName;
                acc.LastName = req.lastName;
                if (acc.Patient_Type__c == null) acc.Patient_Type__c = 'New';
                acc.PersonEmail = req.email;
                acc.Phone = req.phone;
                acc.PersonMobilePhone = req.phone;
                acc.Store_UUID__c = new Uuid().getValue();

                acc.BillingStreet = req.address1;
                if (!String.isBlank(req.address2)) acc.BillingStreet += ', ' + req.address2;
                if (!String.isBlank(req.address3)) acc.BillingStreet += ', ' + req.address3;
                acc.BillingCity = req.city;
                acc.BillingPostalCode = req.postalCode;
                acc.BillingState = req.county;

                upsert acc;

                delete requests;

                acc.Store_password__c = null;
                return null;
            }
            catch (MHCException e) {
                return e.getMessage();
            }
        }
        catch (Exception e) {
            return e.getMessage();
        }

    }

    @AuraEnabled
    public static String activateRegistrationByCode(String email, String code) {

        if (String.isBlank(email) || String.isBlank(code)) return null;

        try {
            List<Patient_Registration_Request__c> requests = [SELECT Id, Request__c, Password__c FROM Patient_Registration_Request__c WHERE Activation_Code__c = :code AND Request_Hash__c = :email LIMIT 1];
            if (requests.size() == 0) return null;

            RegisterRequest req = (RegisterRequest) (JSON.deserialize(requests[0].Request__c, RegisterRequest.class));
            req.password = requests[0].Password__c;

            // validate
            Account acc = validateRegistrationRequest(req.email, req.dob);

            // NOTE: IF ACCOUNT ALREADY THERE; WILL NOW BE SET WITH NEW VALUES!
            if (acc == null) acc = new Account();

            acc.Store_password__c = req.password;
            acc.RecordTypeId = Cache.recordTypeId(AccountManager.RT_PERSON_ACCOUNT);
            acc.Date_of_Birth__c = req.dob;
            acc.Online_Registration_Date__c = Datetime.now();
            if (acc.FirstName == null) acc.FirstName = req.firstName;
            if (acc.LastName == null) acc.LastName = req.lastName;
            if (acc.Patient_Type__c == null) acc.Patient_Type__c = 'New';
            acc.PersonEmail = req.email;
            acc.Phone = req.phone;
            acc.PersonMobilePhone = req.phone;
            acc.Store_UUID__c = new Uuid().getValue();
            acc.Gender__c = req.gender;

            acc.BillingStreet = req.address1;
            if (!String.isBlank(req.address2)) acc.BillingStreet += ', ' + req.address2;
            if (!String.isBlank(req.address3)) acc.BillingStreet += ', ' + req.address3;
            acc.BillingCity = req.city;
            acc.BillingPostalCode = req.postalCode;
            acc.BillingState = req.county;

            upsert acc;

            delete requests;

            acc.Store_password__c = null;
            return acc.Store_UUID__c;

        }
        catch (Exception e) {
            return null;
        }
    }


    /* create a new account and return as if loggedin */
    public static String registerAndLogin(String request) {
        RegisterRequest req = (RegisterRequest) (JSON.deserialize(request, RegisterRequest.class));

        if (req == null
                || String.isEmpty(req.firstName) || String.isEmpty(req.lastName) || String.isEmpty(req.email) || String.isEmpty(req.phone) || req.dob == null) {
            throw newAuraHandledException('INVALID_REQUEST');
        }

        try {

            req.firstName = req.firstName.trim();
            req.lastName = req.lastName.trim();
            req.email = req.email.trim();
            req.phone = req.phone.trim();

            req.address1 = req.address1?.trim();
            req.address2 = req.address2?.trim();
            req.address3 = req.address3?.trim();
            req.postalCode = req.postalCode?.trim();
            req.city = req.city?.trim();
            req.county = req.county?.trim();


            //check if already exists
            String chk = checkAccountLoginWithDOB(req.email, req.dob);
            if (chk != null) throw newAuraHandledException('ALREADY_REGISTERED');

            Account acc = new Account();
            acc.RecordTypeId = Cache.recordTypeId(AccountManager.RT_PERSON_ACCOUNT);
            acc.Date_of_Birth__c = req.dob;
            acc.FirstName = req.firstName;
            acc.LastName = req.lastName;
            acc.Patient_Type__c = 'New';
            acc.PersonEmail = req.email;
            acc.Phone = req.phone;
            acc.PersonMobilePhone = req.phone;
            acc.Store_UUID__c = new Uuid().getValue();

            acc.BillingStreet = req.address1;
            if (!String.isBlank(req.address2)) acc.BillingStreet += ', ' + req.address2;
            if (!String.isBlank(req.address3)) acc.BillingStreet += ', ' + req.address3;
            acc.BillingCity = req.city;
            acc.BillingPostalCode = req.postalCode;
            acc.BillingState = req.county;

            insert acc;

            return JSON.serialize(acc);
        }
        catch (Exception ex) {
            System.debug(ex.getStackTraceString());
            throw newAuraHandledException(ex.getMessage());
        }
    }


    /**
     * This is a Salesforce Aura Enabled method that looks up a given email
     * in the 'Account' object and retrieves details about the corresponding account.
     * This method is specifically designed for 'PersonAccount' objects, not the regular
     * Salesforce 'Account' objects.
     *
     * @param email An email address string related to a PersonAccount to lookup in Salesforce.
     *
     * @return A JSON serialized representation of the Account record (first record if multiple exist),
     * including fields: Id, PersonEmail, Store_UUID__c, Membership_Type__c, Member_Status__c, Patient_Type__c.
     * If the provided email is null or no account with provided email is found, null is returned.
     * If the account found does not have a UUID, a new UUID is generated and updated for that account.
     *
     * Make sure that only users with appropriate permissions are allowed to call this method
     * because it could inadvertently reveal sensitive information about an Account.
     */
    @AuraEnabled
    public static String findAccountByEmail(String email) {
        if (email == null) return null;

        List<Account> accounts = [
                SELECT Id,
                        PersonEmail,
                        Store_UUID__c,
                        Membership_Type__c,
                        Member_Status__c,
                        Patient_Type__c
                FROM Account
                WHERE IsPersonAccount = TRUE AND PersonEmail = :email
                AND DoNotSync__pc != TRUE
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        if (accounts.isEmpty()) {
            return null;
        }

        Account firstAccount = accounts.get(0);
        if (firstAccount.Store_UUID__c == null) {
            firstAccount.Store_UUID__c = new Uuid().getValue();
            update firstAccount;
        }

        return JSON.serialize(firstAccount);
    }

    @AuraEnabled
    public static String findAccountsByEmail(String email) {

        if (email == null) return null;

        List<Account> accs = [
                SELECT Id,
                        FirstName,
                        LastName,
                        Date_of_Birth__c,
                        PersonEmail,
                        Store_UUID__c,
                        Membership_Type__c,
                        Member_Status__c,
                        Patient_Type__c
                FROM Account
                WHERE IsPersonAccount = TRUE AND PersonEmail = :email
                AND DoNotSync__pc != TRUE
                FOR UPDATE
        ];

        for (Account account : accs) {

            if (account.Store_UUID__c == null) {
                account.Store_UUID__c = new Uuid().getValue();
            }
        }
        update accs;
        return JSON.serialize(accs);
    }


    @AuraEnabled
    public static String findAccountsByEmailOfAccount(String accountUID) {
        List<Account> accs = [
                SELECT Id, PersonEmail
                FROM Account
                WHERE Store_UUID__c = :accountUID
                AND DoNotSync__pc != TRUE
                LIMIT 1
        ];
        if (accs.size() == 0) return '[]';

        Date todayMinus18Years = Date.today().addYears(-18);

        List<Account> ret = [
                SELECT
                        Store_UUID__c, FirstName, LastName, Date_of_Birth__c
                FROM Account
                WHERE
                        PersonEmail = :accs.get (0).PersonEmail
                        AND (Date_of_Birth__c > :todayMinus18Years OR Id = :accs.get (0).Id)
                        AND DoNotSync__pc != TRUE
                FOR UPDATE
        ];

        List<Account> accountsToUpdate = new List<Account>();

        for (Account account : ret) {
            if (account.Store_UUID__c == null) {
                account.Store_UUID__c = new Uuid().getValue();
                accountsToUpdate.add(account);
            }
        }
        update accountsToUpdate;

        return JSON.serialize(ret);
    }

    /**
     * This method is used to find an Account record by passing in the parameters Email and Date of Birth.
     *
     * @param email The email of the Person Account to be found. It's a String type parameter.
     * This parameter is compared with the PersonEmail field of the Account object in Salesforce.
     * @param dob This is the Date of Birth of the Person Account to be found. It's a Date type parameter.
     * This parameter is compared with the Date_of_Birth__c field of the Account object in Salesforce.
     *
     * @return Account
     * The method returns a Person Account record from Salesforce which matches the input Email and Date of Birth.
     * The Account record fields returned as part of this method are - Id, PersonEmail, Store_UUID__c, Membership_Type__c, Member_Status__c, Patient_Type__c, and Store_password__c.
     *
     * Null is returned in case no matching record is found or the input email is null.
     *
     * In case the returned Person Account has the field Store_UUID__c as null, a new UUID is generated and assigned to this field before returning the record.
     *
     * @throws DmlException thrown when the update operation fails
     */
    public static Account findAccountByEmailAndDob(String email, Date dob) {
        if (email == null) return null;
        List<Account> accs = [
                SELECT Id,
                        PersonEmail,
                        Store_UUID__c,
                        Membership_Type__c,
                        Member_Status__c,
                        Patient_Type__c,
                        Store_password__c
                FROM Account
                WHERE IsPersonAccount = TRUE
                AND PersonEmail = :email
                AND Date_of_Birth__c = :dob
                AND DoNotSync__pc != TRUE
                ORDER BY CreatedDate DESC

                LIMIT 1
        ];
        if (accs.isEmpty()) {
            return null;
        }
        else {
            if (accs.get (0).Store_UUID__c == null) {
                accs.get (0).Store_UUID__c = new Uuid().getValue();
                update accs.get (0);
            }
            return accs.get (0);
        }
    }

    public class BookRequest {
        public String recordId;
        public String accountUID;
        public String productSelected;
        public String resourceSelected;
        public String wtgIdSelected;
        public String locationSelected;
        public String discountSelected;
        public String discountName;
        public String referralCode; // [MHC-423]
        public String trackingCookie; // transfers tracking cookie, for example ruler rasash parameter
        public String reasonForVisit;
        public String patientType;
        public Date selectedDate;
        public Datetime timeSelected;
        public Datetime timeSelectedEnd;
        public String mode;
        public String selectedMode;
        public String onlineSessionId;
        public String existingOpportunityId; // [MHC-478]
        public String existingLeadId; // [MHC-600]
        public Boolean withoutLogin; // [MHC-617];
        public String storeName;
        public String thirdPartyRef;
        public String randoxPID; // filled in if booking through randox landing page
        public String voucherTag; // filled in if booking through randox landing page
        public List<FileData> attachments;
    }

    public class FileData {
        public String filename;
        public String base64;
    }

    public class TheoFormRequest {
        public String dob_d;
        public String dob_m;
        public String dob_y;
        public String firstName;
        public String gender;
        public String lastName;
        public String promoCode;
        public String theoEmail;
        public String theoPhone;
        public String theoReasonForVisitInput;
        public String county;
        public String city;
        public String postalCode;
        public String address3;
        public String address2;
        public String address1;
    }

    public class CheckQuoteResponse {
        public Decimal amount;
        public Boolean quoteCalculated;
    }


    public class BookResponse {
        public String oppId;
        public String appId;
        public Decimal amount;
        public String quoteId;
        public String serviceType;
        public String oomCounter;
        public OnlBookPricingController.OOMSurcharge oomSurcharge;

        public BookResponse() {

        }

        public BookResponse(String oppId, String appId, Decimal amount, String quoteId) {
            this.appId = appId;
            this.oppId = oppId;
            this.amount = amount;
            this.quoteId = quoteId;
        }
    }


    public class PricesByBook {
        public Decimal standardPrice;

        public PricesByBook() {

        }

    }

    public class BookingException extends Exception {

    }

    public class ProductWrapper {
        public Product2 product;
        public Decimal standardPrice;
        public Id defaultWTGId;
        public Id defaultAppointmentID;
        public Date availableFrom;
        public Boolean hasUpsells;

        public List<ProductWrapper> upsells = new List<OnlBookUI.ProductWrapper>();

        public ProductWrapper() {

        }

        public ProductWrapper(Product2 product, Decimal standardPrice, Id defaultWTGId) {
            this.product = product;
            this.standardPrice = standardPrice;
            this.defaultWTGId = defaultWTGId;
        }
    }


    public class ProductFilter {
        public String wtgServiceType;
        public String storeName;
        public String category;
        public String dev; // a way to get all apps shown
        public String voucherTag;
        public Boolean showHidden;
    }

    public class RegisterRequest {
        public String firstName;
        public String lastName;
        public String email;
        public Date dob;
        public String phone;
        public String password;
        public String gender;

        public String address1;
        public String address2;
        public String address3;
        public String postalCode;
        public String city;
        public String county;
    }


    /**
     * Patient wants to register when:
     * - There is no patient already with that email in system -> Ok, we create a new account
     * - There is already a patient with that email and they have registered  -> Patient can not register, must use different email address
     * - There is a single patient with that email in system, but no Date of birth -> We reuse that existing account
     * - There is a single patient with that email in system, and the Date of birth is the same -> We reuse that existing account
     * - There is a single patient with that email in system, and the Date of birth is different -> They can not register, they have to call staff to sort out (change date of birth or create a new account)
     * - There are multiple patient with that email in system:
     *   o	None are there with the same DOB -> Patient has to call and sort out the duplicates / change DOBs before registering
     *   o	If there is one with the same date of birth, OK, We reuse that existing account
     *   o	If there are multiple with the same email and DOB -> Patient has to call and sort out the duplicates / change DOBs before registering
     *
     * @param email
     * @param dob
     *
     * @return null if no Candidate account is found, or Account if there is a viable candidate, or thrown an exception
     */
    public static Account validateRegistrationRequest(String email, Date dob) {

        List<Account> accounts = [
                SELECT
                        Id,
                        PersonEmail,
                        Date_of_Birth__c,
                        FirstName,
                        LastName,
                        Store_UUID__c,
                        Patient_Type__c,
                        Store_password__c
                FROM Account
                WHERE PersonEmail = :email
                AND IsPersonAccount = TRUE
                AND DoNotSync__pc != TRUE
                ORDER BY CreatedDate DESC
        ];

        //no accounts with same email
        if (accounts.size() == 0) return null;

        // if there is already a patient with that email and they have registered  -> Patient can not register, must use different email address
        for (Account account : accounts) {
            if (!String.isEmpty(account.Store_password__c)) {
                throw new MHCException('EMAIL_ALREADY_REGISTERED_WITH_PASSWORD');
            }
        }

        if (accounts.size() == 1) {
            // - There is a single patient with that email in system, but no Date of birth -> We reuse that existing account
            // - There is a single patient with that email in system, and the Date of birth is the same -> We reuse that existing account
            if (accounts.get (0).Date_of_Birth__c == null
                    || accounts.get (0).Date_of_Birth__c == Date.newInstance(1970, 1, 1)
                    || accounts.get (0).Date_of_Birth__c == dob
                    || accounts.get (0).Date_of_Birth__c == dob.addDays(1)
                    || accounts.get (0).Date_of_Birth__c == dob.addDays(-1)
            ) {
                return accounts.get (0);
            }
            else {
                throw new MHCException('DOB_DIFFERENT');
            }
        }
        //-	There are multiple patient with that email in system:
        else {
            Account candidate = null;

            //None are there with the same DOB -> Patient has to call and sort out the duplicates / change DOBs before registering
            //If there is one with the same date of birth, OK, We reuse that existing account
            //If there are multiple with the same email and DOB -> Patient has to call and sort out the duplicates / change DOBs before registering
            for (Account account : accounts) {
                if (account.Date_of_Birth__c == dob || accounts.get (0).Date_of_Birth__c == dob.addDays(1) || accounts.get (0).Date_of_Birth__c == dob.addDays(-1)) {
                    if (candidate != null) throw new MHCException('MULTIPLE_CANDIDATES');
                    candidate = account;
                }
            }

            if (candidate != null) return candidate;
            else throw new MHCException('MULTIPLE_CANDIDATES');
        }
    }


    /**
     * Note: this will return a product even when Hide_In_Store_Browsing__c = TRUE, for example for Randox COnsultion products
     *
     * @param productCode
     * @param store
     *
     * @return
     */
    @AuraEnabled
    public static String aura_findProductForDirect(String productCode, String store) {
        try {
            List<Product2> ps = [
                    SELECT Id,
                            Name,
                            ProductCode,
                            Store_Categories__c,
                            Store_Sub_Category__c,
                            Work_Type_Group__c,
                            Store_Sort_Order__c,
                            Store_Title__c,
                            Store_Subtitle__c,
                            Store_Highlight__c,
                            Store_Image__c,
                            Store_Upsell_Tier__c,
                            Store_Upsell_Description__c,
                            Store_Upsell_Group__c,
                            Store_Hide_Practitioner_List__c,
                            Store_Attachment_Required__c,
                            Store_Attachment_Text__c,
                            Work_Type_Group__r.Service_Type__c,
                            Business_Unit__c,
                            Work_Type_Group__r.Appointment_Type__c,
                            Description, (
                            SELECT Id,
                                    Pricebook2.Name,
                                    Pricebook2.IsStandard,
                                    Pricebook2.IsActive,
                                    UnitPrice
                            FROM PricebookEntries
                    )
                    FROM Product2
                    WHERE ProductCode = :productCode
                    AND IsActive = TRUE
                    AND Appointment__c = TRUE
                    AND Available_in_Stores__c INCLUDES (:store)
                    AND Include_in_Store__c = TRUE
            ];

            if (ps.isEmpty()) return null;

            Product2 product = ps[0];

            product.Name = normalizeProductName(product);

            return JSON.serializePretty(product);
        }
        catch (Exception e) {
            return null;
        }
    }

    public static String normalizeProductName(Product2 product) {
        if (isNotBlank(product.Store_Title__c) && isNotBlank(product.Store_Subtitle__c)) {
            return safeConcatWithDash(product.Store_Title__c, product.Store_Subtitle__c);
        }
        else if (isNotBlank(product.Store_Title__c)) {
            return product.Store_Title__c;
        }
        else {
            return product.Name;
        }
    }

    /**
     * This is a private utility method that safely concatenates two strings with a dash.
     * If one of the strings is blank, it will return the other string. If both strings are blank, it will return an empty string.
     *
     * @param str1 The first string to be concatenated.
     * @param str2 The second string to be concatenated.
     *
     * @return The concatenated string with a dash, or the non-blank string, or empty string if both inputs are blank.
     */
    @TestVisible
    private static String safeConcatWithDash(String str1, String str2) {
        if (isNotBlank(str1) && isNotBlank(str2)) {
            return str1 + ' - ' + str2;
        }
        else if (isNotBlank(str1)) {
            return str1;
        }
        else if (isNotBlank(str2)) {
            return str2;
        }
        else {
            return '';
        }
    }

    private static Boolean isNotBlank(String str) {
        return String.isNotBlank(str);
    }

    public static Boolean isMedical(ServiceAppointment app, Map<String, String> mapServiceType) {
        return SERVICE_TYPE_MEDICAL.equalsIgnoreCase(mapServiceType.get(app.WorkTypeId));
    }
    public static Boolean isDental(ServiceAppointment app, Map<String, String> mapServiceType) {
        return SERVICE_TYPE_DENTAL.equalsIgnoreCase(mapServiceType.get(app.WorkTypeId));
    }


}