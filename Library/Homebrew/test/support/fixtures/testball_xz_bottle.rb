class TestballXzBottle < Formula
  def initialize(name = "testball_bottle", path = Pathname.new(__FILE__).expand_path, spec = :stable, alias_path: nil)
    self.class.instance_eval do
      stable.url "file://#{TEST_FIXTURE_DIR}/tarballs/testball-0.1.tbz"
      stable.sha256 TESTBALL_SHA256
      stable.bottle do
        cellar :any_skip_relocation
        root_url "file://#{TEST_FIXTURE_DIR}/bottles"
        compression_type :xz
        sha256 "5bbb2cbae8e00dc750eaabf85f6824ab6fff277f9a477bd09d7970799227668b" => Utils::Bottles.tag
      end
      cxxstdlib_check :skip
    end
    super
  end

  def install
    prefix.install "bin"
    prefix.install "libexec"
  end
end
