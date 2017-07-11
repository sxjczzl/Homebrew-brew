require_relative "./mktmpdir"

module Test
  module Helper
    module FakeCurl
      def with_fake_curl(shell_command)
        saved_value = ENV["HOMEBREW_CURL"]

        begin
          mktmpdir do |path|
            fake_curl_path = path/"fake_curl"
            File.open(fake_curl_path, "w") do |file|
              file.write("#! #{`which bash`}\n#{shell_command}\n")
            end
            FileUtils.chmod 0755, fake_curl_path
            ENV["HOMEBREW_CURL"] = fake_curl_path
          end
          return yield
        ensure
          ENV["HOMEBREW_CURL"] = saved_value
        end
      end
    end
  end
end
