# Public: App.config has all config keys stored in settings.rb in their respective
# environment, or under `defaults` for all environments
module App
  class ConfigHash < Hashie::Mash

    def deep_merge(other_hash)
      dup.deep_merge!(other_hash)
    end

    # Same as +deep_merge+, but modifies +self+.
    def deep_merge!(other_hash)
      other_hash.each_pair do |k,v|
        tv = self[k]
        self[k] = tv.is_a?(Hash) && v.is_a?(Hash) ? tv.deep_merge(v) : v
      end
      self
    end

  end
  class << self
    attr_reader :config

    def config=(config_hash={})
      @config = ConfigHash.new(config_hash[:defaults])
      @config.deep_merge!(config_hash[(ENV['RACK_ENV'] || 'development').to_sym]|| {})
    end
  end
end

