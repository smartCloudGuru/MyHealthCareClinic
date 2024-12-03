/**
 * @author Zoran Zunko
 *
 * @date 3/9/21
 *
 * https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/requests_ls_getappointmentcandidates.htm
 * https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/requests_ls_getappointmentslots.htm
 * https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/requests_ls_scheduling.htm
 * https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_resources_service_territories.htm
 */
public without sharing class onl_CheckoutCtrl {

    public static final String PRODUCT_DELIVERY_CLASS_CLICKCOLLECT = 'Click & Collect';
    public static final String PRODUCT_DELIVERY_FAMILY = 'Delivery Option';
    public static final Integer CUTOFF_HOUR = 15;
    public static final String STORE_BUSINESS_UNIT = 'GP';
    /**
     * A container for the COVID Tests available online
     */
    public class SearchTestCenterResponse {
        public Product2 product;
        public List<TestCenterInfo> locations;
        public Integer daysQueried;
        public SearchTestCenterResponse(Integer daysQueried) {
            this.daysQueried = daysQueried;
            locations = new List<onl_CheckoutCtrl.TestCenterInfo>();
        }
    }

    public static Map<String, Id> map_SchedulerPolicyDevName_Id;

    public static Map<String, Id> schedulerPolicyNameIdMap() {
        if (map_SchedulerPolicyDevName_Id == null) {
            map_SchedulerPolicyDevName_Id = new Map<String, Id>();
            List<AppointmentSchedulingPolicy> policies = [SELECT Id, DeveloperName FROM AppointmentSchedulingPolicy];
            for (AppointmentSchedulingPolicy appointmentSchedulingPolicy : policies) {
                map_SchedulerPolicyDevName_Id.put(appointmentSchedulingPolicy.DeveloperName, appointmentSchedulingPolicy.Id);
            }
        }

        return map_SchedulerPolicyDevName_Id;
    }


    /**
     * A container for Test Center information
     */
    public class TestCenterInfo {
        public String name;
        public Datetime firstAvailable;
        public String distance;
        public String city;
        public String country;
        public String postalCode;
        public String state;
        public String street;
        public String id;

        public TestCenterInfo(String name, Datetime firstAvailable) {
            this.name = name;
            this.firstAvailable = firstAvailable;
        }

        public TestCenterInfo(String name) {
            this(name, null);
        }
    }

    @AuraEnabled(Cacheable=true)
    public static String getCustomSettings() {
        return OnlineStoreSettingsManager.getStoreSettings().IdealPostcodes_API_Key__c;
    }

    @AuraEnabled(Cacheable=true)
    public static String getFindByTestTypeOptions() {
        List<Online_Store_Lists_Config__c> conf = [SELECT Id, BookTestInClinicOptions__c FROM Online_Store_Lists_Config__c LIMIT 1];
        List<ValueLabelPair> ret = new List<ValueLabelPair>();
        if (!conf.isEmpty()) {
            if (!String.isEmpty(conf[0].BookTestInClinicOptions__c)) {
                String[] opts = conf[0].BookTestInClinicOptions__c.split(';');
                for (String str : opts) {
                    ret.add(new ValueLabelPair(str));
                }
            }
        }
        return JSON.serialize(ret);
    }

    /**
     * Present Delivery options to Online Store, based on store name and current dayOfWeek and time. Uses cutoff for next delivery collection
     *
     * @param store
     *
     * @return
     */
    @AuraEnabled(Cacheable=true)
    public static String getDeliveryOptions(String store) {

        //we need configured holidays so some dates can be skipped
        List<Holiday> holidays = [SELECT StartTimeInMinutes, Name, ActivityDate FROM Holiday];

        List<Product2> dos = [
                SELECT Id,
                        Name,
                        Description,
                        Is_Delivery_Option__c,
                        Non_Membership_Price__c,
                        Delivery_Class__c,
                        Delivery_Product_Within_Days__c,
                        Delivery_Product_By_Hours__c
                FROM Product2
                WHERE Is_Delivery_Option__c = TRUE
                AND IsActive = TRUE
                AND Available_in_Stores__c INCLUDES (:store)
                ORDER BY Store_Sort_Order__c
        ];

        List<Product2> ret = new List<Product2>();

        //get current delivery class options
        String currentNeededDeliveryClass = 'Monday to Friday';

        Datetime now = Datetime.now();
        Boolean isAfterCutoff = now.hour() >= CUTOFF_HOUR;
        String dayOfWeek = now.format('u');

        System.debug(':getDeliveryOptions:dayOfWeek=' + dayOfWeek + ',isAfterCutoff=' + isAfterCutoff);

        if ((dayOfWeek == '4' && isAfterCutoff) || (dayOfWeek == '5' && !isAfterCutoff)) currentNeededDeliveryClass = 'Saturday';
        else if ((dayOfWeek == '5' && isAfterCutoff) || (dayOfWeek == '6' && !isAfterCutoff)) currentNeededDeliveryClass = 'Sunday';

        for (Product2 p : dos) {
            if (p.Delivery_Class__c == 'Click & Collect' || p.Delivery_Class__c == currentNeededDeliveryClass || (p.Delivery_Class__c == 'Monday to Friday' && p.Non_Membership_Price__c == 0)) // always include the free next day option
            {
                //modify description of delivery options for GUI
                p.Description = getDescriptiveDateForDeliveryProduct(p, holidays);
                if (p.Description != null) ret.add(p);
            }
        }

        return JSON.serialize(ret);
    }

    public static String getDescriptiveDateForDeliveryProduct(Product2 p, List<Holiday> holidays) {
        Datetime now = Datetime.now();
        Boolean isAfterCutoff = now.hour() >= CUTOFF_HOUR;

        String ret = p.Description;
        String retShort = p.Description;

        try {
            if (p.Is_Delivery_Option__c && p.Delivery_Class__c != PRODUCT_DELIVERY_CLASS_CLICKCOLLECT) {
                Datetime expectedDelivery;

                //calculate earliest delivery date by the Delivery_Product_Within_Days__c specified on the product, or default to 1 days
                if (p.Delivery_Product_Within_Days__c != null) {
                    expectedDelivery = now.addDays((Integer) p.Delivery_Product_Within_Days__c);
                }
                else {
                    expectedDelivery = now.addDays(1);
                }
                if (isAfterCutoff) {
                    expectedDelivery = expectedDelivery.addDays(1);
                }

                //System.debug(isAfterCutoff);
                //because we add3d the default option for free, add the next monday
                if (p.Delivery_Class__c == 'Monday to Friday') {
                    String dayOfWeek = now.format('u');
                    if (dayOfWeek == '4' && isAfterCutoff) expectedDelivery = now.addDays(4);
                    if (dayOfWeek == '5') expectedDelivery = now.addDays(3);
                    if (dayOfWeek == '6') expectedDelivery = now.addDays(2);
                    if (dayOfWeek == '7') expectedDelivery = now.addDays(1);
                }

                // if the expectedDelivery date is on a holiday, or a day after a holiday, do not use it (returns null to be ignored)
                if (checkIsHoliday(expectedDelivery.date(), holidays)) return null;
                if (checkIsHoliday(expectedDelivery.addDays(1).date(), holidays)) return null;


                ret = 'Courier Delivery, ' + expectedDelivery.format('EEEE dd MMM');
                retShort = 'Delivery, ' + expectedDelivery.format('EEE dd MMM');
                if (p.Delivery_Product_By_Hours__c != null) {
                    ret += ' by ' +
                            Datetime.newInstance(
                                    expectedDelivery.year(),
                                    expectedDelivery.month(),
                                    expectedDelivery.day(),
                                    p.Delivery_Product_By_Hours__c.hour(),
                                    p.Delivery_Product_By_Hours__c.minute(), 0).format('hh:mm aa');
                    retShort += ' by ' +
                            Datetime.newInstance(
                                    expectedDelivery.year(),
                                    expectedDelivery.month(),
                                    expectedDelivery.day(),
                                    p.Delivery_Product_By_Hours__c.hour(),
                                    p.Delivery_Product_By_Hours__c.minute(), 0).format('hh:mm aa');
                }
            }

            ret = ret + '|' + retShort;
            ret = ret.replaceAll('12:00 PM', '12:00 Midday');
        }
        catch (Exception ignore) {
        }

        return ret;
    }

    public static Boolean checkIsHoliday(Date dte, List<Holiday> holidays) {
        if (holidays == null) return false;
        for (Holiday hDay : holidays) {
            if (dte.daysBetween(hDay.ActivityDate) == 0) return true;
        }
        return false;
    }

    /**
     * Searches available test centers for a given type of test and locaitons
     *
     * @param params Input Parameters as JSON String
     * <p>
     *     <code>
     *         {
     *           "postalcode": "W1A 1AA",
     *           "distance": "10",
     *           "type": "PCR Test",
     *           "turnaround": "48 Hour"
     *         }
     *     </code>
     * </p>
     *
     * @return JSON serialized
     *
     * @see onl_CheckoutCtrl.SearchTestCenterResponse
     */
    @AuraEnabled public static String searchCovidTests(String params) {
        return null;
//        try {
//            //read all the input parameters
//            Map<String, Object> parameters = (Map<String, Object>) JSON.deserializeUntyped(params);
//            String postalcode = (String) parameters.get('postalcode');
//            String radius = (String) parameters.get('distance');
//            String type = (String) parameters.get('type');
//            String turnaround = (parameters.get('turnaround') == null) ? '' : (String) parameters.get('turnaround');
//
//            String store = (String) parameters.get('store');
//
//            //filter by store category including both turnaround and test type
//            String includesClause = type + ';' + turnaround;
//            //            System.debug('::searchCovidTests:includesClause: ' + includesClause);
//            List<Product2> availableProducts = [
//                    SELECT Id,
//                            Quantity_of_COVID_Tests__c,
//                            Description,
//                            Store_Sort_Order__c,
//                            Turnaround_Time_Global__c,
//                            Requires_scheduling__c,
//                            Requires_delivery__c,
//                            Product_Sub_Family__c,
//                            Work_Type_Group__c,
//                            Non_Membership_Price__c,
//                            Name, (
//                            SELECT COVID_Test_Type__c,
//                                    Name,
//                                    Number_of_Tests__c,
//                                    Product__c,
//                                    Turnaround_Time__c,
//                                    Work_Type_Group__c,
//                                    First_Available__c,
//                                    Sort_Order__c
//                            FROM Product2.Default_COVID_Tests__r
//                    )
//                    FROM Product2
//                    WHERE Include_in_Store__c = TRUE AND IsActive = TRUE AND Store_Categories__c INCLUDES (:includesClause) AND Available_in_Stores__c INCLUDES (:store)
//                    ORDER BY Quantity_of_COVID_Tests__c ASC, Non_Membership_Price__c ASC
//            ];
//
//            System.debug('::searchCovidTests:found available products: ' + availableProducts);
//
//            Map<Id, List<Product2>> workGroupTypeIds = new Map<Id, List<Product2>>();
//            for (Product2 availableProduct : availableProducts) {
//                Id workGroupTypeId;
//                if (availableProduct.Default_COVID_Tests__r.isEmpty()) {
//                    System.debug('::searchCovidTests:problem with product: ' + availableProduct.Id);
//                }
//                else {
//                    System.debug('::searchCovidTests:Default_COVID_Tests__r[0].Work_Type_Group__c: ' + availableProduct.Default_COVID_Tests__r[0].Work_Type_Group__c);
//                }
//                if (availableProduct.Default_COVID_Tests__r.size() == 1 && String.isNotBlank(availableProduct.Default_COVID_Tests__r[0].Work_Type_Group__c)) {
//                    workGroupTypeId = availableProduct.Default_COVID_Tests__r[0].Work_Type_Group__c;
//                }
//                //find first available
//                else if (availableProduct.Default_COVID_Tests__r.size() > 1) {
//                    for (Default_COVID_Test__c defaultCOVIDTest : availableProduct.Default_COVID_Tests__r) {
//                        if (defaultCOVIDTest.First_Available__c) {
//                            workGroupTypeId = defaultCOVIDTest.Work_Type_Group__c;
//                            break;
//                        }
//                    }
//                    //if there no first available use the first one with work type group
//                    if (String.isBlank(workGroupTypeId)) {
//                        for (Default_COVID_Test__c defaultCOVIDTest : availableProduct.Default_COVID_Tests__r) {
//                            if (String.isNotBlank(defaultCOVIDTest.Work_Type_Group__c)) {
//                                workGroupTypeId = defaultCOVIDTest.Work_Type_Group__c;
//                                break;
//                            }
//                        }
//                    }
//                }
//                System.debug('::searchCovidTests:workGroupTypeId: ' + workGroupTypeId);
//                if (String.isNotBlank(workGroupTypeId)) {
//                    if (!workGroupTypeIds.containsKey(workGroupTypeId)) {
//                        workGroupTypeIds.put(workGroupTypeId, new List<Product2>());
//                    }
//                    workGroupTypeIds.get(workGroupTypeId).add(availableProduct);
//                }
//            }
//
//
//            System.debug('::searchCovidTests:workGroupTypeIds: ' + workGroupTypeIds);
//            if (!workGroupTypeIds.isEmpty()) {
//                System.Location queryLocation = GeoCodeAPI.getGeocode('UK ' + postalcode);
//                System.debug('::searchCovidTests:queryLocation: ' + queryLocation);
//                List<SearchTestCenterResponse> response = new List<onl_CheckoutCtrl.SearchTestCenterResponse>();
//                //read settings and log in
//                OnlineStoreSettings__c storeSettings = OnlineStoreSettingsManager.getStoreSettings();
//                Login.LoginResponse loginResponse = Login.login(storeSettings.Username__c, storeSettings.Password__c, storeSettings.Login_URL__c);
//                for (Id workGroupTypeId : workGroupTypeIds.keySet()) {
//                    System.debug('::searchCovidTests:serviceTerritoriesRequest:wtg=' + workGroupTypeId + ':queryLocation=' + queryLocation + ':radius=' + radius);
//                    //create a request to get the service territories
//                    SchedulerAPI.GetServiceTerritoriesRequest serviceTerritoriesRequest = new SchedulerAPI.GetServiceTerritoriesRequest(
//                            workGroupTypeId,
//                            //get geocoded postal key
//                            queryLocation,
//                            radius
//                    );
//                    SchedulerAPI scheduler = new SchedulerAPI(loginResponse.salesforceUrl);
//                    SchedulerAPI.ServiceTerritoriesOutput testCenters;
//                    try {
//                        testCenters = scheduler.getServiceTerritories(loginResponse.sessionId, serviceTerritoriesRequest);
//                    }
//                    catch (Exception ex) {
//                        System.debug(LoggingLevel.ERROR, ex.getMessage() + ' - ' + ex.getStackTraceString()); continue;
//                    }
//                    System.debug('::searchCovidTests:testCenters:' + testCenters);
//                    if (testCenters.result.serviceTerritories.isEmpty()) continue;
//                    Map<String, SchedulerAPI.ServiceTerritoriesResult> serviceTerritoriesByIds = new Map<String, SchedulerAPI.ServiceTerritoriesResult>();
//                    List<String> testCenterNames = new List<String>();
//
//                    for (SchedulerAPI.ServiceTerritoriesResult testCenter : testCenters.result.serviceTerritories) {
//                        serviceTerritoriesByIds.put(testCenter.id, testCenter);
//                        testCenterNames.add(testCenter.name);
//                    }
//
//                    Map<String, Datetime> testCenterAvailableDates = new Map<String, Datetime>();
//
//                    for (Product2 product : workGroupTypeIds.get(workGroupTypeId)) {
//                        SearchTestCenterResponse getLocResponse = new SearchTestCenterResponse(OnlineStoreSettingsManager.getDayQueried());
//                        getLocResponse.product = product;
//                        for (String territoryId : serviceTerritoriesByIds.keySet()) {
//                            if (testCenterAvailableDates.containsKey(territoryId)) {
//                                getLocResponse.locations.add(new TestCenterInfo(serviceTerritoriesByIds.get(territoryId).name, testCenterAvailableDates.get(territoryId)));
//                            }
//                            else {
//                                getLocResponse.locations.add(new TestCenterInfo(serviceTerritoriesByIds.get(territoryId).name));
//                            }
//                        }
//                        response.add(getLocResponse);
//                    }
//                }
//
//                return JSON.serialize(response, true);
//            }
//            else {
//                return null;
//            }
//        }
//        catch (Exception e) {
//            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
//
//            throw newAuraHandledException(e.getMessage());
//        }
    }

    public static Exception newAuraHandledException(String msg) {
        AuraHandledException aEx = new AuraHandledException(msg);
        aEx.setMessage(msg);
        return aEx;
    }

    @AuraEnabled public static String searchProducts(String store) {
        try {

            //filter by store category including both turnaround and test type
            String includesClause = 'Products';
            return JSON.serialize([
                    SELECT Id,
                            Non_Membership_Price__c,
                            Quantity__c,
                            Requires_scheduling__c,
                            Requires_delivery__c,
                            Name,
                            Store_Categories__c,
                            Description,
                            Store_Sort_Order__c,
                            Is_Home_Test__c
                    FROM Product2
                    WHERE Include_in_Store__c = TRUE AND Requires_delivery__c = TRUE AND IsActive = TRUE AND Store_Categories__c INCLUDES (:includesClause) AND Available_in_Stores__c INCLUDES (:store)
                    ORDER BY Quantity_of_COVID_Tests__c ASC, Non_Membership_Price__c ASC
            ], true);
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            throw newAuraHandledException(e.getMessage());
        }
    }


    /**
     * A container for personal details and/or address data
     */
    public class PersonalDetails {
        public String firstName;
        public String lastName;
        public String email;
        public String phone;
        public String street;
        public String address1;
        public String address2;
        public String address3;
        public String city;
        public String postalCode;
        public String country;
        public String county;
    }

    /**
     * A container for personal details and/or address data
     */
    public class ScheduleAppointment {
        public PersonalDetails personalDetails;
        public String basketId;
        public String productId;
        public String defaultCovidTestId;
        public String defaultAppointmentId;
        public String serviceCenterId;
        public String startTime;
        public String endTime;
        public String store;
        public Integer quantity;
        public String resourceId;
    }
    /**
     * A container for location search parameters
     */

    public class DefaultLocation {
        public String distance;
        public String postalcode;

        public DefaultLocation(String distance, String postalcode) {
            this.distance = distance;
            this.postalcode = postalcode;
        }
    }

    public class BasketItem {
        public String id;
        public Integer quantity;
        public String type;

    }

    /**
     * A container for create order parameters
     */
    public class CreateOrderRequest {
        public PersonalDetails personalDetails;
        public List<BasketItem> basket;
        public PersonalDetails shippingInformation;
        public String basketId;
        public String store;
        public String oppid;
        public DefaultLocation defaultLocation;
        public Boolean checkMarketing;
        public Boolean checkTerms;
        public Boolean checkShare;
        public Boolean checkClickAndCollect;
        public String clickCollectLocationId;


        public CreateOrderRequest() {
            checkMarketing = false;
            checkTerms = false;
            checkClickAndCollect = false;
        }
    }

    /**
     * Stores the basket as an opportunity
     *
     * @param basketParameters json string representing the items in the basket
     *
     * @return uuid for the generated opportunity
     *
     * @see onl_CheckoutCtrl.CreateOrderRequest <p>
     *     <code>
     *          {
     *              "personalDetails": {
     *                  "firstName": "Some",
     *                  "lastName": "One",
     *                  "email": "someone@example.com",
     *                  "phone": "9234567896"
     *              },
     *              "basket": [
     *                  {
     *                      "id": "01u3H000003xLc5QAE",
     *                      "type": "Product"
     *                      "quantity": 3,
     *                  },
     *                  {
     *                      "id": "01u3H000003xLc5QAE",
     *                      "quantity": null,
     *                      "type": "Coupon"
     *                  }
     *              ],
     *              "shippingInformation": {
     *                  "firstName": "First",
     *                  "lastName": "Last",
     *                  "phone": "9234567896"
     *                  "street": "Street North XC4",
     *                  "city": "London",
     *                  "postalCode": "W11",
     *                  "country": "UK"
     *              },
     *              "basketId": "1036e4a4-b8f6-4b6b-b9b9-03609dcfb533",
     *              "defaultLocation": {
     *                  "distance": "15",
     *                  "postalcode": "W11"
     *              },
     *              "checkMarketing":true,
     *              "checkTerms":true
     *          }
     *     </code>
     * </p>
     */
    @AuraEnabled public static String createOrder(String basketParameters) {
        try {
            CreateOrderRequest orderRequest = (CreateOrderRequest) JSON.deserialize(basketParameters, CreateOrderRequest.class);

            List<Account> accounts = [SELECT Id FROM Account WHERE PersonEmail = :orderRequest.personalDetails.email LIMIT 1];
            Account acc;
            if (accounts.isEmpty()) {
                acc = new Account();
                acc.RecordTypeId = Cache.recordTypeId(AccountManager.RT_PERSON_ACCOUNT);
                acc.FirstName = orderRequest.personalDetails.firstName;
                acc.LastName = orderRequest.personalDetails.lastName;
                acc.PersonEmail = orderRequest.personalDetails.email;
                acc.Phone = orderRequest.personalDetails.phone;
                acc.PersonMobilePhone = orderRequest.personalDetails.phone;

                if (orderRequest.shippingInformation != null) {
                    acc.ShippingCity = orderRequest.shippingInformation.city;
                    acc.ShippingStreet = orderRequest.shippingInformation.street;
                    acc.ShippingPostalCode = orderRequest.shippingInformation.postalCode;
                    acc.ShippingCountry = orderRequest.shippingInformation.country;
                }

                insert acc;
            }
            else {
                acc = accounts[0];
            }
            Uuid newUuid = new Uuid();
            Opportunity opp = new Opportunity();
            opp.Call_Back__c = 'Not a call back'; //21-11-03 added default value
            opp.AccountId = acc.Id;
            opp.Name = 'Online Order ' + orderRequest.personalDetails.firstName + ' ' + orderRequest.personalDetails.lastName + ' (' + (Datetime.now() + '').left(10) + ')';
            opp.LeadSource = 'Did Not Obtain';
            opp.CloseDate = Date.today();
            opp.StageName = 'Qualification';
            opp.Site__c = 'None specified';
            opp.Business_Unit__c = STORE_BUSINESS_UNIT;
            opp.Mode__c = 'Online Booking';
            opp.Date_Appointment_Made__c = Date.today();
            opp.Appointment_Date__c = Date.today();
            opp.Online_First_Name__c = orderRequest.personalDetails.firstName;
            opp.Online_Last_Name__c = orderRequest.personalDetails.lastName;
            opp.Online_Email__c = orderRequest.personalDetails.email;
            opp.Online_Phone__c = orderRequest.personalDetails.phone;
            opp.Online_Mobile__c = orderRequest.personalDetails.phone;
            opp.Online_Post_Code__c = orderRequest.defaultLocation.postalcode;
            opp.Online_Radius__c = orderRequest.defaultLocation.distance;
            opp.Online_Terms_Accepted__c = orderRequest.checkTerms;
            opp.Online_Marketing_Accepted__c = orderRequest.checkMarketing;
            opp.UUID__c = newUuid.getValue();
            opp.Online_Store__c = orderRequest.store;
            opp.Store_Site_URL__c = StoreConfigMetadataManager.getOnlineStoreConfig(orderRequest.store)?.Store_Site_URL__c;

            if (orderRequest.shippingInformation != null) {
                opp.Online_Shipping_City__c = orderRequest.shippingInformation.city;
                opp.Online_Shipping_Street__c = orderRequest.shippingInformation.street;
                opp.Online_Shipping_Postcode__c = orderRequest.shippingInformation.postalCode;
                opp.Online_Shipping_Country__c = orderRequest.shippingInformation.country;
            }
            insert opp;

            upsert new Basket__c(Session_Id__c = orderRequest.basketId, Opportunity__c = opp.Id) Session_Id__c;

            Map<String, Integer> productsWithQuantities = new Map<String, Integer>();
            Set<Id> discountCodeIds = new Set<Id>();
            for (BasketItem product : orderRequest.basket) {
                if (product.type == 'product' || product.type == 'covid') {
                    productsWithQuantities.put(product.id, product.quantity);
                }
                else if (product.type == 'coupon') {
                    discountCodeIds.add(product.id);
                }
            }

            System.debug(LoggingLevel.FINE, 'createOrder - pbItemsWithQuantities: ' + productsWithQuantities);
            System.debug(LoggingLevel.FINE, 'createOrder - discountCodeIds: ' + discountCodeIds);

            List<Discount_Code__c> discountCodes = [
                    SELECT
                            Active__c,
                            Coupon_Code__c,
                            Discount_Amount__c,
                            End_date__c,
                            Name,
                            Percentage_discount__c,
                            Product__c,
                            Product_Family__c,
                            Start_date__c,
                            Discount_Product__c
                    FROM Discount_Code__c
                    WHERE Id IN :discountCodeIds
                    LIMIT 1
            ];


            List<Product2> products = [
                    SELECT Id,
                            Non_Membership_Price__c,
                            Requires_scheduling__c,
                            Product_Sub_Family__c,
                            Store_Categories__c,
                            Family, (
                            SELECT COVID_Test_Type__c,
                                    Name,
                                    Number_of_Tests__c,
                                    Sort_Order__c,
                                    Product__c,
                                    Turnaround_Time__c,
                                    Work_Type_Group__c,
                                    First_Available__c
                            FROM Product2.Default_COVID_Tests__r
                    ), (
                            SELECT Id
                            FROM PricebookEntries
                            WHERE Pricebook2.IsStandard = TRUE AND IsActive = TRUE
                            LIMIT 1
                    )

                    FROM Product2
                    WHERE Id IN :productsWithQuantities.keySet()
            ];


            Map<Id, List<OpportunityLineItem>> productsWithOLIs = new Map<Id, List<OpportunityLineItem>>();
            Map<Id, List<COVID_Test__c>> productsWithCovidTests = new Map<Id, List<COVID_Test__c>>();
            List<OpportunityLineItem> olis = new List<OpportunityLineItem>();


            Decimal discountAmount = 0;
            if (!discountCodes.isEmpty() && discountCodes[0].Discount_Amount__c != null) {
                discountAmount = discountCodes[0].Discount_Amount__c;
            }
            for (Product2 product : products) {
                productsWithOLIs.put(product.Id, new List<OpportunityLineItem>());
                if (!productsWithQuantities.containsKey(product.Id)) continue;
                for (Integer i = 0; i < productsWithQuantities.get(product.Id); i++) {
                    OpportunityLineItem oli = new OpportunityLineItem();
                    System.debug(LoggingLevel.ERROR, 'createOrder - product.PricebookEntries: ' + product.PricebookEntries);
                    oli.OpportunityId = opp.Id;
                    oli.PricebookEntryId = product.PricebookEntries[0].Id;
                    oli.Product2Id = product.Id;
                    oli.UnitPrice = product.Non_Membership_Price__c;
                    oli.Quantity = 1;
                    olis.add(oli);

                    if (!discountCodes.isEmpty() && discountCodes[0].Percentage_discount__c != null && doesDiscountApply(discountCodes[0], product)) {
                        discountAmount += oli.UnitPrice * oli.Quantity * discountCodes[0].Percentage_discount__c / 100;
                    }
                    productsWithOLIs.get(product.Id).add(oli);
                }

            }
            System.debug(LoggingLevel.FINE, 'createOrder - discountAmount: ' + discountAmount);

            if (!discountCodes.isEmpty() && discountAmount > 0) {
                PricebookEntry discountPriceBookEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id = :discountCodes[0].Discount_Product__c];
                OpportunityLineItem oli = new OpportunityLineItem();

                oli.OpportunityId = opp.Id;
                oli.PricebookEntryId = discountPriceBookEntry.Id;
                oli.Product2Id = discountCodes[0].Discount_Product__c;
                oli.UnitPrice = -discountAmount;
                oli.Quantity = 1;
                oli.Description = discountCodes[0].Name;
                olis.add(oli);
                insert new Discount_Code_Usage__c(Discount_Code__c = discountCodes[0].Id, Opportunity__c = opp.Id);

            }
            insert olis;

            List<COVID_Test__c> testsToInsert = new List<COVID_Test__c>();

            Integer numTests = 1;
            for (Product2 product : products) {
                if (product.Requires_scheduling__c) {
                    for (OpportunityLineItem oli : productsWithOLIs.get(product.Id)) {
                        for (Default_COVID_Test__c defaultCOVIDTest : product.Default_COVID_Tests__r) {
                            numTests = 1;
                            if (defaultCOVIDTest.Number_of_Tests__c != null) numTests = (Integer) defaultCOVIDTest.Number_of_Tests__c;
                            for (Integer i = 0; i < numTests; i++) {
                                COVID_Test__c covidTest = new COVID_Test__c();
                                covidTest.Turnaround_Time_Global__c = defaultCOVIDTest.Turnaround_Time__c;
                                covidTest.Test_Type__c = defaultCOVIDTest.COVID_Test_Type__c;
                                covidTest.Work_Type_Group__c = defaultCOVIDTest.Work_Type_Group__c;
                                covidTest.Sort_Order__c = defaultCOVIDTest.Sort_Order__c == null ? 1 : defaultCOVIDTest.Sort_Order__c;
                                covidTest.Provided_Email__c = orderRequest.personalDetails.email;
                                covidTest.Provided_First_Name__c = orderRequest.personalDetails.firstName;
                                covidTest.Provided_Last_Name__c = orderRequest.personalDetails.lastName;
                                covidTest.Provided_Phone_Number__c = orderRequest.personalDetails.phone;
                                covidTest.Provided_Mobile_Phone__c = orderRequest.personalDetails.phone;
                                covidTest.Reservation_Date_Time__c = Datetime.now().addMinutes(OnlineStoreSettingsManager.getCancellationWindow());
                                covidTest.Patient__c = acc.Id;
                                covidTest.Opportunity__c = opp.Id;
                                covidTest.Opportunity_Product__c = oli.Id;

                                testsToInsert.add(covidTest);
                            }
                        }
                    }
                }
            }

            if (!testsToInsert.isEmpty()) {
                insert testsToInsert;
            }
            AnthologyTriggerDispatch.noTriggers = true;
            opp.Send_Confirmation_Email__c = true;
            update opp;
            return opp.UUID__c;
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            throw newAuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String getLocations(String postalcode, String radius, String covidTestId) {
        try {
            SearchTestCenterResponse response = new SearchTestCenterResponse(OnlineStoreSettingsManager.getDayQueried());
            COVID_Test__c covidTest = [SELECT Id, Work_Type_Group__c FROM COVID_Test__c WHERE Id = :covidTestId];
            //read settings and log in
            OnlineStoreSettings__c storeSettings = OnlineStoreSettingsManager.getStoreSettings();
            Login.LoginResponse loginResponse = Login.login(storeSettings.Username__c, storeSettings.Password__c, storeSettings.Login_URL__c);
            Location loc = GeoCodeAPI.getGeocode('UK ' + postalcode);
            //create a request to get the service territories
            SchedulerAPI.GetServiceTerritoriesRequest serviceTerritoriesRequest = new SchedulerAPI.GetServiceTerritoriesRequest(
                    //get the workTypeGroup from available products, the products should all point to the same work type group id
                    covidTest.Work_Type_Group__c,
                    //get ge0coded postal key
                    loc,
                    radius
            );
            SchedulerAPI scheduler = new SchedulerAPI(loginResponse.salesforceUrl);

            SchedulerAPI.ServiceTerritoriesOutput testCenters = scheduler.getServiceTerritories(loginResponse.sessionId, serviceTerritoriesRequest);

            Set<String> testCentersWithoutDates = new Set<String>();

            //if no service centers
            if (testCenters.result.serviceTerritories.isEmpty()) return JSON.serialize(response, true);
            for (SchedulerAPI.ServiceTerritoriesResult testCenter : testCenters.result.serviceTerritories) {
                testCentersWithoutDates.add(testCenter.id);
            }

            for (SchedulerAPI.ServiceTerritoriesResult testCenter : testCenters.result.serviceTerritories) {
                TestCenterInfo centerInfo = new TestCenterInfo(testCenter.name);
                centerInfo.city = testCenter.city;
                centerInfo.street = testCenter.street;
                centerInfo.postalCode = testCenter.postalCode;
                centerInfo.id = testCenter.id;

                response.locations.add(centerInfo);
            }

            return JSON.serialize(response, true);
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            throw newAuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static String getOpportunity(String opid) {
        try {
            String covidTestsIncludesClause = 'COVID Tests';
            Map<String, Object> response = new Map<String, Object>();
            response.put('opportunityId', opid);
            response.put('covidTests', [
                    SELECT Id,
                            Product2.Work_Type_Group__c,
                            Product2.Description,
                            Product2.Store_Sort_Order__c,
                            Opportunity.Online_Post_Code__c,
                            Opportunity.Online_Radius__c,
                            Opportunity.StageName,
                            UnitPrice,
                            Quantity,
                            TotalPrice,
                            Product2.Name,
                            Product2.Requires_delivery__c,
                            Product2.Requires_scheduling__c,
                            Product2.Delivery_Product_By_Hours__c,
                            Product2.Delivery_Product_Within_Days__c,
                            Product2.Is_Home_Test__c,
                            Product2.Store_Categories__c,
                            Opportunity.IsWon, (
                            SELECT Id,
                                    Work_Type_Group__c,
                                    Turnaround_Time_Global__c,
                                    Test_Type__c,
                                    Scheduled_Appointment__c,
                                    Scheduled_Appointment__r.Status,
                                    Scheduled_Appointment__r.SchedStartTime,
                                    Scheduled_Appointment__r.SchedEndTime,
                                    Scheduled_Appointment__r.ServiceTerritory.Name,
                                    Scheduled_Appointment__r.ServiceTerritory.Address,
                                    Provided_Email__c,
                                    Provided_First_Name__c,
                                    Provided_Last_Name__c,
                                    Provided_Phone_Number__c,
                                    Provided_Mobile_Phone__c,
                                    Allows_Scheduling__c,
                                    Sort_Order__c,
                                    Opportunity_Product__r.Opportunity.Online_Post_Code__c,
                                    Opportunity_Product__r.Opportunity.Online_Radius__c,
                                    Opportunity_Product__r.Opportunity.IsWon
                            FROM OpportunityLineItem.COVID_Tests__r
                            ORDER BY Sort_Order__c ASC
                    )
                    FROM OpportunityLineItem
                    WHERE Opportunity.UUID__c = :opid AND Product2.Family = :covidTestsIncludesClause AND Product2.Requires_scheduling__c = TRUE
                    ORDER BY Product2.Store_Sort_Order__c ASC
            ]);

            response.put('appointments', [
                    SELECT Id,
                            Product2.Work_Type_Group__c,
                            Product2.Description,
                            Product2.Store_Sort_Order__c,
                            Opportunity.Online_Post_Code__c,
                            Opportunity.Online_Radius__c,
                            Opportunity.StageName,
                            UnitPrice,
                            Quantity,
                            TotalPrice,
                            Product2.Name,
                            Product2.Requires_delivery__c,
                            Product2.Requires_scheduling__c,
                            Product2.Delivery_Product_By_Hours__c,
                            Product2.Delivery_Product_Within_Days__c,
                            Product2.Is_Home_Test__c,
                            Product2.Store_Categories__c,
                            Opportunity.IsWon, (
                            SELECT Id,
                                    WorkType.Name,
                                    SchedStartTime,
                                    SchedEndTime,
                                    ServiceTerritory.Name,
                                    ServiceTerritory.Address,
                                    Opportunity_Product__r.Opportunity.Online_Post_Code__c,
                                    Opportunity_Product__r.Opportunity.Online_Radius__c,
                                    Opportunity_Product__r.Opportunity.IsWon
                            FROM OpportunityLineItem.Appointments__r
                    )
                    FROM OpportunityLineItem
                    WHERE Opportunity.UUID__c = :opid AND Product2.Appointment__c = TRUE
                    ORDER BY Product2.Store_Sort_Order__c ASC
            ]);
            String productsIncludesClause = 'Products';

            response.put('products', [
                    SELECT Id,
                            UnitPrice,
                            Product2.Description,
                            Product2.Store_Sort_Order__c,
                            Quantity,
                            TotalPrice,
                            Product2.Name,
                            Product2.Requires_delivery__c,
                            Product2.Requires_scheduling__c,
                            Product2.Store_Categories__c,
                            Product2.Is_Home_Test__c
                    FROM OpportunityLineItem
                    WHERE Opportunity.UUID__c = :opid AND Product2.Store_Categories__c INCLUDES (:productsIncludesClause)
                    ORDER BY Product2.Store_Sort_Order__c ASC
            ]);
            response.put('discounts', [
                    SELECT Id,
                            Description,
                            TotalPrice
                    FROM OpportunityLineItem
                    WHERE Opportunity.UUID__c = :opid AND Product2.Family = 'Discount'
            ]);
            response.put('delivery', [
                    SELECT Id,
                            Description,
                            TotalPrice,
                            Product2.Delivery_Product_By_Hours__c,
                            Product2.Delivery_Product_Within_Days__c
                    FROM OpportunityLineItem
                    WHERE Opportunity.UUID__c = :opid AND Product2.Is_Delivery_Option__c = TRUE
            ]);
            Opportunity opp = [
                    SELECT
                            Id,
                            IsWon,
                            Online_Stripe_Session__c,
                            Paid__c,
                            Amount,
                            Online_Post_Code__c,
                            Online_Radius__c,
                            Account.ShippingCity,
                            Account.ShippingStreet,
                            Account.ShippingPostalCode,
                            Account.ShippingCountry,
                            Online_First_Name__c,
                            Online_Last_Name__c,
                            Online_Email__c,
                            Online_Phone__c,
                            Online_Mobile__c,
                            Online_Billing_Address_Line_1__c,
                            Online_Billing_Address_Line_2__c,
                            Online_Billing_Address_Line_3__c,
                            Online_Billing_Postal_Code__c,
                            Online_Billing_City__c,
                            Online_Shipping_First_Name__c,
                            Online_Shipping_Last_Name__c,
                            Online_Shipping_Email__c,
                            Online_Shipping_Phone__c,
                            Online_Shipping_Address_Line_1__c,
                            Online_Shipping_Address_Line_2__c,
                            Online_Shipping_Address_Line_3__c,
                            Online_Shipping_City__c,
                            Online_Shipping_Country__c,
                            Online_Shipping_Postcode__c,
                            Online_Order_Number__c,
                            Online_Shipping_Street__c,
                            Click_and_Collect__c,
                            Pickup_Location__c,
                            StageName
                    FROM Opportunity
                    WHERE UUID__c = :opid
            ];
            PersonalDetails personalDetails = new PersonalDetails();
            personalDetails.firstName = opp.Online_First_Name__c;
            personalDetails.lastName = opp.Online_Last_Name__c;
            personalDetails.email = opp.Online_Email__c;
            personalDetails.phone = opp.Online_Phone__c;
            personalDetails.address1 = opp.Online_Billing_Address_Line_1__c;
            personalDetails.address2 = opp.Online_Billing_Address_Line_2__c;
            personalDetails.address3 = opp.Online_Billing_Address_Line_3__c;
            personalDetails.postalCode = opp.Online_Billing_Postal_Code__c;
            personalDetails.city = opp.Online_Billing_City__c;
            response.put('personalDetails', personalDetails);

            PersonalDetails shippingInformation = new PersonalDetails();
            shippingInformation.postalCode = opp.Online_Shipping_Postcode__c;
            shippingInformation.city = opp.Online_Shipping_City__c;
            shippingInformation.address1 = opp.Online_Shipping_Address_Line_1__c;
            shippingInformation.address2 = opp.Online_Shipping_Address_Line_2__c;
            shippingInformation.address3 = opp.Online_Shipping_Address_Line_3__c;
            shippingInformation.country = opp.Online_Shipping_Country__c;
            shippingInformation.firstName = opp.Online_Shipping_First_Name__c;
            shippingInformation.lastName = opp.Online_Shipping_Last_Name__c;
            shippingInformation.email = opp.Online_Shipping_Email__c;
            shippingInformation.phone = opp.Online_Shipping_Phone__c;
            response.put('shippingInformation', shippingInformation);

            response.put('orderNumber', opp.Online_Order_Number__c);
            response.put('defaultLocation', new DefaultLocation(opp.Online_Radius__c, opp.Online_Post_Code__c));
            response.put('opportunityPaid', opp.Paid__c);
            response.put('Click_and_Collect__c', opp.Click_and_Collect__c);
            response.put('Pickup_Location__c', opp.Pickup_Location__c);
            response.put('opportunityClosed', (opp.StageName == 'Closed Won'));
            response.put('opportunitySession', opp.Online_Stripe_Session__c);
            response.put('total', opp.Amount);
            response.put('Id', opp.Id);
            return JSON.serialize(response);
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            throw newAuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String getProductsCountOpportunity(String oppid) {
        try {
            if (String.isNotBlank(oppid)) {
                Map<String, Object> response = new Map<String, Object>();
                Opportunity opp = [SELECT Id, Online_Store_Status__c FROM Opportunity WHERE UUID__c = :oppid];
                List<OpportunityLineItem> olis = [
                        SELECT
                                Id,
                                Quantity,
                                Product2.Family,
                                Product2.Requires_scheduling__c,
                                Product2.Store_Categories__c,
                                Opportunity.Online_Store_Status__c

                        FROM OpportunityLineItem
                        WHERE Opportunity.UUID__c = :oppid
                ];

                Integer covidTests = 0;
                Integer products = 0;
                Integer discounts = 0;
                Integer appointments = 0;

                for (OpportunityLineItem oli : olis) {
                    if ((oli.Product2.Family == 'COVID Tests') && oli.Product2.Requires_scheduling__c) covidTests++;
                    else if (oli.Product2.Family == 'Discount') discounts++;
                    else if ((oli.Product2.Store_Categories__c != null) && (oli.Product2.Store_Categories__c.indexOf('Products') >= 0)) products = products + (Integer) oli.Quantity;
                    else if ((oli.Product2.Store_Categories__c != null) && (oli.Product2.Store_Categories__c.indexOf('Appointments') >= 0)) appointments++;
                }

                response.put('covidTests', covidTests);
                response.put('products', products);
                response.put('discounts', discounts);
                response.put('appointments', appointments);
                response.put('status', opp.Online_Store_Status__c);

                return JSON.serialize(response);
            }
            return null;

        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            throw newAuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String getAvailableSlots(String covidTestId, String serviceCenterId, Date slotDate) {
        try {
            COVID_Test__c covidTest = [SELECT Id, Work_Type_Group__c, Patient__c FROM COVID_Test__c WHERE Id = :covidTestId];

            return getAvailableSlotsByWorkTypeGroup(covidTest.Work_Type_Group__c, serviceCenterId, slotDate);
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            //todo hide message from user
            throw newAuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static String getAvailableSlotsByWorkTypeGroup(String workTypeGroupId, String serviceCenterId, Date slotDate) {
        try {

            //            OnlineStoreSettings__c storeSettings = OnlineStoreSettings__c.getInstance();
            //            Login.LoginResponse loginResponse = Login.login(storeSettings.Username__c, storeSettings.Password__c, storeSettings.Login_URL__c);
            //
            //            System.debug('loginResponse:' + loginResponse);
            //
            //            //get ge0coded postal key
            //            SchedulerAPI.AvailableTerritorySlotsRequest territorySlotsRequest = new SchedulerAPI.AvailableTerritorySlotsRequest();
            //            territorySlotsRequest.startTime = Datetime.newInstance(slotDate, Time.newInstance(0, 0, 0, 0));
            //            territorySlotsRequest.endTime = Datetime.newInstance(slotDate, Time.newInstance(23, 59, 59, 999));
            //            territorySlotsRequest.requiredResourceIds = null;
            //            territorySlotsRequest.workTypeGroupId = workTypeGroupId;
            //            territorySlotsRequest.territoryIds.add(serviceCenterId);
            //            WorkTypeGroup wtg = [SELECT Id, Scheduling_Policy__c FROM WorkTypeGroup WHERE Id = :workTypeGroupId LIMIT 1];
            //            territorySlotsRequest.schedulingPolicyId = schedulerPolicyNameIdMap().get(wtg?.Scheduling_Policy__c);
            //
            //            SchedulerAPI scheduler = new SchedulerAPI(loginResponse.salesforceUrl);
            //            SchedulerAPI.AvailableTerritorySlotsOutput availableSlots = scheduler.getAvailableTerritorySlots(loginResponse.sessionId, territorySlotsRequest);
            //            System.debug('availableSlots:' + availableSlots);
            //
            //            //filter by diary block
            //            if (availableSlots?.result?.territorySlots[0]?.slots!=null) availableSlots.result.territorySlots[0].slots = filterSlotsByDiaryBlock(slotDate, serviceCenterId, availableSlots.result.territorySlots[0].slots);
            //
            //            System.debug('availableSlots after diary blocks:' + availableSlots);
            //
            //            return JSON.serializePretty(availableSlots.result.territorySlots[0]?.slots, false);

            Id workTypeId = [SELECT Id, WorkTypeGroupId, WorkTypeId FROM WorkTypeGroupMember WHERE WorkTypeGroupId = :workTypeGroupId LIMIT 1].WorkTypeId;
            List<String> sids = new List<String>();
            sids.add(serviceCenterId);
            OnlBookDomain.ExtendedTimeSlotsResponse resp = OnlSembleAvailability.getAvailability(workTypeId, sids, null, slotDate, slotDate.addDays(1));

            if (resp?.territorySlots != null) {
                return JSON.serializePretty(resp?.territorySlots, false);
            }
            else {
                return '[]';
            }
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            //todo hide message from user
            throw newAuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String getAvailableSlotsByWorkTypeGroupAtMultipleLocations(String workTypeGroupId, List<String> serviceCenterIds, Date slotDate) {
        try {

            //            OnlineStoreSettings__c storeSettings = OnlineStoreSettings__c.getInstance();
            //            Login.LoginResponse loginResponse = Login.login(storeSettings.Username__c, storeSettings.Password__c, storeSettings.Login_URL__c);
            //
            //            System.debug('loginResponse:' + loginResponse);
            //
            //            //get ge0coded postal key
            //            SchedulerAPI.AvailableTerritorySlotsRequest territorySlotsRequest = new SchedulerAPI.AvailableTerritorySlotsRequest();
            //            territorySlotsRequest.startTime = Datetime.newInstance(slotDate, Time.newInstance(0, 0, 0, 0));
            //            territorySlotsRequest.endTime = Datetime.newInstance(slotDate, Time.newInstance(23, 59, 59, 999));
            //            territorySlotsRequest.requiredResourceIds = null;
            //            territorySlotsRequest.workTypeGroupId = workTypeGroupId;
            //            territorySlotsRequest.territoryIds.addAll(serviceCenterIds);
            //            WorkTypeGroup wtg = [SELECT Id, Scheduling_Policy__c FROM WorkTypeGroup WHERE Id = :workTypeGroupId LIMIT 1];
            //            territorySlotsRequest.schedulingPolicyId = schedulerPolicyNameIdMap().get(wtg?.Scheduling_Policy__c);
            //
            //            SchedulerAPI scheduler = new SchedulerAPI(loginResponse.salesforceUrl);
            //            SchedulerAPI.AvailableTerritorySlotsOutput availableSlots = scheduler.getAvailableTerritorySlots(loginResponse.sessionId, territorySlotsRequest);
            //            System.debug('::getAvailableSlotsByWorkTypeGroupAtMultipleLocations:availableSlots:' + JSON.serializePretty(availableSlots));
            //
            //            if (availableSlots != null && availableSlots.result != null && availableSlots.result.territorySlots != null) {
            //                for (SchedulerAPI.AvailableTerritorySlots ts : availableSlots.result.territorySlots) {
            //                    ts.slots = filterSlotsByDiaryBlock(slotDate, ts.territoryId, ts.slots);
            //                }
            //                System.debug('::getAvailableSlotsByWorkTypeGroupAtMultipleLocations:availableSlots after diary blocks:' + JSON.serializePretty(availableSlots));
            //
            //                List<ExtendedTerritorySlot> ret = new List<ExtendedTerritorySlot>();
            //
            //                ExtendedTerritorySlot found = null;
            //                for (SchedulerAPI.AvailableTerritorySlots atslot : availableSlots.result.territorySlots) {
            //                    for (SchedulerAPI.TerritorySlot ts : atslot.slots) {
            //
            //                        //find if it already exists in the ret list
            //                        found = null;
            //                        for (ExtendedTerritorySlot extendedTerritorySlot : ret) {
            //                            if (extendedTerritorySlot.startTime == ts.startTime) {
            //                                found = extendedTerritorySlot;
            //                                break;
            //                            }
            //                        }
            //
            //                        if (found == null) {
            //                            ret.add(new ExtendedTerritorySlot(atslot.territoryId, ts));
            //                        }
            //                        else {
            //                            found.appendTerritorySlot(atslot.territoryId, ts);
            //                        }
            //                    }
            //                }
            //

            Id workTypeId = [SELECT Id, WorkTypeGroupId, WorkTypeId FROM WorkTypeGroupMember WHERE WorkTypeGroupId = :workTypeGroupId LIMIT 1].WorkTypeId;
            OnlBookDomain.ExtendedTimeSlotsResponse resp = OnlSembleAvailability.getAvailability(workTypeId, serviceCenterIds, null, slotDate, slotDate.addDays(1));

            if (resp?.territorySlots != null) {
                return JSON.serializePretty(resp?.territorySlots, false);
            }
            else {
                return '[]';
            }

        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            //todo hide message from user
            throw newAuraHandledException(e.getMessage());
        }
    }


//    public static List<SchedulerAPI.TerritorySlot> filterSlotsByDiaryBlock(Date slotDate, String serviceCenterId, List<SchedulerAPI.TerritorySlot> territorySlots) {
//        if (territorySlots == null) return null;
//
//        Datetime day_after = Datetime.newInstance(slotDate.addDays(1), Time.newInstance(0, 0, 0, 0));
//        Datetime day_start = Datetime.newInstance(slotDate, Time.newInstance(0, 0, 0, 0));
//
//        return filterSlotsByDiaryBlockDateRange(day_start, day_after, serviceCenterId, territorySlots);
//    }


    @AuraEnabled
    public static Boolean scheduleAppointment(String covidTestId, String serviceCenterId, String startTime, String endTime, String selectedResourceId) {
        try {
            COVID_Test__c covidTest = [
                    SELECT
                            Id,
                            Work_Type_Group__c,
                            Patient__c,
                            Provided_Email__c,
                            Provided_First_Name__c,
                            Provided_Last_Name__c,
                            Provided_Phone_Number__c,
                            Provided_Mobile_Phone__c,
                            Allows_Scheduling__c,
                            Scheduled_Appointment__c,
                            Opportunity__c,
                            Opportunity_Product__c,
                            Opportunity__r.Send_Confirmation_Email__c
                    FROM COVID_Test__c
                    WHERE Id = :covidTestId
            ];

            if (!covidTest.Allows_Scheduling__c) {
                return false;
            }

            String workTypeGroupId = covidTest.Work_Type_Group__c;

            //get ge0coded postal key
            List<ServiceTerritoryWorkType> territoryWorkTypes = [SELECT Id, WorkTypeId FROM ServiceTerritoryWorkType WHERE ServiceTerritoryId = :serviceCenterId];
            Set<Id> workTypeIds = new Set<Id>();
            for (ServiceTerritoryWorkType serviceTerritoryWorkType : territoryWorkTypes) {
                workTypeIds.add(serviceTerritoryWorkType.WorkTypeId);
            }

            WorkTypeGroupMember groupMember = [SELECT Id, WorkTypeId FROM WorkTypeGroupMember WHERE WorkTypeGroupId = :workTypeGroupId AND WorkTypeId IN :workTypeIds LIMIT 1];

            ServiceAppointment newServiceAppointment = new ServiceAppointment();
            newServiceAppointment.ParentRecordId = OnlineStoreSettingsManager.getDefaultAccount();
            newServiceAppointment.WorkTypeId = groupMember.WorkTypeId;
            newServiceAppointment.ServiceTerritoryId = serviceCenterId;
            newServiceAppointment.SchedStartTime = datetimeParse(startTime);
            newServiceAppointment.SchedEndTime = datetimeParse(endTime);

            insert newServiceAppointment;

            AssignedResource assignedResource = new AssignedResource();
            //assignedResource.isPrimaryResource = true;
            assignedResource.IsRequiredResource = true;
            assignedResource.ServiceResourceId = selectedResourceId;
            assignedResource.ServiceAppointmentId = newServiceAppointment.Id;

            insert assignedResource;

            String appointmentId = newServiceAppointment.Id;
            String oldAppointmentId = covidTest.Scheduled_Appointment__c;
            covidTest.Scheduled_Appointment__c = appointmentId;
            update covidTest;
            if (oldAppointmentId != null) {
                delete new ServiceAppointment(Id = oldAppointmentId);
                //if (!covidTest.Opportunity__r.Send_Confirmation_Email__c) {
                AnthologyTriggerDispatch.noTriggers = true;
                update new Opportunity(Id = covidTest.Opportunity__c, Send_Confirmation_Email__c = false);
                update new Opportunity(Id = covidTest.Opportunity__c, Send_Confirmation_Email__c = true);
                AnthologyTriggerDispatch.noTriggers = false;
                //}
            }

            //update new appointment treatment lookup
            ServiceAppointment newApp = new ServiceAppointment(Id = appointmentId);
            newApp.Treatment__c = covidTest.Opportunity__c;
            newApp.Opportunity_Product__c = covidTest.Opportunity_Product__c;

            update newApp;

            return true;
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            throw newAuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String getLocationsDefaultTest(String postalcode, String radius, String defaultCovidTestId) {
        try {
            SearchTestCenterResponse response = new SearchTestCenterResponse(OnlineStoreSettingsManager.getDayQueried());
            Default_COVID_Test__c defaultCOVIDTest = [SELECT Id, Work_Type_Group__c FROM Default_COVID_Test__c WHERE Id = :defaultCovidTestId];
            //read settings and log in
            OnlineStoreSettings__c storeSettings = OnlineStoreSettingsManager.getStoreSettings();
            Login.LoginResponse loginResponse = Login.login(storeSettings.Username__c, storeSettings.Password__c, storeSettings.Login_URL__c);
            Location loc = GeoCodeAPI.getGeocode('UK ' + postalcode);
            //create a request to get the service territories
            SchedulerAPI.GetServiceTerritoriesRequest serviceTerritoriesRequest = new SchedulerAPI.GetServiceTerritoriesRequest(
                    //get the workTypeGroup from available products, the products should all point to the same work type group id
                    defaultCOVIDTest.Work_Type_Group__c,
                    //get ge0coded postal key
                    loc,
                    radius
            );
            SchedulerAPI scheduler = new SchedulerAPI(loginResponse.salesforceUrl);

            SchedulerAPI.ServiceTerritoriesOutput testCenters = scheduler.getServiceTerritories(loginResponse.sessionId, serviceTerritoriesRequest);

            Set<String> testCentersWithoutDates = new Set<String>();
            for (SchedulerAPI.ServiceTerritoriesResult testCenter : testCenters.result.serviceTerritories) {
                testCentersWithoutDates.add(testCenter.id);
            }

            SchedulerAPI.AvailableTerritorySlotsRequest territorySlotsRequest = new SchedulerAPI.AvailableTerritorySlotsRequest();
            territorySlotsRequest.startTime = Datetime.now();
            territorySlotsRequest.requiredResourceIds = null;
            territorySlotsRequest.workTypeGroupId = defaultCOVIDTest.Work_Type_Group__c;

            Map<String, Datetime> testCenterAvailableDates = new Map<String, Datetime>();
            for (Integer increment : OnlineStoreSettingsManager.getEndDateList()) {
                territorySlotsRequest.territoryIds.clear();
                territorySlotsRequest.endTime = territorySlotsRequest.startTime.addDays(increment);
                territorySlotsRequest.territoryIds.addAll(testCentersWithoutDates);

                SchedulerAPI.AvailableTerritorySlotsOutput availableSlots = scheduler.getAvailableTerritorySlots(loginResponse.sessionId, territorySlotsRequest);
                for (SchedulerAPI.AvailableTerritorySlots availableTerritorySlot : availableSlots.result.territorySlots) {
                    if (!testCenterAvailableDates.containsKey(availableTerritorySlot.territoryId) && !availableTerritorySlot.slots.isEmpty()) {
                        testCenterAvailableDates.put(availableTerritorySlot.territoryId, availableTerritorySlot.slots[0].startTime);
                        testCentersWithoutDates.remove(availableTerritorySlot.territoryId);
                    }
                }
                if (testCentersWithoutDates.isEmpty()) break;
            }

            for (SchedulerAPI.ServiceTerritoriesResult testCenter : testCenters.result.serviceTerritories) {
                TestCenterInfo centerInfo;
                if (testCenterAvailableDates.containsKey(testCenter.id)) {
                    centerInfo = new TestCenterInfo(testCenter.name, testCenterAvailableDates.get(testCenter.id));
                }
                else {
                    centerInfo = new TestCenterInfo(testCenter.name);
                }
                System.Location centerLocation = Location.newInstance(testCenter.latitude, testCenter.longitude);
                Decimal distance = loc.getDistance(centerLocation, 'mi');
                centerInfo.distance = distance.round(RoundingMode.HALF_UP) + '';
                centerInfo.city = testCenter.city;
                centerInfo.street = testCenter.street;
                centerInfo.postalCode = testCenter.postalCode;
                centerInfo.id = testCenter.id;

                response.locations.add(centerInfo);
            }

            return JSON.serialize(response, true);
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            throw newAuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String getAvailableSlotsDefaultTest(String defaultId, String serviceCenterId, Date slotDate) {
        Default_COVID_Test__c covidTest = [SELECT Id, Work_Type_Group__c, Work_Type_Group__r.Scheduling_Policy__c FROM Default_COVID_Test__c WHERE Id = :defaultId];

        //read settings and log in
        //            OnlineStoreSettings__c storeSettings = OnlineStoreSettings__c.getInstance();
        //            Login.LoginResponse loginResponse = Login.login(storeSettings.Username__c, storeSettings.Password__c, storeSettings.Login_URL__c);
        //
        //            //get ge0coded postal key
        //            String workTypeGroupId = covidTest.Work_Type_Group__c;
        //
        //            SchedulerAPI.AvailableTerritorySlotsRequest territorySlotsRequest = new SchedulerAPI.AvailableTerritorySlotsRequest();
        //            territorySlotsRequest.startTime = Datetime.newInstance(slotDate, Time.newInstance(0, 0, 0, 0));
        //            territorySlotsRequest.endTime = Datetime.newInstance(slotDate, Time.newInstance(23, 59, 59, 999));
        //            territorySlotsRequest.requiredResourceIds = null;
        //            territorySlotsRequest.workTypeGroupId = workTypeGroupId;
        //            territorySlotsRequest.territoryIds.add(serviceCenterId);
        //            territorySlotsRequest.schedulingPolicyId = schedulerPolicyNameIdMap().get(covidTest?.Work_Type_Group__r?.Scheduling_Policy__c);
        //
        //            SchedulerAPI scheduler = new SchedulerAPI(loginResponse.salesforceUrl);
        //            SchedulerAPI.AvailableTerritorySlotsOutput availableSlots = scheduler.getAvailableTerritorySlots(loginResponse.sessionId, territorySlotsRequest);
        //
        //            if (availableSlots?.result?.territorySlots[0]?.slots != null) availableSlots.result.territorySlots[0].slots = filterSlotsByDiaryBlock(slotDate, serviceCenterId, availableSlots.result.territorySlots[0]?.slots);
        //
        //            return JSON.serializePretty(availableSlots.result.territorySlots[0]?.slots, false);

        return getAvailableSlotsByWorkTypeGroup(covidTest.Work_Type_Group__c, serviceCenterId, slotDate);

    }

    @AuraEnabled public static String scheduleAppointmentAndAddToBasket(String params) {
        try {
            ScheduleAppointment scheduleAppointment = (ScheduleAppointment) JSON.deserialize(params, ScheduleAppointment.class);
            Opportunity opp = new Opportunity();
            Account acc;


            String workTypeGroupId = null;

            if (scheduleAppointment.defaultCovidTestId != null) {
                workTypeGroupId = [
                        SELECT
                                Id,
                                Work_Type_Group__c
                        FROM Default_COVID_Test__c
                        WHERE Id = :scheduleAppointment.defaultCovidTestId
                ].Work_Type_Group__c;
            }

            //get ge0coded postal key
            List<ServiceTerritoryWorkType> territoryWorkTypes = [SELECT Id, WorkTypeId FROM ServiceTerritoryWorkType WHERE ServiceTerritoryId = :scheduleAppointment.serviceCenterId];
            Set<Id> workTypeIds = new Set<Id>();
            for (ServiceTerritoryWorkType serviceTerritoryWorkType : territoryWorkTypes) {
                workTypeIds.add(serviceTerritoryWorkType.WorkTypeId);
            }

            WorkTypeGroupMember groupMember = [SELECT Id, WorkTypeId FROM WorkTypeGroupMember WHERE WorkTypeGroupId = :workTypeGroupId AND WorkTypeId IN :workTypeIds LIMIT 1];


            ServiceAppointment newServiceAppointment = new ServiceAppointment();
            newServiceAppointment.ParentRecordId = OnlineStoreSettingsManager.getDefaultAccount();
            newServiceAppointment.WorkTypeId = groupMember.WorkTypeId;
            newServiceAppointment.ServiceTerritoryId = scheduleAppointment.serviceCenterId;
            newServiceAppointment.SchedStartTime = datetimeParse(scheduleAppointment.startTime);
            newServiceAppointment.SchedEndTime = datetimeParse(scheduleAppointment.endTime);

            insert newServiceAppointment;

            AssignedResource assignedResource = new AssignedResource();
            //assignedResource.isPrimaryResource = true;
            assignedResource.IsRequiredResource = true;
            assignedResource.ServiceResourceId = scheduleAppointment.resourceId;
            assignedResource.ServiceAppointmentId = newServiceAppointment.Id;

            insert assignedResource;

            if (String.isBlank(scheduleAppointment.basketId)) {
                acc = new Account(Id = OnlineStoreSettingsManager.getDefaultAccount());
                Uuid newUuid = new Uuid();
                opp.AccountId = acc.Id;
                opp.Call_Back__c = 'Not a call back'; //21-11-03 added default value
                opp.Name = 'Online Order ' + scheduleAppointment.personalDetails.firstName + ' ' + scheduleAppointment.personalDetails.lastName + ' (' + (Datetime.now() + '').left(10) + ')';
                opp.LeadSource = 'Did Not Obtain';
                opp.CloseDate = Date.today();
                opp.StageName = 'Qualification';
                opp.Site__c = 'None specified';
                opp.Business_Unit__c = STORE_BUSINESS_UNIT;
                opp.Mode__c = 'Online Booking';
                opp.Date_Appointment_Made__c = Date.today();
                opp.Appointment_Date__c = Date.today();
                opp.Online_First_Name__c = scheduleAppointment.personalDetails.firstName;
                opp.Online_Last_Name__c = scheduleAppointment.personalDetails.lastName;
                opp.Online_Email__c = scheduleAppointment.personalDetails.email;
                opp.Online_Phone__c = scheduleAppointment.personalDetails.phone;
                opp.Online_Mobile__c = scheduleAppointment.personalDetails.phone;
                opp.Online_Store_Status__c = 'Draft';
                opp.Send_Confirmation_Email__c = true;
                opp.UUID__c = newUuid.getValue();
                opp.Online_Store__c = scheduleAppointment.store;
                if (StoreConfigMetadataManager.getOnlineStoreConfig(scheduleAppointment.store) != null) {
                    opp.Store_Site_URL__c = StoreConfigMetadataManager.getOnlineStoreConfig(scheduleAppointment.store).Store_Site_URL__c;
                }
                insert opp;
            }
            else {
                opp = [SELECT Id, UUID__c, AccountId FROM Opportunity WHERE UUID__c = :scheduleAppointment.basketId];
                acc = new Account(Id = opp.AccountId);
            }


            List<Product2> products = [
                    SELECT Id,
                            Non_Membership_Price__c,
                            Requires_scheduling__c,
                            Requires_delivery__c,
                            Product_Sub_Family__c,
                            Store_Categories__c,
                            Family, (
                            SELECT COVID_Test_Type__c,
                                    Name,
                                    Number_of_Tests__c,
                                    Sort_Order__c,
                                    Product__c,
                                    Turnaround_Time__c,
                                    Work_Type_Group__c,
                                    First_Available__c
                            FROM Product2.Default_COVID_Tests__r
                    ), (
                            SELECT Id
                            FROM PricebookEntries
                            WHERE Pricebook2.IsStandard = TRUE AND IsActive = TRUE
                            LIMIT 1
                    )

                    FROM Product2
                    WHERE Id = :scheduleAppointment.productId
            ];
            Map<Id, List<OpportunityLineItem>> productsWithOLIs = new Map<Id, List<OpportunityLineItem>>();
            List<OpportunityLineItem> olis = new List<OpportunityLineItem>();


            Decimal discountAmount = 0;
            for (Product2 product : products) {
                //only on now
                productsWithOLIs.put(product.Id, new List<OpportunityLineItem>());
                for (Integer i = 0; i < scheduleAppointment.quantity; i++) {
                    OpportunityLineItem oli = new OpportunityLineItem();
                    System.debug(LoggingLevel.ERROR, 'scheduleAppointmentAndAddToBasket - product.PricebookEntries: ' + product.PricebookEntries);
                    oli.OpportunityId = opp.Id;
                    oli.PricebookEntryId = product.PricebookEntries[0].Id;
                    oli.Product2Id = product.Id;
                    oli.UnitPrice = product.Non_Membership_Price__c;
                    oli.Quantity = 1;
                    olis.add(oli);

                    productsWithOLIs.get(product.Id).add(oli);
                }
            }
            System.debug(LoggingLevel.FINE, 'createOrder - discountAmount: ' + discountAmount);

            insert olis;


            ServiceAppointment sa = new ServiceAppointment(Id = newServiceAppointment.Id);
            sa.Treatment__c = opp.Id;
            //            sa.Provided_Email__c = scheduleAppointment.personalDetails.email;
            //            sa.Provided_First_Name__c = scheduleAppointment.personalDetails.firstName;
            //            sa.Provided_Last_Name__c = scheduleAppointment.personalDetails.lastName;
            //            sa.Provided_Phone_Number__c = scheduleAppointment.personalDetails.phone;
            //            sa.Provided_Mobile_Phone__c = scheduleAppointment.personalDetails.phone;
            //if this was called fro adding an appointment, link the service appointment to the opp line item
            //2022-18-02 decided to write this for all SAs // DEPRECATED: if (scheduleAppointment.defaultAppointmentId != null) sa.Opportunity_Product__c = olis[0].Id;


            //link covid_test to opp line item
            if (scheduleAppointment.defaultCovidTestId != null) {
                List<COVID_Test__c> testsToInsert = new List<COVID_Test__c>();
                Integer numTests = 1;
                for (Product2 product : products) {
                    if (product.Requires_scheduling__c) {
                        Boolean appointmentAdded = false;
                        for (OpportunityLineItem oli : productsWithOLIs.get(product.Id)) {
                            for (Default_COVID_Test__c defaultTest : product.Default_COVID_Tests__r) {
                                numTests = 1;
                                if (defaultTest.Number_of_Tests__c != null) numTests = (Integer) defaultTest.Number_of_Tests__c;
                                for (Integer i = 0; i < numTests; i++) {

                                    COVID_Test__c covidTest = new COVID_Test__c();
                                    covidTest.Turnaround_Time_Global__c = defaultTest.Turnaround_Time__c;
                                    covidTest.Test_Type__c = defaultTest.COVID_Test_Type__c;
                                    covidTest.Work_Type_Group__c = defaultTest.Work_Type_Group__c;
                                    covidTest.Sort_Order__c = defaultTest.Sort_Order__c == null ? 1 : defaultTest.Sort_Order__c;
                                    covidTest.Reservation_Date_Time__c = Datetime.now().addMinutes(OnlineStoreSettingsManager.getCancellationWindow());
                                    covidTest.Patient__c = acc.Id;
                                    covidTest.Opportunity__c = opp.Id;
                                    covidTest.Opportunity_Product__c = oli.Id;
                                    covidTest.Provided_Email__c = scheduleAppointment.personalDetails.email;
                                    covidTest.Provided_First_Name__c = scheduleAppointment.personalDetails.firstName;
                                    covidTest.Provided_Last_Name__c = scheduleAppointment.personalDetails.lastName;
                                    covidTest.Provided_Phone_Number__c = scheduleAppointment.personalDetails.phone;
                                    covidTest.Provided_Mobile_Phone__c = scheduleAppointment.personalDetails.phone;

                                    // IF only here for MHC-208
                                    if (defaultTest.Id == scheduleAppointment.defaultCovidTestId && !appointmentAdded) {
                                        covidTest.Scheduled_Appointment__c = newServiceAppointment.Id;
                                        //2022-18-02 decided to write this for all SAs
                                        sa.Opportunity_Product__c = oli.Id;
                                        appointmentAdded = true;
                                    }
                                    testsToInsert.add(covidTest);
                                }
                            }
                        }
                    }
                }
                if (!testsToInsert.isEmpty()) {
                    insert testsToInsert;
                }
            }

            update sa;


            AnthologyTriggerDispatch.noTriggers = true;
            calculateCouponForBasket(opp.UUID__c);
            return opp.UUID__c;


        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            throw newAuraHandledException(e.getMessage());
        }
    }

    public static Datetime datetimeParse(String dt)
    {
        if (dt==null) return null;
        return Datetime.newInstanceGmt(
                Integer.valueOf(dt.substring(0,4)),
                Integer.valueOf(dt.substring(5,7)),
                Integer.valueOf(dt.substring(8,10)),
                Integer.valueOf(dt.substring(11,13)),
                Integer.valueOf(dt.substring(14,16)),
                Integer.valueOf(dt.substring(17,19))
        );
    }

    @AuraEnabled public static String addToBasket(String params) {
        try {
            ScheduleAppointment scheduleAppointment = (ScheduleAppointment) JSON.deserialize(params, ScheduleAppointment.class);
            Opportunity opp = new Opportunity();
            Account acc;

            if (String.isBlank(scheduleAppointment.basketId)) {
                acc = new Account(Id = OnlineStoreSettingsManager.getDefaultAccount());
                Uuid newUuid = new Uuid();
                opp.AccountId = acc.Id;
                opp.Call_Back__c = 'Not a call back'; //21-11-03 added default value
                opp.Name = 'Online Order' ;
                opp.LeadSource = 'Did Not Obtain';
                opp.CloseDate = Date.today();
                opp.StageName = 'Qualification';
                opp.Site__c = 'None specified';
                opp.Business_Unit__c = STORE_BUSINESS_UNIT;
                opp.Mode__c = 'Online Booking';
                opp.Date_Appointment_Made__c = Date.today();
                opp.Appointment_Date__c = Date.today();
                opp.Online_Store_Status__c = 'Draft';
                opp.Send_Confirmation_Email__c = true;
                opp.UUID__c = newUuid.getValue();
                opp.Online_Store__c = scheduleAppointment.store;
                if (StoreConfigMetadataManager.getOnlineStoreConfig(scheduleAppointment.store) != null) {
                    opp.Store_Site_URL__c = StoreConfigMetadataManager.getOnlineStoreConfig(scheduleAppointment.store).Store_Site_URL__c;
                }
                insert opp;
            }
            else {
                opp = [SELECT Id, UUID__c, AccountId FROM Opportunity WHERE UUID__c = :scheduleAppointment.basketId];
                acc = new Account(Id = opp.AccountId);
            }

            List<Product2> products = [
                    SELECT Id,
                            Non_Membership_Price__c,
                            Requires_scheduling__c,
                            Is_Home_Test__c,
                            Product_Sub_Family__c,
                            Store_Categories__c,
                            Family, (
                            SELECT COVID_Test_Type__c,
                                    Name,
                                    Number_of_Tests__c,
                                    Sort_Order__c,
                                    Product__c,
                                    Turnaround_Time__c,
                                    Work_Type_Group__c,
                                    First_Available__c
                            FROM Product2.Default_COVID_Tests__r
                    ), (
                            SELECT Id
                            FROM PricebookEntries
                            WHERE Pricebook2.IsStandard = TRUE AND IsActive = TRUE
                            LIMIT 1
                    )

                    FROM Product2
                    WHERE Id = :scheduleAppointment.productId
            ];


            // get eventual current olis for this opportunity and their product2Is
            List<OpportunityLineItem> currentOlis = [
                    SELECT
                            Id,
                            Product2Id,
                            Quantity,
                            OpportunityId,
                            PricebookEntryId,
                            UnitPrice
                    FROM OpportunityLineItem
                    WHERE OpportunityId = :opp.Id AND Product2Id = :scheduleAppointment.productId
            ];

            Map<Id, List<OpportunityLineItem>> productsWithOLIs = new Map<Id, List<OpportunityLineItem>>();

            if (currentOlis.size() > 0) {
                currentOlis[0].Quantity += scheduleAppointment.quantity;
                update currentOlis;
                productsWithOLIs.put(scheduleAppointment.productId, currentOlis);
            }
            else {
                List<OpportunityLineItem> olis = new List<OpportunityLineItem>();

                // Decimal discountAmount = 0;
                for (Product2 product : products) {
                    //only on now
                    productsWithOLIs.put(product.Id, new List<OpportunityLineItem>());
                    for (Integer i = 0; i < 1; i++) {
                        //todo change and check
                        OpportunityLineItem oli = new OpportunityLineItem();
                        System.debug(LoggingLevel.ERROR, 'addToBasket - product.PricebookEntries: ' + product.PricebookEntries);
                        oli.OpportunityId = opp.Id;
                        oli.PricebookEntryId = product.PricebookEntries[0].Id;
                        oli.Product2Id = product.Id;
                        oli.UnitPrice = product.Non_Membership_Price__c;
                        oli.Quantity = scheduleAppointment.quantity;
                        olis.add(oli);

                        productsWithOLIs.get(product.Id).add(oli);
                    }
                }

                // System.debug(LoggingLevel.FINE, 'createOrder - discountAmount: ' + discountAmount);

                insert olis;
            }

            Integer numTests = 1;
            List<COVID_Test__c> testsToInsert = new List<COVID_Test__c>();
            for (Product2 product : products) {
                if (product.Is_Home_Test__c) {
                    for (OpportunityLineItem oli : productsWithOLIs.get(product.Id)) {
                        for (Default_COVID_Test__c defaultTest : product.Default_COVID_Tests__r) {
                            numTests = 1;
                            for (Integer i = 0; i < scheduleAppointment.quantity; i++) {
                                if (defaultTest.Number_of_Tests__c != null) numTests = (Integer) defaultTest.Number_of_Tests__c;
                                for (Integer j = 0; j < numTests; j++) {
                                    COVID_Test__c covidTest = new COVID_Test__c();
                                    // covidTest.Turnaround_Time_Global__c = defaultTest.Turnaround_Time__c;
                                    //                             covidTest.Work_Type_Group__c = defaultTest.Work_Type_Group__c;
                                    // covidTest.Reservation_Date_Time__c = Datetime.now().addMinutes(OnlineStoreSettingsManager.getCancellationWindow());
                                    covidTest.Test_Type__c = defaultTest.COVID_Test_Type__c;
                                    covidTest.Sort_Order__c = defaultTest.Sort_Order__c == null ? 1 : defaultTest.Sort_Order__c;
                                    covidTest.Patient__c = acc.Id;
                                    covidTest.Opportunity__c = opp.Id;
                                    covidTest.Opportunity_Product__c = oli.Id;
                                    testsToInsert.add(covidTest);
                                }
                            }
                        }
                    }
                }
            }

            if (!testsToInsert.isEmpty()) {
                insert testsToInsert;
            }
            AnthologyTriggerDispatch.noTriggers = true;
            calculateCouponForBasket(opp.UUID__c);
            //            opp.Send_Confirmation_Email__c = true;
            //            upsert opp UUID__c;
            return opp.UUID__c;

        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            throw newAuraHandledException(e.getMessage() + ' - ' + e.getStackTraceString());
        }
    }

    /**
     * Add a delivery option to basket
     *
     * @param params String JSON format
     *
     * @return String basketId
     */
    @AuraEnabled
    public static String addDeliveryToBasket(String params) {
        try {
            ScheduleAppointment request = (ScheduleAppointment) JSON.deserialize(params, ScheduleAppointment.class);
            Opportunity opp = new Opportunity();
            Account acc;

            if (String.isBlank(request.basketId)) {
                acc = new Account(Id = OnlineStoreSettingsManager.getDefaultAccount());
                Uuid newUuid = new Uuid();
                opp.AccountId = acc.Id;
                opp.Call_Back__c = 'Not a call back'; //21-11-03 added default value
                opp.Name = 'Online Order' ;
                opp.LeadSource = 'Did Not Obtain';
                opp.CloseDate = Date.today();
                opp.StageName = 'Qualification';
                opp.Site__c = 'None specified';
                opp.Business_Unit__c = STORE_BUSINESS_UNIT;
                opp.Mode__c = 'Online Booking';
                opp.Date_Appointment_Made__c = Date.today();
                opp.Appointment_Date__c = Date.today();
                opp.Online_Store_Status__c = 'Draft';
                opp.Send_Confirmation_Email__c = true;
                opp.UUID__c = newUuid.getValue();
                opp.Online_Store__c = request.store;
                if (StoreConfigMetadataManager.getOnlineStoreConfig(request.store) != null) {
                    opp.Store_Site_URL__c = StoreConfigMetadataManager.getOnlineStoreConfig(request.store).Store_Site_URL__c;
                }
                insert opp;
            }
            else {
                opp = [SELECT Id, UUID__c, AccountId, Click_and_Collect__c FROM Opportunity WHERE UUID__c = :request.basketId];
                acc = new Account(Id = opp.AccountId);
            }

            Product2 product = [
                    SELECT Id,
                            Non_Membership_Price__c,
                            Requires_scheduling__c,
                            Is_Home_Test__c,
                            Product_Sub_Family__c,
                            Store_Categories__c,
                            Family,
                            Delivery_Class__c,
                            Description,
                            Delivery_Product_Within_Days__c,
                            Delivery_Product_By_Hours__c, (
                            SELECT Id
                            FROM PricebookEntries
                            WHERE Pricebook2.IsStandard = TRUE AND IsActive = TRUE
                            LIMIT 1
                    )

                    FROM Product2
                    WHERE Id = :request.productId
            ];


            // get eventual current deliveries for this opportunity and their product2Is
            OpportunityLineItem currentDelivery = getCurrentDeliveryOli (opp.Id);

            if (currentDelivery != null) delete currentDelivery;

            OpportunityLineItem oli = new OpportunityLineItem();
            System.debug(LoggingLevel.ERROR, 'addDeliveryToBasket - product.PricebookEntries: ' + product.PricebookEntries);
            oli.OpportunityId = opp.Id;
            oli.PricebookEntryId = product.PricebookEntries[0].Id;
            oli.Product2Id = product.Id;
            oli.UnitPrice = product.Non_Membership_Price__c;
            oli.Quantity = request.quantity;
            oli.Description = product.Description;

            insert oli;

            opp.Delivery_Product__c = product.Id;
            opp.Click_and_Collect__c = (product.Delivery_Class__c == PRODUCT_DELIVERY_CLASS_CLICKCOLLECT);
            if (opp.Click_and_Collect__c == false) {
                opp.Pickup_Location__c = null;
            }

            AnthologyTriggerDispatch.noTriggers = true;

            calculateCouponForBasket(opp.UUID__c);
            update opp;
            calculateCouponForBasket(opp.UUID__c);
            return opp.UUID__c;

        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            throw newAuraHandledException(e.getMessage() + ' - ' + e.getStackTraceString());
        }
    }

    @TestVisible
    private static OpportunityLineItem getCurrentDeliveryOli(String oppid) {
        List<OpportunityLineItem> currentDeliveries = [
                SELECT
                        Id, Product2.Delivery_Class__c, Product2.Id
                FROM OpportunityLineItem
                WHERE OpportunityId = :oppId AND Product2.Is_Delivery_Option__c = TRUE
        ];

        if (currentDeliveries.size() > 0) return currentDeliveries[0];
        else return null;
    }

    /**
     * @param oppId Closes the order (called qfter stripe finished and called ?page=confirm
     *
     * @return
     */
    @AuraEnabled
    public static String closeOrder(String oppId) {
        try {
            Opportunity opp = [
                    SELECT
                            Id,
                            StageName
                    FROM Opportunity
                    WHERE UUID__c = :oppId
            ];

            opp.StageName = 'Closed Won';
            update opp;
            return oppId;
        }
        catch (Exception ex) {
            String ret = ex.getTypeName() + ',' + ex.getMessage() + ', ' + ex.getStackTraceString();
            if (ex.getCause() != null) {
                ret += ' /// ' + ex.getCause().getTypeName() + ',' + ex.getCause().getMessage() + ', ' + ex.getCause().getStackTraceString();
            }
            return ret;
        }
    }

    @AuraEnabled public static String confirmOrder(String basketParameters) {
        try {
            CreateOrderRequest orderRequest = (CreateOrderRequest) JSON.deserialize(basketParameters, CreateOrderRequest.class);
            if (!orderRequest.checkTerms) {
                CheckoutException checkoutEx = new CheckoutException();
                checkoutEx.setMessage('You must accept Terms and Conditions before creating an order');
            }

            List<String> emails = new List<String>();
            emails.add(orderRequest.personalDetails.email);
            if (orderRequest.shippingInformation != null) emails.add(orderRequest.shippingInformation.email);

            List<Patient_Block__c> blocked = [SELECT Id, Name FROM Patient_Block__c WHERE Blocked_Email__c IN :emails LIMIT 1];

            if (!blocked.isEmpty()) {
                throw newAuraHandledException(blocked[0].Name);
            }

            List<Account> accounts = [SELECT Id, Name, LastName, FirstName FROM Account WHERE PersonEmail = :orderRequest.personalDetails.email LIMIT 1];
            Account acc;
            if (accounts.isEmpty()) {
                acc = new Account();
                acc.RecordTypeId = Cache.recordTypeId(AccountManager.RT_PERSON_ACCOUNT);
                acc.FirstName = orderRequest.personalDetails.firstName;
                acc.LastName = orderRequest.personalDetails.lastName;
                acc.PersonEmail = orderRequest.personalDetails.email;
                acc.Phone = orderRequest.personalDetails.phone;
                acc.PersonMobilePhone = orderRequest.personalDetails.phone;
                acc.BillingCity = orderRequest.personalDetails.city;
                acc.BillingPostalCode = orderRequest.personalDetails.postalCode;

                if (orderRequest.shippingInformation != null) {
                    acc.ShippingCity = orderRequest.shippingInformation.city;
                    acc.ShippingStreet = orderRequest.shippingInformation.address1;
                    if (orderRequest.shippingInformation.address2 != null) acc.ShippingStreet += ', ' + orderRequest.shippingInformation.address2;
                    if (orderRequest.shippingInformation.address3 != null) acc.ShippingStreet += ', ' + orderRequest.shippingInformation.address3;
                    acc.ShippingPostalCode = orderRequest.shippingInformation.postalCode;
                    acc.ShippingCountry = orderRequest.shippingInformation.country;
                }

                insert acc;
            }
            else {
                acc = accounts[0];
            }
            Opportunity opp = [
                    SELECT Id,
                            Online_Stripe_Session__c,
                            Delivery_Product__c,
                            Click_and_Collect__c, (
                            SELECT Id,
                                    Product2.Name,
                                    TotalPrice,
                                    Product2Id
                            FROM OpportunityLineItems
                    )
                    FROM Opportunity
                    WHERE UUID__c = :orderRequest.oppid
            ];

            //List<COVID_Test__c> covidTests = [SELECT Id, Patient__c, Scheduled_Appointment__c FROM COVID_Test__c WHERE Opportunity_Product__c IN :opp.OpportunityLineItems AND Scheduled_Appointment__c != NULL];

            opp.AccountId = acc.Id;
            opp.Name = 'Online Order ' + acc.FirstName + ' ' + acc.LastName + ' (' + (Datetime.now() + '').left(10) + ')';


            opp.Online_First_Name__c = orderRequest.personalDetails.firstName;
            opp.Online_Last_Name__c = orderRequest.personalDetails.lastName;
            opp.Online_Email__c = orderRequest.personalDetails.email;
            opp.Online_Phone__c = orderRequest.personalDetails.phone;
            opp.Online_Mobile__c = orderRequest.personalDetails.phone;
            opp.Online_Billing_Address_Line_1__c = orderRequest.personalDetails.address1;
            opp.Online_Billing_Address_Line_2__c = orderRequest.personalDetails.address2;
            opp.Online_Billing_Address_Line_3__c = orderRequest.personalDetails.address3;
            opp.Online_Billing_City__c = orderRequest.personalDetails.city;
            opp.Online_Billing_Postal_Code__c = orderRequest.personalDetails.postalCode;
            opp.Online_Billing_County__c = orderRequest.personalDetails.county;

            // by default set shipping to billing information, later overwrite if separate shipping info is available
            opp.Online_Shipping_First_Name__c = orderRequest.personalDetails.firstName;
            opp.Online_Shipping_Last_Name__c = orderRequest.personalDetails.lastName;
            opp.Online_Shipping_Email__c = orderRequest.personalDetails.email;
            opp.Online_Shipping_Phone__c = orderRequest.personalDetails.phone;
            opp.Online_Shipping_Address_Line_1__c = orderRequest.personalDetails.address1;
            opp.Online_Shipping_Address_Line_2__c = orderRequest.personalDetails.address2;
            opp.Online_Shipping_Address_Line_3__c = orderRequest.personalDetails.address3;
            opp.Online_Shipping_City__c = orderRequest.personalDetails.city;
            opp.Online_Shipping_Postcode__c = orderRequest.personalDetails.postalCode;
            opp.Online_Shipping_County__c = orderRequest.personalDetails.county;

            if (orderRequest.defaultLocation != null) {
                opp.Online_Post_Code__c = orderRequest.defaultLocation.postalcode;
                opp.Online_Radius__c = orderRequest.defaultLocation.distance;
            }
            opp.Online_Terms_Accepted__c = orderRequest.checkTerms;
            opp.Online_Marketing_Accepted__c = orderRequest.checkMarketing;
            //            opp.Share = orderRequest.checkShare;

            if (orderRequest.shippingInformation != null && orderRequest.shippingInformation.firstName != null) {
                opp.Online_Shipping_First_Name__c = orderRequest.shippingInformation.firstName;
                opp.Online_Shipping_Last_Name__c = orderRequest.shippingInformation.lastName;
                opp.Online_Shipping_Email__c = orderRequest.shippingInformation.email;
                opp.Online_Shipping_Phone__c = orderRequest.shippingInformation.phone;
                opp.Online_Shipping_Address_Line_1__c = orderRequest.shippingInformation.address1;
                opp.Online_Shipping_Address_Line_2__c = orderRequest.shippingInformation.address2;
                opp.Online_Shipping_Address_Line_3__c = orderRequest.shippingInformation.address3;
                opp.Online_Shipping_City__c = orderRequest.shippingInformation.city;
                opp.Online_Shipping_Postcode__c = orderRequest.shippingInformation.postalCode;
                opp.Online_Shipping_County__c = orderRequest.shippingInformation.county;
            }


            Boolean oppDeliveryRequired = false;
            List<OpportunityLineItem> olis = [SELECT Id, Product2.Requires_delivery__c FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
            for (OpportunityLineItem oli : olis) {
                if (oli.Product2.Requires_delivery__c) {
                    opp.Fulfillment_status__c = 'Awaiting Fulfillment';
                    oppDeliveryRequired = true;
                    break;
                }
            }

            //   transitional functions - handover to new delivery products
            //            if (oppDeliveryRequired) {
            //                if (opp.Delivery_Product__c == null) {
            //                    try {
            //                        if (orderRequest.checkClickAndCollect) {
            //                            String clickCollectId = [SELECT Id FROM Product2 WHERE Delivery_Class__c = :PRODUCT_DELIVERY_CLASS_CLICKCOLLECT LIMIT 1].Id;
            //                            opp.Delivery_Product__c = clickCollectId;
            //                            opp.Click_and_Collect__c = true;
            //                        }
            //                        else {
            //                            String defProductId = [SELECT Id FROM Product2 WHERE ProductCode = '1^32'].Id;
            //                            opp.Delivery_Product__c = defProductId;
            //                            opp.Click_and_Collect__c = false;
            //                        }
            //                    }
            //                    catch (Exception ignore) {
            //                    }
            //                }
            //
            //            }

            if (opp.Click_and_Collect__c) opp.Pickup_Location__c = orderRequest.clickCollectLocationId;

            update opp;


            Map<Id, ServiceAppointment> serviceAppointments = new Map<Id, ServiceAppointment>([
                    SELECT
                            ActualDuration,
                            ActualEndTime,
                            ActualStartTime,
                            AdditionalInformation,
                            Address,
                            AppointmentNumber,
                            AppointmentType,
                            ArrivalWindowEndTime,
                            ArrivalWindowStartTime,
                            CancellationReason,
                            City,
                            Comments,
                            ContactId,
                            Country,
                            Description,
                            DueDate,
                            Duration,
                            DurationInMinutes,
                            DurationType,
                            EarliestStartTime,
                            Email,
                            GeocodeAccuracy,
                            IsAnonymousBooking,
                            Latitude,
                            Longitude,
                            OwnerId,
                            Opportunity_Product__c,
                            ParentRecordId,
                            ParentRecordStatusCategory,
                            ParentRecordType,
                            Payment_Status__c,
                            Phone,
                            PostalCode,
                            SchedEndTime,
                            SchedStartTime,
                            ServiceNote,
                            ServiceTerritoryId,
                            State,
                            Status,
                            StatusCategory,
                            Street,
                            Subject,
                            Treatment__c,
                            WorkTypeId, (SELECT Id, ServiceResourceId FROM ServiceResources)
                    FROM ServiceAppointment
                    WHERE Treatment__c = :opp.Id
            ]);

            // list of scheduled covid tests on this opportunity
            List<COVID_Test__c> inClinicCovidTests = [SELECT Id, Patient__c, Scheduled_Appointment__c FROM COVID_Test__c WHERE Opportunity_Product__c IN :opp.OpportunityLineItems AND Is_Home_Kit_Test__c = FALSE];
            // list of home kit tests
            List<COVID_Test__c> homeKitTests = [SELECT Id, Patient__c FROM COVID_Test__c WHERE Opportunity_Product__c IN :opp.OpportunityLineItems AND Is_Home_Kit_Test__c = TRUE];

            // CLONE each appointment on this treatment
            List<ServiceAppointment> serviceAppointmentsToDelete = new List<ServiceAppointment>();
            Map<Id, ServiceAppointment> serviceAppointmentsToInsert = new Map<Id, ServiceAppointment>();
            Map<Id, List<AssignedResource>> assignedResourcesToInsert = new Map<Id, List<AssignedResource>>();

            for (ServiceAppointment sa : serviceAppointments.values()) {
                serviceAppointmentsToDelete.add(serviceAppointments.get(sa.Id));
                ServiceAppointment clonedServiceAppointment = serviceAppointments.get(sa.Id).clone(false);
                clonedServiceAppointment.ParentRecordId = acc.Id;
                System.debug('::confirm:serviceAppointmentsToInsert.put.Id:' + sa.Id);
                serviceAppointmentsToInsert.put(sa.Id, clonedServiceAppointment);
                assignedResourcesToInsert.put(sa.Id, new List<AssignedResource>());
                List<AssignedResource> oldResources = serviceAppointments.get(sa.Id).ServiceResources;
                for (AssignedResource resource : oldResources) {
                    AssignedResource assignedResource = new AssignedResource();
                    assignedResource.ServiceResourceId = resource.ServiceResourceId;
                    assignedResource.IsRequiredResource = true;
                    assignedResourcesToInsert.get(sa.Id).add(assignedResource);
                }
            }
            delete serviceAppointmentsToDelete;

            System.debug('::confirm:num of serviceAppointmentsToInsert.values to insert:' + serviceAppointmentsToInsert.values().size());
            insert serviceAppointmentsToInsert.values();

            System.debug('::confirm:inserted serviceAppointmentsToInsert.values:' + JSON.serialize(serviceAppointmentsToInsert.values()));

            List<AssignedResource> allResources = new List<AssignedResource>();
            for (String saId : serviceAppointments.keySet()) {
                List<AssignedResource> newResources = assignedResourcesToInsert.get(saId);
                allResources.addAll(newResources);
                for (AssignedResource resource : newResources) {
                    resource.ServiceAppointmentId = serviceAppointmentsToInsert.get(saId).Id;
                }
            }

            //update covid tests with newer appointment Ids
            List<COVID_Test__c> covidTestsToUpdate = new List<COVID_Test__c>();

            for (COVID_Test__c covidTest : inClinicCovidTests) {
                if (serviceAppointmentsToInsert.get(covidTest.Scheduled_Appointment__c) == null) {
                    System.debug(LoggingLevel.ERROR, '::confirm:missing serviceAppointmentsToInsert.get for covidTest.Scheduled_Appointment__c Id:' + covidTest.Scheduled_Appointment__c);
                }
                covidTestsToUpdate.add(new COVID_Test__c(
                        Id = covidTest.Id,
                        Scheduled_Appointment__c = serviceAppointmentsToInsert.get(covidTest.Scheduled_Appointment__c).Id,
                        Patient__c = acc.Id));
            }

            // fix to add patient (primary contact to non scheduled covid tests
            for (COVID_Test__c hkt : homeKitTests) {
                covidTestsToUpdate.add(new COVID_Test__c(
                        Id = hkt.Id,
                        Patient__c = acc.Id));
            }


            insert allResources;
            update covidTestsToUpdate;

            return orderRequest.oppid;
        }
        catch (AuraHandledException e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            throw e;
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            throw newAuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean updatePersonalInfo(List<String> covidTestIds, String firstName, String lastName, String email, String phone, String mobile) {
        try {
            List<COVID_Test__c> covidTests = [
                    SELECT
                            Id,
                            Work_Type_Group__c,
                            Patient__c,
                            Provided_Email__c,
                            Provided_First_Name__c,
                            Provided_Last_Name__c,
                            Provided_Phone_Number__c,
                            Provided_Mobile_Phone__c
                    FROM COVID_Test__c
                    WHERE Id IN :covidTestIds
            ];
            for (COVID_Test__c covidTest : covidTests) {
                covidTest.Provided_First_Name__c = String.isBlank(firstName) ? covidTest.Provided_First_Name__c : firstName;
                covidTest.Provided_Last_Name__c = String.isBlank(lastName) ? covidTest.Provided_Last_Name__c : lastName;
                covidTest.Provided_Email__c = String.isBlank(email) ? covidTest.Provided_Email__c : email;
                covidTest.Provided_Phone_Number__c = String.isBlank(phone) ? covidTest.Provided_Phone_Number__c : phone;
                covidTest.Provided_Mobile_Phone__c = String.isBlank(mobile) ? covidTest.Provided_Mobile_Phone__c : mobile;
            }

            update covidTests;

            return true;
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            throw newAuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String getStripePublicKey() {
        try {
            return OnlineStoreSettingsManager.getStoreSettings().Stripe_Public_Key__c;
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            throw newAuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String getStripeSession(String opportunityId) {
        try {

            Opportunity opp = [
                    SELECT Id,
                            Account.PersonEmail,
                            UUID__c,
                            AccountId,
                            Account.ContactId__c,
                            StageName,
                            Online_Stripe_Session__c,
                            IsWon, (
                            SELECT Id, Description, TotalPrice, UnitPrice, Quantity, Product2.Name, Product2.Description, Product2.Is_Discount__c, Product2.Is_Delivery_Option__c
                            FROM OpportunityLineItems
                            WHERE Product2.Is_Discount__c = FALSE OR (Product2.Is_Discount__c = TRUE AND TotalPrice > 0)
                    ), (
                            SELECT Id
                            FROM Discount_Code_Usages__r
                    )
                    FROM Opportunity
                    WHERE UUID__c = :opportunityId OR Id = :opportunityId
            ];

            StripeAPI stripe = new StripeAPI(
                    OnlineStoreSettingsManager.getStoreSettings().Stripe_URL__c,
                    'gbp',
                    OnlineStoreSettingsManager.getStoreSettings().Stripe_Payment_Method_Types__c);

            List<OpportunityLineItem> negativePriceOLIs = [
                    SELECT Id,
                            Description,
                            TotalPrice,
                            UnitPrice,
                            Quantity,
                            Product2.Name,
                            Product2.Description,
                            Product2.Is_Discount__c,
                            Product2.Is_Delivery_Option__c
                    FROM OpportunityLineItem
                    WHERE Opportunity.UUID__c = :opportunityId AND TotalPrice < 0
            ];

            OpportunityLineItem discountOli;
            OpportunityLineItem deliveryOli;

            for (OpportunityLineItem oli : negativePriceOLIs) {
                if (oli.Product2.Is_Discount__c) {
                    discountOli = oli;
                }
                else if (oli.Product2.Is_Delivery_Option__c) {
                    deliveryOli = oli;
                }
            }

            System.debug(LoggingLevel.ERROR, 'getStripeSession - discountOli: ' + discountOli);
            System.debug(LoggingLevel.ERROR, 'getStripeSession - deliveryOli: ' + deliveryOli);

            String deliveryCouponId = null;
            String discountCouponId = null;

            //if we have both the discount OLI and a delivery OLI, then we have to comine them
            if ((discountOli != null) && (deliveryOli != null)) {
                discountCouponId = stripe.createCoupon(
                        OnlineStoreSettingsManager.getStoreSettings().Stripe_Private_Key__c,
                        'Discounts', discountOli.TotalPrice + deliveryOli.TotalPrice
                );
            }
            else {
                if (discountOli != null) {
                    discountCouponId = stripe.createCoupon(
                            OnlineStoreSettingsManager.getStoreSettings().Stripe_Private_Key__c,
                            discountOli
                    );
                    System.debug(LoggingLevel.ERROR, 'getStripeSession - discountCouponId: ' + discountCouponId);
                }


                if (deliveryOli != null && deliveryOli.TotalPrice < 0) {
                    deliveryCouponId = stripe.createCoupon(
                            OnlineStoreSettingsManager.getStoreSettings().Stripe_Private_Key__c,
                            deliveryOli
                    );
                    System.debug(LoggingLevel.ERROR, 'getStripeSession - deliveryCouponId: ' + deliveryCouponId);
                }
            }

            opp.Online_Stripe_Session__c = stripe.createPaymentSession(
                    OnlineStoreSettingsManager.getStoreSettings().Stripe_Private_Key__c,
                    opp,
                    OnlineStoreSettingsManager.getStoreSettings().Stripe_Success_URL__c,
                    OnlineStoreSettingsManager.getStoreSettings().Stripe_Cancel_URL__c,
                    discountCouponId, deliveryCouponId);

            update opp;
            if (!opp.Discount_Code_Usages__r.isEmpty() && String.isNotBlank(discountCouponId)) {
                update new Discount_Code_Usage__c(
                        Id = opp.Discount_Code_Usages__r[0].Id,
                        Stripe_Coupon_Id__c = discountCouponId
                );
            }

            return opp.Online_Stripe_Session__c;
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            throw newAuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean checkStripeSessionPaid(String sessionId) {
        StripeAPI stripe = new StripeAPI(
                OnlineStoreSettingsManager.getStoreSettings().Stripe_URL__c,
                'gbp',
                OnlineStoreSettingsManager.getStoreSettings().Stripe_Payment_Method_Types__c);

        return stripe.getPaymentSessionPaid(sessionId);
    }

    @AuraEnabled public static String getBasket(String basketId) {
        try {
            Basket__c basket = [SELECT Id, Session_Id__c, Basket_JSON__c, Opportunity__c FROM Basket__c WHERE Session_Id__c = :basketId];
            if (String.isBlank(basket.Opportunity__c)) {
                return basket.Basket_JSON__c;
            }
            else {
                return null;
            }
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            throw newAuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled public static String saveBasket(String basketId, String basketJSON) {
        try {
            Basket__c newBasket = new Basket__c(Basket_JSON__c = basketJSON);
            if (String.isBlank(basketId)) {
                Uuid newUuid = new Uuid();
                newBasket.Session_Id__c = newUuid.getValue();
            }
            else {
                newBasket.Session_Id__c = basketId;
            }
            upsert newBasket Basket__c.Session_Id__c;
            return newBasket.Session_Id__c;
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            throw newAuraHandledException(e.getMessage());
        }
    }

    /**
     * Checks the validity of the coupon code
     *
     * @param couponCode code for the coupon to verify
     * @param store store for which to verify the coupon
     *
     * @return serialized Discount_Code__c or null if not found
     */
    @AuraEnabled public static String validateCoupon(String couponCode, String store) {
        try {
            List<Discount_Code__c> couponCodes = [SELECT Id, Name, Coupon_Code__c FROM Discount_Code__c WHERE Coupon_Code__c = :couponCode AND Active__c = TRUE AND Valid_for_Stores__c INCLUDES (:store)];
            if (couponCodes.isEmpty()) {
                return null;
            }
            else {
                return JSON.serialize(couponCodes[0]);
            }
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            //todo hide message from user
            throw newAuraHandledException(e.getMessage());
        }
    }

    /**
     * Checks the validity of the coupon code
     *
     * @param couponCode code for the coupon to verify
     * @param store store for which to verify the coupon
     * @param oppId store for which to verify the coupon
     *
     * @return serialized Discount_Code__c or null if not found
     */
    @AuraEnabled public static String validateCouponAndAddToBasket(String couponCode, String store, String oppId) {
        System.debug('validateCouponAndAddToBasket:couponCode=' + couponCode);
        try {
            Opportunity opp = new Opportunity();
            Account acc;
            if (String.isBlank(oppId)) {
                acc = new Account(Id = OnlineStoreSettingsManager.getDefaultAccount());
                Uuid newUuid = new Uuid();
                opp.Call_Back__c = 'Not a call back'; //21-11-03 added default value
                opp.AccountId = acc.Id;
                opp.Name = 'Online Order' ;
                opp.LeadSource = 'Did Not Obtain';
                opp.CloseDate = Date.today();
                opp.StageName = 'Qualification';
                opp.Site__c = 'None specified';
                opp.Business_Unit__c = STORE_BUSINESS_UNIT;
                opp.Mode__c = 'Online Booking';
                opp.Date_Appointment_Made__c = Date.today();
                opp.Appointment_Date__c = Date.today();
                opp.Online_Store_Status__c = 'Draft';
                opp.Send_Confirmation_Email__c = true;
                opp.UUID__c = newUuid.getValue();
                opp.Online_Store__c = store;
                if (StoreConfigMetadataManager.getOnlineStoreConfig(store) != null) {
                    opp.Store_Site_URL__c = StoreConfigMetadataManager.getOnlineStoreConfig(store).Store_Site_URL__c;
                }
                insert opp;
            }
            else {
                opp = [SELECT Id, UUID__c, AccountId FROM Opportunity WHERE UUID__c = :oppId];
                acc = new Account(Id = opp.AccountId);
            }

            List<Discount_Code__c> couponCodes = [SELECT Id, Name, Coupon_Code__c, Percentage_discount__c, Discount_Amount__c, Discount_Product__c FROM Discount_Code__c WHERE Coupon_Code__c = :couponCode AND Active__c = TRUE AND Valid_for_Stores__c INCLUDES (:store)];
            if (couponCodes.isEmpty()) {
                System.debug('validateCouponAndAddToBasket:returning null due to couponCodes empty');
                return null;
            }
            else {
                //List<OpportunityLineItem> olis = [SELECT Id, UnitPrice, Product2.Family, Product2.Id, Quantity, OpportunityId FROM OpportunityLineItem WHERE Opportunity.UUID__c = :oppId];
                PricebookEntry discountPriceBookEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id = :couponCodes[0].Discount_Product__c];

                //delete all previous discountOlis for the opportunity
                delete [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id AND Product2.Family = 'Discount'];

                OpportunityLineItem discountOLI = new OpportunityLineItem();
                discountOLI.OpportunityId = opp.Id;
                discountOLI.PricebookEntryId = discountPriceBookEntry.Id;
                discountOLI.Product2Id = couponCodes[0].Discount_Product__c;
                discountOLI.UnitPrice = 0;
                discountOLI.Quantity = 1;
                discountOLI.Description = couponCodes[0].Name;
                insert discountOLI;

                // delete all previous Discount_Code_Usage__c for this opp.Id
                delete [SELECT Id FROM Discount_Code_Usage__c WHERE Opportunity__c = :opp.Id];

                insert new Discount_Code_Usage__c(Discount_Code__c = couponCodes[0].Id, Opportunity__c = opp.Id);
                calculateCouponForBasket(oppId);
                return opp.UUID__c;
            }
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            throw newAuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled public static String calculateCouponForBasket(String oppUuId) {
        try {

            List<OpportunityLineItem> couponOLIs = [SELECT Id, UnitPrice, PricebookEntryId, Product2.Family, Product2.Id, Quantity, Opportunity.Online_Store__c FROM OpportunityLineItem WHERE Opportunity.UUID__c = :oppUuId AND Product2.Family = 'Discount'];
            if (couponOLIs.isEmpty()) return null;

            List<OpportunityLineItem> regularOLIs = [SELECT Id, UnitPrice, Product2.Family, Product2.Id, Quantity FROM OpportunityLineItem WHERE Opportunity.UUID__c = :oppUuId AND Product2.Family != 'Discount']; // AND Product2.Family = 'COVID Tests'];
            //if (regularOLIs.isEmpty()) return oppUuId;

            List<Discount_Code_Usage__c> discountCodeUsages = [SELECT Id, Discount_Code__c, Opportunity__c FROM Discount_Code_Usage__c WHERE Opportunity__r.UUID__c = :oppUuId];
            if (discountCodeUsages.isEmpty()) return oppUuId;

            List<Discount_Code__c> couponCodes = [SELECT Id, Apply_Discount_Amount_For_Each_Item__c, Name, Coupon_Code__c, Percentage_discount__c, Discount_Amount__c, Product__c, Product_Family__c FROM Discount_Code__c WHERE Id = :discountCodeUsages[0].Discount_Code__c];

            if (couponCodes.isEmpty()) {
                return oppUuId;
            }
            else {
                Discount_Code__c couponCode = couponCodes[0];
                Decimal discountAmount = 0;
                for (OpportunityLineItem oli : regularOLIs) {
                    if (!couponCodes.isEmpty() && doesDiscountApply(couponCode, oli.Product2)) {
                        if (couponCode.Percentage_discount__c != null) {
                            discountAmount += oli.UnitPrice * oli.Quantity * couponCode.Percentage_discount__c / 100;
                        }
                        else if (couponCode.Discount_Amount__c != null) {
                            if (couponCode.Apply_Discount_Amount_For_Each_Item__c) {
                                discountAmount += couponCode.Discount_Amount__c;
                            }
                            else {
                                discountAmount = couponCode.Discount_Amount__c;
                                break;
                            }
                        }
                    }
                }
                couponOLIs[0].UnitPrice = -discountAmount;
                couponOLIs[0].Quantity = 1;
                System.debug(LoggingLevel.ERROR, '::calculateCouponForBasket - discountAmount: ' + discountAmount);
                if (discountAmount == 0) {
                    //delete couponOLIs;
                }
                else {
                    update couponOLIs;
                }
                return oppUuId;
            }
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            throw newAuraHandledException(e.getMessage());
        }
    }

    /**
     * Checks the validity of the coupon code
     *
     * @param lineItemId OLI To delete
     *
     * @return serialized Discount_Code__c or null if not found
     */
    @AuraEnabled public static String removeProductFromOpportunity(String lineItemId) {
        try {
            OpportunityLineItem oliToRemove = [SELECT Id, Opportunity.UUID__c, Opportunity.Id, (SELECT Id, Scheduled_Appointment__r.Id FROM COVID_Tests__r), (SELECT Id FROM Appointments__r) FROM OpportunityLineItem WHERE Id = :lineItemId];
            String oppId = oliToRemove.Opportunity.UUID__c;
            List<ServiceAppointment> bookingsToDelete = new List<ServiceAppointment>();

            if (oliToRemove.COVID_Tests__r.isEmpty() && oliToRemove.Appointments__r.isEmpty()) {
                delete oliToRemove;
            }
            else if (!oliToRemove.COVID_Tests__r.isEmpty()) {
                for (COVID_Test__c covidTest : oliToRemove.COVID_Tests__r) {
                    if (covidTest.Scheduled_Appointment__r != null) {
                        bookingsToDelete.add(covidTest.Scheduled_Appointment__r);
                    }
                }
                delete bookingsToDelete;
                delete oliToRemove.COVID_Tests__r;
                delete oliToRemove;
            }
            else if (!oliToRemove.Appointments__r.isEmpty()) {
                for (ServiceAppointment sa : oliToRemove.Appointments__r) {
                    bookingsToDelete.add(sa);
                }
                delete bookingsToDelete;
                delete oliToRemove;
            }
            calculateCouponForBasket(oppId);
            return oppId;
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            throw newAuraHandledException(e.getMessage());
        }
    }

    public static Boolean doesDiscountApply(Discount_Code__c discountCode, Product2 product) {
        System.debug(LoggingLevel.ERROR, 'doesDiscountApply - pbe.Product2.Family: ' + product.Family);

        if (String.isBlank(discountCode.Product__c) && String.isBlank(discountCode.Product_Family__c)) {
            return true;
        }

        if (!String.isBlank(discountCode.Product__c)) {
            return discountCode.Product__c == product.Id;
        }

        if (!String.isBlank(discountCode.Product_Family__c)) {
            return discountCode.Product_Family__c == product.Family;
        }

        return false;
    }


    @AuraEnabled(Cacheable=true) public static String getServiceCenters() {
        try {
            return JSON.serialize([SELECT Id, Name, PostalCode, Street, City, Country FROM ServiceTerritory WHERE IsActive = TRUE ORDER BY Name ASC]);
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            throw newAuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(Cacheable=true) public static String getPickupLocations() {
        try {
            return JSON.serialize([SELECT Id, Name, PostalCode, Street, City, Country FROM ServiceTerritory WHERE IsActive = TRUE AND Available_for_Click_Collect__c = TRUE ORDER BY Name ASC]);
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            throw newAuraHandledException(e.getMessage());
        }
    }

    /**
     * See https://anthology.atlassian.net/browse/MHC-178
     * Can we add text above the button that says "Your booking will be held for N minutes. Please complete payment before this time otherwise your booking will be cancelled."
     * <p/>
     * The "N" minutes should be the number of minutes set in the system before the booking is cancelled (I think this is a custom setting) rounded down to the nearest 30 minutes, and then subtract 30 minutes.
     * <p/>
     * i.e. If the cancellation delay is 60 minutes, the text will say 30, if it's 64 minutes it will display 30, if it's 125 minutes it will display 90.
     *
     * @return Integer
     */
    @AuraEnabled(Cacheable=true) public static Integer getReservationHeldTime() {
        Decimal ret = OnlineStoreSettingsManager.getCancellationWindow();

        ret = (Math.floor(ret.longValue() / 30) * 30) - 30;

        if (ret < 0) ret = 0;

        return ret.intValue();
    }

    @AuraEnabled public static String getTestDetails(String testId) {
        try {
            return JSON.serialize(
            [
                    SELECT Id,
                            Turnaround_Time_Global__c,
                            Test_Type__c,
                            Scheduled_Appointment__r.ServiceTerritory.Name,
                            Scheduled_Appointment__r.ServiceTerritory.Address,
                            Provided_Email__c,
                            Provided_First_Name__c,
                            Provided_Last_Name__c,
                            Provided_Phone_Number__c,
                            Provided_Mobile_Phone__c,
                            Sort_Order__c,
                            Opportunity_Product__r.Opportunity.Online_Post_Code__c,
                            Opportunity_Product__r.Opportunity.Online_Radius__c,
                            Opportunity_Product__r.Opportunity.IsWon
                    FROM COVID_Test__c
                    WHERE Id = :testId
                    LIMIT 1
            ]
            );
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            throw newAuraHandledException(e.getMessage());
        }
    }

    public class CheckoutException extends Exception {
    }

    public class ValueLabelPair {
        public String value;
        public String label;

        public ValueLabelPair() {

        }

        public ValueLabelPair(String value) {
            this.value = value;
            this.label = value;
        }

    }
}