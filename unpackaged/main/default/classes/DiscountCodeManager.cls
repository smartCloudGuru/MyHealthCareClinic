/**
 * Created by Matija on 27.6.2023..
 */

public without sharing class DiscountCodeManager {

    private static Discount_Code__c p_referAFriendDiscountCode = null;
    public static Discount_Code__c referAFriendDiscountCode() {
        if (p_referAFriendDiscountCode == null) {
            List<ReferAFriend_Settings__mdt> customMetadata = [SELECT Id, RAF_Discount_Code__c FROM ReferAFriend_Settings__mdt LIMIT 1];
            if (!customMetadata.isEmpty()) {
                p_referAFriendDiscountCode = getDiscountCodeByCouponCode(customMetadata[0].RAF_Discount_Code__c);
            }
        }
        return p_referAFriendDiscountCode;
    }

    public static Boolean isRAFCode(String couponCode) {
        if (referAFriendDiscountCode() == null) return false;
        if (couponCode != null) couponCode = couponCode.toUpperCase();
        return (referAFriendDiscountCode().Coupon_Code__c == couponCode);
    }

    public static Id getReferrerAccountIdByRAFCode(String rafCode) {
        if (String.isEmpty(rafCode)) return null;

        rafCode = rafCode.toUpperCase();
        List<Account> accounts = [SELECT Id FROM Account WHERE ReferFriendCode__c = :rafCode LIMIT 1];

        if (accounts.isEmpty()) return null;
        return accounts[0].Id;
    }


    /**
     * This method validates the provided discount code against a variety of checks
     * to ensure that it is a valid discount code for the provided criteria.
     *
     * @param store The store where the discount code is being used. (optional)
     * @param couponCode The discount code that is being checked. (mandatory)
     * @param productId The Id of the product that the discount code is being applied on. (mandatory)
     * @param locationId The location Id where the discount code is being used.  (optional)
     * @param accountId The account Id for the user applying the discount. (optional)
     * @param startTime The start time when the discount is being applied. (optional)
     *
     * @return Discount_Code__c  A Discount_Code__c object if the code is valid for all provided criteria. Returns null if the code is invalid or criteria is not met.
     * Return null if the couponCode or productId is null
     *
     * The method conducts several validation checks including check for
     * - Valid discount code
     * - Store validity
     * - Max code usages
     * - Start time
     * - Product applicability
     * - Location applicability
     * - Account applicability
     * - Product Family
     */
    public static Discount_Code__c validateDiscountCode(String store, String couponCode, String productId, String locationId, String accountId, Datetime startTime) {
        if (couponCode == null) return null;
        if (productId == null) return null;

        // get productToBook
        List<Product2> products = [
                SELECT Id, Family, Work_Type_Group__r.Service_Type__c
                FROM Product2
                WHERE Id = :productId AND IsActive = TRUE
        ];
        if (products.isEmpty()) return null;

        Product2 productToBook = products[0];

        System.debug('::validateDiscountCode:product:' + productToBook);

        Discount_Code__c discountCode = null;
        if (getReferrerAccountIdByRAFCode(couponCode) != null) {
            System.debug('::validateDiscountCode:isRAFCode:true');
            discountCode = referAFriendDiscountCode();
        }
        else {
            discountCode = getDiscountCodeByCouponCode(couponCode);
        }

        System.debug('::validateDiscountCode:discountCode:' + discountCode?.Coupon_Code__c);

        // no such discount code found
        if (discountCode == null) return null;

        Boolean runningTest = Test.isRunningTest();


        // CHECK STORE VALIDITY
        if (!checkStore(discountCode, store)) {
            if (runningTest) System.debug('code ' + couponCode + ' failed validity for store ' + store);
            return null;
        }

        // CHECK MAX CODE USAGES
        if (!checkMaxUsages(discountCode)) {
            if (runningTest) System.debug('code ' + couponCode + ' failed max usages validity');
            return null;
        }

        // CHECK START TIME
        if (!checkStartTime(discountCode, startTime)) {
            if (runningTest) System.debug('code ' + couponCode + ' failed validity for startTime ' + startTime);
            return null;
        }

        // CHECK START DATE
        if (!checkStartDate(discountCode, startTime)) {
            if (runningTest) System.debug('code ' + couponCode + ' failed validity for startDate ' + startTime);
            return null;
        }

        // CHECK PRODUCT
        if (!checkProductApplicable(discountCode, productId)) {
            if (runningTest) System.debug('code ' + couponCode + ' failed validity for productId ' + productId);
            return null;
        }

        // CHECK LOCATION
        if (!checkLocationApplicable(discountCode, locationId)) {
            if (runningTest) System.debug('code ' + couponCode + ' failed validity for locationId ' + locationId);
            return null;
        }

        // CHECK ACCOUNT APPLICABLE
        if (!checkAccountApplicable(discountCode, accountId, productToBook)) {
            if (runningTest) System.debug('code ' + couponCode + ' failed validity for accountId ' + accountId);
            return null;
        }

        // CHECK PRODUCT FAMILY
        if (!checkProductFamily(discountCode, productToBook)) {
            if (runningTest) System.debug('code ' + couponCode + ' failed validity for Family ' + productToBook.Family);
            return null;
        }

        return discountCode;
    }

    @TestVisible
    private static Boolean checkStore(Discount_Code__c discountCode, String store) {
        if (String.isEmpty(store)) return true;

        //referafriend code is valid regardless of store
        if (isRAFCode(discountCode.Coupon_Code__c)) return true;

        if (discountCode.Valid_for_Stores__c == null) return false;

        return discountCode.Valid_for_Stores__c.contains(store);
    }

    @TestVisible
    private static Boolean checkMaxUsages(Discount_Code__c discountCode) {
        if (discountCode.Max_Number_of_Usages__c != null) {
            Decimal codeUsages = discountCode.Code_Usages__c;
            if (codeUsages == null) codeUsages = 0;
            if (discountCode.Code_Usages__c >= discountCode.Max_Number_of_Usages__c) {
                return false;
            }
        }
        return true;
    }

    @TestVisible
    private static Boolean checkStartTime(Discount_Code__c discountCode, Datetime startTime) {
        if (discountCode.Applicable_To_Hours__c == null) return true;
        if (startTime == null) return true;

        //        if (startTime == null) {
        //            if (discountCode.Applicable_To_Hours__c == null) return true;
        //            if (discountCode.Applicable_To_Hours__c != null) return false;
        //        }

        List<OperatingHours> hours = [
                SELECT Id, (SELECT Id, DayOfWeek, StartTime, EndTime FROM TimeSlots)
                FROM OperatingHours
                WHERE Id = :discountCode.Applicable_To_Hours__c
        ];

        if (hours.isEmpty()) return true;

        OperatingHours oh = hours[0];

        String startDayName = startTime.format('EEEE');

        for (TimeSlot timeSlot : oh.TimeSlots) {
            if (timeSlot.DayOfWeek == startDayName && timeSlot.StartTime <= startTime.time() && timeSlot.EndTime >= startTime.time()) return true;
        }

        return false;
    }

    @TestVisible
    private static Boolean checkStartDate(Discount_Code__c discountCode, Datetime startTime) {
        if (startTime == null) return true;
        if (discountCode.Applicable_From_Appointment_Date__c == null && discountCode.Applicable_To_Appointment_Date__c == null) return true;
        if (discountCode.Applicable_From_Appointment_Date__c == null && discountCode.Applicable_To_Appointment_Date__c >= startTime.date()) return true;
        if (discountCode.Applicable_From_Appointment_Date__c <= startTime.date() && discountCode.Applicable_To_Appointment_Date__c == null) return true;
        if (discountCode.Applicable_From_Appointment_Date__c <= startTime.date() && discountCode.Applicable_To_Appointment_Date__c >= startTime.date()) return true;

        return false;
    }

    @TestVisible
    private static Boolean checkProductApplicable(Discount_Code__c discountCode, String productId) {
        if (discountCode.Discount_Product_Members__r == null || discountCode.Discount_Product_Members__r.isEmpty()) return true;

        for (Discount_Product_Member__c discountProductMember : discountCode.Discount_Product_Members__r) {
            if (discountProductMember.Product__c == productId) {
                return true;
            }
        }
        return false;
    }

    @TestVisible
    private static Boolean checkLocationApplicable(Discount_Code__c discountCode, String locationId) {
        if (String.isEmpty(locationId)) return true;
        if (discountCode.Discount_Location_Members__r == null || discountCode.Discount_Location_Members__r.isEmpty()) return true;

        for (Discount_Location_Member__c discountMember : discountCode.Discount_Location_Members__r) {
            if (discountMember.Service_Territory__c == locationId) {
                return true;
            }
        }

        return false;
    }

    @TestVisible
    private static Boolean checkAccountApplicable(Discount_Code__c discountCode, String accountId, Product2 productToBook) {
        if (String.isEmpty(accountId)) return true;

        List<Account> accounts = [
                SELECT Id,
                        Existing_GP_Patient__c,
                        Existing_Dental_Patient__c,
                        Is_Active_Member__c,
                        Is_Active_Corporate_Member__c
                FROM Account
                WHERE Id = :accountId
        ];

        if (accounts.isEmpty()) return false;

        Account account = accounts[0];

        if (account != null && String.isNotBlank(discountCode.Available_to_Patients_by_Category__c)) {
            List<String> applicableTo = discountCode.Available_to_Patients_by_Category__c.split(';');

            for (String pCategory : applicableTo) {
                switch on pCategory {
                    when 'New GP Patients' {
                        if ((productToBook.Work_Type_Group__r?.Service_Type__c == 'Medical') && account.Existing_GP_Patient__c) return false;
                    }
                    when 'New Dental Patients' {
                        if ((productToBook.Work_Type_Group__r?.Service_Type__c == 'Dental') && account.Existing_Dental_Patient__c) return false;
                    }
                    when 'Members' {
                        if (!account.Is_Active_Member__c) return false;
                    }
                    when 'Corporate Members' {
                        if (!account.Is_Active_Corporate_Member__c) return false;
                    }
                }
            }
        }

        return true;
    }

    @TestVisible
    private static Boolean checkProductFamily(Discount_Code__c discountCode, Product2 productToBook) {
        if (String.isBlank(discountCode.Product_Family__c)) return true;

        return (discountCode.Product_Family__c == productToBook.Family);
    }

    public static List<OnlBookDomain.OptionWrapper> getDiscountCodesForProduct(String productId, String store) {
        String family = [SELECT Id, Family FROM Product2 WHERE Id = :productId].Family;

        List<Discount_Code__c> codes = [
                SELECT Id, Name, Product_Family__c, Product__c, Valid_for_Stores__c, Coupon_Code__c, (SELECT Id, Product__c, Product__r.Name FROM Discount_Product_Members__r)
                FROM Discount_Code__c
                WHERE
                        Active__c = TRUE
                        AND (
                                (Product_Family__c = NULL AND Product__c = NULL)
                                OR
                                (Product_Family__c = :family AND Product__c = NULL)
                                OR
                                (Product__c = :productId)
                        )
                ORDER BY Name ASC
        ];

        Map<String, Discount_Code__c> map_id_dCodes = new Map<String, Discount_Code__c>();

        for (Discount_Code__c discountCode : codes) {
            if (store == null || String.isEmpty(discountCode.Valid_for_Stores__c) || ('' + discountCode.Valid_for_Stores__c).containsIgnoreCase(store)) {

                if (discountCode.Discount_Product_Members__r != null && discountCode.Discount_Product_Members__r.size() > 0) {
                    //if the discount code has a product group defined for it, check if the product is in the product group
                    Boolean foundProduct = false;
                    for (Discount_Product_Member__c discountProductMember : discountCode.Discount_Product_Members__r) {
                        if (discountProductMember.Product__c == productId) {
                            foundProduct = true;
                            break;
                        }
                    }
                    if (foundProduct) {
                        System.debug('::getDiscountCodesForProduct:foundInGroup:adding ' + discountCode.Coupon_Code__c);
                        map_id_dCodes.put(discountCode.Id, discountCode);
                    }

                }
                else {
                    System.debug('::getDiscountCodesForProduct:adding ' + discountCode.Coupon_Code__c);
                    map_id_dCodes.put(discountCode.Id, discountCode);
                }
            }
        }

        List<SelectOption> opts = new List<SelectOption>();
        for (Discount_Code__c discountCode : map_id_dCodes.values()) {
            opts.add(new SelectOption(discountCode.Id, discountCode.Name));
        }

        opts.sort();

        List<OnlBookDomain.OptionWrapper> ret = new List<OnlBookDomain.OptionWrapper>();
        for (SelectOption selectOption : opts) {
            ret.add(new OnlBookDomain.OptionWrapper(selectOption.getLabel(), selectOption.getValue()));
        }

        return ret;
    }

    @AuraEnabled
    public static String aura_getDiscountCodesForProduct(String productId, String store) {
        return JSON.serialize(getDiscountCodesForProduct(productId, store));
    }

    @AuraEnabled
    public static String aura_getDiscountCodes(String productId, String store, String locationId, String accountId) {
        return JSON.serialize(getDiscountCodes(productId, store, locationId, accountId, null));
    }

    @AuraEnabled
    public static String aura_getDiscountCodesWithTime(String productId, String store, String locationId, String accountId, Datetime startTime) {
        return JSON.serialize(getDiscountCodes(productId, store, locationId, accountId, startTime));
    }

    public static List<OnlBookDomain.OptionWrapper> getDiscountCodes(String productId, String store, String locationId, String accountId, Datetime startTime) {
        List<OnlBookDomain.OptionWrapper> ret = new List<OnlBookDomain.OptionWrapper>();
        List<Discount_Code__c> codes = [
                SELECT Id,
                        Name,
                        Percentage_discount__c,
                        Campaign__c,
                        Discount_Amount__c,
                        Coupon_Code__c,
                        Product__c,
                        Active__c,
                        Available_to_Patients_by_Category__c,
                        Product_Family__c, (SELECT Id, Product__c, Product__r.Name, Discount_Amount__c, Discount_Percentage__c FROM Discount_Product_Members__r), (SELECT Id, Service_Territory__c FROM Discount_Location_Members__r)
                FROM Discount_Code__c
                WHERE
                        Active__c = TRUE
                ORDER BY Name ASC
        ];

        Map<String, Discount_Code__c> map_id_dCodes = new Map<String, Discount_Code__c>();

        Account acc = null;

        if (accountId != null) {
            List<Account> accs = [
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
                    WHERE Id = :accountId
                    AND DoNotSync__pc != TRUE
                    LIMIT 1
            ];

            if (accs.size() != 0) acc = accs.get(0);
        }

        List<Product2> products = [SELECT Id, Work_Type_Group__r.Service_Type__c, Family FROM Product2 WHERE Id = :productId];

        if (products.isEmpty()) return ret;

        Product2 product = products.get(0);

        for (Discount_Code__c discountCode : codes) {
            if (doesDiscountApply(discountCode, product, locationId, acc, startTime)) {
                map_id_dCodes.put(discountCode.Id, discountCode);
            }
        }

        List<SelectOption> opts = new List<SelectOption>();
        for (Discount_Code__c discountCode : map_id_dCodes.values()) {
            opts.add(new SelectOption(discountCode.Id, discountCode.Name));
        }

        opts.sort();

        for (SelectOption selectOption : opts) {
            OnlBookDomain.OptionWrapper optionWrapper = new OnlBookDomain.OptionWrapper(selectOption.getLabel(), selectOption.getValue());
            if (selectOption.getValue() == referAFriendDiscountCode()?.Id) optionWrapper.flags += 'RAF;';
            ret.add(optionWrapper);
        }

        return ret;
    }

    @AuraEnabled
    public static String aura_validateCoupon(String couponCode, String store, String productId, String locationId, Datetime startTime) {
        try {
            Discount_Code__c dc = validateDiscountCode(store, couponCode, productId, locationId, null, startTime);
            if (dc == null) return null;
            else return JSON.serialize(dc);
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            throw newAuraHandledException(e.getMessage());
        }
    }

    public static Boolean doesDiscountApply(Discount_Code__c discountCode, Product2 product, String locationId, Account account, Datetime startTime) {
        return validateDiscountCode(null, discountCode?.Coupon_Code__c, product?.Id, locationId, account?.Id, startTime) != null;
    }

    public static Boolean isDiscountAvailableForAccount(String accountId, String discountCodeId, String productId) {
        List<Discount_Code__c> discountCodes = [SELECT Id, Max_Usages_Per_Account_Per_Product__c FROM Discount_Code__c WHERE Id = :discountCodeId];

        if (discountCodes.isEmpty()) return false;

        Discount_Code__c dCode = discountCodes[0];

        if (dCode.Max_Usages_Per_Account_Per_Product__c == null) return true;

        List<Discount_Code_Usage__c> usages = [
                SELECT Id
                FROM Discount_Code_Usage__c
                WHERE Opportunity__r.AccountId = :accountId
                AND Opportunity__r.StageName = 'Closed Won'
                AND Product__c = :productId
                AND Discount_Code__c = :discountCodeId
        ];

        System.debug('::isDiscountAvailableForAccount:  dCode.Max_Usages_Per_Account_Per_Product__c = ' + dCode.Max_Usages_Per_Account_Per_Product__c + ', usages: ' + usages.size());

        return dCode.Max_Usages_Per_Account_Per_Product__c > usages.size();
    }

    public static Exception newAuraHandledException(String msg) {
        AuraHandledException aEx = new AuraHandledException(msg);
        aEx.setMessage(msg);
        return aEx;
    }

    /**
     * This function returns the applicable discount values for a particular discount code and product.
     * Default values from the Discount_Code__c are used if they are not overwritten by the product member.
     *
     * @param discountCodeID - The ID of the discount code.
     * @param productId - The ID of the product.
     *
     * @return {DiscountValues} - An instance of the DiscountValues class with the appropriate discount amount and discount percentage.
     */
    public static DiscountValues getApplicableDiscountValuesForCodeAndProduct(Id discountCodeID, Id productId) {
        DiscountValues ret = new DiscountValues();

        List<Discount_Code__c> codes = [
                SELECT Id,
                        Percentage_discount__c,
                        Discount_Amount__c, (SELECT Id, Product__c, Product__r.Name, Discount_Amount__c, Discount_Percentage__c, Price_Override__c FROM Discount_Product_Members__r WHERE Product__c = :productId)
                FROM Discount_Code__c
                WHERE
                        Id = :discountCodeID
                LIMIT 1
        ];
        if (codes.isEmpty()) return ret;

        // take default values from code if it's not overwritten by product member
        ret.discountAmount = codes[0].Discount_Amount__c;
        ret.discountPercentage = codes[0].Percentage_discount__c;

        System.debug(JSON.serialize(codes));

        // else potentially return product member values
        if (codes[0].Discount_Product_Members__r != null && !codes[0].Discount_Product_Members__r.isEmpty() &&
                (codes[0].Discount_Product_Members__r[0].Discount_Amount__c != null
                        || codes[0].Discount_Product_Members__r[0].Discount_Percentage__c != null
                        || codes[0].Discount_Product_Members__r[0].Price_Override__c != null)) {
            ret.discountAmount = codes[0].Discount_Product_Members__r[0].Discount_Amount__c;
            ret.discountPercentage = codes[0].Discount_Product_Members__r[0].Discount_Percentage__c;
            ret.priceOverride = codes[0].Discount_Product_Members__r[0].Price_Override__c;
        }

        return ret;
    }

    public static SBQQ__QuoteLine__c applyDiscountToQuoteLine(SBQQ__QuoteLine__c quoteLine, Discount_Code__c discountCode, Id productId) {

        DiscountCodeManager.DiscountValues discountValues = DiscountCodeManager.getApplicableDiscountValuesForCodeAndProduct(discountCode.Id, productId);

        if (discountValues.priceOverride != null) {
            quoteLine.AdditionalDiscountUnit__c = 'Amount';
            quoteLine.SBQQ__AdditionalDiscountAmount__c = quoteLine.SBQQ__ListPrice__c - discountValues.priceOverride;
        }
        else if (discountValues.discountPercentage != null) {
            quoteLine.AdditionalDiscountUnit__c = 'Percent';
            quoteLine.SBQQ__Discount__c = discountValues.discountPercentage;
        }
        else if (discountValues.discountAmount != null) {
            quoteLine.AdditionalDiscountUnit__c = 'Amount';
            if (discountValues.discountAmount > quoteLine.SBQQ__ListPrice__c) discountValues.discountAmount = quoteLine.SBQQ__ListPrice__c; // 2023-10-31 attempt to not go into negative values
            quoteLine.SBQQ__AdditionalDiscountAmount__c = discountValues.discountAmount;
        }

        return quoteLine;
    }

    public static Discount_Code__c getDiscountCodeByCouponCode(String couponCode) {

        // get DiscountCode__c
        List<Discount_Code__c> discountCodes = [
                SELECT Id,
                        Name,
                        Coupon_Code__c,
                        Product__c,
                        Product_Family__c,
                        Available_to_Patients_by_Category__c,
                        Max_Number_of_Usages__c,
                        Code_Usages__c,
                        Valid_for_Stores__c,
                        Applicable_To_Hours__c,
                        Applicable_From_Appointment_Date__c,
                        Applicable_To_Appointment_Date__c, (SELECT Id, Product__c, Product__r.Name FROM Discount_Product_Members__r), (SELECT Id, Service_Territory__c FROM Discount_Location_Members__r)
                FROM Discount_Code__c
                WHERE Coupon_Code__c = :couponCode
                AND Active__c = TRUE
        ];

        // no such discount code found
        if (discountCodes.isEmpty()) return null;

        return discountCodes[0];
    }

    public class DiscountValues {
        public Decimal discountAmount = null;
        public Decimal discountPercentage = null;
        public Decimal priceOverride = null;
    }
}