/* COOKIE handling */
const cookie_length = 1 * 24 * 60 * 60 * 1000; // 1 day
const basketIdCookieName = 'bid';
const opportunityIdCookieName = 'oid';

/* BASKET */
let basket = [];
let basket_count = 0;
let basket_sum = 0;
let basketMessage = null;

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

function getBasketHasCoupon() {
    if (basket)
    for (let item of basket) {
        if (item.coupon) return true;
    }
    return false;
}

function getCurrentCouponName() {
    if (basket)
        for (let item of basket) {
            if (item.coupon) return item.coupon.Name;
        }
    return '';
}

function addCoupon(coupon) {
    if (!coupon) return false;
    // check if basket already contains a coupon
    if (getBasketHasCoupon()) return false;

    delete coupon.attributes;

    basket.push({
        id: coupon.Id,
        coupon: coupon,
        type: 'coupon'
    });

    recountBasket();

    return true;
}

/**
 * Sets basket to object from given JSON. Used when loading basket from persistence. Recounts basket.
 * @param basketJSON
 */
function setBasket(basketJSON) {
    // console.log('::basket:setBasket', basketJSON);
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

function getBasketHasCovidTests() {
    if (basket) {
        for (let item of basket) {
            if (item.type === 'covid') return true;
        }
    }
    return false;
}

function getBasketRequiresDelivery() {
    if (basket) {
        for (let item of basket) {
            if (item.delivery) return true;
        }
    }
    return false;
}

function getBasketRequiresScheduling() {
    if (basket) {
        for (let item of basket) {
            if (item.scheduling) return true;
        }
    }
    return false;
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


function removeFromBasket(id) {
    // console.log('::basket:removeFromBasket:id', id);
    if (basket) {
        basket = basket.filter(function (i) {
            return (i.id !== id);
        });

        basket = JSON.parse(JSON.stringify(basket));
    } else basket = [];

    recountBasket();
}

function getBasketCount() {
    return basket_count;
}

function getBasketSum() {
    return basket_sum;
}

function getBasket() {
    return basket;
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
 * Stores opportunityId ID to cookies
 * */
function storeOpportunityIdToCookie(value) {
    let currentValue = getOpportunityIdFromCookie();

    //if cookie already exists, extend it
    if (currentValue) value = currentValue;

    const date = new Date();
    date.setTime(date.getTime() + cookie_length);
    let expires = '; expires=' + date.toGMTString();
    document.cookie = opportunityIdCookieName + '=' + escape(value) + expires + '; path=/';

    // console.log('cookie after storing:', getBasketIdFromCookie());
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
 * Retrieves opportunityId from cookies, or null if it's not set
 * @returns {string|null}
 */
function getOpportunityIdFromCookie() {
    let cookieString = '; ' + document.cookie;
    let parts = cookieString.split('; ' + opportunityIdCookieName + '=');
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

function clearOpportunityIdCookie() {
    document.cookie = opportunityIdCookieName + '=; path=/';
    console.log('cleared opportunityIdCookie', getOpportunityIdFromCookie())
}

export {
    addToBasket,
    setBasket,
    getBasketCount,
    getBasketSum,
    getBasket,
    storeBasketIdToCookie,
    storeOpportunityIdToCookie,
    getBasketIdFromCookie,
    getOpportunityIdFromCookie,
    clearBasketIdCookie,
    clearOpportunityIdCookie,
    getBasketHasCovidTests,
    getBasketRequiresScheduling,
    getBasketRequiresDelivery,
    removeFromBasket,
    addCoupon,
    getBasketHasCoupon,
    getCurrentCouponName
};