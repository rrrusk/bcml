#!ruby -Ku
# encoding utf-8
require 'yaml'
require 'strscan'
#コンバート処理
class Convert
	def initialize()
		# 設定ファイルから変数定義
		config_open
	end

	# 設定ファイルから変数定義
	def config_open
		config = YAML.load_file("#{$MY_DIRECTORY}/config.yml")

		@TAGS = config["TAGS"].freeze
		@TAG = make_list(config["TAGS"])
		@TAG.freeze

		@STAGS = config["STAGS"].freeze

		@QUALIFIERS = config["QUALIFIERS"].freeze
		create_starters(@QUALIFIERS) #@STARTERS作成

		@UTAGS = config["UTAGS"].freeze #ユーザー定義のタグ @midasi

		@GENERAL = config["GENERAL"].freeze #シンボルに使う文字など
		general_parse() #@SYMBOL作成
	end

	def general_parse
		@SYMBOL = make_list(@GENERAL["symbol"])
		@BRACKET = make_list(@GENERAL["bracket"])
		@COMMENT = make_list(@GENERAL["comment"])
	end

	#ハッシュのキーの配列を返す
	def make_list(source)
		product = []
		source.each do |x,y|
			x = regex_esc(x)
			product << x
		end
		return product
	end

	#設定の中からスターターのリストを作る(join(|)で正規表現として使う)
	def create_starters(qualifiers)
		@STARTERS = "" 
		qualifiers.each do |key,value|
			@STARTERS << key
		end
		@STARTERS.freeze
	end

	#修飾部分の分離
	def separator_qualifier(qualifier)
		intags = []
		outtags = [[],[]]
		qualifier.scan(/(?<starter>[#{@STARTERS}])(?<qsub>(#{@BRACKET[0]}.+?#{@BRACKET[1]}|[^#{@STARTERS}])+)/) do |match|
			starter,qsub = $~[:starter],$~[:qsub] #starter => qualifierを起動する qsub => qualifierの本文
			qinfo = @QUALIFIERS[starter] 
			if qinfo["point"] == "intag"
				qsub.gsub!(/^#{@BRACKET[0]}(.+?)#{@BRACKET[1]}$/,'\1')
				intags << qinfo["usage"].gsub(/<qsub>/,qsub) #qsubを有るべき場所に入れる
			elsif qinfo["point"] == "outtag"
				qsub.gsub!(/^#{@BRACKET[0]}(.+?)#{@BRACKET[1]}$/,'\1')
				outtags[0] << qinfo["usage"][0].gsub(/<qsub>/,qsub)
				outtags[1] << qinfo["usage"][1].gsub(/<qsub>/,qsub)
			end
		end
		intag = intags.empty? ? "":" " + intags.join(" ")
		outtag = outtags.empty? ? "": [outtags[0].join(),outtags[1].join()]
		return intag,outtag
	end

	#正規表現にマッチしたものをパーツごとに分ける
	def separator(data)
		subject = data[:subject]
		prefix = data[:prefix]
		prefix.slice!(/^(?<tag>[a-z0-9あ-ん]+)/)
		qualifier = prefix
		tag = $~ ? $~[:tag] : ""
		return subject,tag,qualifier
	end

	#pタグとbrタグ挿入
	def text
		ptag_insert
		s = StringScanner.new(@contents)
		point = []
		until s.eos?
			case
			when s.skip(/<\/.+?>[ \t]?$/)
			when s.skip(/<.+?>[ \t]?$/)
			when s.scan(/(\n|.)$/)
				point << s.charpos
			when s.skip(/./m)
			end
		end
		
		pluspoint = 0
		point.each do |x|
			@contents.insert(x + pluspoint,"<br>")
			pluspoint += 4
		end
	end

	def ptag_insert
		s = StringScanner.new(@contents)
		texttag = nil
		taghash = {}
		textpos = nil
		tagcount = 0
		closepos = nil
		until s.eos?
			case
			when texttag
				case
				when s.skip(/<\/#{texttag}>/)
					if tagcount == 0
						closepos = s.charpos
						if !taghash.empty? and textpos - taghash.max[1] <= 0
							taghash[taghash.max[0]] = closepos
						else
							taghash[textpos] = closepos
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
				textpos = s.charpos - s[0].length - 1
				texttag = s[:tag]
			when s.skip(/./m)
			end
		end
		p taghash
		pluspoint = 0
		taghash.each do |key,var|
			@contents.insert(key + pluspoint,"</p>")
			pluspoint += 4
			@contents.insert(var + pluspoint,"<p>")
			pluspoint += 3
		end

		@contents.gsub!(/^\n/,"</p><p>")
		@contents.insert(0,"<p>")
			.insert(-1,"</p>")
			.gsub!(/<p>[ \t]*(\n?)<\/p>/,'\1')
	end

	def convert(strings,re)
		strings.gsub!(re) do |match|
			subject,tag,qualifier = separator($~) #マッチしたものをパーツごとに分ける
			intag,outtag = separator_qualifier(qualifier)
			#タグが設定されてるか確認
			#タグのオプションによって処理を変えたい
			if @TAG.include?(tag) || tag == ""
				if tag == ""
					if intag != "" && outtag != ""
						goal = outtag[0] + "<span#{intag}>" + subject + "</span>" + outtag[1]
					elsif outtag != ""
						goal = outtag[0] + subject + outtag[1]
					elsif intag != ""
						goal = "<span#{intag}>" + subject + "</span>"
					end
				else
					tagt = @TAGS[tag]
					case
					when tagt && tagt["escape"]
						subject.gsub!(/[<>&"]/,"<" => "&lt;", ">" => "&gt;", "&" => "&amp;", '"' => "&quot;")
					end
					goal = outtag[0] + "<#{tag}#{intag}>" + subject + "</#{tag}>" + outtag[1]
				end
				goal

			else #タグが無効なものだったら変換せずに終了
				$~[:origin]
			end
		end
	end

	def oneline
		convert(@contents,/(?<origin>^[ \t]*#{@SYMBOL[0]}(?<prefix>[^\s]+)[ \t](?<subject>.+))/)
	end

	def manyline
		re = /(?<f>#{@SYMBOL[1]}(\g<f>*.*?)*#{@SYMBOL[2]})/m
		while re =~ @contents
			@contents.gsub!(re) do |match|
				match.gsub!(/(\A#{@SYMBOL[1]}|#{@SYMBOL[2]}\Z)/,"")
				convert(match,/(?<origin>^(?<prefix>[^\s]+)\s(?<subject>.+))/m)
			end
		end
	end

	def stag
		foo = @contents.scan(/(?<origin>^\s*#{@SYMBOL[0]}(?<stag>[^\s#{@BRACKET[0]}]+)(#{@BRACKET[0]}(?<ssub>.+?)#{@BRACKET[1]})?)/)
		foo.each do |x|
			stag = x[1]

			if @STAGS.include?(stag)
				origin = regex_esc(x[0])
				unless x[2].nil?
					ssub = x[2]
				end
				case
				when stag = "mokuzi"
					mokuzi(origin,stag,ssub)
				end
			end
		end
	end

	def mokuzi(origin,stag,ssub)
		s = StringScanner.new(@contents)
		alltag = Hash.new{|hash,key| hash[key] = []}
		alltag[:h3] = [[]]
		main = 0
		until s.eos?
			case
			when s.scan(/(?<object><#{ssub}(?<attr>\s.*?)?>(?<con>.+?)<\/#{ssub}>)/m)
				main += 1
				alltag[ssub] << {object: s[:object],attr: s[:attr],con: s[:con]}
				alltag[:h3][main] = []
			when s.scan(/(?<object><h3(?<attr>\s.*?)?>(?<con>.+?)<\/h3>)/m)
				alltag[:h3][main] << {object: s[:object],attr: s[:attr],con: s[:con]}
			when s.skip(/./m)
			end
		end

		alltag[:list] = Array.new(alltag[ssub].length + 1){""}

		if alltag[:h3][0]
			alltag[:list][0] << "<ul>"
			alltag[:h3][0].each_with_index do |x,y|
				alltag[:list][0] << "<li><a href=\"#0#{y}h3\">#{x[:con]}</a></li>"
				@contents.gsub!(/#{x[:object]}/,"<h3#{x[:attr]} id=\"0#{y}h3\">#{x[:con]}</h3>")
			end
			alltag[:list][0] << "</ul>"
		end

		alltag[ssub].each_with_index do |x,i|
			i += 1
			alltag[:list][i] << "<li><a href=\"##{i}#{ssub}\">#{x[:con]}</a></li>"
			@contents.gsub!(/#{x[:object]}/,"<#{ssub}#{x[:attr]} id=\"#{i}#{ssub}\">#{x[:con]}</#{ssub}>")
			if alltag[:h3][i]
				alltag[:list][i] << "<ul>"
				alltag[:h3][i].each_with_index do |x,y|
					alltag[:list][i] << "<li><a href=\"##{i}#{y}h3\">#{x[:con]}</a></li>"
					@contents.gsub!(/#{x[:object]}/,"<h3#{x[:attr]} id=\"#{i}#{y}h3\">#{x[:con]}</h3>")
				end
				alltag[:list][i] << "</ul>"
			end
		end

		alltag[:list].each {|x| p x}

		product = ""
		alltag[:list].each {|x| product << x}
		p product
		@contents.gsub!(/#{origin}/, "<ul>#{product}</ul>") #@mokuzi[]を目次に変更
	end

	def regex_esc(strings)
		if /[-\\*+.?{}()\[\]^$|\/]/ =~ strings
			strings.gsub!(/([-\\*+.?{}()\[\]^$|\/])/) { '\\' + $1 } #正規表現で使えるようエスケープ
		end
		return strings
	end

	def comment
		@contents.gsub!(/^#{@COMMENT[0]}.+?#{@COMMENT[1]}$/m,"")
	end

	def utag
		utagl = []
		utagh = {} 
		utagt = ""
		@UTAGS.each do |key,value|
			utagl << [key,value["bcml"]]
		end
		utagl.each_with_index do |x,index|
			utagh[x[0]] = x[1]
			unless index == utagl.length - 1
				utagt << x[0] + "|"
			else
				utagt << x[0]
			end
		end
		@contents.gsub!(/(?<=#{@SYMBOL[0]}|#{@SYMBOL[1]})(#{utagt})(?=[ \t]+)/, utagh)
	end

	def main(contents)
		@contents = contents
		comment
		utag
		oneline
		manyline
		stag
		text
		puts 'return'
		puts contents
		puts 'end'
		return contents
	end
end
