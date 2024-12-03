public with sharing class SitesData {
	public list<result> result{get;set;}
	public String status{get;set;}
	public class result{
		public list<String> Locations{get;set;}
		public String Name{get;set;}
		public Address Address{get;set;}
		public Integer Key{get;set;}
	}
	public class Address{
		public String Address3{get;set;}
		public String County{get;set;}
		public String City{get;set;}
		public String PostCode{get;set;}
		public String Address2{get;set;}
		public String Country{get;set;}
		public String Address1{get;set;}
	}
}