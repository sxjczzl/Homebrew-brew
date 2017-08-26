require "utils/git"
require "utils/popen"

module GitRepositoryExtension
  def git?
    join(".git").exist?
  end

  def git_origin
    git_client.send_command("config", "--get", "remote.origin.url")
  end

  def git_head
    git_client.send_command("rev-parse", "--verify", "-q", "HEAD")
  end

  def git_short_head
    git_client.send_command("rev-parse", "--short=4", "--verify", "-q", "HEAD")
  end

  def git_last_commit
    git_client.send_command("show", "-s", "--format=%cr", "HEAD")
  end

  def git_branch
    git_client.send_command("rev-parse", "--abbrev-ref", "HEAD")
  end

  def git_last_commit_date
    git_client.send_command("show", "-s", "--format=%cd", "--date=short", "HEAD")
  end

  private

  def git_client
    @client ||= (git? && Utils.git_available?) ? GitClient.new(self) : NullClient.new
  end

  class GitClient
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def send_command(*args)
      path.cd do
        Utils.popen_read("git", *args).chuzzle
      end
    end
  end

  class NullClient
    def send_command(*_args)
      nil
    end
  end
end
