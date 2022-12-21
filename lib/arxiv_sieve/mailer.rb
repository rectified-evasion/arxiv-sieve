require "rubygems"
require 'net/smtp'

require "sequel"
require "cgi"

module ArxivSieve
  class Mailer
    include ProcessingHelper

    attr_accessor :options

    def initialize(options)
      @options = ArxivSieve::Options.new(options)
    end

    def check_and_send

      # check if there is sufficient smtp information to send emails
      if @options.smtp_server.empty? or @options.smtp_from.empty? or @options.smtp_host.empty? or @options.smtp_port == 0
        raise MailerError, "Make sure SMTP login information is set (server, port, host, email address of sender)"
      end

      @num_of_keywords_found = 0

      begin

        db = Sequel.connect(@options.db)

        # use the database to store multiple users or run with single user information from config
        if db.table_exists?(:users) then
          users = db[:users].where(:enable_mail_notifications => 't')
          if users.empty?
            raise MailerError, "No users in the database that have enabled email notifications"
          end
        else
          users = Array.new
          users.push(Hash[
                       name: 'Config file',
                       keywords: @options.keywords,
                       topics: @options.categories,
                       ignore_updates: @options.ignore_updates,
                       email: @options.email])
        end

        users.each do |user|

          @keywords_list = Array.new
          @keywords_list = user[:keywords].split(',')
          @keywords_list.each { |keyword| keyword = keyword.strip! }
          if @keywords_list.empty?
            raise MailerError, "#{user[:name]} has no keywords specified"
          end
          @displayed_topics = Array.new
          @displayed_topics = user[:topics].split(',')
          @displayed_topics.each { |topic| topic = topic.strip! }
          if @displayed_topics.empty?
            raise MailerError, "#{user[:name]} has no Arxiv categories specified"
          end
          @ignore_updates = user[:ignore_updates]
          @email = user[:email]
          if @email.nil? or @email.empty?
            raise MailerError, "#{user[:name]} has no email address specified"
          end

          if db.table_exists?(:tables) then
            @other_tables = db[:tables]
            @current_table = "table#{@other_tables.order(Sequel.desc(:id)).limit(1).first[:id]}"

            @items = db.from(@current_table)
          end

          @keywords_distribution = Hash.new
          @output_items = Array.new
          @num_of_keywords_found = 0

          process_content

          if @num_of_keywords_found > 0 then

            out = "#{@num_of_keywords_found} keywords found in #{@output_items.count} displayed entries.\n\n"

            out = out + "<ul class=\"keyword-distribution-list\">\n"
            @keywords_distribution.each do |key,value|
              out = out + "<li>#{key}: #{value} occurences in the articles: #{@keywords_info[key].join(', ')}</li>\n"
            end
            out = out + "</ul>\n"

            message = "From: Arxiv Sieve <#{@options.smtp_from}>\n" +
                      "To: #{@email}\n" +
                      "MIME-Version: 1.0\n" +
                      "Content-type: text/html\n" +
                      "Subject: #{@num_of_keywords_found} keywords found in the Arxiv News today.\n\n" +
                      out

            Net::SMTP.start(@options.smtp_server, @options.smtp_port, @options.smtp_host, @options.smtp_from, @options.smtp_password, :plain) do |smtp|
              smtp.send_message message, @options.smtp_from, @email
            end

            puts message

          else
            puts "No keywords matched today."
          end

        end

      ensure
        db.disconnect
      end

    end

  end

  class MailerError < StandardError; end
end
