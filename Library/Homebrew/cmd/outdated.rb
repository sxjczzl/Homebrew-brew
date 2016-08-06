#:  * `outdated` [`--quiet`|`--verbose`|`--json=v1`] [`--fetch-HEAD`]:
#:    Show formulae that have an updated version available.
#:
#:    By default, version information is displayed in interactive shells, and
#:    suppressed otherwise.
#:
#:    If `--quiet` is passed, list only the names of outdated brews (takes
#:    precedence over `--verbose`).
#:
#:    If `--verbose` is passed, display detailed version information.
#:
#:    If `--json=`<version> is passed, the output will be in JSON format. The only
#:    valid version is `v1`.
#:
#:    If `--fetch-HEAD` is passed, fetch upstream repository to detect that HEAD
#:    formula is outdated. Otherwise HEAD-installation is considered outdated if
#:    new stable or devel version is bumped after that installation.

require "formula"
require "keg"

module Homebrew
  def outdated
    formulae = if ARGV.resolved_formulae.empty?
      Formula.installed
    else
      ARGV.resolved_formulae
    end
    if ARGV.json == "v1"
      outdated = print_outdated_json(formulae)
    else
      outdated = print_outdated(formulae)
    end
    Homebrew.failed = !ARGV.resolved_formulae.empty? && !outdated.empty?
  end

  def print_outdated(formulae)
    verbose = ($stdout.tty? || ARGV.verbose?) && !ARGV.flag?("--quiet")

    formulae.select(&:outdated?).each do |f|
      if verbose
        puts "#{f.full_name} (#{f.outdated_versions*", "} < #{f.pkg_version})"
      else
        puts f.full_name
      end
    end
  end

  def print_outdated_json(formulae)
    json = []
    outdated = formulae.select(&:outdated?).each do |f|

      json << { :name => f.full_name,
                :installed_versions => f.outdated_versions.collect(&:to_s),
                :current_version => f.pkg_version.to_s }
    end
    puts Utils::JSON.dump(json)

    outdated
  end
end
