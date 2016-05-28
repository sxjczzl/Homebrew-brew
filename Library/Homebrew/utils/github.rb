require "open-uri"

module GitHub
  extend self
  ISSUES_URI = URI.parse("https://api.github.com/search/issues")

  Error = Class.new(RuntimeError)
  HTTPNotFoundError = Class.new(Error)

  class RateLimitExceededError < Error
    def initialize(reset, error)
      super <<-EOS.undent
        GitHub API Error: #{error}
        Try again in #{pretty_ratelimit_reset(reset)}, or create a personal access token:
          #{Tty.em}https://github.com/settings/tokens/new?scopes=&description=Homebrew#{Tty.reset}
        and then set the token as: export HOMEBREW_GITHUB_API_TOKEN="your_new_token"
      EOS
    end

    def pretty_ratelimit_reset(reset)
      pretty_duration(Time.at(reset) - Time.now)
    end
  end

  class AuthenticationFailedError < Error
    def initialize(error)
      message = "GitHub #{error}\n"
      if ENV["HOMEBREW_GITHUB_API_TOKEN"]
        message << <<-EOS.undent
          HOMEBREW_GITHUB_API_TOKEN may be invalid or expired; check:
          #{Tty.em}https://github.com/settings/tokens#{Tty.reset}
        EOS
      else
        message << <<-EOS.undent
          The GitHub credentials in the OS X keychain may be invalid.
          Clear them with:
            printf "protocol=https\\nhost=github.com\\n" | git credential-osxkeychain erase
          Or create a personal access token:
            #{Tty.em}https://github.com/settings/tokens/new?scopes=&description=Homebrew#{Tty.reset}
          and then set the token as: export HOMEBREW_GITHUB_API_TOKEN="your_new_token"
        EOS
      end
      super message
    end
  end

  def api_credentials
    @api_credentials ||= begin
      if ENV["HOMEBREW_GITHUB_API_TOKEN"]
        ENV["HOMEBREW_GITHUB_API_TOKEN"]
      else
        github_credentials = Utils.popen("git credential-osxkeychain get", "w+") do |io|
          io.puts "protocol=https\nhost=github.com"
          io.close_write
          io.read
        end
        github_username = github_credentials[/username=(.+)/, 1]
        github_password = github_credentials[/password=(.+)/, 1]
        if github_username && github_password
          [github_password, github_username]
        else
          []
        end
      end
    end
  end

  def api_credentials_type
    token, username = api_credentials
    if token && !token.empty?
      if username && !username.empty?
        :keychain
      else
        :environment
      end
    else
      :none
    end
  end

  def api_credentials_error_message(response_headers)
    @api_credentials_error_message_printed ||= begin
      unauthorized = (response_headers["status"] == "401 Unauthorized")
      scopes = response_headers["x-accepted-oauth-scopes"].to_s.split(", ")
      if !unauthorized && scopes.empty?
        credentials_scopes = response_headers["x-oauth-scopes"].to_s.split(", ")

        case GitHub.api_credentials_type
        when :keychain
          onoe <<-EOS.undent
            Your OS X keychain GitHub credentials do not have sufficient scope!
            Scopes they have: #{credentials_scopes}
            Create a personal access token: https://github.com/settings/tokens
            and then set HOMEBREW_GITHUB_API_TOKEN as the authentication method instead.
          EOS
        when :environment
          onoe <<-EOS.undent
            Your HOMEBREW_GITHUB_API_TOKEN does not have sufficient scope!
            Scopes it has: #{credentials_scopes}
            Create a new personal access token: https://github.com/settings/tokens
            and then set the new HOMEBREW_GITHUB_API_TOKEN as the authentication method instead.
          EOS
        end
      end
      true
    end
  end

  def api_headers
    {
      "User-Agent" => HOMEBREW_USER_AGENT_RUBY,
      "Accept"     => "application/vnd.github.v3+json"
    }
  end

  def open(url, &_block)
    # This is a no-op if the user is opting out of using the GitHub API.
    return if ENV["HOMEBREW_NO_GITHUB_API"]

    require "net/https"

    headers = api_headers
    token, username = api_credentials
    case api_credentials_type
    when :keychain
      headers[:http_basic_authentication] = [username, token]
    when :environment
      headers["Authorization"] = "token #{token}"
    end

    begin
      Kernel.open(url, headers) { |f| yield Utils::JSON.load(f.read) }
    rescue OpenURI::HTTPError => e
      handle_api_error(e)
    rescue EOFError, SocketError, OpenSSL::SSL::SSLError => e
      raise Error, "Failed to connect to: #{url}\n#{e.message}", e.backtrace
    rescue Utils::JSON::Error => e
      raise Error, "Failed to parse JSON response\n#{e.message}", e.backtrace
    end
  end

  def handle_api_error(e)
    if e.io.meta.fetch("x-ratelimit-remaining", 1).to_i <= 0
      reset = e.io.meta.fetch("x-ratelimit-reset").to_i
      error = Utils::JSON.load(e.io.read)["message"]
      raise RateLimitExceededError.new(reset, error)
    end

    GitHub.api_credentials_error_message(e.io.meta)

    case e.io.status.first
    when "401", "403"
      raise AuthenticationFailedError.new(e.message)
    when "404"
      raise HTTPNotFoundError, e.message, e.backtrace
    else
      error = Utils::JSON.load(e.io.read)["message"] rescue nil
      raise Error, [e.message, error].compact.join("\n"), e.backtrace
    end
  end

  def issues_matching(query, qualifiers = {})
    uri = ISSUES_URI.dup
    uri.query = build_query_string(query, qualifiers)
    open(uri) { |json| json["items"] }
  end

  def repository(user, repo)
    open(URI.parse("https://api.github.com/repos/#{user}/#{repo}")) { |j| j }
  end

  def build_query_string(query, qualifiers)
    s = "q=#{uri_escape(query)}+"
    s << build_search_qualifier_string(qualifiers)
    s << "&per_page=100"
  end

  def build_search_qualifier_string(qualifiers)
    {
      :repo => "Homebrew/homebrew-core",
      :in => "title"
    }.update(qualifiers).map do |qualifier, value|
      "#{qualifier}:#{value}"
    end.join("+")
  end

  def uri_escape(query)
    if URI.respond_to?(:encode_www_form_component)
      URI.encode_www_form_component(query)
    else
      require "erb"
      ERB::Util.url_encode(query)
    end
  end

  def issues_for_formula(name, options = {})
    tap = options[:tap] || CoreTap.instance
    issues_matching(name, :state => "open", :repo => "#{tap.user}/homebrew-#{tap.repo}")
  end

  def print_pull_requests_matching(query)
    return [] if ENV["HOMEBREW_NO_GITHUB_API"]
    ohai "Searching pull requests..."

    open_or_closed_prs = issues_matching(query, :type => "pr")

    open_prs = open_or_closed_prs.select { |i| i["state"] == "open" }
    if open_prs.any?
      puts "Open pull requests:"
      prs = open_prs
    elsif open_or_closed_prs.any?
      puts "Closed pull requests:"
      prs = open_or_closed_prs
    else
      return
    end

    prs.each { |i| puts "#{i["title"]} (#{i["html_url"]})" }
  end

  def private_repo?(user, repo)
    uri = URI.parse("https://api.github.com/repos/#{user}/#{repo}")
    open(uri) { |json| json["private"] }
  end
end
