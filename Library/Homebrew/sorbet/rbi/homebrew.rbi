# typed: strict

module Homebrew
  sig { params(blk: T.untyped(T.proc.bind(Homebrew::CLI::Parser).void)).returns(Homebrew::CLI::Parser) }
  def home_args(&blk)
  end

  sig { void }
  def home
  end

  module CLI
    class Parser
      sig {override.params(names: T.untyped, description: T.untyped, env: T.untyped, required_for: T.untyped, depends_on: T.untyped).void}
      def switch(*names, description: nil, env: nil, required_for: nil, depends_on: nil); end
    end
  end
end

module Homebrew
  module CLI
    class Parser
      extend T::Helpers
      abstract!

      sig {abstract.params(names: T.untyped, description: T.untyped, env: T.untyped, required_for: T.untyped, depends_on: T.untyped).void}
      def switch(*names, description: nil, env: nil, required_for: nil, depends_on: nil); end
    end
  end
end
