# frozen_string_literal: true

require 'open-uri'

module OpenExchangeRatesFetcher
  HIST_URL = 'https://openexchangerates.org/api/historical/'
  OER_URL = 'https://openexchangerates.org/api/latest.json'

  def self.fetch_data(date)
    url = compute_url(date)
    URI.open(url).read
  end

  def self.compute_url(date)
    rates_source = if date == Date.today
                     OER_URL.dup
                   else
                     "#{HIST_URL}#{date.strftime('%Y-%m-%d')}.json"
                   end

    params = "?app_id=#{ENV['OPENEXCHANGERATES_APP_ID']}"

    if ENV['OPENEXCHANGERATES_APP_ID']
      rates_source + params
    else
      rates_source
    end
  end
end
