require "rubygems"
require "sequel"
require "erb"

module ArxivSieve
  class Viewer
    include ProcessingHelper

    attr_accessor :options

    def initialize(options)
      @options = ArxivSieve::Options.new(options)
    end

    def print_html

      @keywords_list = @options.keywords.split(',')
      @keywords_list.each { |keyword| keyword = keyword.strip! }

      @num_of_keywords_found = 0

      begin
        db = Sequel.connect(@options.db)

        if db.table_exists?(:tables) then

          other_tables = db[:tables]
          current_table = "table#{other_tables.order(Sequel.desc(:id)).limit(1).first[:id]}"

          case @options.order_by
           when 'subject'
             @items = db.from(current_table).order(:subject)
           when 'name'
             @items = db.from(current_table).order(:name)
           when 'authors'
             @items = db.from(current_table).order(:authors)
           else
             @items = db.from(current_table)
          end

        else
          raise DatabaseEmptyError
        end

        @keywords_distribution = Hash.new
        @output_items = Array.new

        html_file = File.new("arxiv-sieve.html", "w+")

        process_content

        html_file.puts ERB.new(File.read("#{__dir__}/../view/view.html.erb")).result(binding)
        html_file.close
      ensure
        db.disconnect
      end

    end

  end

  class DatabaseEmptyError < StandardError; end
end
