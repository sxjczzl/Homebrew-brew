#:  * `untap` <tap>:
#:    Remove a tapped repository.

require "tap"
require "formula_store"

module Homebrew
  module_function

  def untap
    raise "Usage is `brew untap <tap-name>`" if ARGV.empty?

    ARGV.named.each do |tapname|
      tap = Tap.fetch(tapname)
      raise "untapping #{tap} is not allowed" if tap.core_tap?
      FormulaStore.unstore_tap tap if ENV["HOMEBREW_EXPERIMENTAL_FORMULA_STORE"]
      tap.uninstall
    end
  end
end
