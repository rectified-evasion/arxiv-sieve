require 'slop'

module ArxivSieve
  class Cli

    def run

      options = Slop.parse suppress_errors: true do |o|
        o.bool 'fetch', 'fetch today\'s new entries via the API'
        o.bool 'view', 'view and highlight most recent entries'
        o.integer '--max_days_stored', 'max number of days stored'
        o.string '--db', 'database connection string, e.g.\ \'sqlite://local.db\' or \'postgres://localhost/blog?user=user&password=password\''
        o.string '--categories', 'comma separated list of Arxiv categories, e.g. \'math.DG, math.GT\''
        o.string '--keywords', 'comma separated list of keywords'
        o.string '--order_by', 'order result list in outputs, possible values: nothing, subject, name, authors'
        o.bool '--ignore_updates', 'do not list updated entries in outputs'
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

    rescue ConfigFileError => e
      puts e.message
    end
  end
end
