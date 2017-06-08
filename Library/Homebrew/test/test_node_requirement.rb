require "testing_env"
require "requirements/node_requirement"
require "fileutils"

class NodeRequirementTests < Homebrew::TestCase
  def setup
    @dir = Pathname.new(mktmpdir)
    (@dir/"bin/node").write <<-EOS.undent
      #!/bin/bash
      echo v5.0
    EOS
    FileUtils.chmod 0755, @dir/"bin/node"
  end

  def teardown
    FileUtils.rm_rf @dir
  end

  def test_raises_for_missing_version_tag
    assert_raises(RuntimeError) { NodeRequirement.new([]) }
  end

  def test_raises_for_non_version_tag
    assert_raises(RuntimeError) { NodeRequirement.new(%w[test]) }
  end

  def test_satisfied
    with_environment("PATH" => @dir/"bin") do
      assert_predicate NodeRequirement.new(%w[4.0]), :satisfied?
    end
  end

  def test_not_satisfied
    with_environment("PATH" => @dir/"bin") do
      refute_predicate NodeRequirement.new(%w[6.0]), :satisfied?
    end
  end
end
