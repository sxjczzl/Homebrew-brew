require "testing_env"
require "extend/hash"

class HashTests < Homebrew::TestCase
  def test_deep_merge
    h1 = { "a" => "b", "c" => { "d" => "e" }, "f" => { "g" => "h" } }.freeze
    h2 = { "a" => "b1", "c" => { "d" => "e1", "f" => "g" } }.freeze
    expect = { "a" => "b1", "c" => { "d" => "e1", "f" => "g"}, "f" => { "g" => "h" } }
    assert_equal expect, h1.deep_merge(h2)
  end
end

