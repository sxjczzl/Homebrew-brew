# typed: true
# frozen_string_literal: true

require "formula"
require "formula_versions"

# Helper class for traversing a formula's previous versions.
#
# @api private
class FormulaeAtRevision
  SNIP = "------------>8-----------------"
  BATCH_SIZE = 500 # git chokes if this number is too large

  attr_reader :formulae, :path, :revision

  def initialize(formulae, path, revision)
    @formulae = formulae
    @path = path
    @revision = revision
  end

  # Given a formula, returns a copy of the formula at `@revision`.
  # A return value of `nil` indicates that the formula did not exist at @revision.
  # Will raise ArgumentError if passed a formula it was not initializd with.
  def [](formula)
    formulae_at_revision.fetch(formula) do
      raise ArgumentError, "#{self.class.name} was not initialized with #{formula.inspect}"
    end
  end

  private

  # Shells out to `git cat-file` with batches of formulae and parses the output.
  #
  # `git cat-file` returns the contents of a file at a given SHA. This method
  # (using `--batch`) is an optimization over shelling out to `git cat-file` for
  # each formula in question.
  def formulae_at_revision
    @formulae_at_revision ||=
      {}.tap do |dictionary|
        entries = formulae.map { |formula| "#{revision}:#{FormulaVersions.new(formula).entry_name}" }

        output =
          entries.each_slice(BATCH_SIZE).map do |slice|
            # Docs: https://git-scm.com/docs/git-cat-file
            Utils.popen_write("git", "-C", path, "cat-file", "--batch=#{SNIP}") do |pipe|
              pipe.write(slice.join("\n"))
            end
          end.join

        # Read the output of git cat-file in chunks
        # Read until we either encounter `SNIP` (the start of a new blob)
        # or else the message "<REVISION>:<PATH> missing" (which indicates a missing blob)
        #
        # Discard the first element in the array because output will be begin
        # with one of these two breaks.
        formula_contents = output.split(/^(?:#{Regexp.escape(SNIP)}|#{revision}:.* missing)\n+/)[1..]

        formulae.zip(formula_contents).each do |(formula, contents)|
          dictionary[formula] =
            unless contents.blank? # The formula did not exist at @revision
              Formulary.from_contents(formula.name, formula.path, contents, ignore_errors: true)
            end
        rescue Exception => e # rubocop:disable Lint/RescueException
          onoe "#{e.message}\n#{e.backtrace&.join("\n")}" if Homebrew::EnvConfig.developer?
        end
      end
  end
end
