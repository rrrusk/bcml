#!ruby -Ku
# encoding utf-8
require 'yaml'
require 'strscan'
#コンバート処理
class Bcml
	attr_accessor :contents, :config
	def initialize()
		# 設定ファイルから変数定義
		@@config = MakeConfig.new()
	end

	def exec(contents)
		@@contents = contents
		comment
		user_tag
		BcmlToHtml.new()
		SpecialTag.new()
		Text.new()
		puts contents
		return contents
	end

	def comment
		@@contents.gsub!(/^#{@@config.COMMENT[0]}.+?#{@@config.COMMENT[1]}$/m,"")
	end

	def user_tag
		user_tag_hash = {} 
		user_tag_pipe = ""
		@@config.USERTAGS.each_with_index do |(key,value),index|
			user_tag_hash[key] = value["bcml"]
			unless index == @@config.USERTAGS.length - 1
				user_tag_pipe << key + "|"
			else
				user_tag_pipe << key
			end
		end
		@@contents.gsub!(/(?<=#{@@config.SYMBOL[0]}|#{@@config.SYMBOL[1]})(#{user_tag_pipe})(?=[ \t]+)/, user_tag_hash)
	end

	def regex_esc(strings)
		if /[-\\*+.?{}()\[\]^$|\/]/ =~ strings
			strings.gsub!(/([-\\*+.?{}()\[\]^$|\/])/) { '\\' + $1 } #正規表現で使えるようエスケープ
		end
		return strings
	end
end

class MakeConfig < Bcml
	attr_reader :TAGS, :TAG, :SPECIALTAGS, :QUALIFIERS, :USERTAGS, :GENERAL, :SYMBOL, :BRACKET, :COMMENT, :STARTERS
	def initialize()
		yaml_open
	end

	# 設定ファイルから変数定義
	def yaml_open
		config = YAML.load_file("#{$MY_DIRECTORY}/config.yml")

		@TAGS = config["TAGS"].freeze
		@TAG = make_list(config["TAGS"])
		@TAG.freeze

		@SPECIALTAGS = config["SPECIALTAGS"].freeze

		@QUALIFIERS = config["QUALIFIERS"].freeze
		create_starters(@QUALIFIERS) #@STARTERS作成

		@USERTAGS = config["USERTAGS"].freeze #ユーザー定義のタグ @midasi

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
end

class SpecialTag < Bcml
	def initialize()
		exec
	end
	def exec
		foo = @@contents.scan(/(?<origin>^\s*#{@@config.SYMBOL[0]}(?<special_tag>[^\s#{@@config.BRACKET[0]}]+)(#{@@config.BRACKET[0]}(?<ssub>.+?)#{@@config.BRACKET[1]})?)/)
		foo.each do |x|
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

		p alltag

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

#テキスト部分にpとかbrとか&nbsp;とかいれる
class Text < Bcml
	def initialize()
		ptag_insert
		br_insert
		space_esc
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
				texttag = s[:tag]
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
end

class BcmlToHtml < Bcml
	def initialize()
		oneliner
		multiliner
	end

	def oneliner
		convert(@@contents,/(?<origin>^[ \t]*#{@@config.SYMBOL[0]}(?<prefix>[^\s]+)[ \t](?<subject>.+))/)
	end

	def multiliner
		re = /(?<f>#{@@config.SYMBOL[1]}(\g<f>*.*?)*#{@@config.SYMBOL[2]})/m
		while re =~ @@contents
			@@contents.gsub!(re) do |match|
				match.gsub!(/(\A#{@@config.SYMBOL[1]}|#{@@config.SYMBOL[2]}\Z)/,"")
				convert(match,/(?<origin>^(?<prefix>[^\s]+)\s(?<subject>.+))/m)
			end
		end
	end

	def convert(strings,re)
		strings.gsub!(re) do |match|
			subject,tag,qualifier = separator($~) #マッチしたものをパーツごとに分ける
			intag,outtag = intag_and_outtag(qualifier)
			#タグが設定されてるか確認
			#タグのオプションによって処理を変えたい
			if @@config.TAG.include?(tag) || tag == ""
				if tag == ""
					if intag != "" && outtag != ""
						goal = outtag[0] + "<span#{intag}>" + subject + "</span>" + outtag[1]
					elsif outtag != ""
						goal = outtag[0] + subject + outtag[1]
					elsif intag != ""
						goal = "<span#{intag}>" + subject + "</span>"
					end
				else
					tagt = @@config.TAGS[tag]
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

	#正規表現にマッチしたものをパーツごとに分ける
	def separator(data)
		subject = data[:subject]
		prefix = data[:prefix]
		prefix.slice!(/^(?<tag>[a-z0-9あ-ん]+)/)
		qualifier = prefix
		tag = $~ ? $~[:tag] : ""
		return subject,tag,qualifier
	end

	#修飾部分の分離
	def intag_and_outtag(qualifier)
		intags = []
		outtags = [[],[]]
		qualifier.scan(/(?<starter>[#{@@config.STARTERS}])(?<qsub>(#{@@config.BRACKET[0]}.+?#{@@config.BRACKET[1]}|[^#{@@config.STARTERS}])+)/) do |match|
			starter,qsub = $~[:starter],$~[:qsub] #starter => qualifierを起動する qsub => qualifierの本文
			qinfo = @@config.QUALIFIERS[starter] 
			if qinfo["point"] == "intag"
				qsub.gsub!(/^#{@@config.BRACKET[0]}(.+?)#{@@config.BRACKET[1]}$/,'\1')
				intags << qinfo["usage"].gsub(/<qsub>/,qsub) #qsubを有るべき場所に入れる
			elsif qinfo["point"] == "outtag"
				qsub.gsub!(/^#{@@config.BRACKET[0]}(.+?)#{@@config.BRACKET[1]}$/,'\1')
				outtags[0] << qinfo["usage"][0].gsub(/<qsub>/,qsub)
				outtags[1] << qinfo["usage"][1].gsub(/<qsub>/,qsub)
			end
		end
		intag = intags.empty? ? "":" " + intags.join(" ")
		outtag = outtags.empty? ? "": [outtags[0].join(),outtags[1].join()]
		return intag,outtag
	end
end
