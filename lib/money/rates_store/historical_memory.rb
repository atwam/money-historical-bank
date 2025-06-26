# frozen_string_literal: true

require 'money/rates_store/memory'
require 'monitor'

class Money
  module RatesStore
    # Stores rates in memory for historical queries.
    # This store is thread-safe.
    class HistoricalMemory < Money::RatesStore::Memory
      SERIALIZER_SEPARATOR = '_TO_'

      def initialize(options = {})
        super
        @rates = {}
      end

      # Adds a rate for a given date.
      #
      # @param [String] from_currency The currency to exchange from.
      # @param [String] to_currency The currency to exchange to.
      # @param [Numeric] rate The exchange rate.
      # @param [Date] date The date for which the rate is valid.
      def add_rate(from_currency, to_currency, rate, date)
        transaction { internal_set_rate(from_currency, to_currency, rate, date) }
      end

      # Gets all rates for a given date.
      #
      # @param [Date] date The date to retrieve rates for.
      # @return [Hash] A hash of rates for the given date.
      def get_rates(date)
        transaction { @rates[date.to_s] }
      end

      # Iterates over each rate in the store.
      #
      # @yield [date, from, to, rate]
      def each_rate
        transaction do
          @rates.each do |date, date_rates|
            date_rates.each do |key, rate|
              from, to = key.split(SERIALIZER_SEPARATOR)
              yield date, from, to, rate
            end
          end
        end
      end

      private

      def internal_set_rate(from, to, rate, date)
        return unless Money::Currency.find(from) && Money::Currency.find(to)

        date_rates = @rates[date.to_s] ||= {}
        date_rates[rate_key_for(from, to)] = rate
      end

      def rate_key_for(from, to)
        "#{from}_TO_#{to}".upcase
      end
    end
  end
end
