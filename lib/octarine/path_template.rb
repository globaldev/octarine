module Octarine
  class PathTemplate
    BadTemplateError = Class.new(ArgumentError)
    
    module StringExtention
      def /(arg)
        PathTemplate.new(self).apply(*arg.respond_to?(:to_ary) ? arg : [arg])
      end
    end
    
    attr_reader :parts
    protected :parts
    
    def initialize(string)
      @parts = parse(string)
    end
    
    def apply(*args)
      params = args.last.respond_to?(:each) ? args.pop.dup : {}
      
      @parts.find {|type, val| params[val] ||= args.pop if type == :format}
      @parts.select do |type, value|
        params[value] ||= args.shift if type == :variable && !args.empty?
      end
      @parts.find {|type, val| params[val] ||= args if type == :glob}
      
      format = nil
      path = []
      @parts.each do |type, value|
        case type
        when :variable
          path << params.delete(value)
        when :glob
          path << params.delete(value).join("/")
        when :format
          format = params.delete(value)
        else
          path << value
        end
      end
      
      out = path.join("/")
      out << ".#{format}" if format
      out << query(params) if !params.empty?
      out
    end
    
    def recognize(string)
      other_parts = parse(string).each
      params = {}
      
      @parts.each do |type, value|
        other_type, other_value = (other_parts.next rescue nil)
        case type
        when :variable
          return unless other_value
          params[value] = other_value
        when :glob
          params[value] = other_value ? [other_value] : []
          while (other_parts.peek.first == :string rescue nil)
            other_type, other_value = other_parts.next
            params[value] << other_value
          end
        when :format
          return nil unless type == other_type
          params[value] = other_value.to_s
        when :string
          return nil unless type == other_type && value == other_value
        end
      end
      other_type, other_value = (other_parts.next rescue nil)
      return nil unless other_type == :query_string || other_type.nil?
      if other_value
        query = parse_query(other_value)
        params.merge!(query)
      end
      params
    end
    alias === recognize
    
    def +(string)
      parts = parse(string)
      parts.shift if parts.first == [:leading_joiner, nil]
      dup.tap {|cp| cp.parts.concat(parts)}
    end
    
    def without(string)
      part = parse(string).first
      dup.tap {|cp| cp.parts.reject! {|pt| pt == part}}
    end
    alias - without
    
    def ==(other)
      self.class === other && parts == other.parts
    end
    
    def initialize_copy(source)
      super
      @parts = @parts.dup
    end
    
    private
    
    def query(params)
      return nil if !params || params.empty?
      "?" << params.map {|kv| kv.join("=")}.join("&")
    end
    
    def tokenize(string)
      string.scan(%r{([/:*.?]|[^/:*.?]+)}).flatten
    end
    
    def lex(tokens)
      enum = tokens.each
      parts = []
      seen_glob = false
      seen_format = false
      
      parts << [:leading_joiner, nil] if enum.peek == "/"
      while part = enum.next
        raise BadTemplateError.new(".format must be last") if seen_format
        
        case part
        when "/"
        when ":"
          raise BadTemplateError.new(":variable cannot follow *glob") if seen_glob
          parts << [:variable, enum.next.to_sym]
        when "*"
          raise BadTemplateError.new("multiple *glob not allowed") if seen_glob
          seen_glob = true
          parts << [:glob, enum.next.to_sym]
        when "."
          seen_format = true
          parts << [:format, enum.next.to_sym]
        when "?"
          parts << [:query_string, enum.next.freeze]
        else
          parts << [:string, part.freeze]
        end
      end
      parts
    rescue StopIteration
      parts
    end
    
    def parse(string)
      string = Symbol === string ? ":#{string}" : string.to_s
      lex(tokenize(string))
    end
    
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
