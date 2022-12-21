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
      options[:max_days_stored].to_i
    end

    def db
      options[:db].to_s
    end

    def keywords
      options[:keywords].to_s
    end

    def categories
      options[:categories].to_s
    end

    def order_by
      options[:order_by].to_s
    end

    def ignore_updates
      options[:ignore_updates]
    end

    def email
      options[:email].to_s
    end

    def smtp_server
      options[:smtp_server].to_s
    end

    def smtp_port
      options[:smtp_port].to_i
    end

    def smtp_host
      options[:smtp_host].to_s
    end

    def smtp_from
      options[:smtp_from].to_s
    end

    def smtp_password
      options[:smtp_password].to_s
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
          set_option_if_not_empty(:max_days_stored, cnf['general']['max_days_stored'])
          set_option_if_not_empty(:db, validate_db(cnf['general']['db']))
          set_option_if_not_empty(:keywords, cnf['user']['keywords'])
          set_option_if_not_empty(:categories, cnf['user']['categories'])
          set_option_if_not_empty(:order_by, cnf['user']['order_by'])
          set_option_if_not_empty(:ignore_updates, cnf['user']['ignore_updates'])
          set_option_if_not_empty(:email, cnf['user']['email'])
          set_option_if_not_empty(:smtp_server, cnf['smtp']['server'])
          set_option_if_not_empty(:smtp_port, cnf['smtp']['port'].to_i)
          set_option_if_not_empty(:smtp_host, cnf['smtp']['host'])
          set_option_if_not_empty(:smtp_from, cnf['smtp']['from'])
          set_option_if_not_empty(:smtp_password, cnf['smtp']['password'])
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
