module Bcml
	class MakeConfig < Bcml
		attr_reader :TAGS, :TAG, :SPECIALTAGS, :QUALIFIERS, :USERTAGS, :GENERAL, :SYMBOL, :BRACKET, :COMMENT, :STARTERS
		def initialize(source)
			yaml_open(source)
		end

		private
		# 設定ファイルから変数定義
		def yaml_open(source)
			config = source.empty? ? YAML.load_file("#{File.dirname(__FILE__)}/../config.yml") : YAML.load(source)

			@TAGS = config["TAGS"]
			@TAG = make_list(config["TAGS"])

			@SPECIALTAGS = config["SPECIALTAGS"]

			@QUALIFIERS = config["QUALIFIERS"]
			create_starters(@QUALIFIERS) #@STARTERS作成

			@USERTAGS = config["USERTAGS"] #ユーザー定義のタグ @midasi

			@GENERAL = config["GENERAL"] #シンボルに使う文字など
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
			return @STARTERS
		end
	end
end
