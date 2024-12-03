@IsTest
public class AppointmentTypeMatcherTest {
    @IsTest
    static void addTypesTest(){
        AppointmentTypeMatcher matcher = new AppointmentTypeMatcher();
        matcher.addAppointmentTypes(new List<String>{'Test'});
    }
}