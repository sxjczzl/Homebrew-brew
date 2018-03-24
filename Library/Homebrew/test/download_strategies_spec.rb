require "download_strategy"

describe AbstractDownloadStrategy do
  subject { described_class.new(name, resource) }
  let(:specs) { {} }
  let(:name) { "foo" }
  let(:url) { "http://example.com/foo.tar.gz" }
  let(:resource) { double(Resource, url: url, mirrors: [], specs: specs, version: nil) }
  let(:args) { %w[foo bar baz] }

  describe "#expand_safe_system_args" do
    it "works with an explicit quiet flag" do
      args << { quiet_flag: "--flag" }
      expanded_args = subject.expand_safe_system_args(args)
      expect(expanded_args).to eq(%w[foo bar baz --flag])
    end

    it "adds an implicit quiet flag" do
      expanded_args = subject.expand_safe_system_args(args)
      expect(expanded_args).to eq(%w[foo bar -q baz])
    end

    it "does not mutate the arguments" do
      result = subject.expand_safe_system_args(args)
      expect(args).to eq(%w[foo bar baz])
      expect(result).not_to be args
    end
  end

  specify "#source_modified_time" do
    FileUtils.mktemp "mtime" do
      FileUtils.touch "foo", mtime: Time.now - 10
      FileUtils.touch "bar", mtime: Time.now - 100
      FileUtils.ln_s "not-exist", "baz"
      expect(subject.source_modified_time).to eq(File.mtime("foo"))
    end
  end

  context "when specs[:bottle] => true" do
    let(:specs) { { bottle: true } }

    it "extends Pourable" do
      expect(subject).to be_a_kind_of(AbstractDownloadStrategy::Pourable)
    end
  end

  context "when specs[:bottle] => false" do
    let(:specs) { { bottle: false } }

    it "is not Pourable" do
      expect(subject).to_not be_a_kind_of(AbstractDownloadStrategy::Pourable)
    end
  end

  context "when specs[:bottle] is unspecified" do
    it "is not Pourable" do
      expect(subject).to_not be_a_kind_of(AbstractDownloadStrategy::Pourable)
    end
  end
end

describe AbstractDownloadStrategy::Pourable do
  let(:specs) { {} }
  let(:name) { "foo" }
  let(:url) { "http://example.com/foo.tar.gz" }
  let(:resource) { double(Resource, url: url, mirrors: [], specs: specs, version: nil) }
  let(:download_strategy) { AbstractDownloadStrategy.new(name, resource) }
  subject(:pourable_strategy) { download_strategy.extend(AbstractDownloadStrategy::Pourable) }

  describe "#stage" do
    before(:each) do
      cached_location = double("cached_location")
      allow(cached_location).to receive(:basename).and_return("foo.tar.gz")
      allow(pourable_strategy).to receive(:cached_location).and_return(cached_location)
    end

    it "ohai's a 'Pouring' message using the object's cached_location.basename" do
      expect(pourable_strategy).to receive(:ohai).with("Pouring foo.tar.gz")
      pourable_strategy.stage
    end
  end
end

describe VCSDownloadStrategy do
  let(:url) { "http://example.com/bar" }
  let(:resource) { double(Resource, url: url, mirrors: [], specs: {}, version: nil) }

  describe "#cached_location" do
    it "returns the path of the cached resource" do
      allow_any_instance_of(described_class).to receive(:cache_tag).and_return("foo")
      downloader = described_class.new("baz", resource)
      expect(downloader.cached_location).to eq(HOMEBREW_CACHE/"baz--foo")
    end
  end
end

describe GitHubPrivateRepositoryDownloadStrategy do
  subject { described_class.new("foo", resource) }
  let(:url) { "https://github.com/owner/repo/archive/1.1.5.tar.gz" }
  let(:resource) { double(Resource, url: url, mirrors: [], specs: {}, version: nil) }

  before(:each) do
    ENV["HOMEBREW_GITHUB_API_TOKEN"] = "token"
    allow(GitHub).to receive(:repository).and_return({})
  end

  it "sets the @github_token instance variable" do
    expect(subject.instance_variable_get(:@github_token)).to eq("token")
  end

  it "parses the URL and sets the corresponding instance variables" do
    expect(subject.instance_variable_get(:@owner)).to eq("owner")
    expect(subject.instance_variable_get(:@repo)).to eq("repo")
    expect(subject.instance_variable_get(:@filepath)).to eq("archive/1.1.5.tar.gz")
  end

  its(:download_url) { is_expected.to eq("https://token@github.com/owner/repo/archive/1.1.5.tar.gz") }
end

describe GitHubPrivateRepositoryReleaseDownloadStrategy do
  subject { described_class.new("foo", resource) }
  let(:url) { "https://github.com/owner/repo/releases/download/tag/foo_v0.1.0_darwin_amd64.tar.gz" }
  let(:resource) { double(Resource, url: url, mirrors: [], specs: {}, version: nil) }

  before(:each) do
    ENV["HOMEBREW_GITHUB_API_TOKEN"] = "token"
    allow(GitHub).to receive(:repository).and_return({})
  end

  it "parses the URL and sets the corresponding instance variables" do
    expect(subject.instance_variable_get(:@owner)).to eq("owner")
    expect(subject.instance_variable_get(:@repo)).to eq("repo")
    expect(subject.instance_variable_get(:@tag)).to eq("tag")
    expect(subject.instance_variable_get(:@filename)).to eq("foo_v0.1.0_darwin_amd64.tar.gz")
  end

  describe "#download_url" do
    it "returns the download URL for a given resource" do
      allow(subject).to receive(:resolve_asset_id).and_return(456)
      expect(subject.download_url).to eq("https://token@api.github.com/repos/owner/repo/releases/assets/456")
    end
  end

  specify "#resolve_asset_id" do
    release_metadata = {
      "assets" => [
        {
          "id" => 123,
          "name" => "foo_v0.1.0_linux_amd64.tar.gz",
        },
        {
          "id" => 456,
          "name" => "foo_v0.1.0_darwin_amd64.tar.gz",
        },
      ],
    }
    allow(subject).to receive(:fetch_release_metadata).and_return(release_metadata)
    expect(subject.send(:resolve_asset_id)).to eq(456)
  end

  describe "#fetch_release_metadata" do
    it "fetches release metadata from GitHub" do
      expected_release_url = "https://api.github.com/repos/owner/repo/releases/tags/tag"
      expect(GitHub).to receive(:open_api).with(expected_release_url).and_return({})
      subject.send(:fetch_release_metadata)
    end
  end
end

describe GitHubGitDownloadStrategy do
  subject { described_class.new(name, resource) }
  let(:name) { "brew" }
  let(:url) { "https://github.com/homebrew/brew.git" }
  let(:resource) { double(Resource, url: url, mirrors: [], specs: {}, version: nil) }

  it "parses the URL and sets the corresponding instance variables" do
    expect(subject.instance_variable_get(:@user)).to eq("homebrew")
    expect(subject.instance_variable_get(:@repo)).to eq("brew")
  end
end

describe GitDownloadStrategy do
  subject { described_class.new(name, resource) }
  let(:name) { "baz" }
  let(:url) { "https://github.com/homebrew/foo" }
  let(:resource) { double(Resource, url: url, mirrors: [], specs: {}, version: nil) }
  let(:cached_location) { subject.cached_location }

  before(:each) do
    @commit_id = 1
    FileUtils.mkpath cached_location
  end

  def git_commit_all
    system "git", "add", "--all"
    system "git", "commit", "-m", "commit number #{@commit_id}"
    @commit_id += 1
  end

  def setup_git_repo
    system "git", "init"
    system "git", "remote", "add", "origin", "https://github.com/Homebrew/homebrew-foo"
    FileUtils.touch "README"
    git_commit_all
  end

  describe "#source_modified_time" do
    it "returns the right modification time" do
      cached_location.cd do
        setup_git_repo
      end
      expect(subject.source_modified_time.to_i).to eq(1_485_115_153)
    end
  end

  specify "#last_commit" do
    cached_location.cd do
      setup_git_repo
      FileUtils.touch "LICENSE"
      git_commit_all
    end
    expect(subject.last_commit).to eq("f68266e")
  end

  describe "#fetch_last_commit" do
    let(:url) { "file://#{remote_repo}" }
    let(:version) { Version.create("HEAD") }
    let(:resource) { double(Resource, url: url, mirrors: [], specs: {}, version: version) }
    let(:remote_repo) { HOMEBREW_PREFIX/"remote_repo" }

    before(:each) { remote_repo.mkpath }

    after(:each) { FileUtils.rm_rf remote_repo }

    it "fetches the hash of the last commit" do
      remote_repo.cd do
        setup_git_repo
        FileUtils.touch "LICENSE"
        git_commit_all
      end

      subject.shutup!
      expect(subject.fetch_last_commit).to eq("f68266e")
    end
  end
end

describe CurlDownloadStrategy do
  subject { described_class.new(name, resource) }
  let(:name) { "foo" }
  let(:url) { "http://example.com/foo.tar.gz" }
  let(:resource) { double(Resource, url: url, mirrors: [], specs: { user: "download:123456" }, version: nil) }

  it "parses the opts and sets the corresponding args" do
    expect(subject.send(:_curl_opts)).to eq(["--user", "download:123456"])
  end

  describe "#tarball_path" do
    subject { described_class.new(name, resource).tarball_path }

    context "when URL ends with file" do
      it { is_expected.to eq(HOMEBREW_CACHE/"foo-.tar.gz") }
    end

    context "when URL file is in middle" do
      let(:url) { "http://example.com/foo.tar.gz/from/this/mirror" }
      it { is_expected.to eq(HOMEBREW_CACHE/"foo-.tar.gz") }
    end
  end
end

describe S3DownloadStrategy do
  let(:s3_object_summary) { double("s3_object_summary") }
  let(:name) { "foo" }
  let(:url) { "https://bar.s3.amazonaws.com/baz/foo-1.0.0.tar.gz" }
  let(:parsed_bucket_name) { "bar" }
  let(:parsed_key) { "baz/foo-1.0.0.tar.gz" }
  let(:invalid_url) { "http://invalid.s3.example.com/foo/foo-1.0.0.tar.gz" }
  let(:presigned_url) do
    %w[
      https://bar.s3.amazonaws.com/baz/foo-1.0.0.tar.gz
      ?X-Amz-Algorithm=AWS4-HMAC-SHA256
      &X-Amz-Credential=AKIAIOSFODNN7EXAMPLE/19990101/us-east-1/s3/aws4_request
      &X-Amz-Date=19990101T000000Z&X-Amz-Expires=900
      &X-Amz-SignedHeaders=host
      &X-Amz-Signature=0000000000000000000000000000000000000000000000000000000000000000
    ].join
  end
  let(:resource) { double(Resource, url: url, mirrors: [], specs: {}, version: "1.0.0") }

  subject(:download_strategy) { described_class.new(name, resource) }

  before(:each) do
    # ensure we don't use real credentials
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("HOMEBREW_AWS_ACCESS_KEY_ID").and_return("EXAMPLE_AWS_ACCESS_KEY_ID")
    allow(ENV).to receive(:[]).with("HOMEBREW_AWS_SECRET_ACCESS_KEY").and_return("EXAMPLE_AWS_SECRET_ACCESS_KEY")

    # ensure we don't actually call curl
    allow(download_strategy).to receive(:curl_download)

    # stub out the object summary by default
    allow(download_strategy).to receive(:s3_object_summary).and_return(s3_object_summary)
    allow(download_strategy).to receive(:create_s3_object_summary).and_return(s3_object_summary)

    allow(s3_object_summary).to receive(:presigned_url).and_return(presigned_url)
    allow(s3_object_summary).to receive(:key).and_return(parsed_key)
    allow(s3_object_summary).to receive(:bucket_name).and_return(parsed_bucket_name)

    # stub out the gem requirement
    allow(download_strategy).to receive(:require).with("aws-sdk-s3").and_return(true)
  end

  describe "#parse_s3_bucket" do
    it "returns the S3 URL's bucket" do
      expect(download_strategy.parse_s3_bucket).to eq(parsed_bucket_name)
    end

    context "when URL does not match expected S3 format" do
      let(:url) { invalid_url }
      it "raises an ErrorDuringExecution" do
        expect {
          download_strategy.parse_s3_bucket
        }.to raise_error(ErrorDuringExecution)
      end
    end
  end

  describe "#parse_s3_key" do
    it "returns the S3 URL's key" do
      expect(download_strategy.parse_s3_key).to eq(parsed_key)
    end

    context "when URL does not match expected S3 format" do
      let(:url) { invalid_url }
      it "raises an ErrorDuringExecution" do
        expect {
          download_strategy.parse_s3_key
        }.to raise_error(ErrorDuringExecution)
      end
    end
  end

  describe "s3_bucket" do
    it "calls parse_s3_bucket" do
      expect(download_strategy).to receive(:parse_s3_bucket)
      download_strategy.s3_bucket
    end

    it "returns a parsed s3 bucket name" do
      expect(download_strategy.s3_bucket).to eq(parsed_bucket_name)
    end
  end

  describe "s3_key" do
    it "calls parse_s3_key" do
      expect(download_strategy).to receive(:parse_s3_key)
      download_strategy.s3_key
    end

    it "returns a parsed s3 key" do
      expect(download_strategy.s3_key).to eq(parsed_key)
    end
  end

  describe "#create_s3_object_summary" do
    it "creates an object summary using s3_bucket" do
      test_object_summary = download_strategy.create_s3_object_summary
      expect(test_object_summary.bucket_name).to eq(parsed_bucket_name)
    end

    it "creates an object summary using s3_key" do
      test_object_summary = download_strategy.create_s3_object_summary
      expect(test_object_summary.key).to eq(parsed_key)
    end
  end

  describe "#s3_object_summary" do
    context "when the object summary doesn't exist" do
      it "calls create_s3_object_summary" do
        # unmock the object summary so it will create itself
        allow(download_strategy).to receive(:s3_object_summary).and_call_original
        expect(download_strategy).to receive(:create_s3_object_summary)
        download_strategy.s3_object_summary
      end
    end

    it "returns an s3 object summary" do
      expect(download_strategy.s3_object_summary).to eq(s3_object_summary)
    end
  end

  describe "#require_aws_s3_sdk" do
    context "when aws-sdk-s3 gem is found" do
      it "requires the aws-sdk-s3 gem" do
        expect(download_strategy).to receive(:require).with("aws-sdk-s3").and_return(true)
        download_strategy.require_aws_s3_sdk
      end
    end

    context "when aws-sdk-s3 gem is missing" do
      it "raises a LoadError" do
        allow(download_strategy).to receive(:require).with("aws-sdk-s3").and_raise(LoadError)
        expect {
          download_strategy.require_aws_s3_sdk
        }.to raise_error(LoadError)
      end
    end
  end

  describe "#request_s3_url" do
    it "calls require_aws_s3_sdk" do
      expect(download_strategy).to receive(:require_aws_s3_sdk)
      download_strategy.request_s3_url
    end

    it "preserves the environment's AWS_ACCESS_KEY_ID" do
      ENV["AWS_ACCESS_KEY_ID"] = "ORIGINAL_AWS_ACCESS_KEY_ID"
      download_strategy.request_s3_url
      expect(ENV["AWS_ACCESS_KEY_ID"]).to eq("ORIGINAL_AWS_ACCESS_KEY_ID")
    end

    it "preserves the environment's AWS_SECRET_ACCESS_KEY" do
      ENV["AWS_SECRET_ACCESS_KEY"] = "ORIGINAL_AWS_SECRET_ACCESS_KEY"
      download_strategy.request_s3_url
      expect(ENV["AWS_SECRET_ACCESS_KEY"]).to eq("ORIGINAL_AWS_SECRET_ACCESS_KEY")
    end

    it "requests a presigned GET url" do
      expect(s3_object_summary).to receive(:presigned_url).with(:get)
      download_strategy.request_s3_url
    end

    context "when AWS credentials are missing" do
      it "uses the url as-is" do
        stub_const("Aws::Errors::MissingCredentialsError", Class.new(Exception))
        allow(s3_object_summary).to receive(:presigned_url).and_raise(Aws::Errors::MissingCredentialsError)
        expect(download_strategy.request_s3_url).to eq(url)
      end
    end
  end

  describe "#s3_url" do
    it "calls request_s3_url" do
      expect(download_strategy).to receive(:request_s3_url)
      download_strategy.s3_url
    end

    it "returns a presigned s3 url" do
      expect(download_strategy.s3_url).to eq(presigned_url)
    end
  end

  describe "#_fetch" do
    it "calls curl_download with s3_url and to: temporary_path" do
      allow(download_strategy).to receive(:s3_url).and_return("s3_url")
      allow(download_strategy).to receive(:temporary_path).and_return("temporary_path")
      expect(download_strategy).to receive(:curl_download).with("s3_url", to: "temporary_path")
      download_strategy._fetch
    end
  end
end

describe DownloadStrategyDetector do
  describe "::detect" do
    subject { described_class.detect(url, strategy) }
    let(:url) { Object.new }
    let(:strategy) { nil }

    context "when given Git URL" do
      let(:url) { "git://example.com/foo.git" }
      it { is_expected.to eq(GitDownloadStrategy) }
    end

    context "when given a GitHub Git URL" do
      let(:url) { "https://github.com/homebrew/brew.git" }
      it { is_expected.to eq(GitHubGitDownloadStrategy) }
    end

    context "when given strategy = S3DownloadStrategy" do
      let(:url) { "https://bkt.s3.amazonaws.com/key.tar.gz" }
      let(:strategy) { S3DownloadStrategy }
      it "requires aws-sdk-s3" do
        allow(DownloadStrategyDetector).to receive(:require_aws_sdk).and_return(true)
        is_expected.to eq(S3DownloadStrategy)
      end
    end

    it "defaults to cURL" do
      expect(subject).to eq(CurlDownloadStrategy)
    end

    it "raises an error when passed an unrecognized strategy" do
      expect {
        described_class.detect("foo", Class.new)
      }.to raise_error(TypeError)
    end
  end
end
