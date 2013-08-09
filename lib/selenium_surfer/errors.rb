module SeleniumSurfer

  # Error thrown when a bad configuration parameter is passed or missing
  class ConfigurationError < StandardError; end

  # Error thrown when a driver operation is attempted in an unbound context
  class UnboundContextError < StandardError; end

  # Error thrown when a programming setup error is found
  class SetupError < StandardError; end

  # Error thrown when an element operation is attempted in an empty search result set
  class EmptySetError < StandardError; end

end