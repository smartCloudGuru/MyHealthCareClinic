/* COOKIE handling */
const cookie_length = 1 * 24 * 60 * 60 * 1000; // 1 day
const ref_cookie_length = 3 * 60 * 60 * 1000; // 3 hrs
const ruler_cookie_length = 24 * 60 * 60 * 1000; // 24 hrs
const consent_cookie_length = 365 * 24 * 60 * 60 * 1000; // 1 year
const console_length = 7 * 24 * 60 * 60 * 1000; // 7 days
const lead_length  = 6 * 60 * 60 * 1000; // 6 hrs
const ptUUIDIdCookieName = 'ptu';
const basketIdCookieName = 'bid';
const consoleCookieName = 'console';
const refCookieName = 'ref';
const rulerCookieName = 'rasash';
const consentCookieName = 'consent';
const leadCookieName = 'qpld';

/* BASKET */
let basket = [];
let basket_count = 0;
let basket_sum = 0;

/**
 * Called when [add to basket] button is pressed
 * @param detail
 * @returns {string} basket as JSON
 */
function addToBasket(detail) {
    console.log('::basket:addToBasket', JSON.stringify(detail));

    if (detail.product) {
        delete detail.product.attributes;
    }

    // check if basket already contains this product
    let found = false;
    for (let item of basket) {
        if (item.id === detail.product.Id) {
            //if already in basket, add quantity
            item.quantity += parseInt(detail.quantity);
            found = true;
            break;
        }
    }

    let delivery = detail.product && (detail.product.Requires_delivery__c === true);

    let scheduling = detail.product && (detail.product.Requires_scheduling__c === true);

    // if not found add to basket
    if (!found) {
        basket.push({
            id: detail.product.Id,
            product: detail.product,
            quantity: parseInt(detail.quantity),
            type: detail.product.type,
            delivery: delivery,
            scheduling: scheduling
        });
    }

    recountBasket();
}


/**
 * Recounts items in basket
 * @returns {string} basket as JSON
 */
function recountBasket() {
    basket_count = 0;
    basket_sum = 0;

    sortBasket();

    if (basket) {
        for (let item of basket) {
            if (item.product) {
                basket_count += item.quantity;
                item.totalPrice = (item.quantity * item.product.Non_Membership_Price__c)
                basket_sum += item.totalPrice;
            }
        }
    }

    // sort basket so that coupon is at the end

    // console.log('::basket:recountBasket:basket_count', basket_count)
}

function sortBasket() {
    if (basket) basket.sort((a, b) => {
        if (a.type === 'coupon') {
            return 1;
        }
        if (b.type === 'coupon') {
            return -1;
        }
        return 0;
    });
}


/**
 * Stores basket ID to cookies
 * */
function storeBasketIdToCookie(value) {
    let currentValue = getBasketIdFromCookie();

    //if cookie already exists, extend it
    if (currentValue) value = currentValue;

    const date = new Date();
    date.setTime(date.getTime() + cookie_length);
    let expires = '; expires=' + date.toGMTString();
    document.cookie = basketIdCookieName + '=' + escape(value) + expires + '; path=/';

    // console.log('cookie after storing:', getBasketIdFromCookie());
}

/**
 * Stores basket ID to cookies
 * */
function storeLoggedInToCookie(value) {
    let currentValue = getLoggedInCookie();

    //if cookie already exists, extend it
    if (currentValue) value = currentValue;

    const date = new Date();
    date.setTime(date.getTime() + cookie_length);
    let expires = '; expires=' + date.toGMTString();
    document.cookie = ptUUIDIdCookieName + '=' + value + expires + '; path=/';

    //console.log('cookie after storing:', getLoggedInCookie());
}

function storeReferralCookie(value) {

    const date = new Date();
    date.setTime(date.getTime() + ref_cookie_length);
    let expires = '; expires=' + date.toGMTString();
    document.cookie = refCookieName + '=' + value + expires + '; path=/';
}

function storeRulerCookie(value) {

    const date = new Date();
    date.setTime(date.getTime() + ruler_cookie_length);
    let expires = '; expires=' + date.toGMTString();
    document.cookie = rulerCookieName + '=' + value + expires + '; path=/';
}

function storeLeadCookie(value) {

    const date = new Date();
    date.setTime(date.getTime() + lead_length);
    let expires = '; expires=' + date.toGMTString();
    document.cookie = leadCookieName + '=' + value + expires + '; path=/';
}

function storeConsentCookie(value) {

    const date = new Date();
    date.setTime(date.getTime() + consent_cookie_length);
    let expires = '; expires=' + date.toGMTString();
    document.cookie = consentCookieName + '=' + JSON.stringify(value) + expires + '; path=/';

    //console.log('cookie after storing:', getReferralCookie());
}

/**
 * enables console mode
 * */
function enableConsoleOutput(mode) {
    const date = new Date();
    date.setTime(date.getTime() + console_length);
    let expires = '; expires=' + date.toGMTString();
    document.cookie = consoleCookieName + '=' + mode + expires + '; path=/';
}

/**
 * Retrieves basket_id from cookies, or null if it's not set
 * @returns {string|null}
 */
function getBasketIdFromCookie() {
    // console.log('::basket:getBasketIdFromCookie:document.cookie', document.cookie);
    let cookieString = '; ' + document.cookie;
    let parts = cookieString.split('; ' + basketIdCookieName + '=');
    if (parts.length === 2) {
        let ret = parts.pop().split(';').shift();
        if (ret === '') return null;
        return ret;
    }
    return null;
}

/**
 * Retrieves patient_uuid from cookies, or null if it's not set
 * @returns {string|null}
 */
function getLoggedInCookie() {
    let cookieString = '; ' + document.cookie;
    let parts = cookieString.split('; ' + ptUUIDIdCookieName + '=');
    if (parts.length === 2) {
        let ret = parts.pop().split(';').shift();
        if (ret === '') return null;
        return ret;
    }
    return null;
}

function getReferralCookie() {
    let cookieString = '; ' + document.cookie;
    let parts = cookieString.split('; ' + refCookieName + '=');
    if (parts.length === 2) {
        let ret = parts.pop().split(';').shift();
        if (ret === '') return null;
        return ret;
    }
    return null;
}

function getRulerCookie() {
    let cookieString = '; ' + document.cookie;
    let parts = cookieString.split('; ' + rulerCookieName + '=');
    if (parts.length === 2) {
        let ret = parts.pop().split(';').shift();
        if (ret === '') return null;
        return ret;
    }
    return null;
}

function getLeadCookie() {
    let cookieString = '; ' + document.cookie;
    let parts = cookieString.split('; ' + leadCookieName + '=');
    if (parts.length === 2) {
        let ret = parts.pop().split(';').shift();
        if (ret === '') return null;
        return ret;
    }
    return null;
}

function getConsentCookie() {
    let cookieString = '; ' + document.cookie;
    let parts = cookieString.split('; ' + consentCookieName + '=');
    if (parts.length === 2) {
        let ret = parts.pop().split(';').shift();
        if (ret === '') return null;
        return ret;
    }
    return null;
}


/**
 * Retrieves basket_id from cookies, or null if it's not set
 */
function getConsoleOutput() {
    // console.log('::basket:getBasketIdFromCookie:document.cookie', document.cookie);
    let cookieString = '; ' + document.cookie;
    let parts = cookieString.split('; ' + consoleCookieName + '=');
    if (parts.length === 2) {
        let ret = parts.pop().split(';').shift();
        if (ret === '') return null;
        return ret;
    }
    return null;
}


function clearBasketIdCookie() {
    document.cookie = basketIdCookieName + '=; path=/';
    console.log('cleared basketIdCookie', getBasketIdFromCookie())
}

function clearLoggedInCookie() {
    document.cookie = ptUUIDIdCookieName + '=; path=/';
}

export {
    addToBasket,
    storeBasketIdToCookie,
    getBasketIdFromCookie,
    clearBasketIdCookie,
    enableConsoleOutput,
    getConsoleOutput,
    getLoggedInCookie,
    clearLoggedInCookie,
    storeLoggedInToCookie,
    storeReferralCookie,
    storeRulerCookie,
    getReferralCookie,
    getRulerCookie,
    storeLeadCookie,
    getLeadCookie,
    storeConsentCookie,
    getConsentCookie
};