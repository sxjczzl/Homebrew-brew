require "testing_env"
require "dev-cmd/test-bot"

class TestbotCommandTests < Homebrew::TestCase
  def with_environment(h)
    old = Hash[h.keys.map { |k| [k, ENV[k]] }]
    ENV.update h
    begin
      yield
    ensure
      ENV.update old
    end
  end

  def test_resolve_test_tap
    tap = Homebrew::resolve_test_tap
    assert_equal tap, nil

    with_environment("TRAVIS_REPO_SLUG" => "spam/homebrew-eggs") do
      tap = Homebrew::resolve_test_tap
      assert_equal tap.user, "spam"
    end

    with_environment("UPSTREAM_BOT_PARAMS" => "--tap=spam/homebrew-eggs") do
      tap = Homebrew::resolve_test_tap
      assert_equal tap.user, "spam"
    end

    url = "https://github.com/spam/homebrew-eggs.git"
    with_environment("UPSTREAM_GIT_URL" => url) do
      tap = Homebrew::resolve_test_tap
      assert_equal tap.user, "spam"
    end

    with_environment("GIT_URL" => url) do
      tap = Homebrew::resolve_test_tap
      assert_equal tap.user, "spam"
    end

    ARGV.expects(:value).with("tap").returns("spam/homebrew-eggs")
    tap = Homebrew::resolve_test_tap
    assert_equal tap.user, "spam"
  end
end
