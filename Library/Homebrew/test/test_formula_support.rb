require "testing_env"
require "formula_support"

class BottleDisableReasonTests < Homebrew::TestCase
  def test_bottle_unneeded
    bottle_disable_reason = BottleDisableReason.new :unneeded, nil
    assert_predicate bottle_disable_reason, :unneeded?
    assert_equal "This formula doesn't require compiling.", bottle_disable_reason.to_s
  end

  def test_bottle_disabled
    bottle_disable_reason = BottleDisableReason.new :disable, "reason"
    refute_predicate bottle_disable_reason, :unneeded?
    assert_equal "reason", bottle_disable_reason.to_s
  end
end
