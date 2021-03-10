# typed: false
# frozen_string_literal: true

require "formula"
require "service"

describe Homebrew::Service do
  let(:klass) do
    Class.new(Formula) do
      url "https://brew.sh/test-1.0.tbz"
    end
  end
  let(:name) { "formula_name" }
  let(:path) { Formulary.core_path(name) }
  let(:spec) { :stable }
  let(:f) { klass.new(name, path, spec) }

  let(:service) { described_class.new(f) }

  describe "#to_plist" do
    it "returns valid PLIST" do
      service.instance_eval do
        run ["#{HOMEBREW_PREFIX}/bin/beanstalkd"]
        run_type :immediate
        environment_variables PATH: "#{HOMEBREW_PREFIX}/bin:#{HOMEBREW_PREFIX}/sbin:/usr/bin:/bin:/usr/sbin:/sbin"
        error_log_path "#{HOMEBREW_PREFIX}/var/log/beanstalkd.error.log"
        log_path "#{HOMEBREW_PREFIX}/var/log/beanstalkd.log"
        working_dir "#{HOMEBREW_PREFIX}/var/"
        keep_alive true
      end

      plist = service.to_plist
      expect(plist).to include("<string>homebrew.service.#{name}</string>")
      expect(plist).to include("<key>Label</key>")
      expect(plist).to include("<key>KeepAlive</key>")
      expect(plist).to include("<key>RunAtLoad</key>")
      expect(plist).to include("<key>ProgramArguments</key>")
      expect(plist).to include("<key>WorkingDirectory</key>")
      expect(plist).to include("<key>StandardOutPath</key>")
      expect(plist).to include("<key>StandardErrorPath</key>")
      expect(plist).to include("<key>EnvironmentVariables</key>")
    end

    it "returns valid partial PLIST" do
      service.instance_eval do
        run ["#{HOMEBREW_PREFIX}/bin/beanstalkd"]
        run_type :immediate
      end

      plist = service.to_plist
      expect(plist).to include("<string>homebrew.service.#{name}</string>")
      expect(plist).to include("<key>Label</key>")
      expect(plist).not_to include("<key>KeepAlive</key>")
      expect(plist).to include("<key>RunAtLoad</key>")
      expect(plist).to include("<key>ProgramArguments</key>")
      expect(plist).not_to include("<key>WorkingDirectory</key>")
      expect(plist).not_to include("<key>StandardOutPath</key>")
      expect(plist).not_to include("<key>StandardErrorPath</key>")
      expect(plist).not_to include("<key>EnvironmentVariables</key>")
    end
  end
end
