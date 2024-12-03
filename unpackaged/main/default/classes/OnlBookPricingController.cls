/**
 * Created by Matija on 28.11.2023..
 */

public without sharing class OnlBookPricingController {

    /**
    * Searches for conditions when an appointment is done more than N times a year that is allowed per Membership
    * In that case we search for a "Surcharge Product" configured in "Out-of-Membership Surcharge" object and we add that price to the quote
    *
    * @param accountId
    * @param productId
    * @param bookingDate provide null if only info on current state is needed, (spent and next free date)
    *
    * @return PricebookEntry for the Surcharge Product, if applicable for this case, or nul lif no surcharge is needed
    */
    public static OOMSurchargeCalcResponse checkForOutOfMembershipSurcharge(Id accountId, Id productId, Date bookingDate) {

        OOMSurchargeCalcResponse ret = new OOMSurchargeCalcResponse();

        try {
            PricebookEntry priceBookEntry = getPriceBookEntryForAccountAndProduct(accountId, productId);
            if (priceBookEntry == null) return null;
            Id priceBookId = priceBookEntry.Pricebook2Id;

            List<Account> accs = [
                    SELECT Id,
                            Membership_Type__c,
                            Member_Status__c,
                            Membership_Start_Date__c,
                            Member_Since__c,
                            Membership_Change_Dates__c,
                            Patient_Type__c,
                            Membership_Contract__c,
                            Membership_Contract__r.Membership_Tier__c,
                            Membership_Contract__r.Membership_Tier__r.Tier_Level__c,
                            Membership_Tier__r.Tier_Level__c,
                            Member_Group__c,
                            Member_Group__r.Membership_Type__c,
                            Member_Group__r.Member_Status__c,
                            Member_Group__r.Membership_Start_Date__c,
                            Member_Group__r.Member_Since__c,
                            Member_Group__r.Membership_Change_Dates__c,
                            Member_Group__r.Patient_Type__c,
                            Member_Group__r.Membership_Tier__r.Tier_Level__c,
                            Is_Active_Member__c
                    FROM Account
                    WHERE Id = :accountId
            ];

            if (accs.size() == 0) {
                System.debug(LoggingLevel.WARN, '::checkForOutOfMembershipSurcharge:returning null, no such account');
                return null;
            }

            Account acc = accs[0];

            System.debug(LoggingLevel.WARN, '::checkForOutOfMembershipSurcharge:acc:' + JSON.serializePretty(acc));

            //take own member status, or the main payer one if current is not defined

            String membershipTierLevel = acc.Membership_Contract__r?.Membership_Tier__r?.Tier_Level__c;
            if (membershipTierLevel == null) membershipTierLevel = acc.Membership_Tier__r?.Tier_Level__c;
            //fallback to legacy
            if (membershipTierLevel == null && String.isNotEmpty(acc.Membership_Type__c)) {
                if (acc.Membership_Type__c.containsIgnoreCase('Premium')) membershipTierLevel = 'Premium';
                else if (acc.Membership_Type__c.containsIgnoreCase('Complete')) membershipTierLevel = 'Complete';
                else if (acc.Membership_Type__c.containsIgnoreCase('Dental')) membershipTierLevel = 'Dental';
                else if (acc.Membership_Type__c.containsIgnoreCase('GP')) membershipTierLevel = 'GP';
            }

            Boolean isActiveMember = (acc.Is_Active_Member__c == true);
            if (!isActiveMember) {
                System.debug('::checkForOutOfMembershipSurcharge:returning null, not an active member');
                return null;
            }

            Date membershipStartDate = null;

            if (acc.Membership_Start_Date__c != null) {
                membershipStartDate = acc.Membership_Start_Date__c;
            }
            else if (acc.Member_Group__c != null && acc.Member_Group__r.Membership_Start_Date__c != null) {
                membershipStartDate = acc.Member_Group__r.Membership_Start_Date__c;
            }
            else if (acc.Membership_Change_Dates__c != null) {
                membershipStartDate = acc.Membership_Change_Dates__c;
            }
            else if (acc.Member_Group__c != null && acc.Member_Group__r.Membership_Change_Dates__c != null) {
                membershipStartDate = acc.Member_Group__r.Membership_Change_Dates__c;
            }
            else if (acc.Member_Since__c != null) {
                membershipStartDate = acc.Member_Since__c;
            }
            else if (acc.Member_Group__c != null && acc.Member_Group__r.Member_Since__c != null) {
                membershipStartDate = acc.Member_Group__r.Member_Since__c;
            }

            if (membershipStartDate == null) {
                System.debug(LoggingLevel.WARN, '::checkForOutOfMembershipSurcharge:returning null, no membership start date found for ' + acc.Id);
                return null;
            }

            // normalize start date to be for within the last year
            Date membershipStartDateThisYear = Date.newInstance(Date.today().year(), membershipStartDate.month(), membershipStartDate.day());
            if (membershipStartDateThisYear > Date.today()) membershipStartDateThisYear = membershipStartDateThisYear.addYears(-1);

            List<OutOfMembership_Surcharge__c> oomSurcharges = [
                    SELECT
                            Id, Max_Free__c, Surcharge_Product__c, Product__r.Work_Type_Group__c, Benefit_Group__c
                    FROM OutOfMembership_Surcharge__c
                    WHERE Product__c = :productId
                    AND Surcharge_Product__r.IsActive = TRUE
                    AND Membership_Tier_Level__c = :membershipTierLevel
                    LIMIT 1
            ];

            if (oomSurcharges.size() == 0) {
                System.debug('::checkForOutOfMembershipSurcharge:returning null, no surcharges configured for productId ' + productId + ' and mem tier level ' + membershipTierLevel);
                return null;
            }

            ret.membershipBenefitCounter = oomSurcharges[0].Benefit_Group__c;

            if (oomSurcharges[0].Max_Free__c == null || oomSurcharges[0].Max_Free__c < 0) {
                System.debug(LoggingLevel.WARN, '::checkForOutOfMembershipSurcharge:returning null, Max_Free__c not positive integer ' + oomSurcharges[0].Id + ' with max free ' + oomSurcharges[0].Max_Free__c);
                return ret;
            }

            OOMSurcharge surchargeData = new OOMSurcharge();

            //checkHowManyFreeAppointmentsWereUsedSince

            Integer alreadySpentFree = 0;
            //get all workTypeIds for the given work type group

            ServiceAppointment lastBookedServiceAppointment = null;

            //where it's net 0 price and there is no discount applied
            List<ServiceAppointment> sas = [
                    SELECT Id,
                            SchedStartTime,
                            Treatment__c,
                            Treatment__r.Amount,
                            Treatment__r.SBQQ__PrimaryQuote__c,
                            Treatment__r.SBQQ__PrimaryQuote__r.SBQQ__NetAmount__c
                    FROM ServiceAppointment
                    WHERE AccountId = :accountId
                    AND SchedStartTime >= :membershipStartDateThisYear
                    AND Count_Against_Membership_Counter__c = TRUE
                    AND Membership_Benefit_Counter__c = :oomSurcharges[0].Benefit_Group__c
                    ORDER BY SchedStartTime DESC
            ];

            if (!sas.isEmpty()) {
                lastBookedServiceAppointment = sas[0];
                surchargeData.lastBookedDate = lastBookedServiceAppointment.SchedStartTime.date();
            }

            System.debug('::checkForOutOfMembershipSurcharge:found ' + sas.size() + ' previous free Scheduled appointments for accId ' + accountId + ' and BenefitGroup ' + oomSurcharges[0].Benefit_Group__c);

            //count spent appointments only within current membership period
            alreadySpentFree = 0;
            for (ServiceAppointment serviceAppointment : sas) {
                if (serviceAppointment.SchedStartTime >= membershipStartDateThisYear) alreadySpentFree++;
            }

            surchargeData.spentFree = alreadySpentFree;
            surchargeData.maxFree = Integer.valueOf(oomSurcharges[0].Max_Free__c);

            Boolean tooManyFreeBooked = (alreadySpentFree >= oomSurcharges[0].Max_Free__c);

            // booking is to early if the latest booking is less than ((12/MAXfree) months - 14 days) from today
            Date dateWhenBookingCouldBeFreeFrom = null;
            Boolean tooEarlyBooking;

            if (oomSurcharges[0].Max_Free__c > 0 && lastBookedServiceAppointment != null) {
                dateWhenBookingCouldBeFreeFrom = lastBookedServiceAppointment.SchedStartTime.addMonths(Integer.valueOf(12 / oomSurcharges[0].Max_Free__c)).addDays(-14).date();
                if (bookingDate != null) tooEarlyBooking = (bookingDate < dateWhenBookingCouldBeFreeFrom);
                else tooEarlyBooking = false;
            }
            else {
                tooEarlyBooking = false;
                dateWhenBookingCouldBeFreeFrom = null;
            }

            if (tooEarlyBooking || (bookingDate == null)) {
                surchargeData.nextFreeDate = dateWhenBookingCouldBeFreeFrom;
            }

            System.debug('::checkForOutOfMembershipSurcharge:tooManyFreeBooked ' + tooManyFreeBooked);
            System.debug('::checkForOutOfMembershipSurcharge:dateWhenBookingCouldBeFreeFrom ' + dateWhenBookingCouldBeFreeFrom);
            System.debug('::checkForOutOfMembershipSurcharge:tooEarlyBooking ' + tooEarlyBooking);


            //include surgarge if it's too early, or too many bookings, or if this is just for info (bookingDate=null)
            Boolean calculateSurcharge = tooEarlyBooking || tooManyFreeBooked;
            if (bookingDate == null && dateWhenBookingCouldBeFreeFrom > Date.today()) calculateSurcharge = true;

            if (calculateSurcharge) {

                Id potentialSurchargeProductId = oomSurcharges[0].Surcharge_Product__c;

                //check if there is a pricebookentry for the "Surcharge product" in Patient's pricebook
                List<PricebookEntry> pbes = [
                        SELECT
                                Id, UnitPrice, Product2Id
                        FROM PricebookEntry
                        WHERE Pricebook2Id = :priceBookId
                        AND Product2Id = :potentialSurchargeProductId
                        LIMIT 1
                ];
                if (pbes.size() == 0) {
                    System.debug('::checkForOutOfMembershipSurcharge:returning null, no surcharge PBE configured for productId ' + potentialSurchargeProductId + ' in price book ' + priceBookId);
                    return ret;
                }

                surchargeData.pricebookEntry = pbes[0];
            }

            if (tooManyFreeBooked) {
                surchargeData.nextFreeDate = null;
            }
            if (surchargeData.nextFreeDate != null && surchargeData.nextFreeDate <= Date.today()) surchargeData.nextFreeDate = null;

            ret.surchargeData = surchargeData;

            return ret;

        }
        catch (Exception ex) {
            System.debug('::checkForOutOfMembershipSurcharge:returning null, failed' + ex.getMessage());
            return null;
        }

    }

    public static PricebookEntry getPriceBookEntryForAccountAndProduct(Id accId, Id productId) {
        Account acc = [
                SELECT Id,
                        FirstName,
                        LastName,
                        Membership_Type__c,
                        Member_Status__c,
                        Patient_Type__c,
                        Membership_Tier__r.Price_Book__c,
                        Membership_Contract__r.Membership_Tier__r.Price_Book__c,
                        Is_Active_Member__c
                FROM Account
                WHERE Id = :accId
                LIMIT 1
        ];
        System.debug('::getPriceBookEntryForAccountAndProduct:acc' + acc);
        List<Product2> products = [
                SELECT Id,
                        Name,
                        Non_Membership_Price__c, (
                        SELECT
                                Id,
                                Pricebook2.Name,
                                Pricebook2.IsStandard,
                                Pricebook2.IsActive,
                                UnitPrice
                        FROM
                                PricebookEntries
                )
                FROM Product2
                WHERE Id = :productId
                LIMIT 1
        ];

        Product2 product = products.get (0);
        System.debug('::getPriceBookEntryForAccountAndProduct:acc' + product);

        PricebookEntry standardPriceBookPBE = null;

        Boolean isActiveMember = acc.Is_Active_Member__c == true;
        System.debug('::getpb:isActiveMember:' + isActiveMember);
        Id accPbook = acc.Membership_Contract__r?.Membership_Tier__r?.Price_Book__c;
        if (accPbook == null) accPbook = acc.Membership_Tier__r.Price_Book__c;

        for (PricebookEntry pbe : product.PricebookEntries) {
            if (isActiveMember
                    && pbe.Pricebook2.IsActive
                    && (pbe.Pricebook2Id == accPbook)) {
                System.debug('::getPriceBookEntryForAccountAndProduct:' + accId + ',' + productId + '=in pricebook =' + pbe.Pricebook2Id + ' /' + pbe.Pricebook2.Name);
                return pbe;
            }
            if (pbe.Pricebook2.IsActive && pbe.Pricebook2.IsStandard) {
                standardPriceBookPBE = pbe;
            }
        }

        System.debug('::getPriceBookEntryForAccountAndProduct:' + accId + ',' + productId + '=in STANDARD pricebook =' + standardPriceBookPBE?.Pricebook2Id);
        return standardPriceBookPBE;
    }

    public class OOMSurchargeCalcResponse {
        public OOMSurcharge surchargeData = null;
        public String membershipBenefitCounter = null;
    }

    public class OOMSurcharge {
        public PricebookEntry pricebookEntry = null;
        public Integer spentFree;
        public Integer maxFree;
        public Date nextFreeDate = null;
        public Date lastBookedDate = null;
    }
}