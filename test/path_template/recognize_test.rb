require "minitest/autorun"
require_relative "../../lib/octarine/path_template"

module Octarine
  class PathTemplateRecognizeTest < MiniTest::Unit::TestCase
    
    def test_basic_variable
      template = PathTemplate.new("/test/:variable")
      
      result = template.recognize("/test/1")
      
      assert_equal({:variable => "1"}, result)
    end
    
    def test_multiple_variables
      template = PathTemplate.new("/test/:test_num/example/:example_num")
      
      result = template.recognize("/test/2/example/1")
      
      assert_equal({:test_num => "2", :example_num => "1"}, result)
    end
    
    def test_glob
      template = PathTemplate.new("/:var/b/*rest")
      
      result = template.recognize("/a/b/c/d")
      
      assert_equal({:var => "a", :rest => ["c", "d"]}, result)
    end
    
    def test_format
      template = PathTemplate.new("/:folder/:file.format")
      
      result = template.recognize("/photos/me.jpg")
      
      assert_equal({:folder => "photos", :file => "me", :format => "jpg"}, result)
    end
    
    def test_glob_with_format
      template = PathTemplate.new("/:root/*path.format")
      
      result = template.recognize("/blog/2011/11/4.html")
      
      expected = {:root => "blog", :path => %W{2011 11 4}, :format => "html"}
      assert_equal(expected, result)
    end
    
    def test_no_leading_slash
      template = PathTemplate.new(":foo/:bar")
      
      result = template.recognize("baz/qux")
      
      assert_equal({:foo => "baz", :bar => "qux"}, result)
    end
    
    def test_query_string
      template = PathTemplate.new("/:var")
      
      result = template.recognize("/foo?bar=baz&qux=quxx")
      
      assert_equal({:var => "foo", "bar" => "baz", "qux" => "quxx"}, result)
    end
    
    def test_empty_glob
      template = PathTemplate.new("/foo/*rest")
      
      result = template.recognize("/foo")
      
      assert_equal({:rest => []}, result)
    end
    
    def test_no_match
      assert_nil(PathTemplate.new("/foo/:id").recognize("/bar/1"))
      assert_nil(PathTemplate.new("/foo/:id").recognize("/foo/"))
      
      assert_nil(PathTemplate.new("/foo/:id/bar").recognize("/bar/1/foo"))
      assert_nil(PathTemplate.new("/foo/:id/bar").recognize("/foo/1"))
      
      assert_nil(PathTemplate.new("/foo/*rest").recognize("/bar/1/2/3"))
      
      assert_nil(PathTemplate.new("/foo/:file.format").recognize("/foo/bar"))
      assert_nil(PathTemplate.new("/foo/:file.format").recognize("/foo/bar/baz"))
      assert_nil(PathTemplate.new("/foo/:file.format").recognize("/f/o/o.ext"))
      
      assert_nil(PathTemplate.new("/foo/*rest.format").recognize("/foo/1/2/3"))
      
      assert_nil(PathTemplate.new("/foo").recognize("?foo=bar"))
      
      assert_nil(PathTemplate.new("/:id").recognize("1"))
      assert_nil(PathTemplate.new(":id").recognize("/1"))
    end
    
  end
end
