# frozen_string_literal: true

require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper'))

describe Money::Bank::HistoricalBank do
  describe 'update_rates' do
    before do
      @bank = Money::Bank::HistoricalBank.new
    end

    it 'should store any rate stored for a date, and retrieve it when asked' do
      d1 = Date.new(2001, 1, 1)
      d2 = Date.new(2002, 1, 1)
      @bank.set_rate(d1, 'USD', 'EUR', 1.234)
      @bank.set_rate(d2, 'GBP', 'USD', 1.456)

      assert_equal @bank.get_rate(d1, 'USD', 'EUR'), 1.234
      assert_equal @bank.get_rate(d2, 'GBP', 'USD'), 1.456
    end

    it "shouldn't throw an error when internal_set_rate is called with a non existing currency" do
      d1 = Date.new(2011, 1, 1)
      @bank.set_rate(d1, 'BLA', 'ZZZ', 1.01)
      assert_empty @bank.rates
    end

    it 'should return the correct rate interpolated from existing pairs when asked' do
      d1 = Date.new(2001, 1, 1)
      @bank.set_rate(d1, 'USD', 'EUR', 1.234)
      @bank.set_rate(d1, 'GBP', 'USD', 1.456)

      assert_in_epsilon @bank.get_rate(d1, 'EUR', 'USD'), 1.0 / 1.234
      assert_in_epsilon @bank.get_rate(d1, 'GBP', 'EUR'), 1.456 * 1.234
    end

    it 'should return the correct rates using exchange_with a date' do
      d1 = Date.new(2001, 1, 1)
      @bank.set_rate(d1, 'USD', 'EUR', 0.73062465)
      from = Money.new(5000, 'EUR')
      assert_equal @bank.exchange_with(d1, from, 'USD').cents, 6843
    end
    it 'should return the correct rates using exchange_with no date (today)' do
      d1 = Date.today
      @bank.set_rate(d1, 'USD', 'EUR', 0.8)
      from = Money.new(5000, 'EUR')
      assert_equal @bank.exchange_with(from, 'USD').cents, 6250
    end
  end

  describe 'no rates available yet' do
    before do
      @bank = Money::Bank::HistoricalBank.new
      ENV['OPENEXCHANGERATES_APP_ID'] = nil
    end

    it 'should download new rates from url' do
      url = "#{OpenExchangeRatesFetcher::BASE_API_URL}/historical/2011-10-18.json"
      fixture_path = "#{File.dirname(__FILE__)}/fixtures/2011-10-18.json"
      stub(URI).open(url) { File.open fixture_path }
      d1 = Date.new(2011, 10, 18)

      rate = @bank.get_rate(d1, 'USD', 'EUR')
      assert_equal rate, 0.73062465
    end
  end

  describe 'export/import' do
    before do
      @bank = Money::Bank::HistoricalBank.new
    end
    it 'should store any rate stored for a date, and retrieve it after importing exported json' do
      d1 = Date.new(2001, 1, 1)
      d2 = Date.new(2002, 1, 1)
      @bank.set_rate(d1, 'USD', 'EUR', 1.234)
      @bank.set_rate(d2, 'GBP', 'USD', 1.456)

      json = @bank.export_rates(:json)
      @bank.import_rates(:json, json)

      assert_equal @bank.get_rate(d1, 'USD', 'EUR'), 1.234
      assert_equal @bank.get_rate(d2, 'GBP', 'USD'), 1.456
    end
  end
end
