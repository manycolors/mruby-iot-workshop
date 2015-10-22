webapi
======================
enziからのセンサ情報を受け取りtwitterかslackに投稿する
  
使い方
------
###設定変更###
事前にTwitter及びSlackの登録を行いキーを取得の上、下記を書き換えて下さい。
SECはランダムな文字列であればなんでも構いません。

    SEC = ""
    YOUR_CONSUMER_KEY = ""
    YOUR_CONSUMER_SECRET = ""
    SLACK_TOKEN = ""
  
Twitter http://dev.twitter.com/
Slack https://api.slack.com/web

### 起動 ###
    # bundle install
    # bundle exec shotgun

これで http://localhost:9393 にアクセス
 
### Twitter OAuthによるトークンの取得 ###
http://localhost:9393/twitter/auth
にアクセスの上認証を行い

    TOKEN=""
    SECRET=""
 
を書き換えて下さい。

###アクセス、投稿###

http://localhost:9393/SEC/:media/:type/:id/:value

で投稿可能です。

* SECには設定済みのランダムな文字列が入ります。
* :mediaにはtwitterまたはslackという文字列が入ります。
* :typeはtemp, hum, barという文字列が入ります。
* :idはカラ以外の任意の文字列が入ります。
* :valueは値が入ります。
 

####例####
    http://localhost:9393/jojjpoijjpo8909ii/slack/temp/0/23


