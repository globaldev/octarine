require "forwardable"

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
  #   path.query_string   #=> "history=true"
  #   path.to_hash        #=> {:user_id=>"1234", :message_id=>"5678", "history"=>"true"}
  #   path.query          #=> {"history"=>"true"}
  # 
  # The following methods are available and behave as if the path was a hash:
  # assoc, [], each_key, each_pair, each_value, empty?, fetch, has_key?,
  # has_value?, key, key?, keys, merge, rassoc, to_a, to_hash, value?, values,
  # values_at and all Enumerable methods
  # 
  # The following methods are available and behave as if path was a string:
  # +, =~, bytesize, gsub, length, size, sub, to_str, to_s
  # 
  class Path
    # String of the path, without the query string.
    attr_reader :path
    # String of the query string.
    attr_reader :query_string
    # Hash of the query string.
    attr_reader :query
    
    extend Forwardable
    def_delegators :@params, :assoc, :[], :each_key, :each_pair,
      :each_value, :empty?, :fetch, :has_key?, :has_value?, :key, :key?, :keys,
      :merge, :rassoc, :to_a, :value?, :values, :values_at,
      *Enumerable.public_instance_methods
    def_delegator :@params, :dup, :to_hash
    def_delegators :@full_path, :+, :=~, :bytesize, :gsub, :length, :size, :sub,
      :to_str, :to_s
    
    # :call-seq: Path.new(string, path_params, query_string) -> path
    # 
    # Create a new Path instance from the a string or the path, the path
    # parameters as a hash, and a string of the query string.
    # 
    def initialize(path, params, query_string)
      @path = path
      params.each do |key, value|
        self.class.class_eval do
          define_method(key) {@params[key]}
        end
      end
      @query_string = query_string
      @query = parse_query(@query_string)
      @full_path = @path.dup
      @full_path << "?#{@query_string}" if @query_string && !@query_string.empty?
      @params = params.merge(@query)
    end
    
    # :call-seq: path.lchomp(separator=$/) -> string
    # 
    # Like String#chomp, but removes seperator from the left of the path.
    # 
    def lchomp(separator=$/)
      string = to_s
      string.start_with?(separator) ? string[separator.length..-1] : string
    end
    
    private
    
    def parse_query(string)
      string.split("&").each_with_object({}) do |key_value, out|
        key, value = key_value.split("=")
        key, value = url_decode(key), url_decode(value)
        out[key] = out.key?(key) ? [*out[key]].push(value) : value
      end
    end
    
    def url_decode(str)
      str.tr("+", " ").gsub(/(%[0-9a-f]{2})+/i) {|m| [m.delete("%")].pack("H*")}
    end
  end
end
