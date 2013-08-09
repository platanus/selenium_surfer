require "selenium_surfer/version"
require "selenium_surfer/errors"
require "selenium_surfer/driver_bucket"
require "selenium_surfer/search_context"
require "selenium_surfer/surf_context"
require "selenium_surfer/robot"

module SeleniumSurfer

  # Configuration defaults
  @@config = {
    :webdriver => nil,
    :remote_host => 'http://localhost:8080',
    :remote_timeout => 120
  }

  # Configure through hash
  def self.configure(_opts = {})
    _opts.each { |k,v| @@config[k.to_sym] = v if @@config.has_key? k.to_sym }
  end

  # Configure through yaml file
  def self.configure_with(_path_to_yaml_file)
    begin
      config = YAML::load(IO.read(_path_to_yaml_file))
    rescue Errno::ENOENT
      log(:warning, "YAML configuration file couldn't be found. Using defaults."); return
    rescue Psych::SyntaxError
      log(:warning, "YAML configuration file contains invalid syntax. Using defaults."); return
    end

    configure(config)
  end

  def self.config
    @@config
  end
end
