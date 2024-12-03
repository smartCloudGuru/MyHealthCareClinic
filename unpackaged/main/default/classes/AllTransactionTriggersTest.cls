/**
 * Created by david on 25/03/2021.
 */

@IsTest
public with sharing class AllTransactionTriggersTest {
	@IsTest
	static void testTransactionTriggers() {
		bt_stripe__Transaction__c tran = new bt_stripe__Transaction__c();
		try {
			insert tran;
		}
		catch (Exception e)
		{
			System.debug(LoggingLevel.DEBUG, 'Insert failed due to incomplete payment gateway setup etc');
		}
	}

}