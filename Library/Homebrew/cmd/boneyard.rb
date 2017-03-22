#:  * `boneyard` [<git-log-options>] <formula> ...:
#:    Show the last contents for a deleted formula.

require "formula"

module Homebrew
  module_function

  def boneyard
    raise FormulaUnspecifiedError if ARGV.named.empty?
    name = ARGV.named.first
    path = Formulary.path name
    cd path.dirname # supports taps

    if File.exist? "#{`git rev-parse --show-toplevel`.chomp}/.git/shallow"
      opoo <<-EOS.undent
        The git repository is a shallow clone therefore the output may be incomplete.
        Use `git fetch --unshallow` to get the full repository.
      EOS
    end

    log_cmd = "git log --name-only --max-count=1 --format=format:%H -- #{path}"
    revision, path = Utils.popen_read(log_cmd).lines.map(&:chomp)
    if revision.to_s.empty? || path.to_s.empty?
      raise FormulaUnavailableError, name
    end
    exec "git", "show", "#{revision}^:#{path}"
  end
end
