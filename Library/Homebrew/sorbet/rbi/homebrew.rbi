# typed: strict

module Homebrew
  sig { params(blk: T.nilable(T.proc.bind(Homebrew::CLI::Parser).void)).returns(Homebrew::CLI::Parser) }
  def home_args(&blk)
  end

  sig { void }
  def home
  end

  module CLI
    class Parser

      def switch(*names, description: nil, env: nil, required_for: nil, depends_on: nil)
      end
    end
  end
end
