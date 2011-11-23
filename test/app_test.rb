require "minitest/autorun"
require "stringio"
require_relative "../lib/octarine/app"

module Octarine
  class AppTest < MiniTest::Unit::TestCase
    
    def setup
      @env = {"REQUEST_METHOD" => "GET", "SCRIPT_NAME" => "", "PATH_INFO" => "",
        "QUERY_STRING" => "", "SERVER_NAME" => "localhost",
        "SERVER_PORT" => "9292", "HTTP_HOST" => "localhost:9292",
        "rack.version" => [1,1], "rack.url_scheme" => "http",
        "rack.input" => StringIO.new, "rack.errors" => STDERR,
        "rack.multithread" => false, "rack.multiprocess" => false,
        "rack.run_once" => false}
    end
    
    def test_add
      klass = Class.new do
        include Octarine::App
        
        add "/foo" do |request|
          Octarine::Response.new("test")
        end
      end
      instance = klass.new
      
      status, header, body = instance.call(@env.merge("PATH_INFO" => "/foo"))
      
      assert_equal(200, status)
      assert_equal(["test"], body)
      
      status, header, body = instance.call(@env.merge("PATH_INFO" => "/bar"))
      
      assert_equal(404, status)
    end
    
    def test_get
      klass = Class.new do
        include Octarine::App
        
        get "/foo" do |request|
          Octarine::Response.new("test")
        end
      end
      instance = klass.new
      
      status, header, body = instance.call(@env.merge("REQUEST_METHOD" => "GET", "PATH_INFO" => "/foo"))
      
      assert_equal(200, status)
      assert_equal(["test"], body)
      
      status, header, body = instance.call(@env.merge("REQUEST_METHOD" => "GET", "PATH_INFO" => "/bar"))
      
      assert_equal(404, status)
      
      status, header, body = instance.call(@env.merge("REQUEST_METHOD" => "POST", "PATH_INFO" => "/foo"))
      
      assert_equal(405, status)
      assert_equal([], body)
    end
    
    def test_post
      klass = Class.new do
        include Octarine::App
        
        post "/foo" do |request|
          Octarine::Response.new("test")
        end
      end
      instance = klass.new
      
      status, header, body = instance.call(@env.merge("REQUEST_METHOD" => "POST", "PATH_INFO" => "/foo"))
      
      assert_equal(200, status)
      assert_equal(["test"], body)
      
      status, header, body = instance.call(@env.merge("REQUEST_METHOD" => "POST", "PATH_INFO" => "/bar"))
      
      assert_equal(404, status)
      
      status, header, body = instance.call(@env.merge("REQUEST_METHOD" => "GET", "PATH_INFO" => "/foo"))
      
      assert_equal(405, status)
      assert_equal([], body)
    end
    
    def test_delete
      klass = Class.new do
        include Octarine::App
        
        delete "/foo" do |request|
          Octarine::Response.new("test")
        end
      end
      instance = klass.new
      
      status, header, body = instance.call(@env.merge("REQUEST_METHOD" => "DELETE", "PATH_INFO" => "/foo"))
      
      assert_equal(200, status)
      assert_equal(["test"], body)
      
      status, header, body = instance.call(@env.merge("REQUEST_METHOD" => "DELETE", "PATH_INFO" => "/bar"))
      
      assert_equal(404, status)
      
      status, header, body = instance.call(@env.merge("REQUEST_METHOD" => "GET", "PATH_INFO" => "/foo"))
      
      assert_equal(405, status)
      assert_equal([], body)
    end
    
    def test_put
      klass = Class.new do
        include Octarine::App
        
        put "/foo" do |request|
          Octarine::Response.new("test")
        end
      end
      instance = klass.new
      
      status, header, body = instance.call(@env.merge("REQUEST_METHOD" => "PUT", "PATH_INFO" => "/foo"))
      
      assert_equal(200, status)
      assert_equal(["test"], body)
      
      status, header, body = instance.call(@env.merge("REQUEST_METHOD" => "PUT", "PATH_INFO" => "/bar"))
      
      assert_equal(404, status)
      
      status, header, body = instance.call(@env.merge("REQUEST_METHOD" => "GET", "PATH_INFO" => "/foo"))
      
      assert_equal(405, status)
      assert_equal([], body)
    end
    
    def test_default
      klass = Class.new do
        include Octarine::App
        
        add "/foo" do |request|
          Octarine::Response.new("test")
        end
        
        default do |request|
          Octarine::Response.new("example")
        end
      end
      instance = klass.new
      
      status, header, body = instance.call(@env.merge("REQUEST_METHOD" => "GET", "PATH_INFO" => "/foo"))
      
      assert_equal(200, status)
      assert_equal(["test"], body)
      
      status, header, body = instance.call(@env.merge("REQUEST_METHOD" => "GET", "PATH_INFO" => "/bar"))
      
      assert_equal(200, status)
      assert_equal(["example"], body)
    end
    
    def test_environment
      klass = Class.new {include Octarine::App}
      ENV["RACK_ENV"] = "test"
      assert_equal("test", klass.environment)
    end
    
    def test_environment_defaults_to_development
      klass = Class.new {include Octarine::App}
      ENV["RACK_ENV"] = nil
      assert_equal("development", klass.environment)
    end
    
    def test_convert_object_with_status_headers_and_body_to_rack_response
      response = Class.new {attr_accessor :status, :headers, :body}
      klass = Class.new do
        include Octarine::App
        
        add "/" do |request|
          response.new.tap do |res|
            res.status = 200
            res.headers = {"Content-Length" => "11"}
            res.body = "Hello world"
          end
        end
      end
      instance = klass.new
      
      status, header, body = instance.call(@env)
      
      assert_equal(200, status)
      assert_equal({"Content-Length" => "11"}, header)
      assert_equal(["Hello world"], body)
    end
    
    def test_convert_arrayable_object_to_rack_response
      response = Class.new do
        def initialize(status, headers, body)
          @status, @headers, @body = status, headers, body
        end
        def to_ary
          [@status, @headers, @body]
        end
      end
      klass = Class.new do
        include Octarine::App
        
        add "/" do |request|
          response.new(200, {"Content-Length" => "11"}, ["Hello world"])
        end
      end
      instance = klass.new
      
      status, header, body = instance.call(@env)
      
      assert_equal(200, status)
      assert_equal({"Content-Length" => "11"}, header)
      assert_equal(["Hello world"], body)
    end
    
    def test_string_response_used_as_body_wrapped_in_array
      klass = Class.new do
        include Octarine::App
        
        add "/" do |request|
          "Hello world"
        end
      end
      instance = klass.new
      
      status, header, body = instance.call(@env)
      
      assert_equal(200, status)
      assert_equal({}, header)
      assert_equal(["Hello world"], body)
    end
    
    def test_non_response_object_used_as_body
      klass = Class.new do
        include Octarine::App
        
        add "/" do |request|
          {"Hello" => "world"}
        end
      end
      instance = klass.new
      
      status, header, body = instance.call(@env)
      
      assert_equal(200, status)
      assert_equal({}, header)
      assert_equal({"Hello" => "world"}, body)
    end
    
    def test_request
      request = nil
      klass = Class.new do
        include Octarine::App
        
        get "/" do |req|
          request = req
        end
      end
      klass.new.call(@env)
      
      assert_instance_of(Octarine::Request, request)
    end
    
    def test_request_class
      request = nil
      request_klass = Class.new(Octarine::Request)
      klass = Class.new do
        include Octarine::App
        request_class request_klass
        
        get "/" do |req|
          request = req
        end
      end
      klass.new.call(@env)
      
      assert_instance_of(request_klass, request)
    end
    
  end
end
