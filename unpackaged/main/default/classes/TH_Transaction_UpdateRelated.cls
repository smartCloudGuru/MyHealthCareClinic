/**
 * Created by david on 25/03/2021.
 */

/**
 * Fired on insert of Stripe Transactions
 *
 * Links to Opportunity, Account and COVID Test
 * Updates Opportunity Stage
 * Updates COVID Test Payment Status
 *
 */

public with sharing class TH_Transaction_UpdateRelated extends AnthologyTriggerHandler.DelegateBase {

	public TH_Transaction_UpdateRelated(AnthologyTriggerHandler.AnthologyTriggerContext anthTriggerContext) {
		this.anthTriggerContext = anthTriggerContext;
		name = 'TH_Transaction_UpdateRelated';
	}

	public override void beforeInsert(SObject o) {

		bt_stripe__Transaction__c oTran = (bt_stripe__Transaction__c) o;

			if (String.isNotBlank(oTran.bt_stripe__Metadata__c)) {

				Map<String,String> metadataMap = (Map<String,String>) JSON.deserialize(oTran.bt_stripe__Metadata__c, Map<String,String>.class);

				if (metadataMap.get('AccountId') != null) {
					oTran.bt_stripe__Related_Account__c = metadataMap.get('AccountId');
					oTran.bt_stripe__Recalculate_Parent_Rollup__c = true;
				}
				if (metadataMap.get('OpportunityId') != null) {
					oTran.Opportunity__c = metadataMap.get('OpportunityId');
					oTran.bt_stripe__Recalculate_Parent_Rollup__c = true;
				}

			}

	}
	public override void beforeUpdate(SObject old, SObject o) {

		bt_stripe__Transaction__c oTran = (bt_stripe__Transaction__c) o;

		if (String.isNotBlank(oTran.bt_stripe__Metadata__c)) {

			Map<String,String> metadataMap = (Map<String,String>) JSON.deserialize(oTran.bt_stripe__Metadata__c, Map<String,String>.class);

			if (metadataMap.get('AccountId') != null) {
				oTran.bt_stripe__Related_Account__c = metadataMap.get('AccountId');
				oTran.bt_stripe__Recalculate_Parent_Rollup__c = true;
			}
			if (metadataMap.get('OpportunityId') != null) {
				oTran.Opportunity__c = metadataMap.get('OpportunityId');
				oTran.bt_stripe__Recalculate_Parent_Rollup__c = true;
			}

		}

	}

}