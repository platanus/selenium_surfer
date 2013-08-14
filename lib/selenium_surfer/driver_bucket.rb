module SeleniumSurfer

  # ### Webdriver connection wrapper
  #
  # By wrapping the connection is posible to control reconnection and bound context,
  # this allows for safe context navigation.
  #
  class DriverBucket

    attr_reader :session_id

    def initialize(_session_id, _anonymous)
      @session_id = _session_id
      @bound_ctx = nil
      @anonymous = _anonymous
    end

    # get the current driver instance, reset it if required
    def driver(_reset=false)
      reset if _reset

      # TODO retrieve config data from config file instead of ENV

      if @driver.nil?
        driver_name = SeleniumSurfer.config[:webdriver]
        raise ConfigurationError.new 'must provide a webdriver type' if driver_name.nil?

        case driver_name.to_sym
        when :remote
          url = SeleniumSurfer.config[:remote_host]

          # setup a custom client to use longer timeouts
          client = Selenium::WebDriver::Remote::Http::Default.new
          client.timeout = SeleniumSurfer.config[:remote_timeout]

          @driver = Selenium::WebDriver.for :remote, :url => url, :http_client => client
        else
          @driver = Selenium::WebDriver.for driver_name.to_sym

          # apply browser configuration to new driver
          @driver.manage.window.resize_to(SeleniumSurfer.config[:window_width], SeleniumSurfer.config[:window_height]) rescue nil
        end
      end

      return @driver
    end

    # force current driver connection to be discarded
    def reset
      if @driver
        @driver.quit rescue nil
        @driver = nil
      end
    end

    # return true if there is a context bound to this bucket
    def bound?
      not @bound_ctx.nil?
    end

    # bind a context to this bucket
    #
    # The context may implement the `on_unbind` method to be notified when
    # the bucket it is unbound from the bucket
    #
    def bind(_ctx)
      @bound_ctx.on_unbind if @bound_ctx and @bound_ctx.respond_to? :on_unbind
      @bound_ctx = _ctx
    end

    # unbinds the currently bound context.
    def unbind
      if @bound_ctx
        @bound_ctx.on_unbind if @bound_ctx.respond_to? :on_unbind
        @bound_ctx = nil
      end
      reset if @anonymous # reset bucket if required
    end
  end

end
