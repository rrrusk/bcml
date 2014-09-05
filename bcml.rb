# encoding utf-8
require 'yaml'
require 'pp'
#コンバート処理
class Convert
	def initialize()
		# 設定ファイルからタグリストなどを読み込む
		config = YAML.load_file('config.yml')
		@TAGS = config["TAGS"].freeze
		@QUALIFIERS = config["QUALIFIERS"].freeze

		createStarters(@QUALIFIERS) #@STARTERS作成
	end

	#設定の中からスターターのリストを作る(join(|)で正規表現として使う)
	def createStarters(qualifiers)
		@STARTERS = []
		@SYMBOL = []
		qualifiers.each do |key,value|
			@STARTERS << key + '\[.+?\]'
			@STARTERS << key
			@SYMBOL << key
		end
		@STARTERS.freeze
		@SYMBOL.freeze
	end

	#修飾部分の分離
	def separatorQ(qualifier)
		intags = []
		outtags = [[],[]]
		# /#{@STARTERS.join("|")}(\[.+?\]|[^#{@SYMBOL.join("")}])+/
		qualifier.scan(/(?<starter>#{@STARTERS.join("|")})(?<qsub>(\[.+?\]|[^#{@SYMBOL.join("")}])+)/) do |match|
			starter,qsub = $~[:starter],$~[:qsub] #starter => qualifierを起動する qsub => qualifierの本文
			qinfo = @QUALIFIERS[starter] 
			if qinfo["point"] == "intag"
				p qsub
				qsub.gsub!(/^\[(.+?)\]$/,'\1')
				p qsub
				intags << qinfo["usage"].gsub(/<qsub>/,qsub) #qsubを有るべき場所に入れる
				p intags
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

	def convert(contents,re)
		contents.gsub!(re) do |match|
			subject,tag,qualifier = separator($~) #マッチしたものをパーツごとに分ける
			intag,outtag = separatorQ(qualifier)
			if tag == ""
				if intag != "" && outtag != ""
					goal = outtag[0] + "<span#{intag}>" + subject + "</span>" + outtag[1]
				elsif outtag != ""
					goal = outtag[0] + subject + outtag[1]
				elsif intag != ""
					goal = "<span#{intag}>" + subject + "</span>"
				end
			else
				goal = outtag[0] + "<#{tag}#{intag}>" + subject + "</#{tag}>" + outtag[1]
			end

			#タグが設定されてるか確認
			if @TAGS.include?(tag) || tag == ""
				goal
			else
				$~[:origin]
			end
		end
	end

	def oneline(contents)
		convert(contents,/(?<origin>^\s*@(?<prefix>[^\(\s]+)\s(?<subject>.+))/)
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

	def main(contents)
		manyline(contents)
		oneline(contents)
		puts "converted:\n" + contents
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
