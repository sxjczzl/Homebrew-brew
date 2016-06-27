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
    assert_equal tap, nil, "Should return nil if no tap slug provided"

    slug = "spam/homebrew-eggs"
    url = "https://github.com/#{slug}.git"
    pairs = [
      {"TRAVIS_REPO_SLUG" => slug},
      {"UPSTREAM_BOT_PARAMS" => "--tap=#{slug}"},
      {"UPSTREAM_GIT_URL" => url},
      {"GIT_URL" => url},
    ]

    predicate = Proc.new do
      tap = Homebrew::resolve_test_tap
      assert_kind_of Tap, tap
      assert_equal tap.user, "spam"
      assert_equal tap.repo, "eggs"
    end

    pairs.each do |pair|
      with_environment(pair) do
        predicate.call
      end
    end

    ARGV.expects(:value).with("tap").returns(slug)
    predicate.call
  end
end
