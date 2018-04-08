module Homebrew
  module CLI
    class Arguments < BasicObject
      def initialize
        @args = {}
      end

      def to_hash
        @args.dup
      end
      alias to_h to_hash

      def inspect
        klass = class << self; superclass; end
        "#<#{klass}: #{@args}>"
      end

      def []=(key, value)
        @args[key.to_sym] = value
      end

      def respond_to?(*)
        true
      end

      def respond_to_missing?(*)
        true
      end

      def method_missing(name, *args)
        return super unless args.empty?
        @args[name.to_s.sub(/\?\z/, "").to_sym]
      end
    end
  end
end
