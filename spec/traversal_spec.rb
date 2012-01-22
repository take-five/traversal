require File.expand_path('../test_helper', __FILE__)

# Tree structure:
#
#         +root+
#        /     \
#      +a+     +b+
#      / \       \
#   +c+  +d+     +f+
#  /             / \
# +e+         +g+  +h+

class Node
  attr_accessor :children
  attr_accessor :level
  attr_accessor :id
  acts_as_traversable

  def initialize(id, level)
    @id = id
    @level = level
    @children = []
  end

  def inspect
    "#<Node: #{id.to_s}>"
  end
end

# create tree
root = Node.new(0, 0)
a    = Node.new(1, 1)
b    = Node.new(2, 1)
c    = Node.new(3, 2)
d    = Node.new(4, 2)
e    = Node.new(5, 3)
f    = Node.new(6, 2)
g    = Node.new(7, 3)
h    = Node.new(8, 3)

# link nodes
root.children << a << b
a.children << c << d
c.children << e
b.children << f
f.children << g << h

describe Traversal do
  let(:iter) { Traversal::Description.new }

  it "should traverse all descendants" do
    # traverse whole tree, with default strategy (depth first)
    iter.follow(:children).
         traverse(root).
         to_a.
         should eq([root, a, c, e, d, b, f, g, h])
  end

  it "should exclude some nodes" do
    # this traverse will exclude only +c+ node, but not it's children
    iter.traverse(root).
         follow(:children).
         exclude { |node| node == c }.
         to_a.should eq([root, a, e, d, b, f, g, h])
  end

  it "should disjunct excludes" do
    # this traverse will exclude +c+ and +d+ nodes, but not their children
    iter.traverse(root).
         follow(:children).
         exclude { |node| node == c }.
         exclude { |node| node == d }.
         to_a.should eq([root, a, e, b, f, g, h])
  end

  it "should prune some nodes" do
    # this traverse will exclude all +c+ children
    iter.traverse(root).
         follow(:children).
         prune { |node| node == c }.
         to_a.should eq([root, a, c, d, b, f, g, h])
  end

  it "should disjunct prunes" do
    # this traverse will exclude all +c+ and +f+ children
    iter.traverse(root).
         follow(:children).
         prune { |node| node == c }.
         prune { |node| node == f }.
         to_a.should eq([root, a, c, d, b, f])
  end

  it "should exclude and prune some nodes" do
    # this traverse will exclude +c+ and its children
    iter.traverse(root).
         follow(:children).
         exclude_and_prune { |node| node == c }.
         to_a.should eq([root, a, d, b, f, g, h])
  end

  it "should stop traversal after some condition met" do
    # this traversal will stop after visiting +d+ node
    iter.traverse(root).
         follow(:children).
         stop_after { |node| node == d }.
         to_a.should eq([root, a, c, e, d])
  end

  it "should stop traversal before some condition met" do
    # this traversal will stop before visiting +d+ node
    iter.traverse(root).
         follow(:children).
         stop_before { |node| node == d }.
         to_a.should eq([root, a, c, e])
  end

  it "should traverse with depth_first strategy" do
    iter.traverse(root).
         follow(:children).
         depth_first.
         exclude { |node| node.level == 3 }.
         to_a.should eq([root, a, c, d, b, f])
  end

  it "should traverse with breadth_first strategy" do
    iter.traverse(root).
         follow(:children).
         breadth_first.
         exclude { |node| node.level == 3 }.
         to_a.should eq([root, a, b, c, d, f])
  end

  it "should raise exception when no start node given" do
    lambda { iter.follow(:children).to_a }.should raise_error(Traversal::IncompleteDescription)
  end

  it "should raise exception when no relations given" do
    lambda { iter.traverse(root).to_a }.should raise_error(Traversal::IncompleteDescription)
  end

  it "should have shortcut" do
    root.should respond_to(:traverse)

    root.traverse(:children).count.should eq(9)
  end

  it "should return Enumerable when called without block" do
    iter.traverse(root).follow(:children).each.should be_a(Enumerable)

  end
end