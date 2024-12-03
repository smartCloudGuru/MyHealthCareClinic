@isTest
 private class SitesData_Test{

    static testMethod void myUnitTest(){
 
 SitesData.Address objAdd = new SitesData.Address();
           objAdd.Address3 = 'add';
           objAdd.County = 'India';
           objAdd.City = 'delhi';
           objAdd.PostCode = '1256';
           objAdd.Address2 = 'lebia';
           objAdd.Country = 'India';
           objAdd.Address1 = 'Katr';           
           
    SitesData.result objRelt = new SitesData.result();
        list<String> str = new list<String>{'s','d'};
        objRelt.Locations = str;
        objRelt.Address = objAdd;
        objRelt.Key = 12354;
        objRelt.Name = 'nove';
        
      SitesData objStd = new  SitesData();
        objStd.status='ok';
        //objStd.result = objRelt; //new list<SitesData.result>{new SitesData.result()};  
        
        }
   }