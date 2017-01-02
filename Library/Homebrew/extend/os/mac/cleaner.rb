require "vendor/macho/macho"

class Cleaner
  # Remove explicit linkages to
  def unlink_python_frameworks
    python_modules = Pathname.glob @f.lib/"python*/site-packages/**/*.so"

    python_modules.each do |obj|
      # skip modules that are symlinked in, as these usually embed a python
      # interpreter and as such require explicit linkage.
      # https://github.com/Homebrew/homebrew-core/pull/7599#issuecomment-270014332
      next if File.symlink?(obj)

      file = MachO.open(obj.to_s)

      if file.is_a?(MachO::MachOFile)
        machos = [file]
      else
        machos = file.machos
      end

      machos.each do |macho|
        macho.dylib_load_commands.each do |dylib|
          next unless /Python\.framework/ =~ dylib.name.to_s

          opoo <<-EOS.undent
            Found explicit Python framework linkage in a python module:
              #{obj}
            Homebrew will fix these, but upstreams should make an
            effort to correct their build systems by replacing
            -lpython and/or -framework Python with -undefined dynamic_lookup.
          EOS

          macho.delete_command(dylib)
        end
      end

      file.write!
    end
  end

  private

  def executable_path?(path)
    path.mach_o_executable? || path.text_executable?
  end
end
