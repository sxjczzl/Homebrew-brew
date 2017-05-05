require "testing_env"

class VirtualenvTest < Homebrew::TestCase
  def test_abort_when_virtualenv_is_set
    brew = HOMEBREW_LIBRARY_PATH.parent.parent/"bin/brew"
    virtualenv_message = "Cowardly refusing to run inside virtualenv, please deactivate\n"
    output = Utils.popen_read("env VIRTUAL_ENV=1 /bin/bash #{brew} 2>&1")
    assert !$?.success?
    assert_equal output, virtualenv_message
  end
end
