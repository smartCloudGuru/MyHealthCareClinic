/**
* @author Zoran Zunko
* @date 9/4/18
*
* @group
* @group-content ../../ApexDocContent/
*
* @description
*/
@IsTest
private class AnthologyTriggerHandlerTest {

	private class AnthologyTriggerHandlerImpl extends AnthologyTriggerHandler.DelegateBase {
		public AnthologyTriggerHandlerImpl(AnthologyTriggerHandler.AnthologyTriggerContext anthTriggerContext){
			name = 'AnthologyTriggerHandlerImpl';
			this.anthTriggerContext = anthTriggerContext;
		}
	}

	static testMethod void testDelegate() {
		Account acct = new Account(Name = 'Test Account');
		AnthologyTriggerDispatch.noTriggers = true;
		insert acct;

		AnthologyTriggerHandler.AnthologyTriggerContext anthContext = new AnthologyTriggerHandler.AnthologyTriggerContext(
				Account.SObjectType,
				System.TriggerOperation.BEFORE_INSERT,
				true,
				new List<Account> {acct},
				new Map<Id, SObject> {acct.Id => acct},
				new List<Account> {acct},
				new Map<Id, SObject> {acct.Id => acct}
		);

		AnthologyTriggerHandler.execute(new AnthologyTriggerHandlerImpl(anthContext));
		AnthologyTriggerHandler.executeInProgress(new AnthologyTriggerHandlerImpl(anthContext));

		anthContext.triggerOperation = System.TriggerOperation.AFTER_INSERT;
		AnthologyTriggerHandler.execute(new AnthologyTriggerHandlerImpl(anthContext));
		AnthologyTriggerHandler.executeInProgress(new AnthologyTriggerHandlerImpl(anthContext));

		anthContext.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
		AnthologyTriggerHandler.execute(new AnthologyTriggerHandlerImpl(anthContext));
		AnthologyTriggerHandler.executeInProgress(new AnthologyTriggerHandlerImpl(anthContext));

		anthContext.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
		AnthologyTriggerHandler.execute(new AnthologyTriggerHandlerImpl(anthContext));
		AnthologyTriggerHandler.executeInProgress(new AnthologyTriggerHandlerImpl(anthContext));

		anthContext.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
		AnthologyTriggerHandler.execute(new AnthologyTriggerHandlerImpl(anthContext));
		AnthologyTriggerHandler.executeInProgress(new AnthologyTriggerHandlerImpl(anthContext));

		anthContext.triggerOperation = System.TriggerOperation.AFTER_DELETE;
		AnthologyTriggerHandler.execute(new AnthologyTriggerHandlerImpl(anthContext));
		AnthologyTriggerHandler.executeInProgress(new AnthologyTriggerHandlerImpl(anthContext));

		anthContext.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
		AnthologyTriggerHandler.execute(new AnthologyTriggerHandlerImpl(anthContext));
		AnthologyTriggerHandler.executeInProgress(new AnthologyTriggerHandlerImpl(anthContext));

		AnthologyTriggerHandlerImpl anthologyTriggerHandlerImplTest =  new AnthologyTriggerHandlerImpl(anthContext);
		System.assert(anthologyTriggerHandlerImplTest.getTriggerContext().containsKey('name'));
		System.assert(anthologyTriggerHandlerImplTest.getTriggerContext().containsKey('SObject'));

		System.assert(!anthologyTriggerHandlerImplTest.getSkipLoop());

		System.assert(anthologyTriggerHandlerImplTest.getAnthologyTriggerContext() != null);
	}
}