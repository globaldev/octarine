require "forwardable"
require "http_router"
require_relative "request"
require_relative "endpoint"

module Octarine
  module App
    module ClassMethods
      [:add, :get, :post, :delete, :put, :default].each do |method|
        define_method(method) do |*args, &block|
          (@handlers ||= []) << [method, *args, block]
        end
      end
      
      def add_route(route)
        (@handlers ||= []) << [__method__, route, nil]
      end
      
      def request_class(klass=nil)
        klass ? @request_class = klass : @request_class || Octarine::Request
      end
      
      def environment
        ENV["RACK_ENV"] || "development"
      end
      
      def new(*args)
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
    
    attr_accessor :router
    
    extend Forwardable
    def_delegators :router, :url, :call
    
    def self.included(includer)
      includer.extend(ClassMethods)
    end
    
    def endpoint(host_or_client)
      Octarine::Endpoint.new(host_or_client)
    end
    
  end
end
