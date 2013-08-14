module SeleniumSurfer

  # ### Base class for selenium surfer robots
  #
  # This class defines the interface every test engine must implement.
  #
  # It also provides webdriver managed shared access, this allows for safe
  # webdriver session persistance between tests.
  #
  # Usage: TODO
  #
  class Robot

    @@all_buckets = {}
    @@loaded_buckets = nil
    @@block_options = nil

    # execute a block with managed webdriver connections
    #
    # by putting all web related logic inside a managed block the
    # user can rest asured that any unhandled exception inside the block will
    # discard the requested webdrivers connections. This means that future
    # calls to connect will always return valid driver connections.
    #
    def self.managed(_opt={})

      raise SetupError.new 'cannot call managed block inside managed block' unless @@loaded_buckets.nil?

      keep_sessions = _opt.fetch(:keep_sessions, false)
      session_error = false

      # TODO: When `keep_sessions` is used, special care should be taken in preventing a large number
      # of sessions to remain in memory (like in de case a new session id  for each run)

      unless keep_sessions
        # use separate bucket collection if sessions are to be discarded
        temp = @@all_buckets
        @all_buckets = {}
      end

      @@loaded_buckets = []
      @@block_options = _opt

      begin
        return yield
      rescue
        session_error = true
        raise
      ensure
        force_reset = session_error or !keep_sessions
        @@loaded_buckets.each do |bucket|
          bucket.unbind
          bucket.reset if force_reset
        end
        @@loaded_buckets = nil
        @all_buckets = temp unless keep_sessions
      end
    end

    # creates a new surf context and passes it to the given block.
    #
    # * Can only be called inside a `managed` block.
    # * The context is released when block exits.
    #
    def self.new_surf_session(_session=nil, _opt={}, &_block)

      # load context class to be used, must be a SurfContext or SurfContext subclass
      ctx_class = _opt.fetch(:use, SurfContext)
      raise SetupError.new 'invalid context class' unless ctx_class == SurfContext or ctx_class < SurfContext

      # make sure this is called within a managed block
      raise SetupError.new 'context is not managed' if @@loaded_buckets.nil?

      if _session.nil? and not @@block_options.fetch(:nil_sessions, false)
        # create an anonymous bucket
        bucket = DriverBucket.new nil, true
      else
        bucket = @@all_buckets[_session]
        bucket = @@all_buckets[_session] = DriverBucket.new _session, false if bucket.nil?
        raise SetupError.new 'session already bound' if bucket.bound?
      end

      @@loaded_buckets << bucket
      ctx = ctx_class.new bucket

      # if block is not given, just return context, if given, pass it to block
      # and ensure release
      return ctx unless _block
      begin
        return _block.call ctx
      ensure
        bucket.unbind
        bucket.reset if _opt.fetch(:on_exit, :release) == :discard
      end
    end

    # Object instance flavor of `self.managed`
    def managed(_opt={}, &_block)
      return self.class.managed _opt, &_block
    end

    # Object instance flavor of `self.surf`
    def new_surf_session(_session=nil, _opt={}, &_block)
      return self.class.new_surf_session(_session, _opt, &_block)
    end

  end
end
