const sendHttpGet = require('sendHttpGet');
const JSON = require('JSON');
const logToConsole = require('logToConsole');
const templateDataStorage = require('templateDataStorage');
const getEventData = require('getEventData');
const parseUrl = require('parseUrl');
const getRequestHeader = require('getRequestHeader');
const getContainerVersion = require('getContainerVersion');
const encodeUriComponent = require('encodeUriComponent');
const getCookieValues = require('getCookieValues');

const isLoggingEnabled = determinateIsLoggingEnabled();
const traceId = isLoggingEnabled ? getRequestHeader('trace-id') : undefined;

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

    if (isLoggingEnabled) {
      logToConsole(
        JSON.stringify({
          Name: 'KlaviyoLookup',
          Type: 'Request',
          TraceId: traceId,
          EventName: 'Lookup',
          RequestMethod: 'GET',
          RequestUrl: url,
        })
      );
    }

    return sendHttpGet(url, {
      headers: {
        'Authorization': 'Klaviyo-API-Key ' + data.apiKey,
        'accept': 'application/json',
        'revision': '2024-07-15',
      },
      timeout: 3000,
    }).then((result) => {
      if (isLoggingEnabled) {
        logToConsole(
          JSON.stringify({
            Name: 'KlaviyoLookup',
            Type: 'Response',
            TraceId: traceId,
            EventName: 'Lookup',
            ResponseStatusCode: result.statusCode,
            ResponseHeaders: result.headers,
            ResponseBody: result.body,
          })
        );
      }

      if (result.statusCode === 200) {
        const responseBody = JSON.parse(result.body);
        if (responseBody.data.length === 1) {
          const attributes = responseBody.data[0].attributes;
          const klaviyo_user_data = {
            'email': toLowerCaseIfDefined(attributes.email),
            'phone_number': attributes.phone_number,
            'address': [{
              'first_name': toLowerCaseIfDefined(attributes.first_name),
              'last_name': toLowerCaseIfDefined(attributes.last_name),
            }]
          };
          if (attributes.location) {
            klaviyo_user_data.address[0].street = toLowerCaseIfDefined(attributes.location.address1);
            klaviyo_user_data.address[0].city = toLowerCaseIfDefined(attributes.location.city);
            klaviyo_user_data.address[0].postal_code = attributes.location.zip;
            klaviyo_user_data.address[0].country = toLowerCaseIfDefined(attributes.location.country);
          }
          templateDataStorage.setItemCopy(_kx, JSON.stringify(klaviyo_user_data));

          if (data.output === 'email') {
            return klaviyo_user_data.email;
          }

          return klaviyo_user_data;
        }
      }

      return undefined;
    }).catch(() => undefined);
  }
}

return undefined;

function toLowerCaseIfDefined(value) {
  return value ? value.toLowerCase() : value;
}

function enc(data) {
  data = data || '';
  return encodeUriComponent(data);
}

function determinateIsLoggingEnabled() {
  const containerVersion = getContainerVersion();
  const isDebug = !!(containerVersion && (containerVersion.debugMode || containerVersion.previewMode));

  if (!data.logType) {
    return isDebug;
  }

  if (data.logType === 'no') {
    return false;
  }

  if (data.logType === 'debug') {
    return isDebug;
  }

  return data.logType === 'always';
}
