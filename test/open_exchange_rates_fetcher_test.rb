# frozen_string_literal: true

require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper'))

describe OpenExchangeRatesFetcher do
  describe '.compute_url' do
    before do
      ENV['OPENEXCHANGERATES_APP_ID'] = nil
    end

    it 'returns the latest path with the date of today' do
      date = Date.today
      url = OpenExchangeRatesFetcher.compute_url(date)
      assert_equal url, 'https://openexchangerates.org/api/latest.json'
    end

    it 'returns the historical path with any other date' do
      date = Date.new(2020, 1, 1)
      url = OpenExchangeRatesFetcher.compute_url(date)
      assert_equal url, 'https://openexchangerates.org/api/historical/2020-01-01.json'
    end

    it 'returns the url with app id when it exists in ENV' do
      ENV['OPENEXCHANGERATES_APP_ID'] = 'abc123'
      date = Date.today
      url = OpenExchangeRatesFetcher.compute_url(date)
      assert_equal url, 'https://openexchangerates.org/api/latest.json?app_id=abc123'
    end
  end
end
