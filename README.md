bcml
====

ブログ用マークアップ言語bcml

<h2 id="h22">説明</h2><p>
bcmlはブログなどのサイト上のテキストコンテンツを書きやすくする独自の記法を提供し、bcmlファイルからhtmlファイルを生成することができます。<br>
これを聞くとマークダウンをイメージするかもしれませんがbcmlはクラスを指定するなどより細かい作業に対応しています。<br>
bcmlはユーザーが記法をカスタマイズでき、記事を書く上で煩わしい作業はbcmlが請負ます。<br>
あなたはPCでもスマホでも好きな端末で書きやすい記法にカスタマイズし文章の作成に集中することができます。<br>
</p>
<h2 id="h23">使いかた</h2><p>
bcmlはlib/bcmlにファイル名を引数として渡し実行することでhtmlファイルを生成できます。<br>
lib/bcmlを直接呼び出してもいいですがファイルパスを毎回記述するのはめんどくさいのでパスを通すことをおすすめします。<br>
</p><p>パスの通し方は環境によって違いますがシェルがzshの場合はこれを~/.zshrcに記述してください。</p>
<pre class="brush:bash">PATH=${PATH}:~/bcml/bin</pre><p>
ここで重要なのは、bcmlのフォルダがホームディレクトリに入ってる場合は~/bcml/binにパスを通すということです。<br>
</p><p>では試しにこの文書のソースであるREADME.bcmlを変換してみましょう。<br>
README.bcmlはexamplesフォルダの中にあります。<br>
</p><p>これを変換するとREADME.htmlが出来上がりますが、examplesフォルダはコンパイルした後のものもすぐ見れるようにREADME.htmlがはじめからあるので別のフォルダに移してからコマンドを実行しましょう。<br>
変換しようとしたファイルがすでにある場合は変換後のファイルで置き換えられます。<br>
bcmlという拡張子はわかりやすくするためにこちらが定めたもので特に意味はありませんがこの拡張子にしないとエラーが出ます。<br>
</p>
<code class="command">bcml README.bcml</code>
</p><p><h2 id="h24">文法</h2><p>
h3タグでhello worldと書きたい場合はbcml記法が始まることを表す「@」とタグ名「h3」をbcmlでは書きます。</p>
<pre class="brush:html">
&lt;h3&gt;hello world&lt;/h3&gt;
bcml-&gt; @h3 hello world</pre>
<p>ここで紹介したのはbcmlのデフォルト設定での最も基本的なサンプルです。詳しい情報はdocフォルダのusage.htmlを参照ください。<br>
また、bcmlで書かれた文書のサンプルがexamplesフォルダにあるので何ができるかを知りたい場合はそこを見ると解決すると思います。<br>
このファイルもdocフォルダのドキュメントもbcmlで書かれているのでそれもおいてあります。<br>
設定をしている場合はその設定がコメントに入っています。<br>
</p>
<h2 id="h25">カスタマイズ例</h2><p>
bcmlは設定ファイルを変更することで簡単に文法を変えることができますがこれはその中の一例です。<br>
</p>
<pre class="brush:html">&lt;span class=&quot;command&quot;&gt;bcml sample.bcml&lt;/span&gt;
bcml-&gt; ！こまんど bcml sample.bcml
</pre>
<p>この例を見れば解ると思いますがbcmlはひらがなを使うこともできます。<br>
そしてこの設定にした時の設定ファイルは以下のものです。<br>
</p>
<pre class="brush:yaml">GENERAL:
  symbol: [&quot;！&quot;, &quot;！(&quot;, &quot;)！&quot;]
UTAGS:
  こまんど:
    bcml: span.command
</pre><p>
<br>
具体的な設定ファイルの書きかたはdocフォルダを参照してください。<br>
