const encodeUriComponent = require('encodeUriComponent');
const fromBase64 = require('fromBase64');
const getCookieValues = require('getCookieValues');
const getEventData = require('getEventData');
const getType = require('getType');
const JSON = require('JSON');
const makeString = require('makeString');
const parseUrl = require('parseUrl');
const sendHttpGet = require('sendHttpGet');
const templateDataStorage = require('templateDataStorage');

/*==============================================================================
==============================================================================*/

const userProvidedValidEmail = isValidEmailAddress(data.userProvidedEmail);

if (data.output === 'email' && data.skipApiCallForKnownEmail && userProvidedValidEmail) {
  return toLowerCaseIfDefined(data.userProvidedEmail).trim();
}

const API_VERSION = '2026-07-15';
const _kx = parseKx();

if (!_kx) return undefined;

let storedData = templateDataStorage.getItemCopy(_kx);
if (storedData) {
  storedData = JSON.parse(storedData);
  if (data.output === 'email') {
    return storedData.email;
  }
  return storedData;
} else {
  const requestUrl = 'https://a.klaviyo.com/api/profiles/?filter=equals(_kx,"' + enc(_kx) + '")';
  return sendHttpGet(requestUrl, {
    headers: {
      Authorization: 'Klaviyo-API-Key ' + data.apiKey,
      accept: 'application/json',
      revision: API_VERSION
    },
    timeout: 3000
  })
    .then((result) => {
      if (result.statusCode === 200) {
        const responseBody = JSON.parse(result.body);
        if (responseBody.data.length === 1) {
          const attributes = responseBody.data[0].attributes;
          const klaviyo_user_data = {
            email: toLowerCaseIfDefined(attributes.email),
            phone_number: attributes.phone_number,
            address: [
              {
                first_name: toLowerCaseIfDefined(attributes.first_name),
                last_name: toLowerCaseIfDefined(attributes.last_name)
              }
            ]
          };
          if (attributes.location) {
            klaviyo_user_data.address[0].street = toLowerCaseIfDefined(
              attributes.location.address1
            );
            klaviyo_user_data.address[0].city = toLowerCaseIfDefined(attributes.location.city);
            klaviyo_user_data.address[0].postal_code = attributes.location.zip;
            klaviyo_user_data.address[0].country = toLowerCaseIfDefined(
              attributes.location.country
            );
          }
          templateDataStorage.setItemCopy(_kx, JSON.stringify(klaviyo_user_data));

          if (data.output === 'email') {
            return klaviyo_user_data.email;
          }

          return klaviyo_user_data;
        }
      }

      return undefined;
    })
    .catch(() => undefined);
}

/*==============================================================================
  Vendor related functions
==============================================================================*/

function parseKx() {
  const urlSearchParams = (parseUrl(getEventData('page_location')) || {}).searchParams;
  const kxFromUrl = urlSearchParams && urlSearchParams['_kx'];
  if (kxFromUrl) return kxFromUrl;

  const kxFromStapeCookie = getCookieValues('stape_klaviyo_kx')[0];
  if (kxFromStapeCookie) return kxFromStapeCookie;

  const klaIdCookie = getCookieValues('__kla_id')[0];
  if (klaIdCookie) {
    const klaId = JSON.parse(fromBase64(klaIdCookie) || '{}');
    if (getType(klaId) === 'object' && klaId['$exchange_id']) {
      return klaId['$exchange_id'];
    }
  }
}

/*==============================================================================
  Helpers
==============================================================================*/

function toLowerCaseIfDefined(value) {
  return value ? value.toLowerCase() : value;
}

function enc(data) {
  if (['null', 'undefined'].indexOf(getType(data)) !== -1) data = '';
  return encodeUriComponent(makeString(data));
}

function isValidEmailAddress(email) {
  if (getType(email) !== 'string') return false;
  return !!email.trim().match('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$');
}
