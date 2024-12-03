/**
 * Created by Matija on 20.7.2023..
 */

@IsTest
private class UTMParserInvocable_Test {

    @IsTest
    static void testBehavior() {
        String campaign = '012345678912345';
        String uri = 'https://test.example?utm_campaign=' + campaign;

        List<String> uris = new List<String>();
        uris.add(uri);

        List<UTMParserInvocable.UTMParameters> ret = UTMParserInvocable.parseUTMParameters(uris);

        System.assert(ret != null);
        System.assert(ret.size()==1);
        System.debug(ret[0]);
        System.assert(ret[0].utm_campaign == campaign );


    }
}