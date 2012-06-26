# Money Historical Bank
[![Build Status](https://secure.travis-ci.org/coutud/money-historical-bank.png)](http://travis-ci.org/coutud/money-historical-bank)

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

## License
This gem is available under the *MIT license*

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


Copyright © 2012 Damien Couture <wam@atwam.com>
