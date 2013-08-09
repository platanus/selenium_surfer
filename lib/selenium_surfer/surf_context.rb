module SeleniumSurfer

  # ### Base class for robot contexts
  #
  class SurfContext < SearchContext

    # add a macro attribute writer to context.
    #
    # A macro attribute persist through context changes.
    #
    def self.macro_attr_writer(*_names)
      _names.each do |name|
        send :define_method, "#{name}=" do |v| @macro[name.to_sym] = v end
      end
    end

    # add a macro attribute reader to context.
    #
    # A macro attribute persist through context changes.
    #
    def self.macro_attr_reader(*_names)
      _names.each do |name|
        send :define_method, "#{name}" do @macro[name.to_sym] end
      end
    end

    # add a macro attribute accessor to context.
    #
    # A macro attribute persist through context changes.
    #
    def self.macro_attr_accessor(*_names)
      macro_attr_reader *_names
      macro_attr_writer *_names
    end

    macro_attr_accessor :max_retries

    def initialize(_bucket, _macro=nil, _stack=nil)
      @bucket = _bucket
      @macro = _macro || {}
      @stack = _stack || []

      @bucket.bind self
    end

    # return true if context is bound
    def bound?
      not @bucket.nil?
    end

    # switch to another context
    # new context class should be a SurfContext subclass
    def switch_to(_klass=nil)
      raise UnboundContextError.new unless bound?
      _klass.new @bucket, @macro, @stack
    end

    # ## Helpers

    # retrieves the current driver being used by this context
    def driver
      load_driver
    end

    # return the current page title
    def title
      load_driver.title
    end

    # navigate to a given url (uses the max_retries setting)
    def navigate(_url, _params=nil)
      _url += "?#{_params.to_query}" if _params
      retries = 0

      loop do
        begin
          load_driver(retries > 0).get(_url)
          @stack = [] # clear stack after successfull navigation
          break
        rescue Timeout::Error, Selenium::WebDriver::Error::UnknownError
          trace "Error when opening #{_url}!"
          raise if retries >= @max_retries
          retries += 1
          sleep 1.0
        end
      end
    end

    # changes the context
    # TODO: this method may be unecesary...
    def step(_selector=nil, _options={})
      _options[:css] = _selector if _selector
      new_context = search_elements(_options)
      begin
        @stack << new_context
        yield
      ensure
        @stack.pop
      end

      return true
    end

    # release current driver connection
    def release
      return false if not bound?
      @bucket.unbind
      return true
    end

    # release and discard the current driver connection.
    def quit
      return false if not bound?
      @bucket.unbind true
      return true
    end

    # resets the current driver connection, does not release it.
    def reset
      return false if not bound?
      @bucket.reset
      return true
    end

    # bucket context interface implementation
    # not to be called directly
    def on_unbind
      @bucket = @stack = nil
    end

  private

    def load_driver(_reset=false)
      raise UnboundContextError.new if not bound?
      @bucket.reset if _reset
      @bucket.driver
    end

    def context
      raise UnboundContextError.new if not bound?
      @stack.last || [load_driver]
    end

    def observe
      # get current url
      return yield
      # compare url after function call, if changed reset stack
    end
  end
end
