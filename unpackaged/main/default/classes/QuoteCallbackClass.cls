/**
 * Created 19.4.2022..
 */

global with sharing class QuoteCallbackClass implements SBQQ.CalculateCallback {
    global void callback(String quoteJSON) {
        System.debug('::QuoteCallbackClass:callback: ' + quoteJSON);
        SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', quoteJSON);
    }
}