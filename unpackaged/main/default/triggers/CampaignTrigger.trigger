/**
 * Created 27.6.2024..
 */

trigger CampaignTrigger on Campaign (after insert, after update) {

    CampaignTriggerHandler.onChange(Trigger.new);
}