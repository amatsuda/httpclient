class AVLTree
  include Enumerable

  class Node
    UNDEFINED = Object.new

    class EmptyNode
      def empty?
        true
      end

      def height
        0
      end

      def value
        nil
      end

      def size
        0
      end

      def each(&block)
        # intentionally blank
      end

      # returns new_root
      def store(key, value)
        Node.new(key, value)
      end

      # returns value
      def retrieve(key)
        UNDEFINED
      end

      # returns [deleted_node, new_root]
      def delete(key)
        [self, self]
      end

      def dump_tree(io, indent = '')
        # intentionally blank
      end

      def dump_sexp
        # intentionally blank
      end

      def rotate
        self
      end

      def update_height
        # intentionally blank
      end

      # for debugging
      def check_height
        # intentionally blank
      end
    end
    EMPTY = Node::EmptyNode.new

    attr_reader :key, :value, :height
    attr_reader :left, :right

    def initialize(key, value)
      @key, @value = key, value
      @left = @right = EMPTY
      @height = 1
    end

    def empty?
      false
    end

    def size
      @left.size + 1 + @right.size
    end

    # inorder
    def each(&block)
      @left.each(&block)
      yield [@key, @value]
      @right.each(&block)
    end

    def each_key
      each do |k, v|
        yield k
      end
    end

    def each_value
      each do |k, v|
        yield v
      end
    end

    def keys
      collect { |k, v| k }
    end

    def values
      collect { |k, v| v }
    end

    # returns new_root
    def store(key, value)
      case key <=> @key
      when -1
        @left = @left.store(key, value)
      when 0
        @value = value
      when 1
        @right = @right.store(key, value)
      end
      rotate
    end

    # returns value
    def retrieve(key)
      case key <=> @key
      when -1
        @left.retrieve(key)
      when 0
        @value
      when 1
        @right.retrieve(key)
      end
    end

    # returns [deleted_node, new_root]
    def delete(key)
      case key <=> @key
      when -1
        deleted, @left = @left.delete(key)
        [deleted, self.rotate]
      when 0
        [self, delete_self.rotate]
      when 1
        deleted, @right = @right.delete(key)
        [deleted, self.rotate]
      end
    end

    def delete_min
      if @left.empty?
        [self, delete_self]
      else
        deleted, @left = @left.delete_min
        [deleted, rotate]
      end
    end

    def delete_max
      if @right.empty?
        [self, delete_self]
      else
        deleted, @right = @right.delete_max
        [deleted, rotate]
      end
    end

    def dump_tree(io, indent = '')
      @right.dump_tree(io, indent + '  ')
      io << indent << sprintf("#<%s:0x%010x %d %s> => %s", self.class.name, __id__, height, @key.inspect, @value.inspect) << $/
      @left.dump_tree(io, indent + '  ')
    end

    def dump_sexp
      left = @left.dump_sexp
      right = @right.dump_sexp
      if left or right
        '(' + [@key, left || '-', right].compact.join(' ') + ')'
      else
        @key
      end
    end

    # for debugging
    def check_height
      @left.check_height
      @right.check_height
      lh = @left.height
      rh = @right.height
      if (lh - rh).abs > 1
        puts dump_tree(STDERR)
        raise "height unbalanced: #{lh} #{height} #{rh}"
      end
      if (lh > rh ? lh : rh) + 1 != height
        puts dump_tree(STDERR)
        raise "height calc failure: #{lh} #{height} #{rh}"
      end
    end

  protected

    def left=(left)
      @left = left
    end

    def right=(right)
      @right = right
    end

    def update_height
      @height = (@left.height > @right.height ? @left.height : @right.height) + 1
    end

    def rotate
      case @left.height - @right.height
      when +2
        if @left.left.height >= @left.right.height
          root = rotate_LL
        else
          root = rotate_LR
        end
      when -2
        if @right.left.height <= @right.right.height
          root = rotate_RR
        else
          root = rotate_RL
        end
      else
        root = self
      end
      root.update_height
      root
    end

  private

    def delete_self
      if @left.empty? and @right.empty?
        deleted = EMPTY
      elsif @right.height < @left.height
        deleted, new_left = @left.delete_max
        deleted.left, deleted.right = new_left, @right
      else
        deleted, new_right = @right.delete_min
        deleted.left, deleted.right = @left, new_right
      end
      deleted
    end

    # Right single rotation
    # (B a (D c E)) where D-a > 1 && E > c --> (D (B a c) E)
    #
    #   B              D
    #  / \            / \
    # a   D    ->    B   E
    #    / \        / \
    #   c   E      a   c
    #
    def rotate_RR
      root = @right
      @right = root.left
      root.left = self
      root.left.update_height
      root
    end

    # Left single rotation
    # (D (B A c) e) where B-e > 1 && A > c --> (B A (D c e))
    #
    #     D          B
    #    / \        / \
    #   B   e  ->  A   D
    #  / \            / \
    # A   c          c   e
    #
    def rotate_LL
      root = @left
      @left = root.right
      root.right = self
      root.right.update_height
      root
    end

    # Right double rotation
    # (B a (F (D c e) g)) where F-a > 1 && D > g --> (D (B a c) (F e g))
    #
    #   B               D
    #  / \            /   \
    # a   F    ->    B     F
    #    / \        / \   / \
    #   D   g      a   c e   g
    #  / \
    # c   e
    #
    def rotate_RL
      other = @right
      root = other.left
      @right = root.left
      other.left = root.right
      root.left = self
      root.right = other
      root.left.update_height
      root.right.update_height
      root
    end

    # Left double rotation
    # (F (B a (D c e)) g) where B-g > 1 && D > a --> (D (B a c) (F e g))
    #
    #     F             D
    #    / \          /   \
    #   B   g  ->    B     F
    #  / \          / \   / \
    # a   D        a   c e   g
    #    / \
    #   c   e
    #
    def rotate_LR
      other = @left
      root = other.right
      @left = root.right
      other.right = root.left
      root.right = self
      root.left = other
      root.left.update_height
      root.right.update_height
      root
    end

    def collect
      pool = []
      each do |key, value|
        pool << yield(key, value)
      end
      pool
    end
  end

  DEFAULT = Object.new

  attr_accessor :default
  attr_reader :default_proc

  def initialize(default = DEFAULT, &block)
    if block && default != DEFAULT
      raise ArgumentError, 'wrong number of arguments'
    end
    @root = Node::EMPTY
    @default = default
    @default_proc = block
  end

  def empty?
    @root == Node::EMPTY
  end

  def size
    @root.size
  end
  alias length size

  def each(&block)
    if block_given?
      @root.each(&block)
      self
    else
      Enumerator.new(@root)
    end
  end
  alias each_pair each

  def each_key
    if block_given?
      @root.each do |k, v|
        yield k
      end
      self
    else
      Enumerator.new(@root, :each_key)
    end
  end

  def each_value
    if block_given?
      @root.each do |k, v|
        yield v
      end
      self
    else
      Enumerator.new(@root, :each_value)
    end
  end

  def keys
    @root.keys
  end

  def values
    @root.values
  end

  def clear
    @root = Node::EMPTY
  end

  def []=(key, value)
    @root = @root.store(key.to_s, value)
  end
  alias store []=

  def key?(key)
    @root.retrieve(key.to_s) != Node::UNDEFINED
  end
  alias has_key? key?

  def [](key)
    value = @root.retrieve(key.to_s)
    if value == Node::UNDEFINED
      default_value
    else
      value
    end
  end

  def delete(key)
    deleted, @root = @root.delete(key.to_s)
    deleted.value
  end

  def dump_tree(io = '')
    @root.dump_tree(io)
    io << $/
    io
  end

  def dump_sexp
    @root.dump_sexp || ''
  end

  def to_hash
    inject({}) { |r, (k, v)| r[k] = v; r }
  end

private

  def default_value
    if @default != DEFAULT
      @default
    elsif @default_proc
      @default_proc.call
    else
      nil
    end
  end
end
