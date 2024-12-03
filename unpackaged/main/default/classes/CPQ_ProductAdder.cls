/**
 * Created 19.4.2022..
 */

public with sharing class CPQ_ProductAdder {

    public static QuoteModel addProductToQuote(Id quoteId, Id productId, String priceBookId, String currencyCode) {

        //the JSON formatted String representing the quote model to add a product to
        String quoteModel = readQuoteModel(quoteId);
        //System.debug('quoteModel: ' + quoteModel);

        //the JSON formatted String representing the product to be added to the quote
        String productModel = SBQQ.ServiceRouter.load(
                'SBQQ.ProductAPI.ProductLoader',
                productId,
                '{"pricebookId" : "' + priceBookId + '", "currencyCode" : "' + currencyCode + '"}');
        //System.debug('productModel: ' + quoteModel);

        //the JSON formatted String representing the quote with the product added to it
        String updatedQuoteModel = SBQQ.ServiceRouter.load(
                'SBQQ.QuoteAPI.QuoteProductAdder',
                null,
                '{"quote" : ' + quoteModel + ', "products" : [' + productModel + '], "ignoreCalculate" : true}');
        //System.debug('updatedQuoteModel: ' + updatedQuoteModel);

        // the JSON formatted String represeting the saved quote
        String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', updatedQuoteModel);
        //System.debug('savedQuoteModel: ' + savedQuoteModel);
        return quoteModelFromString(savedQuoteModel);
    }

    public static void calculateQuote(QuoteModel quote) {
        System.debug('::CPQ_ProductAdder:calculateQuote: ' + quote);
        QuoteCalculatorContext ctx = new QuoteCalculatorContext(quote, 'QuoteCallbackClass');
        SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteCalculator', null, JSON.serialize(ctx));
    }

    public static void calculateQuoteFromId(Id quoteId) {
        String qModel = readQuoteModel(quoteId);
        calculateQuote(quoteModelFromString(qModel));
    }

    public static String readQuoteModel(Id quoteId)
    {
        //the JSON formatted String representing the quote model to add a product to
        String quoteModel = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', quoteId);
        return quoteModel;
    }

    public static QuoteModel quoteModelFromString(String quoteModel)
    {
        return (QuoteModel) JSON.deserialize(quoteModel, QuoteModel.class);
    }



//    private class AddProductsContext {
//        private QuoteModel quote;
//        private ProductModel[] products;
//        private Integer groupKey;
//        private final Boolean ignoreCalculate = true; //Must be hardcoded to true
//
//        private AddProductsContext(QuoteModel quote, ProductModel[] products, Integer groupKey) {
//            this.quote = quote;
//            this.products = products;
//            this.groupKey = groupKey;
//        }
//    }

    /**
     * CPQ quote model
     * https://developer.salesforce.com/docs/atlas.en-us.cpq_dev_api.meta/cpq_dev_api/cpq_api_quote_model_9.htm
     */
    public class QuoteModel {
        public SBQQ__Quote__c record;
        public QuoteLineModel[] lineItems;
        public QuoteLineGroupModel[] lineItemGroups;
        public Integer nextKey;
        public Boolean applyAdditionalDiscountLast;
        public Boolean applyPartnerDiscountFirst;
        public Boolean channelDiscountsOffList;
        public Decimal customerTotal;
        public Decimal netTotal;
        public Decimal netNonSegmentTotal;
    }

    // https://developer.salesforce.com/docs/atlas.en-us.cpq_dev_api.meta/cpq_dev_api/cpq_api_product_model_8.htm
    public class ProductModel {
        public Product2 record;
        public Id upgradedAssetId;
        public String currencySymbol;
        public String currencyCode;
        public String[] featureCategories;
        public OptionModel[] options;
        public FeatureModel[] features;
        public ConfigurationModel configuration;
        public ConfigAttributeModel[] configurationAttributes;
        public ConfigAttributeModel[] inheritedConfigurationAttributes;
        public ConstraintModel[] constraints;
    }

    // https://developer.salesforce.com/docs/atlas.en-us.cpq_dev_api.meta/cpq_dev_api/cpq_api_option_model_3.htm
    public class OptionModel {
        public SBQQ__ProductOption__c record;
        public Map<String, String> externalConfigurationData;
        public Boolean configurable;
        public Boolean configurationRequired;
        public Boolean quantityEditable;
        public Boolean priceEditable;
        public Decimal productQuantityScale;
        public Boolean priorOptionExists;
        public Set<Id> dependentIds;
        public Map<String, Set<Id>> controllingGroups;
        public Map<String, Set<Id>> exclusionGroups;
        public String reconfigureDimensionWarning;
        public Boolean hasDimension;
        public Boolean isUpgrade;
        public String dynamicOptionKey;
    }

    // https://developer.salesforce.com/docs/atlas.en-us.cpq_dev_api.meta/cpq_dev_api/cpq_api_quoteline_model_1.htm
    public class QuoteLineModel {
        public SBQQ__QuoteLine__c record;
        public Boolean amountDiscountProrated;
        public Integer parentGroupKey;
        public Integer parentItemKey;
        public Integer key;
        public Boolean upliftable;
        public String configurationType;
        public String configurationEvent;
        public Boolean reconfigurationDisabled;
        public Boolean descriptionLocked;
        public Boolean productQuantityEditable;
        public Decimal productQuantityScale;
        public String dimensionType;
        public Boolean productHasDimensions;
        public Decimal targetCustomerAmount;
        public Decimal targetCustomerTotal;
    }

    // https://developer.salesforce.com/docs/atlas.en-us.cpq_dev_api.meta/cpq_dev_api/cpq_api_quotelinegroup_model_2.htm
    public class QuoteLineGroupModel {
        public SBQQ__QuoteLineGroup__c record;
        public Decimal netNonSegmentTotal;
        public Integer key;
    }

    public class FeatureModel {
        public SBQQ__ProductFeature__c record;
        public String instructionsText;
        public Boolean containsUpgrades;
    }

    public class ConfigurationModel {
        public Id configuredProductId;
        public Id optionId;
        public SBQQ__ProductOption__c optionData; // Editable data about the option in question, such as quantity or discount
        public SBQQ__ProductOption__c configurationData;
        public SBQQ__ProductOption__c inheritedConfigurationData;
        public ConfigurationModel[] optionConfigurations;
        public Boolean configured;
        public Boolean changedByProductActions;
        public Boolean isDynamicOption;
        public Boolean isUpgrade;
        public Set<Id> disabledOptionIds;
        public Set<Id> hiddenOptionIds;
        public Decimal listPrice;
        public Boolean priceEditable;
        public String[] validationMessages;
        public String dynamicOptionKey;
    }

    public class ConfigAttributeModel {
        public String name;
        public String targetFieldName;
        public Decimal displayOrder;
        public String colmnOrder;
        public Boolean required;
        public Id featureId;
        public String position;
        public Boolean appliedImmediately;
        public Boolean applyToProductOptions;
        public Boolean autoSelect;
        public String[] shownValues;
        public String[] hiddenValues;
        public Boolean hidden;
        public String noSuchFieldName;
        public Id myId;
    }

    public class ConstraintModel {
        public SBQQ__OptionConstraint__c record;
        public Boolean priorOptionExists;
    }

    private class QuoteCalculatorContext {
        private QuoteModel quote;             //The quote and callbackClass properties are called in the API code by the exact names seen here.
        private String callbackClass;         //Altering these property names will cause calculator API calls to fail.

        private QuoteCalculatorContext(QuoteModel quote, String callbackClass) {
            this.quote = quote;
            this.callbackClass = callbackClass;
        }
    }


}