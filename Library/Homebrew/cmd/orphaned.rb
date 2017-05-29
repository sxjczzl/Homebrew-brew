#:  * `orphaned`:
#:    Find formulae that were installed as dependencies and are no
#:    longer required.

require "keg"

module Homebrew
  module_function

  def orphaned
    puts Keg.orphaned.map(&:name).uniq
  end
end
