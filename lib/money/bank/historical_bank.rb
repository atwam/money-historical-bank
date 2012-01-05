# encoding: UTF-8
require 'money'
require 'date'

require File.expand_path(File.dirname(__FILE__)) + "/open_exchange_rates_loader"

class Money
  module Bank
    class InvalidCache < StandardError ; end

    class HistoricalBank < Base
      include Money::Bank::OpenExchangeRatesLoader

      attr_reader :rates
      # Available formats for importing/exporting rates.
      RATE_FORMATS = [:json, :ruby, :yaml]
      
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
          unless existing_rates = @rates[date]
            load_data(date)
            existing_rates = @rates[date]
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
              unless from_base_rate = existing_rates[rate_key_for("USD", from)]
                from_inverse_rate = existing_rates[rate_key_for(from, "USD")]
                from_base_rate = 1.0 / from_inverse_rate if from_inverse_rate
              end
              unless to_base_rate = existing_rates[rate_key_for("USD", to)]
                to_inverse_rate = existing_rates[rate_key_for(to, "USD")]
                to_base_rate = 1.0 / to_inverse_rate if to_inverse_rate
              end
              if to_base_rate && from_base_rate
                rate = to_base_rate / from_base_rate
              end
            end
          end
          rate
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
        unless rate
          raise UnknownRate, "No conversion rate available for #{date} '#{from.currency.iso_code}' -> '#{to_currency}'"
        end
        _to_currency_  = Currency.wrap(to_currency)

        cents = BigDecimal.new(from.cents.to_s) / (BigDecimal.new(from.currency.subunit_to_unit.to_s) / BigDecimal.new(_to_currency_.subunit_to_unit.to_s))

        ex = cents * BigDecimal.new(rate.to_s)
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
      def export_rates(format, file=nil)
        raise Money::Bank::UnknownRateFormat unless
          RATE_FORMATS.include? format

        s = ""
        @mutex.synchronize {
          s = case format
              when :json
                JSON.dump(@rates)
              when :ruby
                Marshal.dump(@rates)
              when :yaml
                YAML.dump(@rates)
              end

          unless file.nil?
            File.open(file, "w").write(s)
          end
        }
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

        @mutex.synchronize {
          @rates = case format
                   when :json
                     JSON.load(s)
                   when :ruby
                     Marshal.load(s)
                   when :yaml
                     YAML.load(s)
                   end
        }
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
          date_rates = @rates[date] ||= {}
          date_rates[rate_key_for(from, to)] = rate
        end
      end
    end
  end
end
