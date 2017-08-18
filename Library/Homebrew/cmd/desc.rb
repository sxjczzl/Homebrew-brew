#:  * `desc` <formula>:
#:    Display <formula>'s name and one-line description.
#:
#:  * `desc` -a:
#:    Display name and one-line description for all formulae.
#:
#:  * `desc` -i:
#:    Display name and one-line description for all installed formulae.
#:
#:  * `desc` [`-s`|`-n`|`-d`] (<text>|`/`<text>`/`):
#:    Search both name and description (`-s`), just the names (`-n`), or just  the
#:    descriptions (`-d`) for <text>. If <text> is flanked by slashes, it is interpreted
#:    as a regular expression. Formula descriptions are cached; the cache is created on
#:    the first search, making that search slower than subsequent ones.

require "descriptions"
require "cmd/search"

module Homebrew
  module_function

  def desc
    search_type = []
    search_type << :either    if ARGV.flag? "--search"
    search_type << :name      if ARGV.flag? "--name"
    search_type << :desc      if ARGV.flag? "--description"
    search_type << :all       if ARGV.flag? "--all"
    search_type << :installed if ARGV.flag? "--installed"

    if search_type.size > 1
      odie "Pick one, and only one of -s/--search, -n/--name, or -d/--description -i/--installed -a/--all."
    elsif ARGV.include?("--all") || ARGV.include?("-a")
      Descriptions.all.print
    elsif ARGV.include?("--installed") || ARGV.include?("-i")
      Descriptions.installed.print
    elsif search_type.empty?
      raise FormulaUnspecifiedError if ARGV.named.empty?
      desc = {}
      ARGV.formulae.each { |f| desc[f.full_name] = f.desc }
      results = Descriptions.new(desc)
      results.print
    elsif arg = ARGV.named.first
      regex = Homebrew.query_regexp(arg)
      results = Descriptions.search(regex, search_type.first)
      results.print
    else
      odie "You must provide a search term."
    end
  end
end
