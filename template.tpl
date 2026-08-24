___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "type": "MACRO",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "Klaviyo Lookup",
  "description": "Retrieve the user profile from Klaviyo using the identifier Klaviyo Exchange ID (_kx).",
  "containerContexts": [
    "SERVER"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "apiKey",
    "displayName": "Private API Key",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ],
    "help": "Follow this guide if you don\u0027t know \u003ca href\u003d\"https://help.klaviyo.com/hc/en-us/articles/115005062267-How-to-Manage-Your-Account-s-API-Keys#find-your-api-keys1\" target\u003d\"_blank\"\u003eHow to Find your API Key\u003c/a\u003e"
  },
  {
    "type": "RADIO",
    "name": "output",
    "displayName": "Output",
    "radioItems": [
      {
        "value": "email",
        "displayValue": "Email"
      },
      {
        "value": "user_data",
        "displayValue": "All User Data"
      }
    ],
    "simpleValueType": true
  }
]


___SANDBOXED_JS_FOR_SERVER___

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


___SERVER_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "send_http",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedUrls",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "urls",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "https://a.klaviyo.com/api/profiles/*"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_template_storage",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_event_data",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keyPatterns",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "page_location"
              }
            ]
          }
        },
        {
          "key": "eventDataAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "get_cookies",
        "versionId": "1"
      },
      "param": [
        {
          "key": "cookieAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "cookieNames",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "stape_klaviyo_kx"
              },
              {
                "type": 1,
                "string": "_kx"
              },
              {
                "type": 1,
                "string": "__kla_id"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios: []


___NOTES___

2026-08-21 Change Notes:
 - Add __kla_id cookie fallback for _kx identifier detection.

2026-05-21 Change Notes:
 - Console logging removal.
 - Update API version to 2026-04-15.

Created on 17.10.2022 14.30.57

