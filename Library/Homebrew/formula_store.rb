module FormulaStore
  class << self
    STORE_FILE = Pathname.new HOMEBREW_CACHE/"formula_store.bin"

    @_at_exit_registered = false

    def _register_at_exit
      at_exit { save_store }
      @_at_exit_registered = true
    end

    def register_at_exit
      _register_at_exit unless @_at_exit_registered
    end

    def load_store
      return {} unless STORE_FILE.exist?
      Marshal.load(File.binread(STORE_FILE))
    end

    def store
      @store ||= load_store
    end

    def save_store
      File.open(STORE_FILE, 'wb') {|f| f.write(Marshal.dump(store))}
    end

    def stored?(path)
      store.has_key?(path.to_s)
    end

    def store_formula(path)
      return store[path] if stored?(path) and store[path.to_s]["mtime"] == path.mtime.to_i

      contents = path.open("r") { |f| Formulary.ensure_utf8_encoding(f).read }

      parts = contents.split(/^__END__$/)
      mod = <<-EOS
        module FormulaNamespace#{Digest::MD5.hexdigest(path.to_s)}
          #{parts[0]}
        end
      EOS

      byte_code = RubyVM::InstructionSequence.new(mod, path.basename.to_s, path.realpath.to_s)

      register_at_exit

      store[path.realpath.to_s] = {
        "byte_code" => byte_code.to_binary,
        "extra_data" => parts[1],
        "mtime" => path.mtime.to_i
      }
    end

    def unstore_formula(path)
      register_at_exit
      store.delete path
    end

    def store_tap(tap)
      tap.formula_files.each do |file|
        store_formula file
      end
    end

    def unstore_tap(tap)
      tap.formula_files.each do |file|
        unstore_formula file
      end
    end
  end
end
