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
  attr_accessor :parent
  attr_accessor :level
  attr_accessor :id
  acts_as_traversable

  def initialize(id, level)
    @id = id
    @level = level
    @children = []
    @parent = nil
  end

  def add(child)
    @children << child
    child.parent = self

    self
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
root.add(a).add(b)
a.add(c).add(d)
c.add(e)
b.add(f)
f.add(g).add(h)

describe Traversal do
  let(:iter) { Traversal::Description.new }

  it "should test equality of traversal descriptions" do
    i1 = Traversal::Description.new.
        follow(:children).
        traverse(root).
        exclude(c)

    i2 = Traversal::Description.new.
        follow(:children).
        traverse(root).
        exclude(c)

    i3 = Traversal::Description.new.
        follow(:children).
        traverse(root).
        exclude(d)

    i1.should eq(i2)
    i1.should_not eq(i3)
  end

  it "should traverse all descendants" do
    # traverse whole tree, with default strategy (depth first)
    root.traverse(:children).
         to_a.
         should eq([root, a, c, e, d, b, f, g, h])
  end

  it "should exclude some nodes" do
    expected = [root, a, e, d, b, f, g, h]

    # this traverse will exclude only +c+ node, but not it's children
    root.traverse(:children).
         exclude { |node| node == c }.
         to_a.should eq(expected)

    # the same, but with more friendly syntax in +exclude+ section
    root.traverse(:children).
         exclude(c).
         to_a.should eq(expected)
  end

  it "should disjunct excludes" do
    # this traverse will exclude +c+ and +d+ nodes, but not their children
    root.traverse(:children).
         exclude(c).
         exclude(d).
         to_a.should eq([root, a, e, b, f, g, h])
  end

  it "should include only certain nodes" do
    root.traverse(:children).
         include_only { |node| node == c || node.parent == c }.
         should have(2).items

    root.traverse(:children).
         include_only(c).
         should have(1).items

    root.traverse(:children).
         include_only(c, d).
         should have(2).items

    root.traverse(:children).
         include_only(c).
         include_only(d).
         should have(0).items
  end

  it "should expand only certain nodes" do
    root.traverse(:children).
         expand_only(root).
         should have(3).items

    root.traverse(:children).
         expand_only(root, a).
         should have(5).items
    
    root.traverse(:children).
         expand_only(root).
         expand_only(a).
         should have(1).items
  end

  it "should prune some nodes" do
    # this traverse will exclude all +c+ children
    root.traverse(:children).
         prune(c).
         to_a.should eq([root, a, c, d, b, f, g, h])
  end

  it "should disjunct prunes" do
    # this traverse will exclude all +c+ and +f+ children
    root.traverse(:children).
         prune(c).
         prune { |node| node == f }.
         to_a.should eq([root, a, c, d, b, f])
  end

  it "should exclude and prune some nodes" do
    # this traverse will exclude +c+ and its children
    root.traverse(:children).
         exclude_and_prune(c).
         to_a.should eq([root, a, d, b, f, g, h])
  end

  it "should stop traversal after some condition met" do
    # this traversal will stop after visiting +d+ node
    root.traverse(:children).
         stop_after(d).
         to_a.should eq([root, a, c, e, d])
  end

  it "should stop traversal before some condition met" do
    # this traversal will stop before visiting +d+ node
    root.traverse(:children).
         stop_before(d).
         to_a.should eq([root, a, c, e])
  end

  it "should traverse with depth_first strategy" do
    root.traverse(:children).
         depth_first.
         exclude { |node| node.level == 3 }.
         to_a.should eq([root, a, c, d, b, f])
  end

  it "should traverse with breadth_first strategy" do
    root.traverse(:children).
         breadth_first.
         exclude { |node| node.level == 3 }.
         to_a.should eq([root, a, b, c, d, f])
  end

  it "should traverse through non-iterable relations" do
    # start from leaf, move to root
    e.traverse(:parent).last.should eq(root)
  end

  it "should ignore absent relation methods" do
    root.traverse(:child).
         exclude(root).
         to_a.should be_empty
  end

  it "should not visit nodes twice" do
    cnt = 0

    # without uniqueness it should be infinite loop
    root.traverse(:children, :parent).
         stop_after { (cnt += 1) > 100 }.
         should have(9).items
  end

  it "should visit nodes twice" do
    cnt = 0

    # without uniqueness it should be infinite loop
    root.traverse(:children, :parent).
         uniq(false).
         stop_after { (cnt += 1) > 100 }.
         should have_at_least(10).items
  end

  it "should be unique by default" do
    root.traverse(:children).should eq(root.traverse(:children).uniq)
  end

  it "should raise exception when no start node given" do
    lambda { iter.follow(:children).to_a }.should raise_error(Traversal::IncompleteDescription)
  end

  it "should raise exception when no relations given" do
    lambda { iter.traverse(root).to_a }.should raise_error(Traversal::IncompleteDescription)
  end

  it "should raise exception when description methods called without arguments and block" do
    lambda { iter.follow }.should raise_error(ArgumentError)
    lambda { iter.exclude }.should raise_error(ArgumentError)
    lambda { iter.prune }.should raise_error(ArgumentError)
    lambda { iter.exclude_and_prune }.should raise_error(ArgumentError)
    lambda { iter.stop_before }.should raise_error(ArgumentError)
    lambda { iter.stop_after }.should raise_error(ArgumentError)
  end

  it "should raise exception when non-comparable object given" do
    strange_instance = Class.new do
      undef_method :===
      undef_method :==
      undef_method :eql?
    end.new

    lambda { iter.follow(strange_instance) }.should raise_error(TypeError)
    lambda { iter.exclude(strange_instance) }.should raise_error(TypeError)
    lambda { iter.prune(strange_instance) }.should raise_error(TypeError)
    lambda { iter.exclude_and_prune(strange_instance) }.should raise_error(TypeError)
    lambda { iter.stop_before(strange_instance) }.should raise_error(TypeError)
    lambda { iter.stop_after(strange_instance) }.should raise_error(TypeError)
  end

  it "should have shortcut" do
    root.should respond_to(:traverse)

    root.traverse(:children).count.should eq(9)
  end

  it "should return Enumerable when called without block" do
    iter.traverse(root).follow(:children).each.should be_a(Enumerable)

  end
end