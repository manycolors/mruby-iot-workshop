# 湿度・温度計のクラス
class HumidityHIH6130
  HIH6130_ADDRESS = 0x27
  
  def initialize
    @temp = 0
    @humidity = 0
    @status = 0
  end
  
  def calc
    # wake up
    #puts 'HIH6130 MR'
    $wire.beginTransmission( HIH6130_ADDRESS )
    $wire.endTransmission()    
    delay( 100 )

    # read registers    
    #puts 'HIH6130 DF'
    $wire.requestFrom( HIH6130_ADDRESS, 4 )
    h_hi = $wire.read
    h_lo = $wire.read
    t_hi = $wire.read
    t_lo = $wire.read
    #$wire.endTransmission()    

    #normalize
    @status = ( h_hi >> 6 ) & 3
    h_hi = h_hi & 0x3f
    
    t = ( t_hi*256 + t_lo ) >> 2
    h = h_hi*256 + h_lo
    
    @temp = t/( 2**14 - 2 )*165.0 - 40.0
    @humidity = h/( 2**14 -2 )*100.0
    
    return true
  end

  def tempereture
    return @temp
  end

  def humidity
    return @humidity
  end    
  
  def status
    return @status
  end
end

$wire = Wire.new( 0x0, Wire::DutyCycle_2 )  

sensor = HumidityHIH6130.new

serv = TCPServer.open('192.168.0.0', 80) #IPアドレスは関係なし
buf_len = 32

temp = Array.new

# グラフ用に10個埋める
10.times do
  sensor.calc
  p temp << sensor.tempereture
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
  content[1] = ""
  c = serv.accept

  recv_text = nil
  while (recv_text.nil?)
    recv_text = c.recv(buf_len)
  end

  while (t = c.recv(buf_len))
    recv_text += t
  end
  
  temp.shift
  sensor.calc
  temp << sensor.tempereture

  counter = temp.size
  temp.each do |t|
    counter -= 1
    content[1] += "['-#{counter}', #{t}],"
  end

  # レスポンス送信
  c.send "HTTP/1.0 200 OK\r\n"
  c.send "Content-Length: #{content.join.length}\r\n"
  c.send "Content-Type: text/html\r\n"
  c.send "\r\n"
  c.send content.join
  
  c.close
end

serv.close