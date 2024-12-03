/**
 * Created 8.11.2021..
 */

public with sharing class ONL_ServiceTerritoryImport {

    private static List<String> days = new List<String>{
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday'
    };

    public static String exportAll() {

        String ret = '';

        List<ServiceTerritory> sts = getAllServiceTerritories();

        //IDs of OHs
        List<String> ohs_ids = new List<String>();
        for (ServiceTerritory st : sts) ohs_ids.add(st.OperatingHoursId);

        //get OpeningHours for STS
        List<OperatingHours> ohs = [SELECT Id, Name, (SELECT Id, DayOfWeek, StartTime, EndTime FROM TimeSlots) FROM OperatingHours WHERE Id IN :ohs_ids];
        System.debug('ohs count:' + ohs.size());

        //IDs of TSs
        //List<String> tss_ids = new List<String>();
        //for (OperatingHours oh : ohs) tss_ids.add(oh.);

        List<String> rows = new List<String>();

        for (ServiceTerritory st : sts) {
            String row = '';
            row += st.Name + ';';
            row += (st.IsActive ? 'Y' : 'N') + ';';
            row += (st.Available_for_Click_Collect__c ? 'Y' : 'N') + ';';
            for (OperatingHours oh : ohs) {
                if (oh.Id == st.OperatingHoursId) {
                    //System.debug(st.Name + ': adding days for ' + oh.Name);
                    for (String day : days) {
                        row += getFromToForDay(oh, day) + ';';
                    }
                    break;
                }
            }
            rows.add(row);
        }

        for (String r : rows) {
            ret += r + '\n';
            System.debug(r);
        }
        ret = ret.substringBeforeLast('\n');

        return ret;
    }

    private static String getFromToForDay(OperatingHours oh, String day) {
        //System.debug('* getting timeslots for ' + oh.Name + ' for ' + day);
        for (TimeSlot ts : oh.TimeSlots) {
            if (ts.DayOfWeek == day && ts.StartTime != null && ts.EndTime != null) {
                return ('' + ts.StartTime + '00000000000').substring(0, 5) + '-' + ('' + ts.EndTime + '00000000000').substring(0, 5);
            }
        }

        return '';
    }

    public static String importAll(String content) {
        List<ServiceTerritory> sts = getAllServiceTerritories();

        //IDs of OHs
        List<String> ohs_ids = new List<String>();

        for (ServiceTerritory st : sts) ohs_ids.add(st.OperatingHoursId);


        List<String> rows = content.split('\n');

        List<ServiceTerritory> stToUpsert = new List<ServiceTerritory>();

        for (String row : rows) {
            System.debug('processing row ' + row);
            String[] data = row.split(';');

            if (data != null) {
                if (data.size() > 2) {
                    data[0] = data[0].trim();
                    ServiceTerritory exists = null;
                    for (ServiceTerritory st : sts) {
                        if (st.Name.trim().toLowerCase() == data[0].toLowerCase()) {
                            exists = st;
                            System.debug('found existing service territory ' + st.Name);
                            break;
                        }
                    }

                    if (exists == null) {
                        exists = new ServiceTerritory();
                        exists.Name = data[0];
                        System.debug('NEW service territory ' + data[0]);
                    }

                    OperatingHours oh;
                    if (exists.OperatingHoursId != null) {
                        oh = [SELECT Id, Name, (SELECT Id, DayOfWeek, StartTime, EndTime FROM TimeSlots) FROM OperatingHours WHERE Id = :exists.OperatingHoursId];
                    }
                    else {
                        oh = new OperatingHours();
                        oh.Name = data[0] + ' Opening Hours';
                        insert oh;
                    }

                    exists.OperatingHoursId = oh.Id;

                    exists.IsActive = data[1].trim().equalsIgnoreCase('y');
                    exists.Available_for_Click_Collect__c = data[2].trim().equalsIgnoreCase('y');

                    stToUpsert.add(exists);

                    upsert stToUpsert;

                    List<TimeSlot> tsToInsert = new List<TimeSlot>();

                    delete oh.TimeSlots;
                    for (Integer i = 0; i < days.size(); i++) {
                        if (data.size() > 3 + i) {
                            if (String.isNotBlank(data[3 + i]) && data[3 + i].trim().length() == 11) {

                                TimeSlot ts = new TimeSlot();
                                ts.OperatingHoursId = oh.Id;
                                ts.DayOfWeek = days[i];
                                ts.StartTime = Time.newInstance(Integer.valueOf(data[3 + i].substring(0, 2)), Integer.valueOf(data[3 + i].substring(3, 5)), 0, 0);
                                ts.EndTime = Time.newInstance(Integer.valueOf(data[3 + i].substring(6, 8)), Integer.valueOf(data[3 + i].substring(9)), 0, 0);
                                tsToInsert.add(ts);
                                //System.debug(exists.Name + ': added timeslot ' + days[i] + ' from ' + ts.StartTime + ' to ' + ts.EndTime);
                            }
                        }
                    }

                    insert tsToInsert;
                }
            }
        }
        return null;
    }

    private static List<ServiceTerritory> getAllServiceTerritories() {

        //get all Service Territories
        List<ServiceTerritory> sts = [
                SELECT Id,
                        Name,
                        OperatingHoursId,
                        IsActive,
                        Available_for_Click_Collect__c
                FROM ServiceTerritory
                ORDER BY Name
        ];

        System.debug('sts count:' + sts.size());
        return sts;
    }


}