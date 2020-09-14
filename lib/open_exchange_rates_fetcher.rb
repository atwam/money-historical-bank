# frozen_string_literal: true

require 'open-uri'

module OpenExchangeRatesFetcher
  BASE_API_URL = 'https://openexchangerates.org/api'

  def self.fetch_data(date)
    url = compute_url(date)
    URI.open(url).read
  end

  def self.compute_url(date)
    path = if date == Date.today
             '/latest.json'
           else
             "/historical/#{date.strftime('%Y-%m-%d')}.json"
           end

    rates_source = BASE_API_URL + path

    params = "?app_id=#{ENV['OPENEXCHANGERATES_APP_ID']}"

    if ENV['OPENEXCHANGERATES_APP_ID']
      rates_source + params
    else
      rates_source
    end
  end
end
