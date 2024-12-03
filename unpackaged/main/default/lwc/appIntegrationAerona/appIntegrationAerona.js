/**
 * Created by Matija on 4.9.2023..
 */

import {LightningElement} from 'lwc';

import aeronaGetAllClinicians from '@salesforce/apex/AppIntegrationController.aeronaGetAllClinicians';

export default class AppIntegrationAerona extends LightningElement {

    getCliniciansResponse = null;

    handleGetClinicians()
    {
        aeronaGetAllClinicians()
            .then(results => {
                console.log('::aeronaGetAllClinicians:results', results)
                this.result = JSON.parse(results);
                this.getCliniciansResponse = results
                    .replaceAll("{\"id\":","<br/>")
                    .replaceAll(",\"clinicianName\":\""," = ")
                    .replaceAll("{\"id\":","<br/>")
                    .replaceAll("\":[\"","<br/>")
                    .replaceAll("\"},","")
                    .replaceAll("\"}],\"","<br/><br/>")
                    .replaceAll("]","")
                    .replaceAll("[","")
                    .replaceAll("[","")
                    .replaceAll("}","")
                    .replaceAll("{","")
                    .replaceAll("\"","")
            })
            .catch(error => {
                console.error('::aeronaGetAllClinicians:failed', error);
            })
            .finally(() => {

            });
    }
}