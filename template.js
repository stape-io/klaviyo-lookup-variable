const encodeUriComponent = require('encodeUriComponent');
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

const API_VERSION = '2026-04-15';
let _kx = '';
const pageUrl = getEventData('page_location');

if (pageUrl && pageUrl.indexOf('_kx=') !== -1) {
  const parsedUrl = parseUrl(pageUrl);
  _kx = parsedUrl.searchParams._kx;
} else {
  let kxCookie = getCookieValues('stape_klaviyo_kx');
  if (kxCookie.length) _kx = kxCookie[0];
}

if (_kx) {
  if (templateDataStorage.getItemCopy(_kx)) {
    const storedData = JSON.parse(templateDataStorage.getItemCopy(_kx));

    if (data.output === 'email') {
      return storedData.email;
    }

    return storedData;
  } else {
    const url = 'https://a.klaviyo.com/api/profiles/?filter=equals(_kx,"' + enc(_kx) + '")';

    return sendHttpGet(url, {
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
}

return undefined;

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
