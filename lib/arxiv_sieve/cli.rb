require 'slop'

module ArxivSieve
  class Cli

    def run

      options = Slop.parse suppress_errors: true do |o|
        o.bool 'fetch', 'fetch today\'s new entries via the Arxiv API'
        o.integer '--max_days_stored', 'max number of days stored'
        o.string '--db', 'database connection string, e.g.\ \'sqlite://local.db\' or \'postgres://localhost/blog?user=user&password=password\''
        o.bool 'view', 'view and highlight most recent entries'
        o.string '--categories', 'comma separated list of Arxiv categories, e.g. \'math.DG, math.GT\''
        o.string '--keywords', 'comma separated list of keywords'
        o.string '--order_by', 'order result list in outputs, possible values: nothing, subject, name, authors'
        o.bool '--ignore_updates', 'do not list updated entries in outputs'
        o.bool 'mail', 'send a summary of keywords, if anything is found'
        o.string '--email', 'email address to send a summary to, if keywords are found'
        o.string '--smtp_server', 'smtp server to send emails from'
        o.integer '--smtp_port', 'smtp server port'
        o.string '--smtp_host', 'smtp server host'
        o.string '--smtp_from', 'smtp server from address to send emails from'
        o.string '--smtp_password', 'smtp server password'
        o.separator ""
        o.on '--version', 'print the version' do
          puts ArxivSieve::VERSION
          exit
        end
        o.on '--help' do
          puts o
          exit
        end
      end

      if options.fetch?
        ArxivSieve::Fetcher.new(options).fetch
      end

      if options.view?
        ArxivSieve::Viewer.new(options).print_html
      end

      if options.mail?
        ArxivSieve::Mailer.new(options).check_and_send
      end

    rescue MailerError => e
      puts "Sending email aborted. #{e.message}"
    rescue ConfigFileError => e
      puts "Error reading the config file. #{e.message}"
    rescue SocketError, Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPFatalError, Net::SMTPUnknownError, Net::SMTPSyntaxError => e
      puts "SMTP Error (#{e.class}). #{e.message}"
    rescue => e
      puts "Error (#{e.class}). #{e.message}"
    end
  end
end
