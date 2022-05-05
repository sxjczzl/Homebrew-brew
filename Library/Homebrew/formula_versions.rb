# typed: true
# frozen_string_literal: true

require "formula"

# Helper class for traversing a formula's previous versions.
#
# @api private
class FormulaVersions
  include Context

  IGNORED_EXCEPTIONS = [
    ArgumentError, NameError, SyntaxError, TypeError,
    FormulaSpecificationError, FormulaValidationError,
    ErrorDuringExecution, LoadError, MethodDeprecatedError
  ].freeze

  MAX_VERSIONS_DEPTH = 2

  attr_reader :name, :path, :repository, :entry_name

  def initialize(formula)
    @name = formula.name
    @path = formula.path
    @repository = formula.tap.path
    @entry_name = @path.relative_path_from(repository).to_s
    @current_formula = formula
    @formula_at_revision = {}
  end

  def rev_list(branch)
    repository.cd do
      rev_list_cmd = ["git", "rev-list", "--abbrev-commit", "--remove-empty"]
      rev_list_cmd << "--first-parent" if repository != CoreTap.instance.path
      Utils.popen_read(*rev_list_cmd, branch, "--", entry_name) do |io|
        yield io.readline.chomp until io.eof?
      end
    end
  end

  def file_contents_at_revision(rev)
    repository.git_cat_file("#{rev}:#{entry_name}").to_s
  end

  def formula_at_revision(rev)
    @formula_at_revision[rev] ||=
      self.class.formula_from_contents(name, path, file_contents_at_revision(rev), rev)

    yield @formula_at_revision[rev] if @formula_at_revision[rev]
  end

  class << self
    include Context

    def formulae_at_repo_revision(formulae, repo, revision)
      entries = formulae.map { |formula| "#{revision}:#{new(formula).entry_name}" }
      contents = repo.git_cat_files(entries).values

      formulae.zip(contents).to_h do |formula, content|
        [formula, contents.present? && formula_from_contents(formula.name, formula.path, content, revision)]
      end
    end

    def formula_from_contents(name, path, contents, revision)
      Homebrew.raise_deprecation_exceptions = true

      nostdout { Formulary.from_contents(name, path, contents, ignore_errors: true) }
    rescue *IGNORED_EXCEPTIONS => e
      # We rescue these so that we can skip bad versions and
      # continue walking the history
      odebug "#{e} in #{name} at revision #{revision}", e.backtrace
    rescue FormulaUnavailableError
      nil
    ensure
      Homebrew.raise_deprecation_exceptions = false
    end
  end
end
