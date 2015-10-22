#
# twitter用 Web API
# Author: Shota Nakano (Manycolors, Inc.)
#
# 参考記事
# https://it.typeac.jp/article/show/7
#

require 'sinatra/base'
require 'oauth'
require 'twitter'
require 'coffee-script'
require 'slack'

require_relative 'models/init'

class Server < Sinatra::Base
  # Sessionの有効化
  enable :sessions  
 
  ##########
  # 以下設定が必要
  ##########
  # アクセス用のURL
  SEC = ""
  # Twitter API情報の設定
  YOUR_CONSUMER_KEY = ""
  YOUR_CONSUMER_SECRET = ""
  # /twitter/authで得たものに書き換える
  TOKEN=""
  SECRET=""
  
  SLACK_TOKEN = ""
  ##########
  
  sensor_url = "/#{SEC}/:media/:type/:id/:value"
  
  # TwitterAPI ライブラリ 設定(1/2)
  client = Twitter::REST::Client.new do |config|
    config.consumer_key = YOUR_CONSUMER_KEY
    config.consumer_secret = YOUR_CONSUMER_SECRET
  end
 
 
  def oauth_consumer
    return OAuth::Consumer.new(YOUR_CONSUMER_KEY, YOUR_CONSUMER_SECRET, :site => "https://api.twitter.com")
  end
 
  # トップページ
  get '/' do
    "<html><body><a href='/twitter/auth'>Twitter access start!!</a></body></html>"
  end
 
  # Twitter認証
  get '/twitter/auth' do
    # callback先のURLを指定する 
    callback_url = "http://localhost:9393/twitter/callback"
    request_token = oauth_consumer.get_request_token(:oauth_callback => callback_url)
 
    # セッションにトークンを保存
    session[:request_token] = request_token.token
    session[:request_token_secret] = request_token.secret
    redirect request_token.authorize_url
    #"test"
  end
 
  # Twitterからトークンなどを受け取り
  get '/twitter/callback' do
    request_token = OAuth::RequestToken.new(oauth_consumer, session[:request_token], session[:request_token_secret])
 
    # OAuthで渡されたtoken, verifierを使って、tokenとtoken_secretを取得
    access_token = nil
    begin
      access_token = request_token.get_access_token(
        {},
        :oauth_token => params[:oauth_token],
        :oauth_verifier => params[:oauth_verifier])
    rescue OAuth::Unauthorized => @exception
      # 本来はエラー画面を表示したほうが良いが、今回はSinatra標準のエラー画面を表示
      raise
    end
 
    # TwitterAPI ライブラリ 設定(2/2)
    client = Twitter::REST::Client.new do |config|
      puts config.oauth_token = access_token.token
      puts config.oauth_token_secret = access_token.secret
      a = config.oauth_token
      b = config.oauth_token_secret
    end
    # 本来であれば上記情報をDBなどに保存

    # タイムラインの情報を取得、表示
    "<html><body>TOKEN=\"#{a}\"<br>SECRET=\"#{b}\"</body></html>"
  end
  
  def tweet(str)
    client = Twitter::REST::Client.new do |config|
      config.consumer_key = YOUR_CONSUMER_KEY
      config.consumer_secret = YOUR_CONSUMER_SECRET
      config.oauth_token = TOKEN
      config.oauth_token_secret = SECRET
    end
    client.update(str)
  end
  
  def slack(str)
    Slack.configure do |config|
      config.token = SLACK_TOKEN
    end
    Slack.chat_postMessage(text: str, channel: '#general')
  end
    
  get sensor_url do
    if params['type'] == 0 || params['type'] == "temp"
      str = "温度 ID:#{params['id']} VALUE:#{params['value']}"
    elsif params['type'] == 1 || params['type'] == "hum"
      str = "湿度 ID:#{params['id']} VALUE:#{params['value']}"
    else
      nil
    end
    
    if str
      if params['media'] == "twitter"
        sleep(3)
        tweet(str)
      elsif params['media'] == "slack"
        sleep(3)
        slack(str)
      end
    else
      return "<html><body>fault<body></html>"
    end
    
    "<html><body>success<body></html>"
  end
end