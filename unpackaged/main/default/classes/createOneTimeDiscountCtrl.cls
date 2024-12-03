/**
 * Created 12.11.2021..
 */

public without sharing class createOneTimeDiscountCtrl {

    @AuraEnabled
    public static String createOneTimeDiscount(String form) {
        InputForm iform = (InputForm) JSON.deserialize(form, InputForm.class);

        Result ret = new Result();

        if (iform.dorefund && (String.isNotBlank(iform.recordId))) {
            ret.errorMessage = refund(iform.recordId, iform.amount);
        }

        // proceed only if no refund needed or refund was OK
        if (ret.errorMessage == null) {
            if (iform.docoupon) {
                Discount_Code__c dcode = new Discount_Code__c();
                dcode.Coupon_Code__c = iform.code;
                dcode.Valid_for_Stores__c = 'My Healthcare';
                dcode.Name = 'One time coupon ' + iform.code;
                dcode.Start_date__c = Date.today();
                dcode.End_date__c = iform.valid;
                dcode.Product_Family__c = iform.family;
                dcode.Discount_Amount__c = iform.amount;
                List<Product2> discountProduct2s = [SELECT Id FROM Product2 WHERE Name = 'Discount' AND Family = 'Discount' AND IsActive = TRUE];
                if (discountProduct2s.size() > 0) {
                    dcode.Discount_Product__c = discountProduct2s[0].Id;
                }
                dcode.Max_Number_of_Usages__c = 1;

                insert dcode;

                ret.couponId = dcode.Id;

            }

            if (iform.docancel && (String.isNotBlank(iform.recordId))) {
                List<COVID_Test__c> ctests = [SELECT Id, Scheduled_Appointment__c from COVID_Test__c WHERE Id = :iform.recordId];
                if (ctests.size() > 0) {
                    COVID_Test__c ctest = ctests[0];

                    ctest.COVID_Test_Status__c = 'Cancelled';

                    if (ctest.Scheduled_Appointment__c != null) {
                        ServiceAppointment app = new ServiceAppointment(Id = ctest.Scheduled_Appointment__c, Status='Canceled');
                        update app;
                        delete app;
                    }

                    ctest.Scheduled_Appointment__c = null;
                    update ctest;
                }

            }
        }


        return JSON.serialize(ret);
    }

    @AuraEnabled
    public static String refund(String ctestId, Decimal amount) {
        List<COVID_Test__c> ctest = [SELECT Id, Opportunity__c FROM COVID_Test__c WHERE Id = :ctestId];
        if (ctest.isEmpty()) return 'Invalid COVID Test';

        List<Opportunity> opps = [
                SELECT Id, (SELECT Id, bt_stripe__Transaction_Status__c, bt_stripe__Payment_Status__c, bt_stripe__Amount__c FROM Transactions_20210319154712112__r)
                FROM Opportunity
                WHERE Id = :ctest[0].Opportunity__c
        ];
        if (opps.isEmpty()) return 'Unable to find a Opportunity for this COVID test';
        Opportunity opp = opps[0];

        bt_stripe__Transaction__c txToRefund = null;

        for (bt_stripe__Transaction__c btx : opp.Transactions_20210319154712112__r) {
            if (btx.bt_stripe__Transaction_Status__c == 'Completed'
                    && (btx.bt_stripe__Payment_Status__c == 'Captured' || btx.bt_stripe__Payment_Status__c == 'Partially Refunded')
                    && btx.bt_stripe__Amount__c >= amount) {
                txToRefund = btx;
                break;
            }
        }

        if (txToRefund != null) {
            System.debug(LoggingLevel.ERROR, 'txToRefund ' + txToRefund.Id);
            String res = refundTransaction(txToRefund.Id, amount);
            if (res != null) return res;
        }
        else {
            return 'Unable to find a transaction to refund for this test';
        }

        return null;
    }

    public static String refundTransaction(String txId, Decimal amount) {
        try {
            bt_stripe.P360_API_v1.Tra t = bt_stripe.P360_API_v1.transactionFactory(txId);
            t.refund(amount);
            bt_stripe.P360_API_v1.commitWork();
            return null;
        }
        catch (Exception ex) {
            return 'Unable to perform a refund: ' + ex.getMessage();
        }
    }

    public class InputForm {
        public String recordId;
        public Decimal amount;
        public String family;
        public String code;
        public Date valid;
        public Boolean docancel;
        public Boolean docoupon;
        public Boolean dorefund;
    }

    private class Result {
        public String errorMessage;
        public String couponId;
    }


}