# encoding: utf-8
#コンバート処理
class Convert
	def initialize()
	end

	def main(contents)
		tags = %w[h1 h2 h3 h4 h5 h6 a span div]
		qualifier = {
			"."=>{
				"point"=>"intag",
				"usage"=>'class="#{qualifier}"'
			},
		}

#		converted = contents.gsub(/^@(#{tags.join("|")})\s+(.+)/, '<\1>\2</\1>')
#		array = contents.scan(/^@(?<tags>#{tags.join("|")})\.(?<qualifier>.+)\s+(?<subject>.+)/)
#		print converted
#		p array
		scan = contents.scan(/^@(?<prefix>[^\s]+)\s(?<subject>.+)/)
		p scan


#		contents.scan(/^@(?<tags>#{tags.join("|")})\.(?<qualifier>.+)\s+(?<subject>.+)/) {|match|
#			subject = $~[:subject]
#			tags = $~[:tags]
#			qualifier = $~[:qualifier]
#			intag = ' class="' + qualifier + '"'
#			puts "qualifier:" + qualifier if qualifier
#			goal = "<" + tags + intag + ">" + subject + "</" + tags + ">"
#			puts goal
#		}
			
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

