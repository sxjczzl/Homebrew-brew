require "language/node"
require "json"

describe Language::Node do
  describe "#setup_npm_environment" do
    it "calls prepend_path when node formula exists only during the first call" do
      node = formula "node" do
        url "node-test"
      end
      stub_formula_loader(node)
      expect(ENV).to receive(:prepend_path)
      subject.instance_variable_set(:@env_set, false)
      expect(subject.setup_npm_environment).to be_nil

      expect(subject.instance_variable_get(:@env_set)).to eq(true)
      expect(ENV).not_to receive(:prepend_path)
      expect(subject.setup_npm_environment).to be_nil
    end

    it "does not call prepend_path when node formula does not exist" do
      expect(subject.setup_npm_environment).to be_nil
    end
  end

  describe "#std_npm_install_args" do
    npm_install_arg = "libexec"
    npm_pack_cmd = "npm pack --ignore-scripts"

    it "raises error with non zero npm pack exitstatus" do
      allow(IO).to receive(:read).and_return("{}")
      allow(Language::Node).to receive(:safe_system).with("npm", "install", "-ddd", "--build-from-source",
        "--cache=#{HOMEBREW_CACHE}/npm_cache", "--production") { `true` }
      allow(Utils).to receive(:popen_read).with(npm_pack_cmd) { `false` }
      expect { subject.std_npm_install_args(npm_install_arg) }.to \
        raise_error("npm failed to pack #{Dir.pwd}")
    end

    it "raises error with empty npm pack output" do
      allow(IO).to receive(:read).and_return("{}")
      allow(Language::Node).to receive(:safe_system).with("npm", "install", "-ddd", "--build-from-source",
        "--cache=#{HOMEBREW_CACHE}/npm_cache", "--production") { `true` }
      allow(Utils).to receive(:popen_read).with(npm_pack_cmd) { `false` }
      expect { subject.std_npm_install_args(npm_install_arg) }.to \
        raise_error("npm failed to pack #{Dir.pwd}")
    end

    it "does not raise error with a zero npm pack exitstatus" do
      allow(IO).to receive(:read).and_return("{}")
      allow(Language::Node).to receive(:safe_system).with("npm", "install", "-ddd", "--build-from-source",
        "--cache=#{HOMEBREW_CACHE}/npm_cache", "--production") { `true` }
      allow(Utils).to receive(:popen_read).with(npm_pack_cmd) { `echo pack.tgz` }
      resp = subject.std_npm_install_args(npm_install_arg)
      expect(resp).to include("--prefix=#{npm_install_arg}", "#{Dir.pwd}/pack.tgz")
    end

    it "does not raise error with prepare_required set" do
      allow(IO).to receive(:read).and_return('{"name":"example","dependencies":{"foo":"1.2.3","bar":"4.5.6"}}')
      expected_json = '{"name":"example","dependencies":{"foo":"1.2.3","bar":"4.5.6"},'\
                      '"bundledDependencies":["foo","bar"]}'
      expected_json = JSON.pretty_generate(JSON.parse(expected_json))
      allow(IO).to receive(:write).with("package.json", expected_json) { `true` }
      allow(Language::Node).to receive(:safe_system)
        .with("npm", "install", "-ddd", "--build-from-source", "--cache=#{HOMEBREW_CACHE}/npm_cache") { `true` }
      allow(Utils).to receive(:popen_read).with("npm pack --ignore-scripts") { `echo pack.tgz` }
      resp = subject.std_npm_install_args(npm_install_arg, prepare_required: true)
      expect(resp).to include("--prefix=#{npm_install_arg}", "#{Dir.pwd}/pack.tgz")
    end

    it "raises error with non zero local npm install exitstatus" do
      allow(IO).to receive(:read).and_return("{}")
      allow(Language::Node).to receive(:safe_system).and_raise("Failure while executing: npm install -ddd")
      expect { subject.std_npm_install_args(npm_install_arg, prepare_required: true) }.to \
        raise_error("Failure while executing: npm install -ddd")
    end
  end

  specify "#local_npm_install_args" do
    resp = subject.local_npm_install_args
    expect(resp).to include("-ddd", "--build-from-source", "--cache=#{HOMEBREW_CACHE}/npm_cache")
  end
end
