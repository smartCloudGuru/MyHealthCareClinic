import persistBasket from '@salesforce/apex/onl_CheckoutCtrl.saveBasket';

/* COOKIE handling */
const cookie_length = 1 * 24 * 60 * 60 * 1000; // 1 day
const basketIdCookieName = 'basket_id';

/* BASKET */
let basket = [];
let basket_count = 0;
let basket_sum = 0;
let basketMessage = null;

/**
 * Called when [add to basket] button is pressed
 * @param detail example: {"product":{"attributes":{"type":"PricebookEntry","url":"/services/data/v51.0/sobjects/PricebookEntry/01u3H000003xLc5QAE"},"Id":"01u3H000003xLc5QAE","UnitPrice":149,"Product2Id":"01t3H000000xB9RQAU","Product2":{"attributes":{"type":"Product2","url":"/services/data/v51.0/sobjects/Product2/01t3H000000xB9RQAU"},"Quantity_of_COVID_Tests__c":1,"Turnaround_Time__c":"48 hour","Product_Sub_Family__c":"PCR Test","Work_Type_Group__c":"0VS4H000000000YWAQ","Name":"PCR Test 48 Hours","Id":"01t3H000000xB9RQAU"}},"quantity":1}
 * @returns {string} basket as JSON
 */
function addToBasket(detail) {
    console.log('::basket:addToBasket', JSON.stringify(detail));

    if (detail.product) {
        delete detail.product.attributes;
        if (detail.product.Product2) delete detail.product.Product2.attributes;
    }

    // check if basket already contains this product
    let found = false;
    for (let item of basket) {
        if (item.product.Id === detail.product.Id) {
            //if already in basket, add quantity
            item.quantity += parseInt(detail.quantity);
            found = true;
            break;
        }
    }

    // if not found add to basket
    if (!found) {
        basket.push({
            product: detail.product,
            quantity: parseInt(detail.quantity)
        });
    }

    return recountBasket();
}

/**
 * Sets basket to object from given JSON. Used when loading basket from persistence. Recounts basket.
 * @param basketJSON
 */
function setBasket(basketJSON) {
    try {
        if (basketJSON)
            basket = JSON.parse(basketJSON);
        else basket = [];
    } catch (e) {
        console.error('unable to parse loaded basket JSON', e);
        basket = [];
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
    if (basket)
        for (let item of basket) {
            basket_count += item.quantity;
            basket_sum += (item.quantity * item.product.UnitPrice);
        }

    let basket_json = JSON.stringify(basket);
    console.log('::basket', basket_json, basket_count, basket_sum);
    return basket_json;
}

function getBasketCount() {
    return basket_count;
}

function getBasket() {
    return basket;
}

/**
 * Stores basket ID to cookies
 * */
function storeBasketIdToCookie(value) {

    let currentValue = getBasketIdFromCookie();

    // console.log('::cookies:current_basket_id:', currentValue);
    // console.log('::cookies:new_basket_id:', value);

    //if cookie already exists, extend it
    if (currentValue) value = currentValue;

    const date = new Date();
    date.setTime(date.getTime() + cookie_length);
    let expires = '; expires=' + date.toGMTString();
    document.cookie = basketIdCookieName + '=' + escape(value) + expires + '; path=/';

    console.log('cookie after storing:', getBasketIdFromCookie());
}

/**
 * Retrieves basket_id from cookies, or null if it's not set
 * @returns {string|null}
 */
function getBasketIdFromCookie() {
    console.log('::basket:getBasketIdFromCookie:document.cookie', document.cookie);
    let cookieString = '; ' + document.cookie;
    let parts = cookieString.split('; ' + basketIdCookieName + '=');
    if (parts.length === 2) {
        let ret = parts.pop().split(';').shift();
        if (ret === '') return null;
        return ret;
    }
    return null;
}

function clearBasketIdCookie() {
    document.cookie = basketIdCookieName + '=; path=/';
    console.log('cleared basketid', getBasketIdFromCookie())
}

export {
    addToBasket,
    setBasket,
    getBasketCount,
    getBasket,
    storeBasketIdToCookie,
    getBasketIdFromCookie,
    clearBasketIdCookie
};