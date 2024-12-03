public without sharing class SiteMatcher {
    private static IntegrationErrorReporter errorReporter = new IntegrationErrorReporter();

    private List<String> siteNames;

    public SiteMatcher() {
        this.siteNames = new List<String>();
    }

    public void addSite(String siteName) {
        this.siteNames.add(siteName.trim());
    }

    public void addSites(List<String> siteNames) {
        for (String siteName : siteNames) {
            this.addSite(siteName);
        }
    }

    public Map<String, Id> getSiteIds() {
        Map<String, Id> siteIdByName = new Map<String, Id>();

        List<Site__c> sites = [SELECT Id, Name FROM Site__c WHERE Name IN :this.siteNames];

        for (Site__c site : sites) {
            siteIdByName.put(site.Name, site.Id);
        }

        Set<String> missingSiteNames = new Set<String>(this.siteNames);
        missingSiteNames.removeAll(siteIdByName.keySet());

        if (!missingSiteNames.isEmpty()) {
            errorReporter.addWarning(
                'Missing Sites',
                null,
                null,
                null,
                missingSiteNames.toString()
            );

            List<Site__c> newSites = createMissingSites(missingSiteNames);

            for (Site__c site : newSites) {
                if (site.Id != null) {
                    siteIdByName.put(site.Name, site.Id);
                }
            }
        }

        return siteIdByName;
    }

    private List<Site__c> createMissingSites(Set<String> missingSiteNames) {
        List<Site__c> newSites = new List<Site__c>();

        for (String siteName : missingSiteNames) {
            newSites.add(new Site__c(Name = siteName.trim()));
        }

        List<Database.SaveResult> saveResults = Database.insert(newSites, false);

        for (Integer i = 0; i < saveResults.size(); i++) {
            Database.SaveResult result = saveResults[i];

            if (!result.isSuccess()) {
                Site__c failedRecord = newSites[i];

                errorReporter.addError(
                    'Create Site',
                    null,
                    result.getErrors()[0].getMessage(),
                    null,
                    JSON.serialize(failedRecord)
                );
            }
        }

        return newSites;
    }
}