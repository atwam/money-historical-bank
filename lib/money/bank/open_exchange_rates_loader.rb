# encoding: UTF-8
require 'money'
require 'date'
require 'yajl'
require 'open-uri'

class Money
  module Bank
    module OpenExchangeRatesLoader
      HIST_URL = 'https://raw.github.com/currencybot/open-exchange-rates/master/historical/'
      OER_URL = 'http://openexchangerates.org/latest.php'

      # Tries to load data from OpenExchangeRates for the given rate.
      # Won't do anything if there's no data available for that date
      # in OpenExchangeRates (short) history.
      def load_data(date)
        rates_source = if date == Date.today
                         OER_URL
                       else
                         # Should we use strftime, does to_s have better performance ? Or is it localized accross systems ?
                         HIST_URL + date.to_s + '.json'
                       end
        doc = Yajl::Parser.parse(open(rates_source).read)

        base_currency = doc['base'] || 'USD'

        doc['rates'].each do |currency, rate|
          # Don't use set_rate here, since this method can only be called from
          # get_rate, which already aquired a mutex.
          internal_set_rate(date, base_currency, currency, rate)
        end
      end
    end
  end
end
