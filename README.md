# Wedding Scripts

Scripts helpful in wedding planning.

## Setup

Requires ruby 2.5.1. to install dependencies:

```
gem install bundler
bundle install
```

## Usage Instructions

## Google Sheet Parser

1. requires oath credentials from google. visit `https://console.cloud.google.com/apis/credentials` to get them. (see: https://developers.google.com/identity/protocols/OAuth2InstalledApp for more context)

2. Create or use an existing project.

3. use the download button to get a json file in the right format.

4. rename file `client_id.json` and move into root directory of this application.

5. Find you google sheet's id. visible in the url of page: `https://docs.google.com/spreadsheets/d/<<sheet_id>>/edit`

6. run `SHEET_ID=<<sheet_id>> ./google_sheet_parser.rb`. you will be prompted to log into your google account.


