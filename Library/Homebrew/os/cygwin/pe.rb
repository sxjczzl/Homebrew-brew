# @see https://www.red-gate.com/simple-talk/blogs/anatomy-of-a-net-assembly-pe-headers/
module PEShim
  DOS_HEADER_OFFSET = 0x0
  DOS_HEADER_ASCII = "MZ".freeze
  PE_ASCII = "PE".freeze
  DLL_MARKER = 0x2000
  PE_TOKEN_LENGTH = 0x4
  PE_TOKEN_OFFSET = 0x3c

  ARCHITECTURE_OFFSET = 0x4
  ARCHITECTURE_I386 = 0x014c
  ARCHITECTURE_ARM = 0x01c4
  ARCHITECTURE_X86_64 = 0x8664
  ARCHITECTURE_AARCH64 = 0xaa64

  PE_CHARACTERISTIC_OFFSET = 0x16

  def read_uint16(offset)
    read(2, offset).unpack("v").first
  end

  def read_int32(offset)
    read(4, offset).unpack("l").first
  end

  def read_signature
    unless read(DOS_HEADER_ASCII.size, DOS_HEADER_OFFSET) == DOS_HEADER_ASCII
      @pe = false
      return
    end

    pe_offset = read_int32(PE_TOKEN_OFFSET)
    @pe = read(PE_ASCII.size, pe_offset) == PE_ASCII

    if @pe
      arch_token = read_uint16(pe_offset + ARCHITECTURE_OFFSET)
      @arch = case arch_token
        when ARCHITECTURE_I386 then :i386
        when ARCHITECTURE_X86_64 then :x86_64
        when ARCHITECTURE_ARM then :arm
        when ARCHITECTURE_AARCH64 then :arm64
        else :dunno
      end
    end

    pe_characteristics = read_uint16(pe_offset + PE_CHARACTERISTIC_OFFSET)

    if pe_characteristics & DLL_MARKER == DLL_MARKER
      @pe_type = :dylib
    else
      @pe_type = :executable
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