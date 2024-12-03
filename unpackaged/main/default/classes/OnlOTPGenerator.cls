/**
 * Created 14.12.2021..
 */

public with sharing class OnlOTPGenerator {

    public List<String> otps {get;set;}
    public String resulturl {get;set;}
    public String qrcodeurl {get;set;}

    final String chars = '123456789ABCDEFGHIJKLMNPQRSTUVWXYZ';

    public OnlOTPGenerator()
    {
    }

    public void generateOTP() {

        qrcodeurl = OnlineStoreSettingsManager.getStoreSettings().Home_Test_Submission_URL__c + '?c=';
        resulturl = OnlineStoreSettingsManager.getStoreSettings().Home_Test_Submission_URL__c;

        otps = new List<String>();

        String totp;

        for (Integer i=0; i<10; i++) {
            do {
                totp = generateRandom();
            }
            while (otps.contains(totp));
            otps.add(totp);
        }

        List<OneTimePassword__c> oneTimePasswords = new List<OneTimePassword__c>();
        for (String otp: otps)
        {
            oneTimePasswords.add(new OneTimePassword__c(Name=otp));
        }

        insert oneTimePasswords;

    }

    public String generateRandom()
    {
        String otp = '';
        while (otp.length() < 6) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            otp += chars.substring(idx, idx + 1);
        }
        return otp;
    }
}