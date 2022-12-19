require "rubygems"
require "sequel"
require 'rss'
require 'open-uri'
require 'yaml'

require 'date'

require 'ensure/encoding'

module ArxivSieve
  class Fetcher

    attr_accessor :options

    def initialize(options)
      @options = ArxivSieve::Options.new(options)
    end

    def fetch

      # Set url of arxiv api
      urls = [ 'http://export.arxiv.org/rss/math' ]

      begin
        db = Sequel.connect(@options.db)
        drop_later = Array.new

        if db.table_exists?(:tables) then
          tab = db[:tables]
          # most_recent_table = tab.order(:datetime).limit(1).first

          # never store more than [max_days_stored] tables (from config)
          allowed_number = 0
          tab.order(Sequel.desc(:id)).each do |table|
            if db.table_exists?("table#{table[:id]}") then
              allowed_number += 1
              puts "table#{table[:id]} created on #{table[:datetime]}."
              if allowed_number > @options.max_days_stored - 1 then
                puts "Now dropping table#{table[:id]}"
                drop_later.push "table#{table[:id]}"
                tab.where(:id => table[:id]).delete
              end
            else
              tab.where(:id => table[:id]).delete
            end
          end
        else
          db.create_table :tables do
            primary_key :id
            String :datetime
          end
        end

        drop_later.each do |table|
          db.drop_table(table)
        end

        tab = db[:tables]
        db.transaction do
          tab.insert(:datetime => DateTime.now)
        end
        new_id = tab.order(Sequel.desc(:id)).limit(1).first[:id]
        table_name = "table#{new_id}"

        puts "Creating #{table_name}."

        db.create_table table_name do
          primary_key :id
          String :name
          String :arxiv_id
          String :subject # main subject
          String :msc
          String :link
          String :authors
          String :subjects
          String :description, text:true
        end

        items = db.dataset.from(table_name)

        arxiv_id_list = Array.new

        urls.each do |url|

          # open(url) do |rss|
          # puts rss.set_encoding('utf-8')
          feed = RSS::Parser.parse(get_feed_content(url), false)
          feed.items.each do |item|
            arxiv_id = item.link.scan(/abs\/(\S+\.\S+)/)
            if arxiv_id.empty? then
              # rarely there are these weird "math/[some number]" arxiv-ids
              arxiv_id = item.link.scan(/abs\/(math\/\S+)/)
            end
            if arxiv_id.empty? then
              puts "Failed to extract id for entry: #{item.link}"
            else
              if not arxiv_id_list.include?(arxiv_id) then
                arxiv_id_list.push(arxiv_id)
              end
            end
          end
          # end
        end

        puts "#{arxiv_id_list.size} Entries to fetch."
        puts "http://export.arxiv.org/api/query?id_list=#{arxiv_id_list.join(',')}"

        infofeed = RSS::Parser.parse(get_feed_content("http://export.arxiv.org/api/query?id_list=#{arxiv_id_list.join(',')}&max_results=#{arxiv_id_list.count}"))

        db.transaction do

          infofeed.items.each do |item|

            arxiv_id = item.id.content.scan(/abs\/(\S+\.\S+)/)

            authors = Array.new
            item.authors.each do |author| author.name.content
              authors.push(author.name.content)
            end

            subjects = Array.new
            msc = ""
            item.categories.each do |category|
              if category.term.include?("Primary") or category.term.match(/\d\d\w\d\d/) then
                msc = category.term
              else
                subjects.push(category.term)
              end
            end
            items.insert(
              :name => item.title.content.force_encoding(Encoding::UTF_8),
              :arxiv_id => arxiv_id,
              :subject => subjects[0],
              :link => item.link.href,
              :authors => authors.join(", ").force_encoding(Encoding::UTF_8),
              :subjects => subjects[1..subjects.size].join(", "),
              :msc => msc,
              :description => item.summary.content.force_encoding(Encoding::UTF_8))

          end

        end

        puts "Item count: #{items.count}"

      ensure
        db.disconnect
      end
    end

    ##
    # Obtain html content from url and make sure encoding does not break

    private
    def get_feed_content(url)
      uri = URI.parse url
      body = uri.read
      utf8_body = body.ensure_encoding('UTF-8', :external_encoding  => :sniff, :invalid_characters => :transcode)
      utf8_body = body.ensure_encoding('UTF-8', :invalid_characters => :drop)
      return utf8_body
    end

  end
end
