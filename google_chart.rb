sensor = BMP280.new
serv = TCPServer.open('192.168.0.0', 80) #IPアドレスは関係なし
buf_len = 32

temp = Array.new

# グラフ用に10個埋める
10.times do
  temp << sensor.get_temp
end

content = Array.new

# コンテンツ固定箇所前半
content[0] = "<html>"
content[0] += "<head>"
content[0] += "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />"
content[0] += "<script type=\"text/javascript\" src=\"https://www.google.com/jsapi\"></script>"
content[0] += "<script type=\"text/javascript\">"
content[0] += "  google.load('visualization', '1', {'packages':['corechart']});     "
content[0] += "  google.setOnLoadCallback(drawChart);"
content[0] += "  function drawChart() {      "
content[0] += "    var data = google.visualization.arrayToDataTable(["
content[0] += "      ['秒数', '温度'],"
# コンテンツ固定箇所後半
content[2] = "    ]);"
content[2] += "    var options = {"
content[2] += "      title: '温度の推移'"
content[2] += "     };     "
content[2] += "    var chart = new google.visualization.LineChart(document.getElementById('chart_div'));"
content[2] += "    chart.draw(data, options);"
content[2] += "  }"
content[2] += "</script>"
content[2] += "</head>"
content[2] += "<body>"
content[2] += "  <div id=\"chart_div\" style=\"width: 100%; height: 350px\"></div>  "
content[2] += "</body>"
content[2] += "</html>"

loop do
  c = serv.accept

  recv_text = nil
  while (recv_text.nil?)
    recv_text = c.recv(buf_len)
  end

  while (t = c.recv(buf_len))
    recv_text += t
  end
  
  temp.shift
  temp << sensor.get_temp

  counter = temp.size
  temp.each do |t|
    counter -= 1
    content[1] += "['-#{counter}', #{t}],"
  end

  response = "HTTP/1.0 200 OK\r\n\r\n" + content.join
  c.send response
  c.close
end

serv.close