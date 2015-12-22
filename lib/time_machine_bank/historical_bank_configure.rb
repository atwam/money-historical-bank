require 'moneta'
require 'hashie/mash'

module TimeMachineBank
  module HistoricalBankConfigure
    extend self
    
    def configure
      @@config = Hashie::Mash.new
      yield(@@config)
    end

    def config
      @@config
    end

    def store(key, value)
      cache = self.cache
      cache.store(key, value, expires: self.config.expires)
    end

    def load(key)
      cache = self.cache
      cache.load(key)
    end

    def build_key(date, from, to)
      #TODO refactor to config
      "#{date.strftime('%Y-%m')}:#{from}:#{to}"
    end

    def adapter
      self.config.adapter
    end

    def cache
      Moneta.new(self.adapter, server: self.config.connection_string)
    end

  end
end
