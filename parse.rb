require 'pry'
require 'json'

class LocParser
  def initialize(loc_file_location)
    @loc_file_location = loc_file_location
    @current_class = nil
    @current_subclass = nil
    @current_level = nil
    @last_node = nil
    @current_depth = 1

    @last_nodes_at_depth = {}
  end

  def to_nodes
    @file = File.open(@loc_file_location, encoding: 'windows-1252')

    root = @last_node = LocNode.new("root")
    @last_parent = @last_node
    @last_nodes_at_depth[0] = root

    @file.readlines[1..-1].each do |line|
      next if bullshit?(line)

      if current_class(line)
        name = current_class(line)
        current_depth = 1
      elsif current_subclass(line)
        name = current_subclass(line)
        current_depth = 2
      else
        name = category(line)
        current_depth = category_depth(line) + 2
      end

      if current_depth > @current_depth
        parent = @last_node
      elsif current_depth < @current_depth
        parent = @last_nodes_at_depth[current_depth - 1]
      else
        parent = @last_parent
      end

      node = LocNode.new(name)
      node.parent = parent
      node.depth = current_depth
      parent.children.push(node)

      @last_node = node
      @last_parent = parent
      @current_depth = current_depth
      @last_nodes_at_depth[current_depth] = node
    end

    root
  end

  def to_hash
    to_nodes.to_hash
  end

  def current_class(line)
    return nil unless line.strip.match(/^class [a-z]/i)
    line.strip
  end

  def current_subclass(line)
    return nil unless line.strip.match(/^subclass ..?$/i)
    line.strip
  end

  def category_depth(line)
    line.split("\t")[0..-2].length
  end

  def category(line)
    line.split("\t").last.strip
  end

  def bullshit?(line)
    return true if line.strip.empty?
    return line.upcase.strip == "LIBRARY OF CONGRESS CLASSIFICATION OUTLINE"
  end
end

class LocNode
  attr_accessor :parent, :depth, :type
  attr_reader :children, :name

  def initialize(name)
    @name = name
    @children = []
  end

  def to_hash
    children.reduce({}) do |memo, child|
      memo[child.name] = child.to_hash
      memo
    end
  end
end

parser = LocParser.new("./lc_class.txt")
puts JSON.dump(parser.to_hash)
