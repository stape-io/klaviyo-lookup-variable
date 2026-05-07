# Klaviyo Lookup Variable for GTM Server Side

This Google Tag Manager Server-Side variable allows you to retrieve a user profile from Klaviyo using the identifier (`_kx`). It enriches your server-side data with user information such as email, phone number, and address.

## How it works

1.  **Identifier Detection**: The variable first looks for the `_kx` query parameter in the page URL.
2.  **Fallback**: If the URL parameter is not present, it attempts to retrieve the identifier from the `stape_klaviyo_kx` cookie.
3.  **Cache Check**: The variable checks the `templateDataStorage` to see if the user data for this identifier is already cached, preventing unnecessary API calls.
4.  **API Request**: If no cache is found, it sends a GET request to the Klaviyo Profiles API.
5.  **Output**: It returns either the user's email or a full user data object based on your configuration.

## Parameters

- **Api Key**: Input your Klaviyo Private API Key. This is required to authorize the request.
- **Output**: Select the type of data to return:
  - _Email_: Returns only the user's email address string.
  - _All user_data_: Returns a JSON object containing the user profile.
- **Logs Settings**: Control logging behavior:
  - _Do not log_: No logs are generated.
  - _Log to console during debug and preview_: Logs only when GTM is in debug/preview mode.
  - _Always log to console_: Logs requests and responses regardless of the environment.

## Returned Data Structure

If **All user_data** is selected, the variable returns an object containing the following attributes:

```json
{
  "email": "user@example.com",
  "phone_number": "+1234567890",
  "address": [
    {
      "first_name": "john",
      "last_name": "doe",
      "street": "123 main st",
      "city": "new york",
      "postal_code": "10001",
      "country": "us"
    }
  ]
}
```

## Open Source

Initial development was done by [Lars Friis](https://www.linkedin.com/in/lars-friis/).

Klaviyo Lookup Variable for GTM Server Side is developing and maintained by [Stape Team](https://stape.io/) under the Apache 2.0 license.

### GTM Gallery Status
🟢 [Listed](https://tagmanager.google.com/gallery/#/owners/stape-io/templates/klaviyo-lookup-variable)
