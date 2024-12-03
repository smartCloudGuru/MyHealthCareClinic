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



@RestResource(UrlMapping='/Membership/*')
global with sharing class MembershipRestResource {

    @HttpGet
    global static Membership getRecord() {
        RestRequest request = RestContext.request;
        // grab the caseId from the end of the URL
        String id = request.requestURI.substring( request.requestURI.lastIndexOf('/')+1);

        List<Account> membershipGroupAccounts = MembershipTierController.getMembersByMemberId(id);

        Membership membership = new Membership();
        membership.id = id;

        if (membershipGroupAccounts==null || membershipGroupAccounts.size()==0) return membership;

        Account primaryMember = null;
        Account providedMember = null;
        for (Account member : membershipGroupAccounts)
        {
            membership.members.add(new Member(member));
            if (member.Membership_Level__c!=null && member.Membership_Level__c.indexOf('Main Payer')>=0)  primaryMember = member;
            if (member.Id==id) providedMember = member;
        }

        if (primaryMember!=null) {
            MembershipTierController.MembershipTierWrapper tier = MembershipTierController.getMembershipTierByName(providedMember.Membership_Type__c);

            if (tier != null) {
                Profile profile = new Profile();
                profile.membershipTier = providedMember.Membership_Type__c;
                profile.membershipTierLevel = providedMember.Membership_Tier__r?.Tier_Level__c;
                profile.originalStartDate = providedMember.Member_Since__c;
                profile.currentStartDate = providedMember.Membership_Start_Date__c;
                profile.currentEndDate = providedMember.Cancellation_Date__c;

                membership.profile = profile;

                List<Benefit> benefits = new List<Benefit>();
                if (tier.benefits!=null)
                {
                    for (Membership_Benefit__c mb : tier.benefits)
                    {
                        benefits.add(new Benefit(mb));
                    }
                }

                membership.benefits = benefits;

            }

        }

        return membership;
    }

    global class Membership {
        String id;
        Profile profile;
        List<Member> members = new List<Member>();
        List<Benefit> benefits = new List<Benefit>();

        public Membership()
        {

        }
    }

    global class Profile
    {
        String membershipTier;
        String membershipTierLevel;
        Date originalStartDate;
        Date currentStartDate;
        Date currentEndDate;
    }

    global class Member
    {
        String salesforceId;
        String firstName;
        String lastName;
        Date dateOfBirth;
        Boolean isPrimary;
        Boolean isAdult;
        String patientId;
        List <Benefit> benefits = new List<Benefit>();  // Future expansion - member-specific benefits

        public Member()
        {

        }

        public Member(Account acc)
        {
            this.salesforceId = acc.Id;
            this.firstName = acc.FirstName;
            this.lastName = acc.LastName;
            this.dateOfBirth = acc.Date_of_Birth__c;
            this.isPrimary = acc.Membership_Level__c!=null && acc.Membership_Level__c.indexOf('Main Payer')>=0;
            this.isAdult = acc.Membership_Level__c!=null && acc.Membership_Level__c.indexOf('Adult')>=0;
            this.patientId = acc.Patient_Id__c;
        }

    }

    global class Benefit
    {
        String salesforceId;
        String displayName;
        Integer totalEntitlement;
        Integer usedEntitlement;
        Integer availableEntitlement;

        public Benefit()
        {

        }

        public Benefit(Membership_Benefit__c mb)
        {
            this.salesforceId = mb.Id;
            this.displayName = mb.Name;

            if (!mb.IsUnlimited__c)
            {
                // todo calc from actual record(s)
                this.usedEntitlement = 0;
                this.totalEntitlement = (Integer) mb.Annual_Limit__c;
                this.availableEntitlement = this.totalEntitlement - this.usedEntitlement;
            }
        }
    }
}