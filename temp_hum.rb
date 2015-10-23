$wire = Wire.new( 0x0, Wire::DutyCycle_2 )  

hum = HumidityHIH6130.new

100.times
  hum.calc
  
  puts "#{hum.tempereture}"
  puts "#{hum.humidity}"
  delay(1000)
end

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