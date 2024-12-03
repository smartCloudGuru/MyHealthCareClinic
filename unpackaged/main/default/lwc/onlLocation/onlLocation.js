/**
 * Created 14.3.2021..
 */

import {api, LightningElement} from 'lwc';

export default class OnlLocation extends LightningElement {

    @api serviceTerritory;
    @api loc;
    @api dontShowDistance;
    @api allOneLine;

    name;
    city;
    postalCode;
    street;
    distance;

    get distanceFormatted()
    {
        try{
            let d = parseInt(this.distance);
            if (d<=1) return "nearby";
        }
        catch (e)
        {

        }
        return this.distance + " miles away";

    }

    connectedCallback() {
        if (this.serviceTerritory) {
            this.name = this.serviceTerritory.Name;
            if (this.serviceTerritory.Address) {
                this.city = this.serviceTerritory.Address.city;
                this.postalCode = this.serviceTerritory.Address.postalCode;
                this.street = this.serviceTerritory.Address.street;
            }
        } else if (this.loc) {
            //console.log('loc', JSON.stringify(this.loc));
            if (this.loc.name) {
                this.name = this.loc.name;
                this.city = this.loc.city;
                this.postalCode = this.loc.postalCode;
                this.street = this.loc.street;
                this.distance = this.loc.distance;
            }
            else if (this.loc.Name)
            {
                this.name = this.loc.Name;
                this.city = this.loc.City;
                this.postalCode = this.loc.PostalCode;
                this.street = this.loc.Street;
            }
        }
    }
}