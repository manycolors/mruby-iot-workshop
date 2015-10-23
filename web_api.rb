# クラスインスタンスの作成
simple_http = SimpleHttp.new("[ip]", "[port]")
# 必ず必要
simple_http.http_version = "HTTP/1.1"

# get
puts simple_http.get("/[key]/slack/temp/[id]/20.44")
#puts simple_http.get("/[key]/twitter/hum/[id]/50")

simple_http = SimpleHttp.new("108.61.163.72", "9393")
simple_http.http_version = "HTTP/1.1"
simple_http.get("/590544ee05762c62719e87d4ed79f807/slack/temp/10/21")