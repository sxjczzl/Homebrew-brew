#:  * `orphaned`:
#:    List kegs that were installed as dependencies of other kegs, but are no
#:    longer required for any explicitly-installed keg.

require "keg"

module Homebrew
  module_function

  def orphaned
    puts Keg.orphaned.map { |k| "#{k.name} #{k.version}" }
  end
end
