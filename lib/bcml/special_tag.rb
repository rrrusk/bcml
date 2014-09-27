class SpecialTag < Bcml
	def initialize()
		exec
	end
	def exec
		scan = @@contents.scan(/(?<origin>^(?<!\\)#{@@config.SYMBOL[0]}(?<special_tag>[^\s#{@@config.BRACKET[0]}]+)(#{@@config.BRACKET[0]}(?<ssub>.+?)#{@@config.BRACKET[1]})?)/)
		scan.each do |x|
			special_tag = x[1]

			if @@config.SPECIALTAGS.include?(special_tag)
				origin = regex_esc(x[0])
				unless x[2].nil?
					ssub = x[2]
				end
				case
				when special_tag == "mokuzi"
					mokuzi(origin,ssub)
				when special_tag == ":"
					get_link_title(origin,ssub)
				end
			end
		end
	end

	def mokuzi(origin,ssub)
		ssub.scan(/(\w+) ?(\w*)/)
		tag = [$~[1],$~[2]]
		s = StringScanner.new(@@contents)
		alltag = Hash.new{|hash,key| hash[key] = []}
		alltag[tag[1]] = [[]]
		main = 0
		until s.eos?
			case
			when s.scan(/(?<object><#{tag[0]}(?<attr>\s[^>]*?)?>(?<con>[^<]+?)<\/#{tag[0]}>)/m)
				main += 1
				alltag[tag[0]] << {object: s[:object],attr: s[:attr],con: s[:con]}
				alltag[tag[1]][main] = []
			when tag[1] && s.scan(/(?<object><#{tag[1]}(?<attr>\s.*?)?>(?<con>.+?)<\/#{tag[1]}>)/m)
				alltag[tag[1]][main] << {object: s[:object],attr: s[:attr],con: s[:con]}
			when s.skip(/./m)
			end
		end

		alltag[:list] = Array.new(alltag[tag[0]].length + 1){""}

		unless alltag[tag[1]][0].empty?
			alltag[:list][0] << "<ul>"
			alltag[tag[1]][0].each_with_index do |x,y|
				alltag[:list][0] << "<li><a href=\"##{tag[1]}0#{y}\">#{x[:con]}</a></li>"
				@@contents.gsub!(/#{x[:object]}/,"<#{tag[1]}#{x[:attr]} id=\"#{tag[1]}0#{y}\">#{x[:con]}</#{tag[1]}>")
			end
			alltag[:list][0] << "</ul>"
		end

		alltag[tag[0]].each_with_index do |x,i|
			i += 1
			alltag[:list][i] << "<li><a href=\"##{tag[0]}#{i}\">#{x[:con]}</a></li>"
			@@contents.gsub!(/#{x[:object]}/,"<#{tag[0]}#{x[:attr]} id=\"#{tag[0]}#{i}\">#{x[:con]}</#{tag[0]}>")
			unless alltag[tag[1]][i].empty?
				alltag[:list][i] << "<ul>"
				alltag[tag[1]][i].each_with_index do |x,y|
					alltag[:list][i] << "<li><a href=\"##{tag[1]}#{i}#{y}\">#{x[:con]}</a></li>"
					@@contents.gsub!(/#{x[:object]}/,"<#{tag[1]}#{x[:attr]} id=\"#{tag[1]}#{i}#{y}\">#{x[:con]}</#{tag[1]}>")
				end
				alltag[:list][i] << "</ul>"
			end
		end

		product = ""
		alltag[:list].each {|x| product << x}
		@@contents.gsub!(/#{origin}/, "<ul>#{product}</ul>") #@mokuzi[]を目次に変更
	end

	def get_link_title(origin,ssub)
		require 'open-uri'

		if ssub =~ /https?:\/\/.+/
			title = ""
			open(ssub) {|f|
				html = f.read
				html.scan(/<title>(.+)<\/title>/)
				title = $~[1]
			}
			product = "<a href=\"#{ssub}\">#{title}</a>"
		else
			product = "<a href=\"#{ssub}\">#{ssub}</a>"
		end
		@@contents.gsub!(/#{origin}/,product)
	end
end
