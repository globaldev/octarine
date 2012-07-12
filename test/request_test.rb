require "minitest/autorun"
require "stringio"
require_relative "../lib/octarine/request"

module Octarine
  class RequestTest < MiniTest::Unit::TestCase
    
    def setup
      @env = {"REQUEST_METHOD" => "GET", "SCRIPT_NAME" => "", "PATH_INFO" => "/",
        "QUERY_STRING" => "", "SERVER_NAME" => "localhost",
        "SERVER_PORT" => "9292", "HTTP_VERSION" => "HTTP/1.1",
        "HTTP_HOST" => "localhost:9292", "rack.version" => [1,1],
        "rack.url_scheme" => "http", "rack.input" => StringIO.new,
        "rack.errors" => STDERR, "rack.multithread" => false,
        "rack.multiprocess" => false, "rack.run_once" => false}
      @original_simple_http = Octarine::SimpleHTTP
      @mock_client_class = MiniTest::Mock.new
      capture_io {Octarine.const_set(:SimpleHTTP, @mock_client_class)}
      @response_klass = Struct.new(:status, :headers, :body)
    end
    
    def teardown
      capture_io {Octarine.const_set(:SimpleHTTP, @original_simple_http)}
    end
    
    def test_get_header
      headers = {"CONTENT_LENGTH" => "11", "CONTENT_TYPE" => "text/plain",
        "HTTP_ACCEPT" => "text/plain,text/html"}
      request = Octarine::Request.new(@env.merge(headers))
      
      assert_equal("localhost:9292", request["Host"])
      assert_equal("11", request["Content-Length"])
      assert_equal("text/plain", request["Content-Type"])
      assert_equal("text/plain,text/html", request["Accept"])
    end
    
    def test_to
      request = Octarine::Request.new(@env.merge("PATH_INFO" => "/test"))
      
      @mock_client = MiniTest::Mock.new
      response = @response_klass.new(200, {"content-length" => "4", "content-type" => "text/plain"}, "test")
      @mock_client.expect(:get, response, [Octarine::Path.new("/test", "/test"), {}])
      @mock_client_class.expect(:new, @mock_client, ["example.com"])
      
      result = request.to("example.com")
      
      @mock_client.verify
      assert_equal(200, result.status)
      assert_equal({"content-type" => "text/plain"}, result.headers)
      assert_equal("test", result.body)
    end
    
    def test_to_with_query
      request = Octarine::Request.new(@env.merge("PATH_INFO" => "/test", "QUERY_STRING" => "foo=bar&baz=qux"))
      
      @mock_client = MiniTest::Mock.new
      response = @response_klass.new(200, {"content-length" => "4", "content-type" => "text/plain"}, "test")
      @mock_client.expect(:get, response, [Octarine::Path.new("/test", "/test?foo=bar&baz=qux"), {}])
      @mock_client_class.expect(:new, @mock_client, ["example.com"])
      
      result = request.to("example.com")
      
      @mock_client.verify
      assert_equal(200, result.status)
      assert_equal({"content-type" => "text/plain"}, result.headers)
      assert_equal("test", result.body)
    end
    
    def test_post_to
      request = Octarine::Request.new(@env.merge("REQUEST_METHOD" => "POST", "PATH_INFO" => "/submit", "CONTENT_TYPE" => "application/x-www-form-urlencoded", "rack.input" => StringIO.new("foo=bar")))
      
      @mock_client = MiniTest::Mock.new
      response = @response_klass.new(200, {"content-length" => "3", "content-type" => "text/plain"}, "baz")
      @mock_client.expect(:post, response, [Octarine::Path.new("/submit", "/submit"), StringIO, {"content-type" => "application/x-www-form-urlencoded"}])
      @mock_client_class.expect(:new, @mock_client, ["example.com"])
      
      result = request.to("example.com")
      
      @mock_client.verify
      assert_equal(200, result.status)
      assert_equal({"content-type" => "text/plain"}, result.headers)
      assert_equal("baz", result.body)
    end
    
    def test_options_to
      request = Octarine::Request.new(@env.merge("REQUEST_METHOD" => "OPTIONS", "PATH_INFO" => "/test"))
      
      @mock_client = MiniTest::Mock.new
      response = @response_klass.new(204, {"allow" => "GET"}, nil)
      @mock_client.expect(:run_request, response, [:options, Octarine::Path.new("/test", "/test"), {}])
      @mock_client_class.expect(:new, @mock_client, ["example.com"])
      
      result = request.to("example.com")
      
      @mock_client.verify
      assert_equal(204, result.status)
      assert_equal({"allow" => "GET"}, result.headers)
      assert_nil(result.body)
    end
    
    def test_to_s
      request = Octarine::Request.new(@env.merge("HTTP_ACCEPT" => "text/plain"))
      
      assert_equal("GET / HTTP/1.1\r\nHost: localhost:9292\r\nAccept: text/plain\r\n\r\n", request.to_s)
    end
    
  end
end