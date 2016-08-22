require "testing_env"
require "gpg"

class GpgTest < Homebrew::TestCase
  def setup
    skip "GPG Unavailable" unless Gpg.available?
    @dir = Pathname.new(mktmpdir)
  end

  def teardown
    FileUtils.rm_rf(@dir)
  end

  def test_create_test_key
    Dir.chdir(@dir) do
      with_environment("HOME" => @dir) do
        shutup { Gpg.create_test_key(@dir) }
        assert_predicate @dir/".gnupg/secring.gpg", :exist?
      end
    end
  end

  def test_formula_syntax_valid
    f = formula do
      url "https://ftpmirror.gnu.org/wget/wget-1.18.tar.xz"
      gpg "https://ftpmirror.gnu.org/wget/wget-1.18.tar.xz.sig"
    end
    assert_equal "https://ftpmirror.gnu.org/wget/wget-1.18.tar.xz.sig", f.gpg
  end
end
