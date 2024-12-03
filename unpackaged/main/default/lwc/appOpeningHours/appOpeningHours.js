/**
 * Created 12.11.2021..
 */

import {LightningElement} from 'lwc';
import getServiceTerritories from '@salesforce/apex/appOpeningHoursCtrl.getServiceTerritories';

export default class AppOpeningHours extends LightningElement {

    territories;
    workTypeGroups;
    wtgMembers;
    resourceSkills;

    connectedCallback() {
        this.retrieveAll();
    }

    retrieveAll() {
        console.log(':retrieveAll');

        getServiceTerritories()
            .then(results => {
                console.log('::getServiceTerritories:result', results);
                let result = JSON.parse(results);

                this.territories = result.territories;
                this.workTypeGroups = result.workTypeGroups;
                this.wtgMembers = result.wtgMembers;

                //make a structure for each serviceresource skill
                this.resourceSkills = {};
                for (let res of result.resources)
                {
                    this.resourceSkills[res.Id] = null;
                    if (res.ServiceResourceSkills && res.ServiceResourceSkills.records) {
                        for (let skill of res.ServiceResourceSkills.records) {
                            if (this.resourceSkills[res.Id] == null) this.resourceSkills[res.Id] = [];
                            this.resourceSkills[res.Id].push(skill.Skill.MasterLabel);
                        }
                    }
                }


                    //for each territory
                for (let st of this.territories) {
                    // console.log('---------------------------\nprocessing ' + st.serviceTerritory.Name);
                    delete st.attributes;
                    delete st.serviceTerritory.attributes;

                    if (st.serviceTerritory.OperatingHours)
                    {
                        st.serviceTerritory.OperatingHours.link = '/lightning/r/' + st.serviceTerritory.OperatingHours.Id + '/view';
                    }

                    for (let ts of st.timeSlots)
                    {
                        if (ts.StartTime && ts.StartTime.length>4) ts.StartTime = ts.StartTime.substring(0,5);
                        if (ts.EndTime && ts.EndTime.length>4) ts.EndTime = ts.EndTime.substring(0,5);
                    }

                    st.timeSlots.sort(function(a, b) {
                        if (a.DayOfWeek === 'Monday') return 1;
                        if (a.DayOfWeek === 'Tuesday') return 2;
                        if (a.DayOfWeek === 'Wednesday') return 3;
                        if (a.DayOfWeek === 'Thursday') return 4;
                        if (a.DayOfWeek === 'Friday') return 5;
                        if (a.DayOfWeek === 'Saturday') return 6;
                        if (a.DayOfWeek === 'Sunday') return 7;
                        return 0;
                    });

                    st.serviceTerritory.url = '/lightning/r/' + st.serviceTerritory.Id + '/view';

                    st.wtgs = [];
                    // for each work type group
                    for (let wtg of this.workTypeGroups) {
                        // console.log(' - looking for group ' + wtg.Name + ' (' + wtg.Id + ')');
                        delete wtg.attributes;

                        let found = null;
                        let hours = null;
                        let hoursurl = null;
                        // find which work types of this territory belong in this group
                        for (let member of this.wtgMembers) {
                            delete member.attributes;
                            if (member.WorkTypeGroupId === wtg.Id) {
                                // console.log(' --- found a member of this group:' + member.WorkType.Name + ' (' + member.WorkTypeId + ')');
                                for (let stWTG of st.stWorkTypes) {
                                    delete stWTG.attibutes;
                                    // console.log(' ---?? comparing with stWTG.WorkTypeId: ' + stWTG.WorkTypeId + ' = ' + (member.WorkTypeId === stWTG.WorkTypeId));
                                    // if ST has a work type in this group, push the group to st info
                                    if (member.WorkTypeId === stWTG.WorkTypeId) {
                                        // console.log(' ----- stWTG.WorkTypeId matched: ' + stWTG.WorkType.Name);
                                        if (found == null) found = '';
                                        found += '['+stWTG.WorkType.Name + '] ';
                                        if (stWTG.WorkType.OperatingHours)
                                        {
                                            hours = stWTG.WorkType.OperatingHours.Name;
                                            hoursurl = '/lightning/r/' + stWTG.WorkType.OperatingHours.Id + '/view';
                                        }
                                    }
                                }
                                // console.log('cur found: ' + found);
                            }
                        }

                        st.wtgs.push({
                            group: wtg.Name,
                            found: found,
                            hours: hours,
                            hoursurl: hoursurl,
                        });
                    }


                    if (st.serviceTerritory.ServiceResources && st.serviceTerritory.ServiceResources.records)
                    {
                        st.serviceTerritory.resources = st.serviceTerritory.ServiceResources.records;
                    }
                    else st.serviceTerritory.resources = [];

                    for (let sr of st.serviceTerritory.resources)
                    {
                        sr.link = '/lightning/r/' + sr.ServiceResource.Id + '/view';
                        sr.inactive = (sr.ServiceResource.IsActive !== true) ;
                        sr.skills = this.resourceSkills[sr.ServiceResource.Id];
                    }
                }

                console.log('territories', this.territories);
                console.log('workTypeGroups', this.workTypeGroups);
                console.log('wtgMembers', this.wtgMembers);
                console.log('resourceSkills', this.resourceSkills);

            })
            .catch(error => {
                console.error('::getServiceTerritories:failed', error);

            })
            .finally(() => {

            });
    }
}