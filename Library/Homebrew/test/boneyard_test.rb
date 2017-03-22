require "testing_env"

class IntegrationCommandTestBoneyard < IntegrationCommandTestCase
  def test_boneyard
    setup_test_formula "testball"
    setup_test_formula "testball2"

    CoreTap.instance.path.cd do
      shutup do
        system "git", "init"
        system "git", "add", "--all"
        system "git", "commit", "-m", "add testballs"
        system "git", "rm", "Formula/testball2.rb"
        system "git", "commit", "-m", "remove testball2"
      end
    end

    assert_match "class Testball2", cmd("boneyard", "testball2")
  end
end
