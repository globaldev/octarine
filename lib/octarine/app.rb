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
      
      ##
      # :method: default
      # :call-seq: default {|request| block }
      # 
      # Adds block as a handler for when no path is matched.
      
      [:add, :get, :post, :delete, :put, :default].each do |method|
        define_method(method) do |*args, &block|
          if Hash === args.last
            restrictions = Array(args.last[:restrict])
          else
            restrictions = []
            args << {}
          end
          restrictions << @current_restriction if @current_restriction
          args.last[:restrict] = restrictions.flatten
          (@handlers ||= []) << [method, *args, block]
        end
      end
      
      # :call-seq:
      #   restriction(name, response=401) {|request| block }
      #   restriction(name, response=401, proc)
      # 
      # Create a named restriction. response will be returned if the block
      # returns true, otherwise the handler subject to the restriction will be
      # executed as usual.
      # 
      def restriction(name, response=401, proc=nil, &block)
        (@restrictions ||= {})[name] = [response, proc || block]
      end
      
      # :call-seq: restrict(name) { block }
      # 
      # All handlers defined within the block will be subject to the named
      # restriction.
      # 
      def restrict(restriction)
        (@current_restriction ||= []) << restriction
        yield
      ensure
        @current_restriction.pop
      end
      
      # Set the class of the request object handed to the path handler blocks.
      # Defaults to Octarine::Request.
      # 
      attr_writer :request_class
      alias request_class request_class=
      
      # :call-seq: environment -> string
      # 
      # Returns the current enviroment. Defaults to "development".
      # 
      def environment
        ENV["RACK_ENV"] || "development"
      end
      
      def new(*args) # :nodoc:
        request_class = @request_class || Octarine::Request
        restrictions = @restrictions
        handlers = @handlers
        super.instance_eval do
          @request_class ||= request_class
          @router ||= HttpRouter.new
          @restrictions = restrictions
          handlers.each {|m,*args| register_handler(m, *args[0..-2], &args[-1])}
          self
        end
      end
      
    end
    
    extend Forwardable
    
    attr_reader :router, :request_class
    
    ##
    # :method: call
    # :call-seq: app.call(env) -> array
    # 
    # Rack-compatible #call method.
    # 
    def_delegator :router, :call
    
    def self.included(includer) # :nodoc:
      includer.extend(ClassMethods)
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
      elsif res.respond_to?(:to_i)
        [res.to_i, {}, []]
      else
        [200, {}, res]
      end
    end
    
    def register_handler(method, *args, &block)
      return register_default(&block) if method == :default
      restrictions = Hash === args[-1] ? Array(args[-1].delete(:restrict)) : []
      restrictions.map! {|name| @restrictions[name]}
      route = router.send(method, *args)
      route.to do |env|
        env.merge!("router.route" => route.original_path)
        request = request_class.new(env)
        response, = restrictions.find {|_,restr| instance_exec(request, &restr)}
        response ||= instance_exec(request, &block)
        to_rack_response(response)
      end
    end
    
    def register_default(&block)
      router.default(Proc.new do |env|
        to_rack_response(instance_exec(request_class.new(env), &block))
      end)
    end
    
  end
end
