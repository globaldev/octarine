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
    # response.update(path[, opts]) {|value| block } -> response
    # 
    # Called without an argument, the block will be supplied the response body,
    # and the response body will be set to the result of the block. The response
    # itself is returned.
    # 
    # When called with a path argument the body should be a hash, the body will
    # be traversed accoring to the path supplied, the value of the body will be
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
    # Additional options can be passed as a hash, the options available are:
    # [remove]    The full path to the element that should be removed if the
    #             block returns nil. Must be a parent of the element targeted
    #             by the main path argument
    # [remove_if] If supplied along with the remove option the result of the
    #             block will be tested againt this value (using ===) rather
    #             than nil
    # [link]      Should be supplied with a value of a hash, in which the key
    #             is a path to an element to be updated, and the value is an
    #             array of a an element and a method from which to derive a
    #             value
    # Example:
    #   response.body
    #   #=> {"data" => [1, 2, 3], "total" => 3}
    #   
    #   user_names = {1 => "Arthur", 2 => "Ford"}
    #   
    #   total_to_length = {"total" => ["data", :length]}
    #   response.update("data.", remove: "data.", link: total_to_length) do |id|
    #     user_names[id]
    #   end
    #   
    #   response.body
    #   # {"data" => ["Arthur", "Ford"], "total" => 2}
    # 
    def update(path=nil, options={}, &block)
      @body = if body.respond_to?(:to_ary) && path.nil?
        block.call(body)
      else
        path = nil if path == "."
        remove_path = options[:remove]
        remove_if = remove_path ? options[:remove_if] : -> x {false}
        apply(body, path, remove_path, remove_if, &block)
      end
      (options[:link] || []).each do |dest, (source_path, source_method)|
        update(dest) do |val|
          source = body
          source_path.split(".").each do |part|
            source = source[part]
          end
          source.send(source_method)
        end
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
    
    def apply(object, path=nil, remove_path=nil, remove_flag=nil, &block)
      if object.respond_to?(:to_ary)
        return object.to_ary.each_with_object([]) do |obj, collection|
          result = catch :remove do
            apply(obj, path, remove_path, remove_flag, &block)
          end
          if result != :__remove__
            collection << result
          elsif remove_path.nil?
            throw :remove, :__remove__
          end
        end
      end
      
      remove_key, remove_rest = remove_path.split(".", 2) if remove_path
      
      key, rest = path.split(".", 2) if path
      if rest
        object[key] = apply(object[key], rest, remove_rest, remove_flag, &block)
      elsif key
        result = block.call(object[key])
        should_remove = remove_flag === result
        if should_remove && key == remove_path
          object.delete(key)
        elsif should_remove
          throw :remove, :__remove__
        else
          object[key] = result
        end
      else
        result = block.call(object)
        throw :remove, :__remove__ if remove_flag === result
        return result
      end
      object
    end
    
  end
end
