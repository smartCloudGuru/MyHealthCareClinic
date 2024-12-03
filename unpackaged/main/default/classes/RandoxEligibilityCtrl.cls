/**
 * Created by Matija on 2.2.2024..
 */

public without sharing class RandoxEligibilityCtrl {

    @InvocableMethod(Category='Randox' Label='Randox Provision' Description='Provision Randox Eligibility records' Callout=false)
    public static void provision(List<Randox_Eligibility__c> eligibilityList) {

        if (eligibilityList == null || eligibilityList.isEmpty()) return;

        List<EligibilityEntry> allEntries = new List<EligibilityEntry>();

        for (Randox_Eligibility__c randoxEligibility : eligibilityList) {
            allEntries.addAll(processEmail(randoxEligibility));
            randoxEligibility.Provisioned_at__c = Datetime.now();
        }

        List<Randox_Eligibility_Voucher__c> vouchers = entriesToVouchers(allEntries);

        Database.insert(vouchers, false);

        update eligibilityList;

    }

    // New method
    public static List<Randox_Eligibility_Voucher__c> entriesToVouchers(List<EligibilityEntry> eligibilityEntries) {
        List<Randox_Eligibility_Voucher__c> vouchers = new List<Randox_Eligibility_Voucher__c>();

        for (EligibilityEntry entry : eligibilityEntries) {
            Randox_Eligibility_Voucher__c voucher = new Randox_Eligibility_Voucher__c();
            voucher.Randox_Eligibility__c = entry.randoxEligibilityId;
            voucher.Randox_PatientId__c = entry.patientId;
            voucher.Valid_Until__c = Date.today().addMonths(6);
            if (entry.hasTAMProduct()) {
                voucher.Eligible_For__c = 'Every/Discovery+TAM';
            }
            else {
                voucher.Eligible_For__c = 'Every/Discovery';
            }
            vouchers.add(voucher);
        }
        return vouchers;
    }


    /**
     * This method is responsible for processing the email field from a Randox Eligibility object.
     *
     * It takes an instance of Randox Eligibility object as input. The method parses the 'Email_with_PIDs__c' field
     * from the object and extracts Patient IDs and associated product eligibility information.
     * It constructs a list of EligibilityEntry objects where each entry contains
     * the Randox Eligibility record's Id, the Patient ID, and the products the patient is eligible for.
     *
     * Note: Only entries that have a valid positive integer as Patient ID are added to the return list.
     * Also, this method is resistant to errors in input format: if a line of the email field is not processable,
     * it is skipped and the method processes the next line.
     *
     * @param randoxEligibility The Randox_Eligibility__c object from which the email information is to be processed.
     *
     * @return List<EligibilityEntry>  A list of EligibilityEntry objects each containing the Randox Eligibility record's Id,
     *                                 a Patient ID, and the products the patient is eligible for.
     */

    public static List<EligibilityEntry> processEmail(Randox_Eligibility__c randoxEligibility) {

        List<EligibilityEntry> ret = new List<EligibilityEntry>();

        if (randoxEligibility == null) return ret;
        if (String.isBlank(randoxEligibility.Email_with_PIDs__c)) return ret;

        String[] lines = randoxEligibility.Email_with_PIDs__c.split('\n');

        for (String line : lines) {
            String[] parts = line.split('\\s+', 2);
            if (parts.size() >= 2) {
                try {
                    EligibilityEntry entry = new EligibilityEntry();
                    entry.randoxEligibilityId = randoxEligibility.Id;
                    entry.patientId = parts[0].trim();
                    entry.productsEligible = parts[1].trim();
                    //add only if valid integer PID is found at start of the line
                    if (Integer.valueOf(entry.patientId) > 0) {
                        ret.add(entry);
                    }
                }
                catch (Exception ignore) {
                    // NOP
                }

            }
        }

        return ret;
    }

    /**
     * This method checks if a voucher is available for a given patient in the 'Randox_Eligibility_Voucher__c' custom object.
     * It returns the value of 'Eligible_For__c' field of the latest available voucher for the patient or null if no available voucher is found.
     *
     * @param randoxPatientId The ID of the Randox patient to check voucher availability for.
     *
     * @return The 'Eligible_For__c' field of the latest available voucher for the given patient if available, or null otherwise.
     */
    @AuraEnabled(Cacheable=false)
    public static String checkVoucherIsAvailable(String randoxPatientId) {
        List<Randox_Eligibility_Voucher__c> reList = [
                SELECT Id, Randox_PatientId__c, Eligible_For__c, Available__c
                FROM Randox_Eligibility_Voucher__c
                WHERE Randox_PatientId__c = :randoxPatientId
                AND Available__c = TRUE
                ORDER BY CreatedDate ASC
                LIMIT 1
        ];

        if (!reList.isEmpty()) return reList[0].Eligible_For__c;

        return null;
    }

    /**
     * This method sets the Opportunity ID for a Randox Eligibility Voucher record and returns the ID of
     * updated voucher record. It queries on the basis of Patient ID, Eligibility tag and Availability of
     * the voucher. If a matching Voucher record is found, it updates the Opportunity__c lookup field on
     * the Voucher with the provided Opportunity ID.
     *
     * @param randoxPID The Patient ID to match in Randox Eligibility Voucher records.
     * @param tag The Eligibility tag to match in Randox Eligibility Voucher records.
     * @param oppId The ID of the Opportunity to set on the Voucher record.
     *
     * @return The ID of the updated Randox Eligibility Voucher. It returns the ID of first Voucher record
     * from the ordered list by Created Date in ascending order. In case no matching voucher found, it
     * returns null.
     */
    public static String setOpportunityToVoucher(String randoxPID, String tag, Id oppId) {
        try {
            System.debug('::setOpportunityToVoucher:randoxPID='+randoxPID+':tag='+tag+':oppId='+oppId);
            List<Randox_Eligibility_Voucher__c> reList = [
                    SELECT Id, CreatedDate, Randox_PatientId__c, Eligible_For__c, Available__c, Opportunity__c
                    FROM Randox_Eligibility_Voucher__c
                    WHERE Randox_PatientId__c = :randoxPID
                    AND Available__c = TRUE
                    AND Eligible_For__c = :tag
                    ORDER BY CreatedDate ASC
                    LIMIT 1
            ];

            System.debug('::setOpportunityToVoucher:size:'+reList.size());
            if (!reList.isEmpty()) {
                reList[0].Opportunity__c = oppId;
                Database.update (reList, false);
                return reList[0].Id;
            }
        }
        catch (Exception ex) {
        }

        return null;
    }

    public class EligibilityEntry {
        public String patientId;
        public String productsEligible;
        public String randoxEligibilityId;

        public Boolean hasTAMProduct() {
            return this.productsEligible != null && this.productsEligible.contains('TAM');
        }

        public override String toString() {
            return 'EligibilityEntry:{' +
                    'patientId=\'' + patientId + '\'' +
                    ', productsEligible=\'' + productsEligible + '\'' +
                    ', hasTAMProduct=' + hasTAMProduct() + '' +
                    '}';
        }
    }
}