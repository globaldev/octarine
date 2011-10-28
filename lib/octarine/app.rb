require "forwardable"
require "http_router"
require_relative "request"
require_relative "endpoint"

module Octarine # :nodoc:
  module App
    module ClassMethods
      
      ##
      # :method: add
      # :call-seq: add(path, opts={}) {|request| block }
      # 
      # Adds block as a handler for path.
      
      ##
      # :method: get
      # :call-seq: get(path, opts={}) {|request| block }
      # 
      # Adds block as a handler for path when the request method is GET.
      
      ##
      # :method: post
      # :call-seq: post(path, opts={}) {|request| block }
      # 
      # Adds block as a handler for path when the request method is POST.
      
      ##
      # :method: delete
      # :call-seq: delete(path, opts={}) {|request| block }
      # 
      # Adds block as a handler for path when the request method is DELETE.
      
      ##
      # :method: put
      # :call-seq: put(path, opts={}) {|request| block }
      # 
      # Adds block as a handler for path when the request method is PUT.
      
      ##
      # :method: default
      # :call-seq: default {|request| block }
      # 
      # Adds block as a handler for when no path is matched.
      
      [:add, :get, :post, :delete, :put, :default].each do |method|
        define_method(method) do |*args, &block|
          (@handlers ||= []) << [method, *args, block]
        end
      end
      
      def add_route(route) # :nodoc:
        (@handlers ||= []) << [__method__, route, nil]
      end
      
      # :call-seq: request_class(klass)
      # 
      # Set the class of the request object handed to the path handler blocks.
      # Defaults to Octarine::Request.
      # 
      def request_class(klass=nil)
        klass ? @request_class = klass : @request_class || Octarine::Request
      end
      
      # :call-seq: environment -> string
      # 
      # Returns the current enviroment. Defaults to "development".
      # 
      def environment
        ENV["RACK_ENV"] || "development"
      end
      
      def new(*args) # :nodoc:
        instance = super
        instance.router = HttpRouter.new
        @handlers.each do |method, *args|
          block = args.pop
          instance.router.send(method, *args) do |env|
            instance.instance_exec(request_class.new(env), &block)
          end
        end
        instance
      end
    end
    
    attr_accessor :router # :nodoc:
    
    ##
    # :method: call
    # :call-seq: app.call(env) -> array
    # 
    # Rack-compatible #call method.
    
    extend Forwardable
    def_delegators :router, :url, :call
    
    def self.included(includer) # :nodoc:
      includer.extend(ClassMethods)
    end
    
    # :call-seq: app.endpoint(string) -> endpoint
    # app.endpoint(client) -> endpoint
    # 
    # Create an Octarine::Endpoint with either a string of the host:port or
    # a client instance API compatible with Octarine::SimpleHTTP.
    # 
    def endpoint(host_or_client)
      Octarine::Endpoint.new(host_or_client)
    end
    
  end
end
