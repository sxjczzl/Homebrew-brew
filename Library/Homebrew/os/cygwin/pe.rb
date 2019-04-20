# @see https://www.red-gate.com/simple-talk/blogs/anatomy-of-a-net-assembly-pe-headers/
module PEShim
  MZ_OFFSET = 0x0
  MZ_ASCII = "MZ".freeze
  PE_ASCII = "PE".freeze
  SIGNATURE_OFFSET = 0x3C

  def read_uint8(offset)
    read(1, offset).unpack("C").first
  end

  def pe?
    return @pe if defined? @pe
    return @pe = false unless read(MZ_ASCII.size, MZ_OFFSET) == MZ_ASCII

    offset=read_uint8(SIGNATURE_OFFSET)
    offset += 256 if offset < 0
    @pe = read(PE_ASCII.size, offset) == PE_ASCII
  end
end
