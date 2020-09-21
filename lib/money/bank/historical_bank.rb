# frozen_string_literal: true

require 'money'
require 'date'
require 'yajl'

require "#{__dir__}/../../open_exchange_rates_fetcher"

class Money
  module Bank
    class InvalidCache < StandardError; end

    class HistoricalBank < Base
      attr_reader :rates

      # Available formats for importing/exporting rates.
      RATE_FORMATS = %i[json ruby yaml].freeze

      def setup
        @rates = {}
        @mutex = Mutex.new
        self
      end

      # Set the rate for the given currency pair at a given date.
      # Uses +Mutex+ to synchronize data access.
      #
      # @param [Date] date Date for which the rate is valid.
      # @param [Currency, String, Symbol] from Currency to exchange from.
      # @param [Currency, String, Symbol] to Currency to exchange to.
      # @param [Numeric] rate Rate to use when exchanging currencies.
      #
      # @return [Numeric]
      # @example
      #   bank = Money::Bank::HistoricalBank.new
      #   bank.set_rate(Date.new(2001, 1, 1), "USD", "CAD", 1.24514)
      def set_rate(date, from, to, rate)
        @mutex.synchronize do
          internal_set_rate(date, from, to, rate)
        end
      end

      # Retrieve the rate for the given currencies. Uses +Mutex+ to synchronize
      # data access. If no rates have been set for +date+, will try to load them
      # using #load_data.
      #
      # @param [Date] date Date to retrieve the exchange rate at.
      # @param [Currency, String, Symbol] from Currency to exchange from.
      # @param [Currency, String, Symbol] to Currency to exchange to.
      #
      # @return [Numeric]
      #
      # @example
      #   bank = Money::Bank::HistoricalBank.new
      #   d1 = Date.new(2001, 1, 1)
      #   d2 = Date.new(2002, 1, 1)
      #   bank.set_rate(d1, "USD", "CAD", 1.24515)
      #   bank.set_rate(d2, "CAD", "USD", 0.803115)
      #
      #   bank.get_rate(d1, "USD", "CAD") #=> 1.24515
      #   bank.get_rate(d2, "CAD", "USD") #=> 0.803115
      def get_rate(date, from, to)
        @mutex.synchronize do
          unless existing_rates = @rates[date.to_s]
            load_data(date)
            existing_rates = @rates[date.to_s]
          end
          rate = nil
          if existing_rates
            rate = existing_rates[rate_key_for(from, to)]
            unless rate
              # Tries to calculate an inverse rate
              inverse_rate = existing_rates[rate_key_for(to, from)]
              rate = 1.0 / inverse_rate if inverse_rate
            end
            unless rate
              # Tries to calculate a pair rate using USD rate
              unless from_base_rate = existing_rates[rate_key_for('USD', from)]
                from_inverse_rate = existing_rates[rate_key_for(from, 'USD')]
                from_base_rate = 1.0 / from_inverse_rate if from_inverse_rate
              end
              unless to_base_rate = existing_rates[rate_key_for('USD', to)]
                to_inverse_rate = existing_rates[rate_key_for(to, 'USD')]
                to_base_rate = 1.0 / to_inverse_rate if to_inverse_rate
              end
              rate = to_base_rate / from_base_rate if to_base_rate && from_base_rate
            end
          end
          rate
        end
      end

      # Tries to load data from OpenExchangeRates for the given rate.
      # Won't do anything if there's no data available for that date
      # in OpenExchangeRates (short) history.
      def load_data(date)
        data = OpenExchangeRatesFetcher.fetch_data(date)
        doc = Yajl::Parser.parse(data)

        base_currency = doc['base'] || 'USD'

        doc['rates'].each do |currency, rate|
          # Don't use set_rate here, since this method can only be called from
          # get_rate, which already aquired a mutex.
          internal_set_rate(date, base_currency, currency, rate)
        end
      end

      #
      # @overload exchange_with(from, to_currency)
      #   Exchanges the given +Money+ object to a new +Money+ object in
      #   +to_currency+. The exchange rate used will be for Date.today.
      #   If no rates are here for Date.today, it will try to load them.
      #   @param  [Money] from
      #           The +Money+ object to exchange.
      #   @param  [Currency, String, Symbol] to_currency
      #           The currency to exchange to.
      #
      # @overload exchange_with(date, from, to_currency)
      #   Exchanges the +Money+ object +from+ to a new +Money+ object in +to_currency+, using
      #   the exchange rate available on +date+.
      #   @param  [Date] date The +Date+ at which you want to calculate the rate.
      #   @param  [Money] from
      #           The +Money+ object to exchange.
      #   @param  [Currency, String, Symbol] to_currency
      #           The currency to exchange to.
      #
      # @yield [n] Optional block to use when rounding after exchanging one
      #  currency for another.
      # @yieldparam [Float] n The resulting float after exchanging one currency
      #  for another.
      # @yieldreturn [Integer]
      #
      # @return [Money]
      #
      # @raise +Money::Bank::UnknownRate+ if the conversion rate is unknown.
      #
      # @example
      #   bank = Money::Bank::VariableExchange.new
      #   bank.add_rate(Date.today, "USD", "CAD", 1.24515)
      #   bank.add_rate(Date.new(2011,1,1), "CAD", "USD", 0.803115)
      #
      #   c1 = 100_00.to_money("USD")
      #   c2 = 100_00.to_money("CAD")
      #
      #   # Exchange 100 USD to CAD:
      #   bank.exchange_with(c1, "CAD") #=> #<Money @cents=1245150>
      #
      #   # Exchange 100 CAD to USD:
      #   bank.exchange_with(Date.new(2011,1,1), c2, "USD") #=> #<Money @cents=803115>
      def exchange_with(*args)
        date, from, to_currency = args.length == 2 ? [Date.today] + args : args

        return from if same_currency?(from.currency, to_currency)

        rate = get_rate(date, from.currency, to_currency)
        raise UnknownRate, "No conversion rate available for #{date} '#{from.currency.iso_code}' -> '#{to_currency}'" unless rate

        _to_currency_ = Currency.wrap(to_currency)

        cents = BigDecimal(from.cents.to_s) / (BigDecimal(from.currency.subunit_to_unit.to_s) / BigDecimal(_to_currency_.subunit_to_unit.to_s))

        ex = cents * BigDecimal(rate.to_s)
        ex = ex.to_f
        ex = if block_given?
               yield ex
             elsif @rounding_method
               @rounding_method.call(ex)
             else
               ex.to_s.to_i
             end
        Money.new(ex, _to_currency_)
      end

      # Return the known rates as a string in the format specified. If +file+
      # is given will also write the string out to the file specified.
      # Available formats are +:json+, +:ruby+ and +:yaml+.
      #
      # @param [Symbol] format Request format for the resulting string.
      # @param [String] file Optional file location to write the rates to.
      #
      # @return [String]
      #
      # @raise +Money::Bank::UnknownRateFormat+ if format is unknown.
      #
      # @example
      #   bank = Money::Bank::VariableExchange.new
      #   bank.set_rate("USD", "CAD", 1.24515)
      #   bank.set_rate("CAD", "USD", 0.803115)
      #
      #   s = bank.export_rates(:json)
      #   s #=> "{\"USD_TO_CAD\":1.24515,\"CAD_TO_USD\":0.803115}"
      def export_rates(format, file = nil)
        raise Money::Bank::UnknownRateFormat unless
          RATE_FORMATS.include? format

        s = ''
        @mutex.synchronize do
          s = case format
              when :json
                JSON.dump(@rates)
              when :ruby
                Marshal.dump(@rates)
              when :yaml
                YAML.dump(@rates)
              end

          File.open(file, 'w').write(s) unless file.nil?
        end
        s
      end

      # Loads rates provided in +s+ given the specified format. Available
      # formats are +:json+, +:ruby+ and +:yaml+.
      #
      # @param [Symbol] format The format of +s+.
      # @param [String] s The rates string.
      #
      # @return [self]
      #
      # @raise +Money::Bank::UnknownRateFormat+ if format is unknown.
      #
      # @example
      #   s = "{\"USD_TO_CAD\":1.24515,\"CAD_TO_USD\":0.803115}"
      #   bank = Money::Bank::VariableExchange.new
      #   bank.import_rates(:json, s)
      #
      #   bank.get_rate("USD", "CAD") #=> 1.24515
      #   bank.get_rate("CAD", "USD") #=> 0.803115
      def import_rates(format, s)
        raise Money::Bank::UnknownRateFormat unless
          RATE_FORMATS.include? format

        @mutex.synchronize do
          @rates = case format
                   when :json
                     JSON.load(s)
                   when :ruby
                     Marshal.load(s)
                   when :yaml
                     YAML.safe_load(s)
                   end
        end
        self
      end

      private

      # Return the rate hashkey for the given currencies.
      #
      # @param [Currency, String, Symbol] from The currency to exchange from.
      # @param [Currency, String, Symbol] to The currency to exchange to.
      #
      # @return [String]
      #
      # @example
      #   rate_key_for("USD", "CAD") #=> "USD_TO_CAD"
      def rate_key_for(from, to)
        "#{Currency.wrap(from).iso_code}_TO_#{Currency.wrap(to).iso_code}".upcase
      end

      # Set the rate for the given currency pair at a given date.
      # Doesn't use any mutex.
      #
      # @param [Date] date Date for which the rate is valid.
      # @param [Currency, String, Symbol] from Currency to exchange from.
      # @param [Currency, String, Symbol] to Currency to exchange to.
      # @param [Numeric] rate Rate to use when exchanging currencies.
      #
      # @return [Numeric]
      def internal_set_rate(date, from, to, rate)
        if Money::Currency.find(from) && Money::Currency.find(to)
          date_rates = @rates[date.to_s] ||= {}
          date_rates[rate_key_for(from, to)] = rate
        end
      end
    end
  end
end
