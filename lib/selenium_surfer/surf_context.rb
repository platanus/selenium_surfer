module SeleniumSurfer

  # ### Base class for robot contexts
  #
  class SurfContext < SearchContext
    extend Forwardable

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
      super nil, nil

      @bucket = _bucket
      @macro = _macro || { max_retries: 5 }
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
    def driver(_reset=false)
      raise UnboundContextError.new if not bound?
      @bucket.reset if _reset
      @bucket.driver
    end

    # delegate some stuff to driver
    def_delegators 'driver', :title, :current_url, :page_source
    def_delegators 'driver.navigate', :back, :forward, :refresh

    # return the current page url as an URI
    def current_uri
      URI.parse driver.current_url
    end

    # return the current page cookies as a hash
    def cookies
      driver.manage.all_cookies
    end

    # navigate to a given url (uses the max_retries setting)
    def navigate(_url, _params=nil)
      _url += "?#{_params.to_query}" if _params
      retries = 0

      loop do
        begin
          driver(retries > 0).get(_url)
          @stack = [] # clear stack after successfull navigation
          break
        rescue Timeout::Error #, Selenium::WebDriver::Error::UnknownError
          # TODO: log this
          raise if retries >= max_retries
          retries += 1
          sleep 1.0
        end
      end
    end

    # changes the context
    # TODO: this method may be unnecesary...
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
      @bucket.reset
      @bucket.unbind
      return true
    end

    # bucket context interface implementation
    # not to be called directly
    def on_unbind
      @bucket = @stack = nil
    end

  private

    def context
      raise UnboundContextError.new if not bound?
      @stack.last || [driver]
    end

    def observe
      # get current url
      return yield
      # compare url after function call, if changed reset stack
    end
  end
end
