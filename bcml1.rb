# encoding: utf-8

class Convert
	def initialize()
		@tags = %w[h1 h2 h3 h4 h5 h6 a span div]
		@qualifier = {
			"."=>{
				"point"=>"intag",
				"usage"=>'class="#{qualifier}"'
			},
		}
	end

	def main(contents)
		converted = contents.gsub(/^@(?<prefix>.+)\s+(.+)/, '<\1>\2</\1>')
		contents.scan(/^@.+/) do |match|

		contents.scan(/^@(?<tags>#{tags.join("|")})\.(?<qualifier>.+)\s+(?<subject>.+)/) {|match|
			subject = $~[:subject]
			tags = $~[:tags]
			qualifier = $~[:qualifier]
			intag = ' class="' + qualifier + '"'
			puts "qualifier:" + qualifier if qualifier
			goal = "<" + tags + intag + ">" + subject + "</" + tags + ">"
			puts goal
		}

	end
end
