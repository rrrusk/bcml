module Bcml
	class SpecialTag < Bcml
		def initialize()
			exec
		end

		private
		def exec
			scan = @@contents.scan(/(?<!\\)(?<origin>#{@@config.SYMBOL[0]}(?<special_tag>(#{@@config.SPECIALTAGS.join("|")})+)(#{@@config.BRACKET[0]}(?<ssub>.+?)#{@@config.BRACKET[1]})?)/)

			scan.each do |x|
				special_tag = x[1]
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

		def mokuzi(origin,ssub)
			ssub.scan(/(\w+) ?(\w*)/)
			tag = [$~[1],$~[2]]
			s = StringScanner.new(@@contents)
			tag_list = Hash.new{|hash,key| hash[key] = []}
			tag_list[tag[1]] = [[]]
			main = 0

			until s.eos?
				case
				when s.scan(/(?<object><#{tag[0]}(?<attr>\s[^>]*?)?>(?<con>[^<]+?)<\/#{tag[0]}>)/m)
					main += 1
					tag_list[tag[0]] << {object: s[:object],attr: s[:attr],con: s[:con]}
					tag_list[tag[1]][main] = []
				when tag[1] && s.scan(/(?<object><#{tag[1]}(?<attr>\s.*?)?>(?<con>.+?)<\/#{tag[1]}>)/m)
					tag_list[tag[1]][main] << {object: s[:object],attr: s[:attr],con: s[:con]}
				when s.skip(/./m)
				end
			end

			tag_list[:list] = Array.new(tag_list[tag[0]].length + 1){""}
			unless tag_list[tag[1]][0].empty?
				list_string = ""

				tag_list[tag[1]][0].each_with_index do |x,y|
					list_string << "<li><a href=\"##{tag[1]}0#{y}\">#{x[:con]}</a></li>"
					@@contents.gsub!(/#{x[:object]}/,"<#{tag[1]}#{x[:attr]} id=\"#{tag[1]}0#{y}\">#{x[:con]}</#{tag[1]}>")
				end

				tag_list[:list][0] = "<ul>#{list_string}</ul>"
			end

			tag_list[tag[0]].each_with_index do |x,i|
				i += 1
				tag_list[:list][i] << "<li><a href=\"##{tag[0]}#{i}\">#{x[:con]}</a></li>"
				@@contents.gsub!(/#{x[:object]}/,"<#{tag[0]}#{x[:attr]} id=\"#{tag[0]}#{i}\">#{x[:con]}</#{tag[0]}>")
				unless tag_list[tag[1]][i].empty?

					child_list_string = ""
					tag_list[tag[1]][i].each_with_index do |x,y|
						child_list_string << "<li><a href=\"##{tag[1]}#{i}#{y}\">#{x[:con]}</a></li>"
						@@contents.gsub!(/#{x[:object]}/,"<#{tag[1]}#{x[:attr]} id=\"#{tag[1]}#{i}#{y}\">#{x[:con]}</#{tag[1]}>")
					end

					tag_list[:list][i] << "<ul>#{child_list_string}</ul>"
				end
			end

			product = ""
			tag_list[:list].each {|x| product << x}
			@@contents.gsub!(/(?<!\\)#{origin}/, "<ul>#{product}</ul>")
		end

		def get_link_title(origin,ssub)
			require 'open-uri'

			if ssub =~ /https?:\/\/.+/
				begin
					title = ""
					open(ssub) {|f|
						html = f.read
						html.scan(/<title>(.+)<\/title>/)
						title = $~[1]
					}
					product = "<a href=\"#{ssub}\">#{title}</a>"
				rescue
					product = "<a href=\"#{ssub}\">#{ssub}</a>"
				end
			else
				product = "<a href=\"#{ssub}\">#{ssub}</a>"
			end
			@@contents.gsub!(/(?<!\\)#{origin}/,product)
		end
	end
end
