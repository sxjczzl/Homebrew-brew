# @see https://www.red-gate.com/simple-talk/blogs/anatomy-of-a-net-assembly-pe-headers/
module PEShim
  DOS_HEADER_OFFSET = 0x0
  DOS_HEADER_LENGTH = 0x40
  PE_SIGNATURE_LENGTH = 0x20
  MARK_ZBIKOWSKI_ASCII = "MZ".freeze
  PE_ASCII = "PE".freeze
  DLL_MARKER = 0x2000

  ARCHITECTURE_I386 = 0x014c
  ARCHITECTURE_ARM = 0x01c4
  ARCHITECTURE_X86_64 = 0x8664
  ARCHITECTURE_AARCH64 = 0xaa64

  def read_uint8(offset)
    value = read(1, offset).unpack("C").first
	value += 256 if value < 0
	return value
  end

  def read_signature
    dos_header = read(DOS_HEADER_LENGTH, DOS_HEADER_OFFSET)
    mz_token, skip, pe_offset = dos_header.unpack('a2a58l')
    unless mz_token == MARK_ZBIKOWSKI_ASCII
      @pe = false
      return
    end

    pe_signature = read(PE_SIGNATURE_LENGTH, pe_offset)
    pe_token, skip, arch_token, skip2, characteristics = pe_signature.unpack('a2a2va16v')
    @pe = pe_token == PE_ASCII
	
	if @pe
	  @arch = case arch_token
        when ARCHITECTURE_I386 then :i386
        when ARCHITECTURE_X86_64 then :x86_64
        when ARCHITECTURE_ARM then :arm
		when ARCHITECTURE_AARCH64 then :arm64
        else :dunno
      end

      if characteristics & DLL_MARKER == DLL_MARKER
        @pe_type = :dylib
      else
        @pe_type = :executable
      end
	end
  end
  
  def pe?
    return @pe if defined? @pe
    read_signature
	return @pe
  end

  def pe_type
    return :dunno unless pe?
    return @pe_type
  end
  
  def arch
    return :dunno unless pe?
    return @arch
  end
end

