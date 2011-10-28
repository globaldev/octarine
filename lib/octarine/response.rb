require "forwardable"

module Octarine
  class Response
    attr_accessor :body, :status, :header
    alias headers header
    alias headers= header=
    
    extend Forwardable
    def_delegators :to_ary, :first, :last
    
    def initialize(body=[], header={}, status=200)
      status, header = header, status if header.respond_to?(:to_i)
      @body = body
      @header = header
      @status = status.to_i
      header["content-type"] ||= "text/html" unless [204, 304].include?(@status)
    end
    
    def update(path=nil, &block)
      @body = if body.respond_to?(:to_ary) && path.nil?
        block.call(body)
      else
        apply(body, path, &block)
      end
      self
    end
    
    def [](key)
      (key.is_a?(Numeric) ? to_ary : header)[key]
    end
    
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
        raise ArgumentError("Unexpected key #{key}")
      end
    end
    
    def to_ary
      [status, header, body.respond_to?(:each) ? body : [body].compact]
    end
    alias to_a to_ary
    
    private
    
    def apply(object, path=nil, &block)
      if object.respond_to?(:to_ary)
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
