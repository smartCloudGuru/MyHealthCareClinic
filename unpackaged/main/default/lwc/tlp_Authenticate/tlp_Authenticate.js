/**
 * Created 2.4.2024..
 */

import {api, LightningElement} from 'lwc';

import checkAccessKey from '@salesforce/apex/TLPController.checkAccessKey';

export default class TLPAuthenticate extends LightningElement {
    @api queryParameters;
    @api storeConfig;

    loading;
    success;
    error;
    msgError;

    noAccess;

    handleProceed(e) {
        this.noAccess = false;
        let accKey = this.template.querySelector('[data-formfield="accKey"]');

        if (accKey) {
            if (!accKey.reportValidity()) return;

            this.loading = true;

            checkAccessKey({accessKey: accKey.value})
                .then(results => {
                        console.log('::checkAccessKey:result', results);
                        if (!results) {
                            this.loading = false;
                            this.noAccess = true;
                        } else {
                            this.setCookie('tlcsession', results, 12);
                            this.dispatchEvent(new CustomEvent('authok'));
                        }
                    }
                )
                .catch(error => {
                    console.error('::checkAccessKey:failed', error);
                    this.loading = false;
                })
                .finally(() => {

                });
        }
    }

    getCookie(cname) {
        let name = cname + "=";
        let ca = document.cookie.split(';');
        for (let i = 0; i < ca.length; i++) {
            let c = ca[i];
            while (c.charAt(0) === ' ') {
                c = c.substring(1);
            }
            if (c.indexOf(name) === 0) {
                return c.substring(name.length, c.length);
            }
        }
        return "";
    }


    setCookie(cname, cvalue, exhours) {
        let d = new Date();
        d.setTime(d.getTime() + (exhours * 60 * 60 * 1000));
        let expires = "expires=" + d.toUTCString();
        document.cookie = cname + "=" + cvalue + ";" + expires + ";path=/";
    }
}