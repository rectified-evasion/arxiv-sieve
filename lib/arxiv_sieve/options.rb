require 'yaml'

module ArxivSieve
  class Options

    attr_reader :options

    CONFIG_FILE = "../../config.yml"

    def initialize(options)
      @options = options

      read_config_file
    end

    def max_days_stored
      options[:max_days_stored]
    end

    def db
      options[:db]
    end

    def keywords
      options[:keywords]
    end

    def categories
      options[:categories]
    end

    def order_by
      options[:order_by]
    end

    def ignore_updates
      options[:ignore_updates]
    end

    private

    ##
    # Read configuration from yml file
    # Prior set values (e.g. by command line option) are not overwritten
    #
    def read_config_file
      file = File.join(__dir__, CONFIG_FILE)
      if File.exist?(file)
        YAML.load_file(file).tap do |cnf|
          set_option_if_not_empty(:max_days_stored, cnf['default']['max_days_stored'])
          set_option_if_not_empty(:db, validate_db(cnf['default']['db']))
          set_option_if_not_empty(:keywords, cnf['default']['keywords'])
          set_option_if_not_empty(:categories, cnf['default']['categories'])
          set_option_if_not_empty(:order_by, cnf['default']['order_by'])
          set_option_if_not_empty(:ignore_updates, cnf['default']['ignore_updates'])
        end
      else
        raise ConfigFileError, "Config file (#{file}) missing."
      end
    end

    def set_option_if_not_empty(id, value)
      if @options[id].to_s.empty?
        @options[id] = value
      end
    end

    def validate_db(connection_string)
      # in case sqlite with a relative path is used, make sure it is relative to the config file location
      if connection_string.start_with?('sqlite://') and !connection_string.start_with?('sqlite:///')
        connection_string.gsub(/sqlite:\/\//, "sqlite://#{__dir__}/../../")
      end
    end

  end

  class ConfigFileError < StandardError; end
end
