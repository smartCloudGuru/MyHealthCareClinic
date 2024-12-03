/**
 * Created by Matija on 20.7.2023..
 */

public without sharing class UTMParserInvocable {

    @InvocableMethod(Category='Utility' Label='Parse UTM Parameters from URI' Description='Parse UTM Parameters from URI')
    public static List<UTMParameters> parseUTMParameters(List<String> uris) {
        if (uris == null) return null;

        List<UTMParameters> rets = new List<UTMParameters>();

        if (uris.isEmpty()) return rets;

        for (String uri : uris) {
            rets.add(parse(uri));
        }

        return rets;
    }

    public static UTMParameters parse(String uri) {
        UTMParameters ret = new UTMParameters();

        if (String.isBlank(uri)) return ret;

        try {

            System.PageReference pageReference = new System.PageReference(uri);
            Map<String, String> parameters = pageReference.getParameters();
            ret.utm_source = parameters.get('utm_source');
            ret.utm_medium = parameters.get('utm_medium');
            ret.utm_campaign = parameters.get('utm_campaign');
            ret.utm_term = parameters.get('utm_term');
            ret.utm_content = parameters.get('utm_content');
        }
        catch (Exception ex) {

        }

        return ret;
    }

    public class UTMParameters {
        @InvocableVariable(Label='UTM Source' Required=false)
        public String utm_source;

        @InvocableVariable(Label='UTM Source' Required=false)
        public String utm_medium;

        @InvocableVariable(Label='UTM Source' Required=false)
        public String utm_campaign;

        @InvocableVariable(Label='UTM Source' Required=false)
        public String utm_term;

        @InvocableVariable(Label='UTM Source' Required=false)
        public String utm_content;

    }

}