module SharedEnvExtension
  def no_weak_imports_support?
    return false unless compiler == :clang

    if MacOS::Xcode.installed? && MacOS::Xcode.version >= "8.0"
      return true
    end

    if MacOS::CLT.version && MacOS::CLT.version >= "8.0"
      return true
    end

    false
  end
end
