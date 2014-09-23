# encoding utf-8
require 'yaml'
require 'strscan'
#コンバート処理
class Convert
	def initialize()
		# 設定ファイルから変数定義
		config_open()
	end

	# 設定ファイルから変数定義
	def config_open()
		config = YAML.load_file('config.yml')

		@TAGS = config["TAGS"].freeze
		@TAG = make_list(config["TAGS"])
		@TAG.freeze

		@STAGS = config["STAGS"].freeze
		@STAG = make_list(config["STAGS"])
		@STAG.freeze

		@QUALIFIERS = config["QUALIFIERS"].freeze
		create_starters(@QUALIFIERS) #@STARTERS作成

		@UTAGS = config["UTAGS"].freeze
	end

	#ハッシュのキーの配列を返す
	def make_list(source)
		product = []
		source.each_key do |key|
			product << key
		end
		return product
	end

	#設定の中からスターターのリストを作る(join(|)で正規表現として使う)
	def create_starters(qualifiers)
		@STARTERS = "" 
		qualifiers.each do |key,value|
			# keys = key.gsub(/([\\\*\+\.\?\{\}\(\)\[\]\-\^\$\|\/])/,'\\1')
			@STARTERS << key
		end
		@STARTERS.freeze
	end

	#修飾部分の分離
	def separatorQ(qualifier)
		intags = []
		outtags = [[],[]]
		# /#{@STARTERS.join("|")}(\[.+?\]|[^#{@SYMBOL.join("")}])+/
		qualifier.scan(/(?<starter>[#{@STARTERS}])(?<qsub>(\[.+?\]|[^#{@STARTERS}])+)/) do |match|
			starter,qsub = $~[:starter],$~[:qsub] #starter => qualifierを起動する qsub => qualifierの本文
			qinfo = @QUALIFIERS[starter] 
			if qinfo["point"] == "intag"
				qsub.gsub!(/^\[(.+?)\]$/,'\1')
				intags << qinfo["usage"].gsub(/<qsub>/,qsub) #qsubを有るべき場所に入れる
			elsif qinfo["point"] == "outtag"
				qsub.gsub!(/^\[(.+?)\]$/,'\1')
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

	def text(contents)
		s = StringScanner.new(contents)
		point = []
		until s.eos?
			case
			when s.skip(/<\/.+>[ \t]?$/)
			when s.scan(/(\n|.)$/)
				point << s.charpos
			when s.skip(/./m)
			end
		end
		
		pluspoint = 0
		point.each do |x|
			contents.insert(x + pluspoint,"<br>")
			pluspoint += 4
		end

		return contents
	end

	def ptag_insert(contents)
		s = StringScanner.new(contents)
		texttag = nil
		taghash = {}
		textpos = nil
		until s.eos?
			case
			when texttag
				if s.scan_until(/<\/#{texttag}>/)
					taghash[textpos] = s.charpos
					texttag = nil
					textpos = nil
				end
			when s.scan(/<(?<tag>[a-zA-Z0-9]+).*?>/)
				textpos = s.charpos - s[0].length - 1
				texttag = s[:tag]
			when s.skip(/./m)
			end
		end
		pluspoint = 0
		taghash.each do |key,var|
			contents.insert(key + pluspoint,"</p>")
			pluspoint += 4
			contents.insert(var + pluspoint,"<p>")
			pluspoint += 3
		end

		contents.gsub!(/^\n$/,"</p><p>")
			.insert(0,"<p>")
			.insert(-1,"</p>")
			.gsub!(/<p>[ \t]*(\n?)<\/p>/,'\1')
		return contents
	end

	def convert(contents,re)
		contents.gsub!(re) do |match|
			subject,tag,qualifier = separator($~) #マッチしたものをパーツごとに分ける
			intag,outtag = separatorQ(qualifier)
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

	def oneline(contents)
		convert(contents,/(?<origin>^[ \t]*@(?<prefix>[^( ]+)[ \t](?<subject>.+))/)
	end

	def manyline(contents)
		re = /(?<f>@\((\g<f>*.*?)*\)@)/m
		while re =~ contents
			contents.gsub!(re) do |match|
				match.gsub!(/(\A@\(|\)@\Z)/,"")
				convert(match,/(?<origin>^(?<prefix>[^\(\s]+)\s(?<subject>.+))/m)
			end
		end
	end

	def stag(contents)
		foo = contents.scan(/(?<origin>^\s*@(?<stag>[^\s\[]+)(\[(?<ssub>.+?)\])?)/)
		foo.each do |x|
			stag = x[1]

			if @STAG.include?(stag)
				origin = x[0]
				unless x[2].nil?
					ssub = x[2]
				end
				case
				when @STAGS[stag]["mokuzi"]
					@mokuh3 = [] if @mokuh3.nil?

					i = 0
					# p @original.scan(/(?<origin>^\s*@(?<prefix>h3[^\(\s]*)\s(?<subject>.+))/)
					target = contents.scan(/(?<object><#{ssub}(?<attr>\s.*?)?>(?<con>.+?)<\/#{ssub}>)/m)
					target.each do |x|
						object,attr,con = x[0],x[1],x[2]
						con.gsub!(/<.+?>/, "")
						@mokuh3 << con 
						contents.gsub!(/#{object}/,"<#{ssub}#{attr} id=\"#{i}#{ssub}\">#{con}</#{ssub}>")
						i += 1
					end

					li = ""
					@mokuh3.each_with_index do |var,index|
						li = li + "<li><a href=\"##{index}#{ssub}\">#{var}</a></li>"
					end
					origin = regex_esc(origin)
					contents.gsub!(/#{origin}/, "<ul>#{li}</ul>") #@mokuzi[]を目次に変更
				end
			end
		end
	end

	def regex_esc(strings)
		strings.gsub!(/([-\\*+.?{}()\[\]^$|\/])/) { '\\' + $1 } #正規表現で使えるようエスケープ
	end

	def comment(contents)
		contents.gsub!(/^@---.+?---@$/m,"")
	end

	def utag(contents)
		utagl = []
		utagh = {} 
		utagt = ""
		@UTAGS.each do |key,value|
			utagl << ['@'+key,'@'+value["bcml"]]
		end
		utagl.each_with_index do |x,index|
			utagh[x[0]] = x[1]
			unless index == utagl.length - 1
				utagt << x[0] + "|"
			else
				utagt << x[0]
			end
		end
		contents.gsub!(/(#{utagt})(?=[ \t]+)/, utagh)
	end

	def main(contents)
		@original = contents.dup
		comment(contents)
		utag(contents)
		manyline(contents)
		oneline(contents)
		stag(contents)
		text(contents)
		puts 'return'
		puts contents
		puts 'end'
		return contents
	end
end


fileName = File.basename(ARGV[0],'.bcml') #引数からファイル読み込み
newfile = open('convert' + '.html', 'w') #変換先ファイルを開く

#変換元ファイルを開いて変数に格納した後閉じる
source = open(fileName + '.bcml')
contents = source.read
source.close

#変換元データを処理した後変換先ファイルに書き込み
con = Convert.new
converted = con.main(contents)

newfile.write(converted) #書き込み
#開いていたファイルを閉じる
newfile.close

=begin
自動br挿入
generalコンフィグ
目次自動生成
目次自動生成のような機能をコンフィグで
=end
