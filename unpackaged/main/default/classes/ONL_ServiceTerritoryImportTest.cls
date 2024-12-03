@IsTest class  ONL_ServiceTerritoryImportTest {
    @TestSetup
    static void dataSetup() {

    }

    @IsTest static void importExport_test() {

        String clinic1 = 'Dental Clinic;N;Y;09:00-18:00;09:00-18:00;09:00-18:00;09:00-18:00;09:00-18:00;09:00-18:00;09:00-17:00;';
        String clinic2 = 'Dental Clinic;N;Y;09:00-18:00;09:00-18:00;09:00-18:00;09:00-18:00;09:00-18:00;09:00-18:00;09:00-17:00;';
        String clinic1update = 'Dental Clinic;N;Y;09:45-10:00;;09:00-18:00;09:00-18:00;09:00-18:00;09:00-18:00;09:00-16:00;';

        String content = clinic1 + '\n' + clinic2;

        // test import all
        ONL_ServiceTerritoryImport.importAll(content);
        String exported = ONL_ServiceTerritoryImport.exportAll();
        System.debug(exported);
        System.assertEquals(content, exported);

        // test modification of one of the opening hours
        content = clinic1update;
        ONL_ServiceTerritoryImport.importAll(content);
        exported = ONL_ServiceTerritoryImport.exportAll();
        System.debug(exported);
        System.assertEquals(content + '\n' + clinic2, exported);

    }


}