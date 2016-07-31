require "os"

module Hardware
  class CPU
    INTEL_64BIT_ARCHS = [:x86_64].freeze

    class << self
      OPTIMIZATION_FLAGS = {
        :penryn => "-march=core2 -msse4.1",
        :core2 => "-march=core2",
        :core => "-march=prescott",
        :dunno => "",
      }.freeze

      def optimization_flags
        OPTIMIZATION_FLAGS
      end

      def arch_32_bit
        :i386
      end

      def arch_64_bit
        :x86_64
      end

      def type
        :intel
      end

      def family
        :haswell
      end

      def cores
        8
      end

      def bits
        64
      end

      def sse4?
        RUBY_PLATFORM.to_s.include?("x86_64")
      end

      def is_32_bit?
        bits == 32
      end

      def is_64_bit?
        bits == 64
      end

      def intel?
        type == :intel
      end

      def ppc?
        type == :ppc
      end

      def arm?
        type == :arm
      end

      def features
        []
      end

      def feature?(name)
        features.include?(name)
      end
    end
  end

  def self.cores_as_words
    case Hardware::CPU.cores
    when 1 then "single"
    when 2 then "dual"
    when 4 then "quad"
    when 6 then "hexa"
    when 8 then "octa"
    else
      Hardware::CPU.cores
    end
  end

  def self.oldest_cpu
    :haswell
  end
end

require "extend/os/hardware"
