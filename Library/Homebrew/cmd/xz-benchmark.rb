require "benchmark"
require "formula"
require "resource"
require "checksum"

module Homebrew
  XZ_BOTTLE_PREFIX = "https://dl.bintray.com/kabel/bottles-xz/".freeze
  BOOST_HIGH_SIERRA_BOTTLE = "boost-1.66.0.high_sierra.bottle.tar".freeze

  module_function

  def xz_benchmark
    xz_resource = Resource.new
    gzip_resource = Resource.new

    xz_resource.url XZ_BOTTLE_PREFIX + BOOST_HIGH_SIERRA_BOTTLE + ".xz"
    xz_resource.checksum = Checksum.new "sha256", "3e2430de82603d2bec2321c8f83cfbc3807fb8b8a998d464a3d3d18494fad1bb"

    gzip_resource.url XZ_BOTTLE_PREFIX + BOOST_HIGH_SIERRA_BOTTLE + ".gz"
    gzip_resource.checksum = Checksum.new "sha256", "78cb090c515e20aa7307c6619a055ffd8858cc6a3bd756958edbf34f463e4bc1"

    xz_resource.name = gzip_resource.name = "benchmark"
    xz_resource.owner = gzip_resource.owner = Formulary.factory "boost"
    xz_resource.download_strategy = gzip_resource.download_strategy = CurlBottleDownloadStrategy
    xz_resource.version = gzip_resource.version = PkgVersion.new "1.66", 0

    gzip_real = 0
    xz_real = 0

    Benchmark.bm(10, ">xz", ">gzip") do |x|
      xz_fetch = x.report("xz:fetch") { nostdout { xz_resource.fetch } }
      xz_stage = x.report("xz:stage") { nostdout { xz_resource.stage {} } }
      gzip_fetch = x.report("gzip:fetch") { nostdout { gzip_resource.fetch } }
      gzip_stage = x.report("gzip:stage") { nostdout { gzip_resource.stage {} } }

      xz_total = xz_fetch + xz_stage
      gzip_total = gzip_fetch + gzip_stage
      xz_real = xz_total.real
      gzip_real = gzip_total.real

      [xz_total, gzip_total]
    end

    xz_size = xz_resource.cached_download.size
    gzip_size = gzip_resource.cached_download.size
    diff_size = gzip_size - xz_size
    diff_size_pct = diff_size.to_f / gzip_size * 100
    diff_real = gzip_real - xz_real
    diff_real_pct = diff_real / gzip_real * 100

    xz_size_f = format "%6s", disk_usage_readable(xz_size)
    gzip_size_f = format "%6s", disk_usage_readable(gzip_size)
    diff_size_f = format "%6s", disk_usage_readable(diff_size)
    diff_size_pct_f = format "%4.1f", diff_size_pct
    diff_real_f = format "%7.3f", diff_real
    diff_real_pct_f = format "%5.1f", diff_real_pct

    puts "               xz    gzip    diff  diff%"
    puts "Filesize   #{xz_size_f}  #{gzip_size_f}  #{diff_size_f}   #{diff_size_pct_f}"
    puts "Real                      #{diff_real_f}  #{diff_real_pct_f}"

    xz_resource.clear_cache
    gzip_resource.clear_cache
  end
end
