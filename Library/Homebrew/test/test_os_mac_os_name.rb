require "testing_env"
require "os/mac"

class OSMacOsNameTests < Homebrew::TestCase
  def test_os_name
    assert_equal "OS X", OS::Mac.os_name("10.7")
    assert_equal "OS X", OS::Mac.os_name("10.11")
    assert_equal "macOS", OS::Mac.os_name("10.12")
    assert_equal "macOS", OS::Mac.os_name("10.13")
  end

  def test_os_name_with_version
    assert_equal "OS X", OS::Mac.os_name(Version.create("10.9"))
    assert_equal "OS X", OS::Mac.os_name(Version.create("10.11"))
    assert_equal "macOS", OS::Mac.os_name(Version.create("10.12"))
    assert_equal "macOS", OS::Mac.os_name(Version.create("10.13"))
  end
end
