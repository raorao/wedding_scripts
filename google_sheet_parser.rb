#!/usr/bin/env ruby

# gem install google-api-client -v '~> 0.8'

module GoogleSheetLoader
  require 'google/apis/sheets_v4'
  require 'googleauth'
  require 'googleauth/stores/file_token_store'
  require 'fileutils'

  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
  APPLICATION_NAME = 'Google Sheets API Ruby Quickstart'.freeze
  CLIENT_SECRETS_PATH = 'client_id.json'.freeze
  CREDENTIALS_PATH = 'token.yaml'.freeze
  SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS_READONLY

  module_function

  def fetch(spreadsheet_id:, range:)
    service = Google::Apis::SheetsV4::SheetsService.new
    service.client_options.application_name = APPLICATION_NAME
    service.authorization = authorize
    service.get_spreadsheet_values(spreadsheet_id, range).values
  end

  private_class_method def authorize
    client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)

    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts 'Open the following URL in the browser and enter the ' \
           'resulting code after authorization:\n' + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI
      )
    end

    credentials
  end
end

EventStrategy = Struct.new(
  :name_column,
  :email_column,
  :filter_column,
  :filename,
  keyword_init: true
) do

  def format(row_hash)
    [formatted_name(row_hash), row_hash.fetch(email_column)]
  end

  def formatted_name(row_hash)
    row_hash.fetch(name_column).sub(" and Guest", "")
  end

  def invited_to?(row_hash)
    row_hash.fetch(filter_column) == "Yes"
  end
end

module InviteCSVCreator
  module_function

  def from_google_sheet(rows:, headers:, strategy:)
    puts "formatting data"

    formatted_rows = rows.
      map { |row| headers.zip(row).to_h }.
      select { |row_hash| strategy.invited_to?(row_hash) }.
      map { |row_hash| strategy.format(row_hash) }

    missing_email_rows = formatted_rows.
      reject { |formatted_row| formatted_row.last =~ /@/ }

    unless missing_email_rows.empty?
      puts "missing emails for #{missing_email_rows.map(&:first).join(", ")}"
    end

    puts "creating #{strategy.filename}"

    require 'csv'

    CSV.open(strategy.filename, "wb") do |csv|
      csv << ["Name", "Email"]
      formatted_rows.each { |formatted_row| csv << formatted_row }
    end
  end
end

STRATEGIES = [
  EventStrategy.new(
    name_column: "Henna Party Name",
    email_column: "Henna Party Email",
    filter_column: "Mehindi Party?",
    filename: "henna_party_guests.csv"
  ),
  EventStrategy.new(
    name_column: "Name for Invite",
    email_column: "Email",
    filter_column: "Speeches and Drinks?",
    filename: "speeches_and_drinks.csv"
  )
]

puts "fetching data"

spreadsheet_id = ENV['SHEET_ID']


headers, *rows = GoogleSheetLoader.fetch(
  spreadsheet_id: spreadsheet_id,
  range: 'Guest List!A:W'
)


puts "#{rows.length} rows fetched."

STRATEGIES.each do |strategy|
  InviteCSVCreator.from_google_sheet(
    headers: headers,
    rows: rows,
    strategy: strategy
  )
end


