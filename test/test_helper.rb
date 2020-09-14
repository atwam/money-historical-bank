# frozen_string_literal: true

require 'minitest/autorun'
require 'rr'
require 'date'
require 'money/bank/historical_bank'

Money.rounding_mode = BigDecimal::ROUND_HALF_EVEN
