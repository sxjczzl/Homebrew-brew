#: @hide_from_man_page
#:  * `update-store` [tap]:
#:    Update formula store for all formulae in a tap (defaults to all taps).

require "tap"
require "formula_store"

module Homebrew
  module_function

  def update_store
    taps = if ARGV.named.empty?
      Tap
    else
      [Tap.fetch(ARGV.named.first)]
    end
    taps.each do |tap|
      FormulaStore.store_tap tap
    end
    FormulaStore.save_store
  end
end
