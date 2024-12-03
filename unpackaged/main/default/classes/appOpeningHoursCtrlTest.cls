/**
 * @author Zoran Zunko
 *
 * @date 5/14/21
 */
@IsTest
public class appOpeningHoursCtrlTest {
    @TestSetup
    static void dataSetup() {

        ServiceTerritory st= new ServiceTerritory();
        st.Name = 'test';


        OperatingHours oh = new OperatingHours();
        oh.Name = 'test Opening Hours';
        insert oh;

        st.OperatingHoursId = oh.Id;

        insert st;
    }

    @IsTest static void getServiceTerritories_test() {

        appOpeningHoursCtrl.getServiceTerritories();

    }


}