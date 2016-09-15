require "testing_env"
require "os/mac"

class OSMacTests < Homebrew::TestCase
  def test_os_name
    assert_equal "OS X", MacOS.os_name("10.7")
    assert_equal "OS X", MacOS.os_name("10.11")
    assert_equal "macOS", MacOS.os_name("10.12")
    assert_equal "macOS", MacOS.os_name("10.13")
  end
end
