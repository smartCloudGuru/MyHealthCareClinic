@IsTest
public class SiteMatcherTest {
    @TestSetup
    static void makeData() {
        Site__c testSite = new Site__c(Name = 'Test');
        insert testSite;
    }

    @IsTest
    static void getPatientsTest() {
        SiteMatcher matcher = new SiteMatcher();
        matcher.addSites(new List<String>{'Test', 'Test2'});

        Map<String, Id> matchedSites = matcher.getSiteIds();
        System.assert(!matchedSites.isEmpty());
        System.assertNotEquals(null, matchedSites.get('Test'));
        System.assertNotEquals(null, matchedSites.get('Test2'));
    }
}