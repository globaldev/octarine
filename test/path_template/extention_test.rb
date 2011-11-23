require "minitest/autorun"
require_relative "../../lib/octarine/path_template"

module Octarine
  class StringExtentionRecognizeTest < MiniTest::Unit::TestCase
    
    def test_string_extention
      string = "/blog/:year/:month/:day"
      string.extend(PathTemplate::StringExtention)
      
      result = string / {year: 2011, month: "nov", day: 4}
      
      assert_equal("/blog/2011/nov/4", result)
    end
    
    def test_positional_string_extention
      string = "/blog/:year/:month/:day"
      string.extend(PathTemplate::StringExtention)
      
      result = string / [2011, "nov", 4]
      
      assert_equal("/blog/2011/nov/4", result)
    end
    
  end
end
