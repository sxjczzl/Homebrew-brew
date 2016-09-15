require "testing_env"
require "formula_support"

class KegOnlyReasonTests < Homebrew::TestCase
  def test_to_s_explanation
    r = KegOnlyReason.new :provided_by_osx, "test"
    assert_equal "test", r.to_s
  end

  def test_to_s_no_explanation
    r = KegOnlyReason.new :provided_by_osx, ""
    assert_match(/^(?:macOS|OS X) already provides/, r.to_s)
  end
end
