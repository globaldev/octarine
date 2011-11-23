require "forwardable"

module Octarine # :nodoc:
  class Response
    attr_accessor :body, :status, :header
    alias headers header
    alias headers= header=
    
    extend Forwardable
    def_delegators :to_ary, :first, :last
    
    # :call-seq: Response.new(body) -> response
    # Response.new(body, header) -> response
    # Response.new(body, header, status) -> response
    # 
    # Create a new Response instance.
    # 
    def initialize(body=[], header={}, status=200)
      status, header = header, status if header.respond_to?(:to_i)
      @body = body
      @header = header
      @status = status.to_i
      header["content-type"] ||= "text/html" unless [204, 304].include?(@status)
    end
    
    # :call-seq: response.update {|body| block } -> response
    # response.update(path) {|value| block } -> response
    # 
    # Called without an argument, the block will be supplied the response body,
    # and the response body will be set to the result of the block. The response
    # itself is returned.
    # 
    # When called with an argument the body should be a hash, the body will be
    # traversed accoring to the path supplied, the value of the body will be
    # yielded to the block, and then replaced with the result of the block.
    # Example:
    #   response.body
    #   #=> {"data" => [{"user" => "1234", "message" => "..."}]}
    #   
    #   response.update("data.user") {|id| User.find(id).to_hash}
    #   
    #   response.body
    #   #=> {"data" => [{"user" => {"id" => "1234", ...}, "message" => "..."}]}
    # 
    def update(path=nil, &block)
      @body = if body.respond_to?(:to_ary) && path.nil?
        block.call(body)
      else
        apply(body, path, &block)
      end
      self
    end
    
    # :call-seq: response[key] -> value
    # 
    # Get a header.
    # 
    def [](key)
      (key.is_a?(Numeric) ? to_ary : header)[key]
    end
    
    # :call-seq: response[key] = value -> value
    # 
    # Set a header.
    # 
    def []=(key, value)
      return header[key] = value unless key.is_a?(Numeric)
      case key
      when 0
        @status = value
      when 1
        @header = value
      when 2
        @body = value
      else
        raise ArgumentError.new("Unexpected key #{key}")
      end
    end
    
    # :call-seq: response.to_ary -> array
    # response.to_a -> array
    # 
    # Convert to a Rack response array of [status, headers, body]
    # 
    def to_ary
      [status, header, body.respond_to?(:each) ? body : [body].compact]
    end
    alias to_a to_ary
    
    private
    
    def apply(object, path=nil, &block)
      if object.respond_to?(:to_ary)
        path = nil if path == "."
        return object.to_ary.map {|obj| apply(obj, path, &block)}
      end
      
      key, rest = path.split(".", 2) if path
      if rest
        object[key] = apply(object[key], rest, &block)
      elsif key
        object[key] = block.call(object[key])
      else
        return block.call(object)
      end
      object
    end
    
  end
end
