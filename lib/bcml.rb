#!ruby -Ku
# encoding utf-8
dir = File.dirname(__FILE__)
$LOAD_PATH.unshift dir unless $LOAD_PATH.include?(dir)
require 'yaml'
require 'strscan'
#コンバート処理
module Bcml
	class Bcml
		attr_accessor :contents, :config
		def initialize(source)
			# 設定ファイルから変数定義
			@@config = MakeConfig.new(source)
		end

		def exec(contents)
			@@contents = contents
			comment
			user_tag
			BcmlToHtml.new()
			SpecialTag.new()
			Text.new()
			return @@contents
		end

		private
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
			@@contents.gsub!(/(?<=#{@@config.SYMBOL[0]}|#{@@config.SYMBOL[1]})(#{user_tag_pipe})(?=[ \n\t]+)/, user_tag_hash)
		end

		def regex_esc(strings)
			if /[-\\*+.?{}()\[\]^$|\/]/ =~ strings
				strings.gsub!(/([-\\*+.?{}()\[\]^$|\/])/) { '\\' + $1 } #正規表現で使えるようエスケープ
			end
			return strings
		end
	end
end

require 'bcml/special_tag'
require 'bcml/text'
require 'bcml/bcml_to_html'
require 'bcml/make_config'
