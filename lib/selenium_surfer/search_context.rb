require 'forwardable'

module SeleniumSurfer

  # ### WebDriver Element wrapper
  #
  # Provides jQuery-like access to elements.
  #
  class SearchContext
    include Enumerable
    extend Forwardable

    def initialize(_elements, _parent)
      @elements = _elements
      @parent = _parent
    end

    # return the context's root context
    def root_context
      return @parent.root_context if @parent
      self
    end

    # return the context's parent context
    def parent_context
      @parent
    end

    # forward read-only array methods to context
    def_delegators :context, :each, :[], :length, :count, :empty?, :first, :last

    # yield individual SearchContext for each element contained in this result
    def explode(&_block)
      return enum_for(__method__) if _block.nil?
      context.each do |el|
        _block.call SearchContext.new([el], self)
      end
    end

    # searches for elements that match a given selector
    def search(_selector=nil, _options={})
      _options[:css] = _selector if _selector
      SearchContext.new search_elements(_options), self
    end

    # clears and sends_keys to this context main element
    def fill(_value)
      raise EmptySetError.new('Cannot call \'fill\' on an empty set', self) if empty?
      context.first.clear
      context.first.send_keys _value
    end

    # Any methods missing are forwarded to the main element (first).
    def method_missing(_method, *_args, &_block)
      m = /^(.*)_all$/.match _method.to_s
      if m then
        return [] if empty?
        context.map { |e| e.send(m[1], *_args, &_block) }
      else
        raise EmptySetError.new("Cannot call '#{_method}' on an empty set", self) if empty?
        context.first.send(_method, *_args, &_block)
      end
    end

    def respond_to?(_method, _include_all=false)
      return true if super
      m = /^.*_all$/.match _method.to_s
      if m then
        return true if empty?
        context.first.respond_to? m[1], _include_all
      else
        return true if empty?
        context.first.respond_to? _method, _include_all
      end
    end

  private

    def search_elements(_options)
      context.inject([]) do |r, element|
        r + element.find_elements(_options)
      end
    end

    def context
      @elements
    end

  end
end