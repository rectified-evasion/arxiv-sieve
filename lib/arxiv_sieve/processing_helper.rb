
module ArxivSieve
  module ProcessingHelper

    private
    def process_content

      @displayed_topics = Array.new
      @displayed_topics = @options.categories.to_s.split(', ')
      @displayed_topics.each { |topic| topic.strip! }

      @keywords_info = Hash.new

      if not @items.nil? then

        @items.each do |item|
          show = false
          @displayed_topics.each do |topic|
            if not show and item[:subjects].include?(topic) then
              show = true
            end
          end

          is_update = (item[:arxiv_id].to_s[-2,2] != "v1")

          if (show or @displayed_topics.include?(item[:subject])) and not (is_update and @options.ignore_updates) then

            location_info = "<a href=\"#{item[:link]}\">#{item[:name]} (#{item[:authors]})</a>"

            authors = ""
            @current_entry_keyword_hits = 0
            if not item[:authors].nil? then
              authors = item[:authors].split(", ")
              authors.map! { |author| "<a href=\"http://arxiv.org/find/all/1/all:+EXACT+#{convert_to_ascii(author.downcase.gsub(' ','_'))}/0/1/0/all/0/1\">#{highlight_keywords(CGI::escapeHTML(author), location_info)}</a>" }
            end
            output_item = Hash.new
            output_item[:is_update] = is_update;
            output_item[:is_extern] = (not(item[:arxiv_id].nil?) and not(item[:link].include?(item[:arxiv_id])));
            output_item[:arxiv_id] = item[:arxiv_id]
            output_item[:link] = item[:link]
            output_item[:id] = item[:id]
            output_item[:name] = highlight_keywords(CGI::escapeHTML(item[:name]), location_info)
            output_item[:subject] = item[:subject]
            output_item[:subjecthighlight] = highlight_keywords(item[:subject], location_info)
            output_item[:subjects] = highlight_keywords(item[:subjects], location_info)
            output_item[:msc] = highlight_keywords(item[:msc], location_info)
            output_item[:description] = highlight_keywords(CGI::escapeHTML(item[:description]), location_info)
            output_item[:authors] = authors.join(", ")
            output_item[:keyword_hits] = @current_entry_keyword_hits
            @output_items.push output_item
          end
        end
      end
    end

    private
    def raw(s)
      s.to_s
    end

    private
    def highlight_keywords (text, location_info = "")
      keywords = @keywords_list
      if not keywords.nil? then
        keywords.each do |keyword|
          if keyword[0] == '?' then
            searchword = keyword[1..keyword.size]
            searchword = CGI::escape(searchword).gsub(/\+/,' ')
            # puts searchword
            text = text.gsub(/#{searchword}/i) do |word|
              if @keywords_distribution[searchword].nil? then
                @keywords_distribution[searchword] = 1
                @keywords_info[searchword] = Array.new
                if location_info != "" then
                  @keywords_info[searchword].push location_info
                end
              else
                @keywords_distribution[searchword] += 1
                if location_info != "" then
                  if !@keywords_info[searchword].include? location_info then
                    @keywords_info[searchword].push location_info
                  end
                end
              end
              @num_of_keywords_found += 1
              @current_entry_keyword_hits += 1
              "<span class=\"keyword\">" << word << "</span>"
            end
          else
            searchword = CGI::escape(keyword).gsub(/\+/,' ')
            text = text.gsub(/#{searchword}/) do |word|
              if @keywords_distribution[searchword].nil? then
                @keywords_distribution[searchword] = 1
                @keywords_info[searchword] = Array.new
                if location_info != "" then
                  @keywords_info[searchword].push location_info
                end
              else
                @keywords_distribution[searchword] += 1
                if location_info != "" then
                  if !@keywords_info[searchword].include? location_info then
                    @keywords_info[searchword].push location_info
                  end
                end
              end
              @num_of_keywords_found += 1
              @current_entry_keyword_hits += 1
              "<span class=\"keyword\">" << word << "</span>"
            end
          end
        end
      end
      return text
    end

    private
    def convert_to_ascii(s)
      undefined = ''
      fallback = { 'À' => 'A', 'Á' => 'A', 'Â' => 'A', 'Ã' => 'A', 'Ä' => 'A',
                   'Å' => 'A', 'Æ' => 'AE', 'Ç' => 'C', 'È' => 'E', 'É' => 'E',
                   'Ê' => 'E', 'Ë' => 'E', 'Ì' => 'I', 'Í' => 'I', 'Î' => 'I',
                   'Ï' => 'I', 'Ñ' => 'N', 'Ò' => 'O', 'Ó' => 'O', 'Ô' => 'O',
                   'Õ' => 'O', 'Ö' => 'O', 'Ø' => 'O', 'Ù' => 'U', 'Ú' => 'U',
                   'Û' => 'U', 'Ü' => 'U', 'Ý' => 'Y', 'à' => 'a', 'á' => 'a',
                   'â' => 'a', 'ã' => 'a', 'ä' => 'a', 'å' => 'a', 'æ' => 'ae',
                   'ç' => 'c', 'è' => 'e', 'é' => 'e', 'ê' => 'e', 'ë' => 'e',
                   'ì' => 'i', 'í' => 'i', 'î' => 'i', 'ï' => 'i', 'ñ' => 'n',
                   'ò' => 'o', 'ó' => 'o', 'ô' => 'o', 'õ' => 'o', 'ö' => 'o',
                   'ø' => 'o', 'ù' => 'u', 'ú' => 'u', 'û' => 'u', 'ü' => 'u',
                   'ý' => 'y', 'ÿ' => 'y', 'ß' => 'ss', 'ı' => 'i', 'Ş' => 'S' }
      s.encode('ASCII', fallback: lambda { |c| fallback.key?(c) ? fallback[c] : undefined })
    end

  end
end
