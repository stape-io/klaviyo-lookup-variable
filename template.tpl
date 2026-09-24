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
  },
  {
    "type": "CHECKBOX",
    "name": "skipApiCallForKnownEmail",
    "checkboxText": "Skip API call for known email",
    "simpleValueType": true,
    "enablingConditions": [
      {
        "paramName": "output",
        "paramValue": "email",
        "type": "EQUALS"
      }
    ],
    "help": "Check this box to provide an email and skip the API call. If the input is not recognized as a valid email address the variable will behave normally and will perform the API call.",
    "subParams": [
      {
        "type": "TEXT",
        "name": "userProvidedEmail",
        "displayName": "Email Address",
        "simpleValueType": true,
        "enablingConditions": [
          {
            "paramName": "skipApiCallForKnownEmail",
            "paramValue": true,
            "type": "EQUALS"
          }
        ],
        "valueValidators": [
          {
            "type": "NON_EMPTY"
          }
        ]
      }
    ]
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

scenarios:
- name: '[Skip API] Returns the normalized user provided email without any lookup'
  code: |-
    [
      { input: 'john.doe@example.com', expected: 'john.doe@example.com' },
      { input: '  John.Doe+Tag@Example.COM  ', expected: 'john.doe+tag@example.com' },
      { input: 'first_last%x-y@sub.domain.co.uk', expected: 'first_last%x-y@sub.domain.co.uk' }
    ].forEach((scenario) => {
      const copyMockData = createMockData({ userProvidedEmail: scenario.input });

      const variableResult = runCode(copyMockData);

      assertThat(variableResult).isEqualTo(scenario.expected);
    });

    assertApi('getEventData').wasNotCalled();
    assertApi('getCookieValues').wasNotCalled();
    assertApi('sendHttpGet').wasNotCalled();
- name: '[Skip API] Returns the user provided email even when no Exchange ID is available'
  code: |-
    pageLocation = 'https://example.com/';

    const variableResult = runCode(createMockData({ userProvidedEmail: 'john@example.com' }));

    assertThat(variableResult).isEqualTo('john@example.com');
    assertApi('sendHttpGet').wasNotCalled();
- name: '[Skip API] Falls back to the API lookup when the user provided email is invalid'
  code: |-
    const scenarios = [
      'not-an-email',
      'john@example',
      'john doe@example.com',
      '@example.com',
      '',
      '   ',
      'undefined',
      'null',
      undefined,
      null,
      123,
      true,
      { email: 'john@example.com' },
      ['john@example.com']
    ];

    scenarios.forEach((input) => {
      cleanup();

      runCode(createMockData({ userProvidedEmail: input })).then((variableResult) => {
        assertThat(variableResult).isEqualTo('john.doe@example.com');
      });
    });

    callLater(() => {
      assertThat(requestCount).isEqualTo(scenarios.length);
    });
- name: '[Skip API] Ignores the user provided email when the checkbox is unchecked'
  code: |-
    const copyMockData = createMockData({
      skipApiCallForKnownEmail: false,
      userProvidedEmail: 'stale@example.com'
    });

    runCode(copyMockData).then((variableResult) => {
      assertThat(variableResult).isEqualTo('john.doe@example.com');
    });

    callLater(() => {
      assertThat(requestCount).isEqualTo(1);
    });
- name: '[Skip API] Ignores the user provided email when output is All User Data'
  code: |-
    const copyMockData = createMockData({
      output: 'user_data',
      userProvidedEmail: 'john@example.com'
    });

    runCode(copyMockData).then((variableResult) => {
      assertThat(variableResult).isEqualTo(expectedUserData);
    });

    callLater(() => {
      assertThat(requestCount).isEqualTo(1);
    });
- name: '[API] Builds the request and returns the mapped user data'
  code: |-
    mock('sendHttpGet', (url, options) => {
      requestCount++;
      assertThat(url).isEqualTo('https://a.klaviyo.com/api/profiles/?filter=equals(_kx,"kx%20url")');
      assertThat(options).isEqualTo({
        headers: {
          Authorization: 'Klaviyo-API-Key pk_test_123',
          accept: 'application/json',
          revision: '2026-07-15'
        },
        timeout: 3000
      });
      return Promise.create((resolve) => resolve({ statusCode: 200, body: JSON.stringify(apiResponse) }));
    });

    runCode(createMockData({ output: 'user_data' })).then((variableResult) => {
      assertThat(variableResult).isEqualTo(expectedUserData);
    });

    callLater(() => {
      assertThat(requestCount).isEqualTo(1);
    });
- name: '[API] Returns the lowercased email when output is Email'
  code: |-
    runCode(createMockData()).then((variableResult) => {
      assertThat(variableResult).isEqualTo('john.doe@example.com');
    });

    callLater(() => {
      assertThat(requestCount).isEqualTo(1);
    });
- name: '[API] Omits location fields when the profile has no location'
  code: |-
    const attributes = apiResponse.data[0].attributes;
    Object.delete(attributes, 'location');

    runCode(createMockData({ output: 'user_data' })).then((variableResult) => {
      assertThat(variableResult).isEqualTo({
        email: 'john.doe@example.com',
        phone_number: '+15551234567',
        address: [{ first_name: 'john', last_name: 'doe' }]
      });
    });
- name: '[API] Caches the mapped user data under the Exchange ID'
  code: |-
    runCode(createMockData({ output: 'user_data' })).then(() => {
      assertThat(JSON.parse(cache['kx url'])).isEqualTo(expectedUserData);
    });
- name: '[API] Returns undefined and caches nothing on unsuccessful lookups'
  code: |-
    [
      () => Promise.create((resolve) => resolve({ statusCode: 401, body: '{}' })),
      () => Promise.create((resolve) => resolve({ statusCode: 200, body: JSON.stringify({ data: [] }) })),
      () => Promise.create((resolve) => resolve({
        statusCode: 200,
        body: JSON.stringify({ data: [apiResponse.data[0], apiResponse.data[0]] })
      })),
      () => Promise.create((resolve, reject) => reject({ reason: 'timed_out' }))
    ].forEach((response) => {
      mock('sendHttpGet', response);

      runCode(createMockData({ output: 'user_data' })).then((variableResult) => {
        assertThat(variableResult).isUndefined();
      });
    });

    callLater(() => {
      assertThat(cache).isEqualTo({});
    });
- name: '[Cache] Returns cached data without calling the API'
  code: |-
    cache['kx url'] = JSON.stringify(expectedUserData);

    assertThat(runCode(createMockData())).isEqualTo('john.doe@example.com');
    assertThat(runCode(createMockData({ output: 'user_data' }))).isEqualTo(expectedUserData);
    assertApi('sendHttpGet').wasNotCalled();
- name: '[Identifier] Falls back to the stape_klaviyo_kx cookie'
  code: |-
    pageLocation = 'https://example.com/?foo=bar';
    cookies.stape_klaviyo_kx = ['kx-stape'];
    cookies.__kla_id = [toBase64(JSON.stringify({ '$exchange_id': 'kx-kla' }))];

    mock('sendHttpGet', (url) => {
      assertThat(url).isEqualTo('https://a.klaviyo.com/api/profiles/?filter=equals(_kx,"kx-stape")');
      return Promise.create((resolve) => resolve({ statusCode: 200, body: JSON.stringify(apiResponse) }));
    });

    runCode(createMockData()).then((variableResult) => {
      assertThat(variableResult).isEqualTo('john.doe@example.com');
    });
- name: '[Identifier] Falls back to the Exchange ID in the __kla_id cookie'
  code: |-
    pageLocation = 'https://example.com/';
    cookies.__kla_id = [toBase64(JSON.stringify({ '$exchange_id': 'kx-kla' }))];

    mock('sendHttpGet', (url) => {
      assertThat(url).isEqualTo('https://a.klaviyo.com/api/profiles/?filter=equals(_kx,"kx-kla")');
      return Promise.create((resolve) => resolve({ statusCode: 200, body: JSON.stringify(apiResponse) }));
    });

    runCode(createMockData()).then((variableResult) => {
      assertThat(variableResult).isEqualTo('john.doe@example.com');
    });
- name: '[Identifier] Returns undefined without calling the API when no Exchange ID is found'
  code: |-
    [
      {},
      { __kla_id: [toBase64(JSON.stringify({ '$referrer': 'x' }))] }
    ].forEach((scenarioCookies) => {
      pageLocation = 'https://example.com/';
      cookies = scenarioCookies;

      assertThat(runCode(createMockData())).isUndefined();
    });

    assertApi('sendHttpGet').wasNotCalled();
setup: |-
  const JSON = require('JSON');
  const Promise = require('Promise');
  const callLater = require('callLater');
  const toBase64 = require('toBase64');
  const Object = require('Object');

  const assign = (target, source) => {
    Object.keys(source).forEach((key) => {
      target[key] = source[key];
    });
    return target;
  };

  const createMockData = (overrides) => {
    return assign(
      {
        apiKey: 'pk_test_123',
        output: 'email',
        skipApiCallForKnownEmail: true,
        userProvidedEmail: undefined
      },
      overrides || {}
    );
  };

  const apiResponse = {
    data: [
      {
        attributes: {
          email: 'John.Doe@Example.com',
          phone_number: '+15551234567',
          first_name: 'John',
          last_name: 'Doe',
          location: {
            address1: '123 Main St',
            city: 'New York',
            zip: '10001',
            country: 'US'
          }
        }
      }
    ]
  };

  const expectedUserData = {
    email: 'john.doe@example.com',
    phone_number: '+15551234567',
    address: [
      {
        first_name: 'john',
        last_name: 'doe',
        street: '123 main st',
        city: 'new york',
        postal_code: '10001',
        country: 'us'
      }
    ]
  };

  let pageLocation = 'https://example.com/?_kx=kx%20url';
  let cookies = {};
  let cache = {};
  let requestCount = 0;

  const cleanup = () => {
    cache = {};
  };

  mock('getEventData', (key) => {
    if (key === 'page_location') return pageLocation;
  });

  mock('getCookieValues', (name) => cookies[name] || []);

  mockObject('templateDataStorage', {
    getItemCopy: (key) => cache[key],
    setItemCopy: (key, value) => {
      cache[key] = value;
    }
  });

  mock('sendHttpGet', () => {
    requestCount++;
    return Promise.create((resolve) => resolve({ statusCode: 200, body: JSON.stringify(apiResponse) }));
  });


___NOTES___

2026-08-21 Change Notes:
 - Add __kla_id cookie fallback for _kx identifier detection.

2026-05-21 Change Notes:
 - Console logging removal.
 - Update API version to 2026-04-15.

Created on 17.10.2022 14.30.57


