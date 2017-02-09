require "testing_env"
require "extend/ARGV"

describe HomebrewArgvExtension do
  subject { argv.extend(HomebrewArgvExtension) }

  describe "#formulae" do
    let(:argv) { ["mxcl"] }

    it do
      expect { subject.formulae }.must_raise FormulaUnavailableError
    end
  end

  describe "#casks" do
    let(:argv) { ["mxcl"] }

    it do
      expect(subject.casks).must_equal []
    end
  end

  describe "#kegs" do
    let(:argv) { ["mxcl"] }

    before do
      keg = HOMEBREW_CELLAR + "mxcl/10.0"
      keg.mkpath
    end

    it do
      expect(subject.kegs.length).must_equal 1
    end
  end

  describe "#named" do
    let(:argv) { ["foo", "--debug", "-v"] }

    it do
      expect(subject.named).must_equal ["foo"]
    end
  end

  describe "#options_only" do
    let(:argv) { ["--foo", "-vds", "a", "b", "cdefg"] }

    it do
      expect(subject.options_only).must_equal ["--foo", "-vds"]
    end
  end

  describe "#flags_only" do
    let(:argv) { ["--foo", "-vds", "a", "b", "cdefg"] }

    it do
      expect(subject.flags_only).must_equal ["--foo"]
    end
  end

  describe "#empty?" do
    let(:argv) { [] }

    it do
      expect(subject.named).must_be :empty?
      expect(subject.kegs).must_be :empty?
      expect(subject.formulae).must_be :empty?
      expect(subject).must_be :empty?
    end
  end

  describe "#switch?" do
    let(:argv) { ["-ns", "-i", "--bar", "-a-bad-arg"] }

    it do
      %w[n s i].each { |s| assert subject.switch?(s) }
      %w[b ns bar --bar -n a bad arg].each { |s| assert !subject.switch?(s) }
    end
  end

  describe "#flag?" do
    let(:argv) { ["--foo", "-bq", "--bar"] }

    it do
      expect(subject.flag?("--foo")).must_equal true
      expect(subject.flag?("--bar")).must_equal true
      expect(subject.flag?("--baz")).must_equal true
      expect(subject.flag?("--qux")).must_equal true
      expect(subject.flag?("--frotz")).must_equal false
      expect(subject.flag?("--debug")).must_equal false
    end
  end

  describe "#value" do
    let(:argv) { ["--foo=", "--bar=ab"] }

    it do
      expect(subject.value("foo")).must_equal ""
      expect(subject.value("bar")).must_equal "ab"
      expect(subject.value("baz")).must_be_nil
    end
  end

  describe "#values" do
    let(:argv) { ["--foo=", "--bar=a", "--baz=b,c"] }

    it do
      expect(subject.values("foo")).must_equal []
      expect(subject.values("bar")).must_equal ["a"]
      expect(subject.values("baz")).must_equal ["b", "c"]
      expect(subject.values("qux")).must_be_nil
    end
  end
end
