require "utils/curl"

describe "in `utils/curl`" do
  before(:example) { ENV["HOMEBREW_CURL"] = "" }

  describe "the `curl_args` method" do
    let(:saved_travis_env) { ENV["TRAVIS"] }
    before(:example) { ENV["TRAVIS"] = "1" }

    describe "given no options" do
      subject { curl_args }

      it { is_expected.to be_an(Array) }

      its(:size) { is_expected.to eq(8) }

      it { is_expected.to start_with("/usr/bin/curl") }

      it {
        is_expected.to contain_exactly(
          "/usr/bin/curl",
          "--remote-time",
          "--location",
          "--user-agent",
          HOMEBREW_USER_AGENT_CURL,
          "--progress-bar",
          "--fail",
          "--silent",
        )
      }
    end

    describe "with the `user_agent` option set to `:browser`" do
      subject { curl_args(user_agent: :browser) }

      it { is_expected.to be_an(Array) }

      its(:size) { is_expected.to eq(8) }

      it { is_expected.to start_with("/usr/bin/curl") }

      it {
        is_expected.to contain_exactly(
          "/usr/bin/curl",
          "--remote-time",
          "--location",
          "--user-agent",
          HOMEBREW_USER_AGENT_FAKE_SAFARI,
          "--progress-bar",
          "--fail",
          "--silent",
        )
      }
    end

    describe "with the `show_output` option enabled" do
      subject { curl_args(show_output: true) }

      it { is_expected.to be_an(Array) }

      its(:size) { is_expected.to eq(5) }

      it { is_expected.to start_with("/usr/bin/curl") }

      it {
        is_expected.to contain_exactly(
          "/usr/bin/curl",
          "--remote-time",
          "--location",
          "--user-agent",
          HOMEBREW_USER_AGENT_CURL,
        )
      }
    end

    after(:example) { ENV["TRAVIS"] = saved_travis_env }
  end

  describe "the `curl_output` method" do
    describe "when curl outputs something on STDOUT only" do
      subject { with_fake_curl("seq 1 5") { curl_output } }

      it { is_expected.to be_an(Array) }
      its(:size) { is_expected.to eq(3) }

      its([0]) { is_expected.to eq([1, 2, 3, 4, 5, nil].join("\n")) }
      its([1]) { is_expected.to be_empty }
      its([2]) { is_expected.to be_a_success }
    end

    describe "when curl outputs something on STDERR only" do
      subject { with_fake_curl("seq 1 5 >&2") { curl_output } }

      it { is_expected.to be_an(Array) }
      its(:size) { is_expected.to eq(3) }

      its([0]) { is_expected.to be_empty }
      its([1]) { is_expected.to eq([1, 2, 3, 4, 5, nil].join("\n")) }
      its([2]) { is_expected.to be_a_success }
    end

    describe "when curl outputs something on STDOUT and STDERR" do
      subject {
        with_fake_curl(<<-EOF.undent) { curl_output }
          for i in $(seq 1 2 5); do
            echo $i; echo $(($i + 1)) >&2
          done
        EOF
      }

      it { is_expected.to be_an(Array) }
      its(:size) { is_expected.to eq(3) }

      its([0]) { is_expected.to eq([1, 3, 5, nil].join("\n")) }
      its([1]) { is_expected.to eq([2, 4, 6, nil].join("\n")) }
      its([2]) { is_expected.to be_a_success }
    end

    describe "with a very long STDERR output" do
      let(:shell_command) {
        <<-EOF.undent
          for i in $(seq 1 2 100000); do
            echo $i; echo $(($i + 1)) >&2
          done
        EOF
      }

      it "returns without deadlocking" do
        wait(15).for {
          with_fake_curl(shell_command) { curl_output }
        }.to end_with(an_object_satisfying(&:success?))
      end
    end
  end

  after(:example) { ENV["HOMEBREW_CURL"] = "" }
end
