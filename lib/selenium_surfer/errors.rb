module SeleniumSurfer

  # Error thrown when a bad configuration parameter is passed or missing
  class ConfigurationError < StandardError; end

  # Error thrown when a driver operation is attempted in an unbound context
  class UnboundContextError < StandardError; end

  # Error thrown when a programming setup error is found
  class SetupError < StandardError; end

  # Base class for context errors
  class ContextError < StandardError

    attr_reader :context, :source

    def initialize(_msg, _context)
      super _msg
      @context = _context
      @source = _context.root_context.page_source rescue nil # cache page source for future reference
    end
  end

  # Error thrown when an element operation is attempted in an empty search result set
  class EmptySetError < ContextError; end

  # Wraps a web driver error adding
  class WebDriverError < ContextError

    attr_reader :original

    def initialize(_original, _context)
      super _original.message, _context
      @original = _original
    end
  end

end