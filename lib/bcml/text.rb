module Bcml
	#テキスト部分にpとかbrとか&nbsp;とかいれる
	class Text < Bcml
		def initialize()
			ptag_insert
			br_insert
			space_esc
			symbol_esc
		end

		private
		def ptag_insert
			s = StringScanner.new(@@contents)
			tagname = nil
			ptags_pair = {}
			textpos = nil
			tagcount = 0
			until s.eos?
				case
				when tagname
					case
					when s.skip(/<\/#{tagname}>/)
						if tagcount == 0
							if !ptags_pair.empty? and textpos - ptags_pair.max[1] <= 0
								ptags_pair[ptags_pair.max[0]] = s.charpos
							else
								ptags_pair[textpos] = s.charpos
							end
							#末尾のハッシュのキーと現在の位置を比較
							tagname = nil
							textpos = nil
						else
							tagcount -= 1
						end
					when s.skip(/<(?<!\/)#{tagname}.*?>/)
						tagcount += 1
					when s.skip(/./m)
					end
				when s.scan(/<(?<tag>[a-zA-Z0-9]+).*?>/)
					textpos = s.charpos - s[0].length >= 1? s.charpos - s[0].length - 1 : 0
					if @@config.TAGS[s[:tag]] and @@config.TAGS[s[:tag]]['display'] == 'block'
						tagname = s[:tag]
					end
				when s.skip(/./m)
				end
			end

			pluspoint = 0
			ptags_pair.each do |key,var|
				@@contents.insert(key + pluspoint,"</p>")
				pluspoint += 4
				@@contents.insert(var + pluspoint,"<p>")
				pluspoint += 3
			end

			ptags_pair = tag_pair
			pluspoint = 0
			ptags_pair.each do |key,var|
				@@contents[key+pluspoint..var-1+pluspoint] = @@contents[key+pluspoint..var-1+pluspoint].gsub(/^\n/) do |match|
					"</p><p>"
				end
			end

			@@contents.insert(0,"<p>")
				.insert(-1,"</p>")
				.gsub!(/<p>[ \t]*(\n?)<\/p>/,'\1')
		end

		def br_insert
			s = StringScanner.new(@@contents)
			point = []
			until s.eos?
				case
				when s.skip(/<pre( [^>]*)?>/)
					esc = true
				when s.skip(/<\/pre>/)
					esc = false
				when s.skip(/<\/[^>]+>([ \t]*)?$/)
				when s.skip(/<[^>]+>([ \t]*)?$/)
				when s.skip(/(\n|.)$/)
					point << s.charpos unless esc
				when s.skip(/./m)
				end
			end
			
			pluspoint = 0
			point.each do |x|
				@@contents.insert(x + pluspoint,"<br>")
				pluspoint += 4
			end
		end

		def space_esc
			ptags_pair = tag_pair

			pluspoint = 0
			ptags_pair.each do |key,var|
				@@contents[key+pluspoint..var-1+pluspoint] = @@contents[key+pluspoint..var-1+pluspoint].gsub(/  ++/) do |match|
					pluspoint += 1 + 5 * (match.length - 1)
					" " + "&nbsp;" * (match.length - 1)
				end
			end
		end

		def symbol_esc
			@@contents.gsub!(/\\(#{@@config.SYMBOL[0]}|#{@@config.SYMBOL[1]})/,'\1')
			@@contents.gsub!(/(#{@@config.SYMBOL[2]})\\/,'\1')
		end

		def tag_pair
			s = StringScanner.new(@@contents)
			open = true
			ptags_pair = {}
			start = 0

			until s.eos?
				case
				when s.skip(/<p( .*?)?>/)
					if open
						open = false
						start = s.charpos
					end
				when s.skip(/<\/p>/)
					if !open
						open = true
						ptags_pair[start] = s.charpos - s[0].length
					end
				when s.skip(/./m)
				end
			end

			return ptags_pair
		end
	end
end
