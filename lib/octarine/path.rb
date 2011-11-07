require "forwardable"
require_relative "path_template"

module Octarine # :nodoc:
  
  # Octarine::Path represents the path and query string portion of a url.
  # 
  # You are unlikely to need to create a Path instance yourself, insted you
  # will usually obtain one from Request#path.
  # 
  # If you set a handler like so:
  #   get "/users/:user_id/messages/:message_id" {|request| ... }
  # and a request is made like:
  #   GET /users/1234/messages/4567?history=true
  # then `request.path` will behave as below:
  #   path.user_id        #=> "1234"
  #   path[:user_id]      #=> "1234"
  #   path.message_id     #=> "5678"
  #   path[:message_id]   #=> "5678"
  #   path["history"]     #=> "true"
  #   path.to_s           #=> "/users/1234/messages/4567?history=true"
  #   path.path           #=> "/users/1234/messages/4567"
  #   path.to_hash        #=> {:user_id=>"1234", :message_id=>"5678", "history"=>"true"}
  # 
  # The following methods are available and behave as if the path was a hash:
  # assoc, [], each, each_key, each_pair, each_value, empty?, fetch, has_key?,
  # has_value?, key, key?, keys, rassoc, to_a, to_hash, value?, values,
  # values_at and all Enumerable methods
  # 
  # The following methods are available and behave as if path was a string:
  # ===, =~, bytesize, length, size
  # 
  class Path
    attr_reader :params
    attr_accessor :template
    protected :params, :template, :template=
    
    extend Forwardable
    def_delegators :@params, :assoc, :[], :each, :each_key, :each_pair,
      :each_value, :empty?, :fetch, :has_key?, :has_value?, :key, :key?, :keys,
      :rassoc, :to_a, :value?, :values, :values_at,
      *Enumerable.public_instance_methods
    def_delegator :@params, :dup, :to_hash
    def_delegators :@full_path, :===, :=~, :bytesize, :length, :size
    
    # :call-seq: Path.new(template, path_string) -> path
    # 
    # Create a new Path instance from a path template and a string of the path.
    # 
    def initialize(template, path)
      @template = Octarine::PathTemplate.new(template)
      @params = @template.recognize(path)
      
      @params.each do |key, value|
        next unless Symbol === key
        self.class.class_eval {define_method(key) {@params[key]}}
      end
    end
    
    def without(part)
      dup.tap do |cp|
        cp.template = @template.without(part)
        cp.params.delete(part)
      end
    end
    
    def merge(other)
      dup.tap {|cp| cp.params.merge!(other)}
    end
    
    def +(part)
      dup.tap {|cp| cp.template = @template + part}
    end
    
    def to_s
      @template.apply(@params)
    end
    alias to_str to_s
    
    def initialize_copy(source) # :nodoc:
      super
      @template = @template.dup
      @params = @params.dup
    end
    
  end
end
