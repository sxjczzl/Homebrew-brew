require "forwardable"

module Hbc
  class URL
    FAKE_USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10) https://caskroom.github.io".freeze

    attr_reader :using, :revision, :trust_cert, :uri, :cookies, :referer, :data

    extend Forwardable
    def_delegators :uri, :path, :scheme, :to_s

    def self.from(*args, &block)
      if block_given?
        Hbc::DSL::StanzaProxy.once(self) { new(*block.call) }
      else
        new(*args)
      end
    end

    def initialize(uri, options = {})
      @uri        = URI(uri)
      @user_agent = options[:user_agent]
      @cookies    = options[:cookies]
      @referer    = options[:referer]
      @using      = options[:using]
      @revision   = options[:revision]
      @trust_cert = options[:trust_cert]
      @data       = options[:data]
    end

    def user_agent
      return FAKE_USER_AGENT if @user_agent == :fake
      @user_agent
    end
  end
end
