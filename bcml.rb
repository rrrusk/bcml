# encoding: utf-8
#コンバート処理
class Convert
	def initialize()
		# 本来は別ファイルから読み込む
		@tags = %w[h1 h2 h3 h4 h5 h6 a span div]
		@qualifiers = {
			"."=>{
				"point"=>"intag",
				"usage"=>'class="<qsub>"',
			},
			"#"=>{
				"point"=>"intag",
				"usage"=>'id="<qsub>"',
			},
			":"=>{
				"point"=>"outtag",
				"usage"=>['<a href="<qsub>">','</a>'],
				"other"=>["bracket",],
			},
		}

		@starters = []

		#設定の中からスターターのリストを作る(join(|)で正規表現として使う)
		@qualifiers.each do |key,value|
			if value["other"]
				if value["other"].include?("bracket")
					@starters << key + "[.+?]"
				end
			else
				@starters << key
			end
		end
	end

	def main(contents)
		#ワンライナーbcml記法
		converted = contents.gsub(/^\s*@(?<prefix>\S+)\s(?<subject>.+)/) do |match|
			subject,prefix = $~[:subject],$~[:prefix] #subject => 本文 prefix => @~の~の部分
			
			#タグを書いてる部分と修飾してる部分分離
			prefix.slice!(/^(?<tag>[a-z0-9あ-ん]+)/)
			qualifier = prefix
			tag = $~ ? $~[:tag] : ""

			#タグが設定されてるか確認
			if @tags.include?(tag) || tag == ""
				intags = []
				outtags = [[],[]]

				#修飾部分の分離
				qualifier.scan(/(?<starter>#{@starters.join("|")})(?<qsub>.+)/) do |match| 
					starter,qsub = $~[:starter],$~[:qsub] #starter => qualifierを起動する qsub => qualifierの本文

					qinfo = @qualifiers[starter]
					if qinfo["point"] == "intag"
						intags << qinfo["usage"].gsub(/<qsub>/,qsub) #qsubを有るべき場所に入れる
					elsif qinfo["point"] == "outtag"
						qsub.gsub!(/^\[(.+?)\]$/,'\1')
						outtags[0] << qinfo["usage"][0].gsub(/<qsub>/,qsub)
						outtags[1] << qinfo["usage"][1].gsub(/<qsub>/,qsub)
						p outtags
					end
				end
				intag = intags.empty? ? "":" " + intags.join(" ")
				outtags[0].join()
				outtag = outtags.empty? ? "": [outtags[0].join(),outtags[1].join()]
				p outtag

				if tag == ""
					if outtag != ""
						goal = outtag[0] + subject + outtag[1]
					elsif intag != ""
						goal = "<span" + intag + ">" + subject + "</span>"
					elsif intag != "" && outtag != ""
						goal = outtag[0] + "<span" + intag + ">" + subject + "</span>" + outtag[1]
					end
				else
					goal = outtag[0] + "<" + tag + intag + ">" + subject + "</" + tag + ">" + outtag[1]
				end

				puts goal
				goal
			
			else #タグが設定されてないのなら置き換えずに終了
				match
			end
		end
		return converted
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
