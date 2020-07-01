# typed: strict

module Homebrew
  def home_args()
  end

  sig { void }
  def home
  end

  def args
  end

  module CLI
    class Parser

      sig do
        params(
          names: T::Array[String],
          description: T.nilable(String),
          env: T.nilable(String),
          required_for: T.nilable(String),
          depends_on: T.nilable(String),
        )
        .void
      end
      def switch(*names, description: nil, env: nil, required_for: nil, depends_on: nil); end

      sig {params(text: String).void}
      def usage_banner(text); end
    end
  end
end
