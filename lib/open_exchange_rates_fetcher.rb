# frozen_string_literal: true

require 'open-uri'

module OpenExchangeRatesFetcher
  HIST_URL = 'https://openexchangerates.org/api/historical/'
  OER_URL = 'https://openexchangerates.org/api/latest.json'

  def self.fetch_data(date)
    rates_source = if date == Date.today
                     OER_URL.dup
                   else
                     "#{HIST_URL}#{date.strftime('%Y-%m-%d')}.json"
                   end

    params = "?app_id=#{ENV['OPENEXCHANGERATES_APP_ID']}"

    url = if ENV['OPENEXCHANGERATES_APP_ID']
            rates_source + params
          else
            rates_source
          end

    URI.open(url).read
  end
end
