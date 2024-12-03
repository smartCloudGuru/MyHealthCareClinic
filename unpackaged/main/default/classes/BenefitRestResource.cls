/**
 * Created 13.1.2022..

example
    profile: {
		MembershipTier: "Premium Member",
		OriginalStartDate: YYYY-MM-DD,
		CurrentStartDate: YYYY-MM-DD,
		CurrentEndDate: YYYY-MM-DD
	},
	members: [
		{
			FirstName: "Elizabeth",
			LastName: "Smith",
			DateOfBirth: YYYY-MM-DD,
			IsPrimary: true,
			IsAdult: true,
			PatientId: "PID-12345601",
			SalesforceId: "001000000000000001",
			Benefits: [] // Future expansion - member-specific benefits
		},
		....
	],
	benefits: [
		{
			DisplayName: "Flu Vaccine",
			TotalEntitlement: 5,
			UsedEntitlement: 0,
			AvailableEntitlement: 5,
			SalesforceId: "00A000000000000001"
		},
		...,
	]
}

 */


@RestResource(UrlMapping='/m/benefit/*')
global with sharing class BenefitRestResource {

    @HttpGet
    global static BenefitWrapper getRecord() {
        RestRequest request = RestContext.request;
        // grab the caseId from the end of the URL
        String id = request.requestURI.substring(request.requestURI.lastIndexOf('/') + 1);
        System.debug(LoggingLevel.INFO, '::M:BenefitRestResource:GET:requestURI: ' + request?.requestURI);

        BenefitWrapper ret = new BenefitWrapper();

        List<Membership_Benefit__c> benefits = [SELECT Id, Name, Benefit_Product_Group__c FROM Membership_Benefit__c WHERE Id = :id];

        if (!benefits.isEmpty()) {

            Membership_Benefit__c ben = benefits.get(0);
            ret = new BenefitWrapper(ben);

            List<Benefit_Product_Group_Member__c> groupMembers = [
                    SELECT Id,
                            Product__r.Id,
                            Product__r.Name,
                            Product__r.Description,
                            Product__r.Family
                    FROM Benefit_Product_Group_Member__c
                    WHERE Benefit_Product_Group__c = :ben.Benefit_Product_Group__c
            ];

            for (Benefit_Product_Group_Member__c benefitProductGroupMember : groupMembers) {
                ret.products.add(benefitProductGroupMember.Product__r);
            }
        }

        System.debug(LoggingLevel.INFO, '::M:BenefitRestResource:GET:requestURI: ' + JSON.serialize(ret));
        return ret;
    }

    global class BenefitWrapper {
        public Membership_Benefit__c benefit;
        public List<Product2> products = new List<Product2>();

        public BenefitWrapper() {
        }
        public BenefitWrapper(Membership_Benefit__c benefit) {
            this.benefit = benefit;
        }
    }
}