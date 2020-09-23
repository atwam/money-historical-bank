# Money Historical Bank [![TravisCI][badge]][travis]

A gem that add a `Money::Bank` able to handle historical rates, and infer rates from limited rates.

* You can add rates for any currency pair, at a special date. Use `home_run` gem if you need fast date handling in ruby.
* If no rates exist for a given date, the gem will try to download historical rates from [open-exchange-rates](http://josscrowcroft.github.com/open-exchange-rates/)
* The gem is able to guess inverse rates (EURUSD rate when only USDEUR is present), and go through USD when using other pairs. For example, GBPEUR will be calculated using USDGBP and USDEUR. This strategy isn't used if said rate (GBPEUR) is already set.
* No caching exists, but you can use `import_data` and `export_data` the same way `Money::Bank::VariableExchange` works.

## Usage

```ruby
require 'money/bank/historical_bank'
mh = Money::Bank::HistoricalBank.new

# Exchanges 1000 EUR to USD using Date.today (default if no date has been entered).
# Will download today's rates if none have been entered
mh.exchange_with(1000.to_money('EUR'), 'USD')

# Exchanges 1000 EUR to USD using historical rates
date = Date.new(2009,9,9)
mh.set_rate(date, 'USD', 'EUR', 0.7634)
mh.exchange_with(date, 1000.to_money('USD'), 'EUR') # => 763.4 EUR

Money.default_bank = mh
```

## Refs
Created using mainly the base `VariableExchange` implementation, OpenExchangeRates implementation and idea based on `money-open-exchange-rates` gem.

* https://github.com/currencybot/open-exchange-rates
* https://github.com/RubyMoney/money
* https://github.com/spk/money-open-exchange-rates

## Extension

Feel free to create a new loader (cf `OpenExchangeRatesLoader`) if you know a source for more historical data.
Feel free to suggest refactoring.

## Releasing

This project is released by Travis when tags are pushed and one can do this like
so:

```
$ ./bin/release 0.0.4 0.0.5
```

So that command will bump the gem to version 0.0.5, push on master, push tags
and trigger Travis to release.

Note: this script assumes you have called your remote `origin`, that it's
pointing at atwam/money-historical-bank and that you have push access.

[travis]: https://travis-ci.org/github/atwam/money-historical-bank
[badge]: https://travis-ci.org/atwam/money-historical-bank.svg
