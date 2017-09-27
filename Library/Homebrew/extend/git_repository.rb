require "utils/git"
require "utils/popen"

module GitRepositoryExtension
  def git?
    join(".git").exist?
  end

  def git_origin
    git_client.run("config", "--get", "remote.origin.url")
  end

  def git_head
    git_client.run("rev-parse", "--verify", "-q", "HEAD")
  end

  def git_short_head
    git_client.run("rev-parse", "--short=4", "--verify", "-q", "HEAD")
  end

  def git_last_commit
    git_client.run("show", "-s", "--format=%cr", "HEAD")
  end

  def git_branch
    git_client.run("rev-parse", "--abbrev-ref", "HEAD")
  end

  def git_last_commit_date
    git_client.run("show", "-s", "--format=%cd", "--date=short", "HEAD")
  end

  private

  def git_client
    @client ||= begin
      if git? && Utils.git_available?
        GitClient.new(self)
      else
        NullClient.new
      end
    end
  end

  class GitClient
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def run(*args)
      raise TapUnavailableError, path.name unless path.directory?
      path.cd do
        Utils.popen_read("git", *args).chuzzle
      end
    end
  end

  class NullClient
    def run(*); end
  end
end
