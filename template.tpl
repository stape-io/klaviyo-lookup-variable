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
  "description": "Retrieve the user profile from Klaviyo using the identifier (_kx).",
  "containerContexts": [
    "SERVER"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "apiKey",
    "displayName": "Api Key",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
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
        "displayValue": "All user_data"
      }
    ],
    "simpleValueType": true
  },
  {
    "displayName": "Logs Settings",
    "name": "logsGroup",
    "groupStyle": "ZIPPY_CLOSED",
    "type": "GROUP",
    "subParams": [
      {
        "type": "RADIO",
        "name": "logType",
        "radioItems": [
          {
            "value": "no",
            "displayValue": "Do not log"
          },
          {
            "value": "debug",
            "displayValue": "Log to console during debug and preview"
          },
          {
            "value": "always",
            "displayValue": "Always log to console"
          }
        ],
        "simpleValueType": true,
        "defaultValue": "debug"
      }
    ]
  }
]


___SANDBOXED_JS_FOR_SERVER___

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
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "all"
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
              },
              {
                "type": 1,
                "string": "event_name"
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
        "publicId": "read_request",
        "versionId": "1"
      },
      "param": [
        {
          "key": "headerWhitelist",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "headerName"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "trace-id"
                  }
                ]
              }
            ]
          }
        },
        {
          "key": "headersAllowed",
          "value": {
            "type": 8,
            "boolean": true
          }
        },
        {
          "key": "requestAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "headerAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "queryParameterAccess",
          "value": {
            "type": 1,
            "string": "any"
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
        "publicId": "read_container_data",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  }
]


___TESTS___

scenarios: []


___NOTES___

Created on 17.10.2022 14.30.57


