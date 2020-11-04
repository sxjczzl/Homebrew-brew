# typed: true
# frozen_string_literal: true

class Keg
  def change_dylib_id(id, file)
    return if file.dylib_id == id

    @require_relocation = true
    odebug "Changing dylib ID of #{file}\n  from #{file.dylib_id}\n    to #{id}"
    MachO::Tools.change_dylib_id(file, id, strict: false)
    apply_ad_hoc_signature(file)
  rescue MachO::MachOError
    onoe <<~EOS
      Failed changing dylib ID of #{file}
        from #{file.dylib_id}
          to #{id}
    EOS
    raise
  end

  def change_install_name(old, new, file)
    return if old == new

    @require_relocation = true
    odebug "Changing install name in #{file}\n  from #{old}\n    to #{new}"
    MachO::Tools.change_install_name(file, old, new, strict: false)
    apply_ad_hoc_signature(file)
  rescue MachO::MachOError
    onoe <<~EOS
      Failed changing install name in #{file}
        from #{old}
          to #{new}
    EOS
    raise
  end

  def apply_ad_hoc_signature(file)
    return if MacOS.version < :catalina

    # Use quiet_system to squash notifications about resigning binaries
    # which already have valid signatures.
    unless quiet_system("codesign", "--sign", "-", "--force",
                        "--preserve-metadata=entitlements,requirements,flags,runtime",
                        file)
      onoe <<~EOS
        Failed applying an ad-hoc signature to #{file}
      EOS
    end
  end
end
