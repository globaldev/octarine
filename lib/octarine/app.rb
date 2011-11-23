require "forwardable"
require "http_router"
require_relative "request"
require_relative "path"

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
      
      [:add, :get, :post, :delete, :put].each do |method|
        define_method(method) do |*args, &block|
          (@handlers ||= []) << [method, *args, block]
        end
      end
      
      # :call-seq: default {|request| block }
      # 
      # Adds block as a handler for when no path is matched.
      # 
      def default(&block)
        @default = block
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
        super.tap do |instance|
          instance.router = HttpRouter.new
          @handlers.each do |method, *args|
            block = args.pop
            route = instance.router.send(method, *args)
            route.to do |env|
              env.merge!("router.route" => route.original_path)
              response = instance.instance_exec(request_class.new(env), &block)
              to_rack_response(response)
            end
          end
          instance.router.default(Proc.new do |env|
            response = instance.instance_exec(request_class.new(env), &@default)
            to_rack_response(response)
          end) if @default
        end
      end
      
      private
      
      def to_rack_response(res)
        if res.respond_to?(:status) && res.respond_to?(:headers) &&
          res.respond_to?(:body)
          status, headers, body = res.status, res.headers, res.body
          [status, headers, body.respond_to?(:each) ? body : [body].compact]
        elsif res.respond_to?(:to_ary)
          res.to_ary
        elsif res.respond_to?(:to_str)
          [200, {}, [res.to_str]]
        else
          [200, {}, res]
        end
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
    
  end
end
