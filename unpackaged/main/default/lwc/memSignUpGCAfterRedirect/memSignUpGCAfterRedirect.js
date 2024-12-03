/**
 * Created 15.9.2022..
 */

import {api, LightningElement} from 'lwc';


import completeRedirectFlow from '@salesforce/apex/memSignUpCtrl.aura_completeRedirectFlow';

export default class MemSignUpGcAfterRedirect extends LightningElement {

    @api queryParameters;
    @api config;

    loading = true;
    success;
    error;
    msgError;

    connectedCallback() {
        //console.log(this.queryParameters.redirect_flow_id);

        let flowId = this.queryParameters.redirect_flow_id;
        if (!flowId)
        {
            this.msgError = 'The page you requested does not exist';
            this.loading = false;
            this.error = true;
        }

        completeRedirectFlow({flowId: flowId})
            .then(results => {
                //console.log('::completeRedirectFlow:results', results);
                if (results) {
                    if (!results)
                    {
                        console.error('::completeRedirectFlow:results null', results);
                        this.error = true;
                    }
                    else if (results.indexOf('ERR_')>=0)
                    {
                        console.error('::completeRedirectFlow:results ERR', results);
                        this.error = true;
                    }
                    else {
                        let res = JSON.parse(results);
                        if (res?.session_token) this.success = true;
                    }
                }

            })
            .catch(error => {
                console.error('::completeRedirectFlow:failed', error);
                this.error = true;
                if (error && error.body)
                {
                    if ('ERR_INVALID_FLOW_ID' === error.body.message)
                    {
                        this.msgError = 'The page you requested does not exist';
                    }
                    else if ('ERR_EXT' === error.body.message)
                    {
                        this.msgError = 'Unable to communicate to the external system';
                    }
                    else if ('ERR_NO_MANDATE' === error.body.message)
                    {
                        this.msgError = 'Unable to create a mandate for your direct debit. The link you used may have expired';
                    }
                }
            })
            .finally(() => {
                this.loading = false;
            });
    }
}