#!/usr/bin/env ruby

# gem install httparty
# budget id 28197ec1-5e38-4e80-943f-5b2230d4aac3

require 'httparty'
require 'json'

def fetch_data(access_token, budget_id)
  HTTParty.get("https://api.youneedabudget.com/v1/budgets/#{budget_id}/transactions",
    query: {access_token: access_token}
  )
end


since = ARGV[0]

f = File.read("ynab_credentials.json")
credentials = JSON.parse(f)
access_token = credentials["access_token"]
budget_id = credentials["budget_id"]

unless access_token && budget_id
  fail "credentials are malformed. expected JSON with attributes `access_token` and `budget_id`"
end

transactions = fetch_data(access_token, budget_id)

formatted_rows = transactions
  .fetch("data")
  .fetch("transactions")
  .reject { |t| !!t["deleted"] }
  .select { |t| t["category_name"] == "Wedding" }
  .map { |t| [ t["payee_name"], t["amount"] / 1000.0, t["date"] ] }
  .sort_by(&:last)
  .reverse

if since
  formatted_rows = formatted_rows.take_while do |row|
    row.last > since
  end
end

puts "writing transactions.csv"

CSV.open("transactions.csv", "wb") do |csv|
  csv << ["Payee", "Amount", "Date" ]
  formatted_rows.each { |formatted_row| csv << formatted_row }
end
