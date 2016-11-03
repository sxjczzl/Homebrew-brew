class NodeRequirement < Requirement
  fatal true
  default_formula "node"

  def initialize(tags)
    @version = tags.shift if /^\d+\.\d+$/ =~ tags.first
    raise "NodeRequirement requires a version!" unless @version
    super
  end

  satisfy build_env: false do
    next false unless which "node"
    node_version = Utils.popen_read("node", "--version")[/v(\d+\.\d+)(?:\.\d+)?/, 1]
    Version.create(node_version) >= Version.create(@version)
  end

  def message
    s = "Node #{@version} is required to install this formula."
    s += super
    s
  end

  def inspect
    "#<#{self.class.name}: #{name.inspect} #{tags.inspect} version=#{@version.inspect}>"
  end

  def display_s
    if @version
      "#{name} >= #{@version}"
    else
      name
    end
  end
end
