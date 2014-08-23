fileName = File.basename(ARGV[0],'.bcml') #引数からファイル読み込み
newfile = open(fileName + '.html', 'w') #変換先ファイルを開く

#変換元ファイルを開いて変数に格納した後閉じる
source = open(fileName + '.bcml')
contents = source.read
source.close

#変換元データを処理した後変換先ファイルに書き込み
newfile.write(contents)

#開いていたファイルを閉じる
newfile.close

#コンバート処理
class Convert
	def initialize(contents)
		@contents = contents
	end

	def execute
	end

end
