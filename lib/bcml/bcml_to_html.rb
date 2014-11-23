module Bcml
	class BcmlToHtml < Bcml
		def initialize()
			oneliner
			multiliner
		end

		private
		def oneliner
			convert(@@contents,/(?<origin>^[ \t]*(?<!\\)#{@@config.SYMBOL[0]}(?<prefix>[a-zA-Z0-9][^\s]*)[ 　\t](?<subject>.+))/)
		end

		def multiliner
			re = /(?<f>(?<!\\)#{@@config.SYMBOL[1]}(\g<f>*.*?)*#{@@config.SYMBOL[2]})(?!\\)/m
			while re =~ @@contents
				@@contents.gsub!(re) do |match|
					match.gsub!(/(\A#{@@config.SYMBOL[1]}|#{@@config.SYMBOL[2]}\Z)/,"")
					convert(match,/(?<origin>^(?<prefix>[a-zA-Z0-9][^\s]*)[　\s](?<subject>.+))/m)
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
						case
						when intag != "" && outtag != ""
							product = outtag[0] + "<span#{intag}>" + subject + "</span>" + outtag[1]
						when outtag != ""
							product = outtag[0] + subject + outtag[1]
						when intag != ""
							product = "<span#{intag}>" + subject + "</span>"
						end
					else
						this_tag = @@config.TAGS[tag]
						if this_tag && this_tag["escape"]
							subject.gsub!(/[<>&"]/,"<" => "&lt;", ">" => "&gt;", "&" => "&amp;", '"' => "&quot;")
						end
						product = outtag[0] + "<#{tag}#{intag}>" + subject + "</#{tag}>" + outtag[1]
					end
					product

				else #タグが無効なものだったら変換せずに終了
					$~[:origin]
				end
			end
		end

		#正規表現にマッチしたものをパーツごとに分ける
		def separator(data)
			subject = data[:subject]
			prefix = data[:prefix]
			prefix.slice!(/^(?<tag>[a-z0-9]+)/)
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
end
