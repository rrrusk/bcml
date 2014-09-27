#テキスト部分にpとかbrとか&nbsp;とかいれる
class Text < Bcml
	def initialize()
		ptag_insert
		br_insert
		space_esc
		symbol_esc
	end

	def ptag_insert
		s = StringScanner.new(@@contents)
		texttag = nil
		taghash = {}
		textpos = nil
		tagcount = 0
		until s.eos?
			case
			when texttag
				case
				when s.skip(/<\/#{texttag}>/)
					if tagcount == 0
						if !taghash.empty? and textpos - taghash.max[1] <= 0
							taghash[taghash.max[0]] = s.charpos
						else
							taghash[textpos] = s.charpos
						end
						#末尾のハッシュのキーと現在の位置を比較
						texttag = nil
						textpos = nil
					else
						tagcount -= 1
					end
				when s.skip(/<(?<!\/)#{texttag}.*?>/)
					tagcount += 1
				when s.skip(/./m)
				end
			when s.scan(/<(?<tag>[a-zA-Z0-9]+).*?>/)
				textpos = s.charpos - s[0].length >= 1? s.charpos - s[0].length - 1 : 0
				if @@config.TAGS[s[:tag]] and @@config.TAGS[s[:tag]]['display'] == 'block'
					texttag = s[:tag]
				end
			when s.skip(/./m)
			end
		end

		pluspoint = 0
		taghash.each do |key,var|
			@@contents.insert(key + pluspoint,"</p>")
			pluspoint += 4
			@@contents.insert(var + pluspoint,"<p>")
			pluspoint += 3
		end

		@@contents.gsub!(/^\n/,"</p><p>")
		@@contents.insert(0,"<p>")
			.insert(-1,"</p>")
			.gsub!(/<p>[ \t]*(\n?)<\/p>/,'\1')
	end

	def br_insert
		s = StringScanner.new(@@contents)
		point = []
		until s.eos?
			case
			when s.skip(/<\/.+?>[ \t]?$/)
			when s.skip(/<.+?>[ \t]?$/)
			when s.skip(/<pre( .*?)?>/)
				esc = true
			when s.skip(/<\/pre>/)
				esc = false
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
		s = StringScanner.new(@@contents)
		open = true
		text = {}
		pluspoint = 0

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
					text[start] = s.charpos - s[0].length
				end
			when s.skip(/./m)
			end
		end

		text.each do |key,var|
			@@contents[key+pluspoint..var-1+pluspoint] = @@contents[key+pluspoint..var-1+pluspoint].gsub(/ /) do |match|
				pluspoint += 5
				"&nbsp;"
			end
		end
	end

	def symbol_esc
		@@contents.gsub!(/\\(#{@@config.SYMBOL[0]}|#{@@config.SYMBOL[1]})/,'\1')
	end
end
