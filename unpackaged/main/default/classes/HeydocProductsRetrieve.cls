/**
 * Created 24.5.2022..
 */

public without sharing class HeydocProductsRetrieve {

    @TestVisible
    private static IntegrationErrorReporter logger = new IntegrationErrorReporter('ExtSync-Products');


    @InvocableMethod(Category='External Sync' Label='Retrieve Product(s) from HD' Description='Retrieve Product(s) from HD')
    public static void getProducts(List<Product2> filterByProduct) {
        syncProductsFromHeydoc(filterByProduct);
    }

    /* for manual sync only */
    /**
     * @param filterByProduct used in the Product Action button (if not null, then code expect one and only one product to fetch & upsert data for)
     *
     * @return
     */
    public static List<HeyDocService.HeydocProduct> syncProductsFromHeydoc(List<Product2> filterByProduct) {

        List<HeyDocService.HeydocProduct> allHDProducts = new List<HeyDocService.HeydocProduct>();

        Product2 singleProductToUpsert = null;
        String singleProductNewHDId = null;
        if (filterByProduct != null && filterByProduct.size() > 0) {
            singleProductToUpsert = [SELECT Id, Name, Work_Type_Group__r.Heydoc_Id__c FROM Product2 WHERE Id = :filterByProduct.get(0).Id];
        }

        try {
            //HEYDOC
            HeyDocService.Pagination pagination = new HeyDocService.Pagination();
            pagination.page = 0;
            pagination.pageSize = 200;

            HeyDocService.QueryOptions queryOptions = new HeyDocService.QueryOptions();
            queryOptions.includeDeleted = false;

            Boolean hasMore = true;

            while (hasMore) {
                pagination.page++;
                System.debug('Page::' + pagination.page);
                if (pagination.page >= 99) {
                    logger.addLog(LoggingLevel.ERROR, null, 'Too many pages to sync from HEYDOC!');
                    break;
                }
                hasMore = false;
                List <HeyDocService.HeydocProduct> resp = HeyDocService.queryProducts('', pagination, queryOptions);
                if (resp != null) {
                    System.debug('Retrieved products from HD:' + resp.size());
                    if (singleProductToUpsert != null) {
                        for (HeyDocService.HeydocProduct product : resp) {
                            if (product.name.equalsIgnoreCase(singleProductToUpsert.Name)) {
                                allHDProducts.add(product);
                                singleProductNewHDId = product.id;
                                break;
                            }
                        }
                    }
                    else {
                        //exclude the PCR Products
                        for (HeyDocService.HeydocProduct heydocProduct : resp) {
                            if (!heydocProduct.name.toLowerCase().contains('fit to fly') && !String.isEmpty(heydocProduct.name)) {
                                allHDProducts.add(heydocProduct);
                            }
                        }

                    }
                    hasMore = (resp.size() == pagination.pageSize);
                }
            }

            System.debug('allHDProducts size:' + allHDProducts.size());

            // BUILD MAP of HDID <-> ExistingProduct
            List<Product2> existingHDProducts;
            if (filterByProduct != null) {
                existingHDProducts = [SELECT Id, Work_Type_Group__r.Heydoc_Id__c, Appointment__c FROM Product2 WHERE Work_Type_Group__r.Heydoc_Id__c != NULL];
            }
            else {
                existingHDProducts = new List<Product2>();
            }
            Map<String, Product2> map_HDID_Product = new Map<String, Product2>();

            if (singleProductToUpsert == null) {
                for (Product2 product : existingHDProducts) {
                    map_HDID_Product.put(product.Work_Type_Group__r?.Heydoc_Id__c, product);
                }
            }
            else {
                map_HDID_Product.put(singleProductNewHDId, singleProductToUpsert);
            }

            // BUILD MAP of HDID <-> ExistingWorkTypeGroup
            List<WorkTypeGroup> existingWTGSs = [SELECT Id, Heydoc_Id__c FROM WorkTypeGroup WHERE Heydoc_Id__c != NULL];
            Map<String, WorkTypeGroup> map_HDID_WTG = new Map<String, WorkTypeGroup>();
            for (WorkTypeGroup wtg : existingWTGSs) {
                map_HDID_WTG.put(wtg.Heydoc_Id__c, wtg);
            }

            // BUILD MAP of HDID <-> ExistingWorkType
            List<WorkTypeGroupMember> existingWmembers = [SELECT Id, WorkTypeId, WorkType.Id, WorkTypeGroupId, WorkTypeGroup.Heydoc_Id__c FROM WorkTypeGroupMember WHERE WorkTypeGroup.Heydoc_Id__c != NULL];
            Map<String, WorkType> map_HDID_WT = new Map<String, WorkType>();
            Map<String, WorkTypeGroupMember> map_HDID_WTGM = new Map<String, WorkTypeGroupMember>();
            for (WorkTypeGroupMember workTypeGroupMember : existingWmembers) {
                map_HDID_WTGM.put(workTypeGroupMember.WorkTypeGroup.Heydoc_Id__c, workTypeGroupMember);
                map_HDID_WT.put(workTypeGroupMember.WorkTypeGroup.Heydoc_Id__c, workTypeGroupMember.WorkType);
            }

            Pricebook2 standardPb = [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE AND IsActive = TRUE];

            List<PricebookEntry> pbEntries = [SELECT Id, Product2.Work_Type_Group__r.Heydoc_Id__c FROM PricebookEntry WHERE Pricebook2Id = :standardPb.Id AND Product2.Work_Type_Group__r.Heydoc_Id__c != NULL];

            Map<String, PricebookEntry> map_HDID_PBE = new Map<String, PricebookEntry>();
            for (PricebookEntry pbe : pbEntries) {
                map_HDID_PBE.put(pbe.Product2.Work_Type_Group__r.Heydoc_Id__c, pbe);
            }

            for (HeyDocService.HeydocProduct heydocProduct : allHDProducts) {

                System.debug('::building:' + JSON.serialize(heydocProduct));

                WorkTypeGroup wtg = map_HDID_WTG.get(heydocProduct.id); //is there a WTG already for it?
                if (wtg == null) System.debug('::build:' + heydocProduct.Name + ': no previous wtg');
                WorkType wt = map_HDID_WT.get(heydocProduct.id); //is there a WT already for it?
                if (wt == null) System.debug('::build:' + heydocProduct.Name + ': no previous wt');
                WorkTypeGroupMember wtgm = map_HDID_WTGM.get(heydocProduct.id); //is there a WTGMember already for it?
                Product2 product = map_HDID_Product.get(heydocProduct.id); //is there a Product already for it?
                PricebookEntry pbe = map_HDID_PBE.get(heydocProduct.id); //is there a standard PBE already for it?

                map_HDID_WT.put(heydocProduct.id, buildWTFromHdProduct(heydocProduct, wt));
                map_HDID_WTG.put(heydocProduct.id, buildWTGFromHdProduct(heydocProduct, wtg));
                map_HDID_WTGM.put(heydocProduct.id, buildWTGMember(wtgm));
                map_HDID_Product.put(heydocProduct.id, buildProductFromHdProduct(heydocProduct, product));
                map_HDID_PBE.put(heydocProduct.id, buildPBEFromHdProduct(heydocProduct, pbe, standardPb));
            }


            ////// INSERTS BELOW

            System.debug('::wtsToUpsert:' + map_HDID_WT.values().size());
            System.debug('::wtgsToUpsert:' + map_HDID_WTG.values().size());

            upsert map_HDID_WT.values();
            upsert map_HDID_WTG.values();

            for (HeyDocService.HeydocProduct heydocProduct : allHDProducts) {
                if (map_HDID_WTGM.get(heydocProduct.id).Id == null) {
                    map_HDID_WTGM.get(heydocProduct.id).WorkTypeGroupId = map_HDID_WTG.get(heydocProduct.id).Id;
                    map_HDID_WTGM.get(heydocProduct.id).WorkTypeId = map_HDID_WT.get(heydocProduct.id).Id;
                    System.debug('at WTGM loop wtg:' + map_HDID_WTG.get(heydocProduct.id).Id + ' name:' + map_HDID_WTG.get(heydocProduct.id).Name + ', wt:' + map_HDID_WT.get(heydocProduct.id).Id);
                }
            }

            //need to insert only some wtgms, existing ones should be OK already
            List<WorkTypeGroupMember> wtgmsToInsert = new List<WorkTypeGroupMember>();
            for (WorkTypeGroupMember wtgm : map_HDID_WTGM.values()) {
                if (wtgm.Id == null) wtgmsToInsert.add(wtgm);
            }

            System.debug('::wtgmsToInsert:' + wtgmsToInsert.size());

            insert wtgmsToInsert;

            // check if we now haw the exact number of expected WTxx

            Integer num_wtgms = [SELECT COUNT() FROM WorkTypeGroupMember WHERE WorkTypeGroup.Heydoc_Id__c != NULL AND WorkTypeGroup.IsActive = TRUE];
            System.debug('AFTER UPSERT: total WTGMS with HDId:' + num_wtgms);

            for (HeyDocService.HeydocProduct heydocProduct : allHDProducts) {
                map_HDID_Product.get(heydocProduct.id).Work_Type_Group__c = map_HDID_WTG.get(heydocProduct.id).Id;
            }

            System.debug('::productsToUpsert:' + map_HDID_Product.values().size());

            upsert map_HDID_Product.values();

            Integer num_PRODS = [SELECT COUNT() FROM Product2 WHERE Work_Type_Group__r.Heydoc_Id__c != NULL AND IsActive = TRUE];
            System.debug('AFTER UPSERT: total PRODUCTS with HDId:' + num_PRODS);

            for (HeyDocService.HeydocProduct heydocProduct : allHDProducts) {
                if (map_HDID_PBE.get(heydocProduct.id).Id == null) map_HDID_PBE.get(heydocProduct.id).Product2Id = map_HDID_Product.get(heydocProduct.id).Id;
            }

            System.debug('::spbEntriesToUpsert:' + map_HDID_PBE.values().size());

            //System.debug('PBES to insert:' + JSON.serializePretty(map_HDID_PBE.values()));

            upsert map_HDID_PBE.values();

            //add work types to all locations

            List<ServiceTerritory> sts = [SELECT Id FROM ServiceTerritory WHERE Heydoc_Id__c != null];

            List<ServiceTerritoryWorkType> stwts = new List<ServiceTerritoryWorkType>();
            if (singleProductToUpsert == null) {
                for (ServiceTerritory st : sts) {
                    for (String hid : map_HDID_WT.keySet()) {
                        if (map_HDID_Product.get(hid)?.Appointment__c == true)
                        {
                            //System.debug('hdproduct ' + hid + ' needs a service territory member : st.Id=' + st.Id + ', WorkType:' + map_HDID_WT.get(hid));
                            stwts.add(new ServiceTerritoryWorkType(ServiceTerritoryId = st.Id, WorkTypeId = map_HDID_WT.get(hid).Id));
                        }
                    }
                }

                Database.insert (stwts, false); // all or nothing to false because some may already exits - insert only new ones
            }

            //insert skills for the work types
            List<SkillRequirement> skills = new List<SkillRequirement>();

            /*
            Skill skill = [SELECT Id FROM Skill WHERE DeveloperName = 'GP'];

            for (WorkType wt : map_HDID_WT.values()) {
                skills.add(new SkillRequirement(SkillId = skill.Id, RelatedRecordId = wt.Id));
            }

            Database.insert (skills, false); // all or nothing to false because some may already exits - insert only new ones
             */


        }
        catch (Exception e) {
            logger.addLog(LoggingLevel.ERROR, null, 'unable to do syncProductsFromHeydoc() ' + e.getMessage() + ' ' + e.getTypeName(), e.getStackTraceString(), null);
        }

        logger.persistLogs();
        return allHDProducts;
    }

    public static WorkTypeGroupMember buildWTGMember(WorkTypeGroupMember wtgm) {
        if (wtgm == null) wtgm = new WorkTypeGroupMember();
        return wtgm;
    }

    public static PricebookEntry buildPBEFromHdProduct(HeyDocService.HeydocProduct heydocProduct, PricebookEntry pbe, Pricebook2 pb) {
        if (pbe == null) pbe = new PricebookEntry();
        pbe.IsActive = true;
        pbe.UnitPrice = heydocProduct.price;
        if (pbe.Id == null) pbe.Pricebook2Id = pb.Id;
        return pbe;
    }

    public static Product2 buildProductFromHdProduct(HeyDocService.HeydocProduct heydocProduct, Product2 product) {
        if (product == null) product = new Product2();
        product.Name = heydocProduct.name;
        product.IsActive = true;
        product.Appointment__c = (heydocProduct.productType == 'appointment');
        product.Non_Membership_Price__c = heydocProduct.price;
        return product;
    }

    public static WorkType buildWTFromHdProduct(HeyDocService.HeydocProduct heydocProduct, WorkType workType) {
        if (workType == null) workType = new WorkType();
        workType.Name = heydocProduct.name + ' (HD WT)';
        workType.EstimatedDuration = heydocProduct.duration == null? 0 : heydocProduct.duration;
        workType.DurationType = 'Minutes';
        return workType;
    }

    public static WorkTypeGroup buildWTGFromHdProduct(HeyDocService.HeydocProduct heydocProduct, WorkTypeGroup wtg) {
        if (wtg == null) wtg = new WorkTypeGroup();
        wtg.Name = heydocProduct.name + ' (HD WTG)';
        wtg.IsActive = true;
        wtg.Heydoc_Id__c = heydocProduct.id;
        wtg.Service_Type__c = 'Medical';
        if (heydocProduct.isVideoConsultation!=null && (heydocProduct.isVideoConsultation == true)) wtg.Appointment_Type__c = 'VIDEO';
        else if (heydocProduct.name.containsIgnoreCase('telephone')) wtg.Appointment_Type__c = 'TELEPHONE';
        else wtg.Appointment_Type__c = 'CLINIC';

        return wtg;
    }
}