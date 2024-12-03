/**
 * Created 18.11.2022..
 */

public without sharing class ImportAeronaProducts {

    @InvocableMethod(Category='External Sync' Label='Retrieve Product(s) from Aerona' Description='Retrieve Product(s) from Aerona')
    public static void getProducts(List<Product2> filterByProduct) {
        syncProducts(filterByProduct);
    }


    /* for manual sync only */
    /**
     * @param filterByProduct used in the Product Action button (if not null, then code expect one and only one product to fetch & upsert data for)
     */
    public static void syncProducts(List<Product2> filterByProduct) {

        List<AeronaServiceOASApi.OASAPIAppointmentType> allProducts = new List<AeronaServiceOASApi.OASAPIAppointmentType>();

        Product2 singleProductToUpsert = null;
        String singleProductNewAeronaId = null;
        if (filterByProduct != null && filterByProduct.size() > 0) {
            singleProductToUpsert = [SELECT Id, Name, Work_Type_Group__r.Aerona_Id__c FROM Product2 WHERE Id = :filterByProduct.get(0).Id];
        }

        try {

            List<AeronaServiceOASApi.OASAPIAppointmentType> resp = AeronaService.getAppointmentTypes();
            if (resp != null) {
                System.debug('Retrieved products from Aerona:' + resp.size());
                System.debug('Retrieved products from Aerona:' + JSON.serializePretty(resp));

                if (singleProductToUpsert != null) {
                    for (AeronaServiceOASApi.OASAPIAppointmentType product : resp) {
                        if (product.type.equalsIgnoreCase(singleProductToUpsert.Name)) {
                            allProducts.add(product);
                            singleProductNewAeronaId = '' + product.id;
                            break;
                        }
                    }
                }
                else {
                    for (AeronaServiceOASApi.OASAPIAppointmentType aeProduct : resp) {
                        allProducts.add(aeProduct);
                    }
                }
            }

            System.debug('allProducts size:' + allProducts.size());

            // BUILD MAP of AEID <-> ExistingProduct
            Map<String, Product2> map_AEID_Product = new Map<String, Product2>();
            List<Product2> existingHDProducts;
            if (filterByProduct != null) {
                existingHDProducts = [SELECT Id, Work_Type_Group__r.Aerona_Id__c, Appointment__c FROM Product2 WHERE Work_Type_Group__r.Aerona_Id__c != NULL];
            }
            else {
                existingHDProducts = new List<Product2>();
            }

            if (singleProductToUpsert == null) {
                for (Product2 product : existingHDProducts) {
                    map_AEID_Product.put(product.Work_Type_Group__r?.Aerona_Id__c, product);
                }
            }
            else {
                map_AEID_Product.put(singleProductNewAeronaId, singleProductToUpsert);
            }


            // BUILD MAP of AEID <-> ExistingWorkTypeGroup
            List<WorkTypeGroup> existingWTGSs = [SELECT Id, Aerona_Id__c FROM WorkTypeGroup WHERE Aerona_Id__c != NULL];
            Map<String, WorkTypeGroup> map_AEID_WTG = new Map<String, WorkTypeGroup>();
            for (WorkTypeGroup wtg : existingWTGSs) {
                map_AEID_WTG.put(wtg.Aerona_Id__c, wtg);
            }

            // BUILD MAP of AEID <-> ExistingWorkType
            List<WorkTypeGroupMember> existingWmembers = [SELECT Id, WorkTypeId, WorkType.Id, WorkTypeGroupId, WorkTypeGroup.Aerona_Id__c FROM WorkTypeGroupMember WHERE WorkTypeGroup.Aerona_Id__c != NULL];
            Map<String, WorkType> map_AEID_WT = new Map<String, WorkType>();
            Map<String, WorkTypeGroupMember> map_AEID_WTGM = new Map<String, WorkTypeGroupMember>();
            for (WorkTypeGroupMember workTypeGroupMember : existingWmembers) {
                map_AEID_WTGM.put(workTypeGroupMember.WorkTypeGroup.Aerona_Id__c, workTypeGroupMember);
                map_AEID_WT.put(workTypeGroupMember.WorkTypeGroup.Aerona_Id__c, workTypeGroupMember.WorkType);
            }

            Pricebook2 standardPb = [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE AND IsActive = TRUE];
            List<PricebookEntry> pbEntries = [SELECT Id, Product2.Work_Type_Group__r.Aerona_Id__c FROM PricebookEntry WHERE Pricebook2Id = :standardPb.Id AND Product2.Work_Type_Group__r.Aerona_Id__c != NULL];

            Map<String, PricebookEntry> map_AEID_PBE = new Map<String, PricebookEntry>();
            for (PricebookEntry pbe : pbEntries) {
                map_AEID_PBE.put(pbe.Product2.Work_Type_Group__r.Aerona_Id__c, pbe);
            }

            String aeId = null;
            for (AeronaServiceOASApi.OASAPIAppointmentType aeProduct : allProducts) {

                System.debug('::building:' + JSON.serialize(aeProduct));

                aeId = '' + aeProduct.id;

                WorkTypeGroup wtg = map_AEID_WTG.get(aeId); //is there a WTG already for it?
                if (wtg == null) System.debug('::build:' + aeProduct.type + ': no previous wtg');
                WorkType wt = map_AEID_WT.get(aeId); //is there a WT already for it?
                if (wt == null) System.debug('::build:' + aeProduct.type + ': no previous wt');
                WorkTypeGroupMember wtgm = map_AEID_WTGM.get(aeId); //is there a WTGMember already for it?
                Product2 product = map_AEID_Product.get(aeId); //is there a Product already for it?
                PricebookEntry pbe = map_AEID_PBE.get(aeId); //is there a standard PBE already for it?

                map_AEID_WT.put(aeId, buildWTFromAeronaProduct(aeProduct, wt));
                map_AEID_WTG.put(aeId, buildWTGFromAeronaProduct(aeProduct, wtg));
                map_AEID_WTGM.put(aeId, buildWTGMember(wtgm));
                map_AEID_Product.put(aeId, buildProductFromAeronaProduct(aeProduct, product));
                map_AEID_PBE.put(aeId, buildPBEFromAeronaProduct(aeProduct, pbe, standardPb));
            }


            ////// INSERTS BELOW

            System.debug('::wtsToUpsert:' + map_AEID_WT.values().size());
            System.debug('::wtgsToUpsert:' + map_AEID_WTG.values().size());

            upsert map_AEID_WT.values();
            upsert map_AEID_WTG.values();

            String aeProductid = null;
            for (AeronaServiceOASApi.OASAPIAppointmentType aeProduct : allProducts) {
                aeProductid = '' + aeProduct.id;
                if (map_AEID_WTGM.get(aeProductid).Id == null) {
                    map_AEID_WTGM.get(aeProductid).WorkTypeGroupId = map_AEID_WTG.get(aeProductid).Id;
                    map_AEID_WTGM.get(aeProductid).WorkTypeId = map_AEID_WT.get(aeProductid).Id;
                    System.debug('at WTGM loop wtg:' + map_AEID_WTG.get(aeProductid).Id + ' name:' + map_AEID_WTG.get(aeProductid).Name + ', wt:' + map_AEID_WT.get(aeProductid).Id);
                }
            }

            //need to insert only some wtgms, existing ones should be OK already
            List<WorkTypeGroupMember> wtgmsToInsert = new List<WorkTypeGroupMember>();
            for (WorkTypeGroupMember wtgm : map_AEID_WTGM.values()) {
                if (wtgm.Id == null) wtgmsToInsert.add(wtgm);
            }

            System.debug('::wtgmsToInsert:' + wtgmsToInsert.size());

            insert wtgmsToInsert;

            // check if we now haw the exact number of expected WTxx

            Integer num_wtgms = [SELECT COUNT() FROM WorkTypeGroupMember WHERE WorkTypeGroup.Aerona_Id__c != NULL AND WorkTypeGroup.IsActive = TRUE];
            System.debug('AFTER UPSERT: total WTGMS with AeronaIds:' + num_wtgms);

            for (AeronaServiceOASApi.OASAPIAppointmentType aeProduct : allProducts) {
                map_AEID_Product.get('' + aeProduct.id).Work_Type_Group__c = map_AEID_WTG.get('' + aeProduct.id).Id;
            }

            System.debug('::productsToUpsert:' + map_AEID_Product.values().size());

            upsert map_AEID_Product.values();

            Integer num_PRODS = [SELECT COUNT() FROM Product2 WHERE Work_Type_Group__r.Aerona_Id__c != NULL AND IsActive = TRUE];
            System.debug('AFTER UPSERT: total PRODUCTS with AeronaId:' + num_PRODS);

            for (AeronaServiceOASApi.OASAPIAppointmentType aeProduct : allProducts) {
                if (map_AEID_PBE.get('' + aeProduct.id).Id == null) map_AEID_PBE.get('' + aeProduct.id).Product2Id = map_AEID_Product.get('' + aeProduct.id).Id;
            }

            System.debug('::spbEntriesToUpsert:' + map_AEID_PBE.values().size());

            //System.debug('PBES to insert:' + JSON.serializePretty(map_HDID_PBE.values()));

            upsert map_AEID_PBE.values();

        }
        catch (Exception e) {
            System.debug('unable to do syncProductsFromAerona ' + e.getMessage() + ' ' + e.getTypeName() + ' ' + e.getStackTraceString());
        }

    }

    public static WorkTypeGroupMember buildWTGMember(WorkTypeGroupMember wtgm) {
        if (wtgm == null) wtgm = new WorkTypeGroupMember();
        return wtgm;
    }

    public static PricebookEntry buildPBEFromAeronaProduct(AeronaServiceOASApi.OASAPIAppointmentType aeProduct, PricebookEntry pbe, Pricebook2 pb) {
        if (pbe == null) pbe = new PricebookEntry();
        pbe.IsActive = true;
        // price not possible to know
        pbe.UnitPrice = 0;
        if (pbe.Id == null) pbe.Pricebook2Id = pb.Id;
        return pbe;
    }

    public static Product2 buildProductFromAeronaProduct(AeronaServiceOASApi.OASAPIAppointmentType aeProduct, Product2 product) {
        if (product == null) product = new Product2();
        product.Name = aeProduct.type;
        product.IsActive = true;
        product.Appointment__c = false;
        product.Non_Membership_Price__c = 0;
        return product;
    }

    public static WorkType buildWTFromAeronaProduct(AeronaServiceOASApi.OASAPIAppointmentType aeProduct, WorkType workType) {
        if (workType == null) workType = new WorkType();
        workType.Name = aeProduct.type + ' (Aerona WT)';
        workType.EstimatedDuration = aeProduct.duration == null ? 0 : aeProduct.duration;
        workType.DurationType = 'Minutes';
        return workType;
    }

    public static WorkTypeGroup buildWTGFromAeronaProduct(AeronaServiceOASApi.OASAPIAppointmentType aeProduct, WorkTypeGroup wtg) {
        if (wtg == null) wtg = new WorkTypeGroup();
        wtg.Name = aeProduct.type + ' (Aerona WTG)';
        wtg.IsActive = true;
        wtg.Aerona_Id__c = '' + aeProduct.id;
        wtg.Service_Type__c = 'Dental';
        wtg.Appointment_Type__c = 'CLINIC';

        return wtg;
    }
}