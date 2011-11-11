require "minitest/autorun"
require_relative "../../lib/octarine"
module Octarine
  class PathTemplateModifierTest < MiniTest::Unit::TestCase
    
    def test_without_string
      template = PathTemplate.new("/foo/:foo/bar/:bar")
      
      minus_foo_string = template.without("foo")
      result = minus_foo_string.apply(foo: 1, bar: 2)
      
      assert_equal("/1/bar/2", result)
    end
    
    def test_without_symbol
      template = PathTemplate.new("/foo/:foo/bar/:bar")
      
      minus_foo_symbol = template.without(:foo)
      result = minus_foo_symbol.apply(bar: 1)
      
      assert_equal("/foo/bar/1", result)
    end
    
    def test_without_doesnt_modify_original
      template = PathTemplate.new("/foo/:foo/bar/:bar")
      
      minus_foo_string = template.without("foo")
      
      assert_equal("/1/bar/2", minus_foo_string.apply(foo: 1, bar: 2))
      assert_equal("/foo/1/bar/2", template.apply(foo: 1, bar: 2))
    end
    
    def test_without_aliased_as_minus
      template = PathTemplate.new("/foo/:foo/bar/:bar")
      
      result = (template - "foo").apply(foo: 1, bar: 2)
      
      assert_equal("/1/bar/2", result)
    end
    
    def test_plus_with_string
      a = PathTemplate.new("/foo/:bar/baz/:qux")
      b = PathTemplate.new("/foo/:bar")
      
      assert_equal(a, b + "/baz/:qux")
      assert_equal("/foo/1/baz/2", (b + "/baz/:qux").apply(bar: 1, qux: 2))
    end
    
  end
end
