class BME280
  BME280_ADDRESS = 0x77
  
  def initialize    
    @osrs_t = 1
    @osrs_p = 1
    @osrs_h = 1
    @mode = 3  
    @t_sb = 5  
    @filter = 0       #Filter off 
    @spi3w_en = 0     #3-wire SPI Disable
  
    @ctrl_meas_reg = (@osrs_t << 5) | (@osrs_p << 2) | @mode
    @config_reg  = (@t_sb << 5) | (@filter << 2) | @spi3w_en
    @ctrl_hum_reg  = @osrs_h
    digitalWrite(D2, 1)
    
    puts readReg(0xD0)
    writeReg(0xF2,@ctrl_hum_reg)
    writeReg(0xF4,@ctrl_meas_reg)
    writeReg(0xF5,@config_reg)
    readTrim
  end

  def readTrim
    data = Array.new
    i=0
    $wire.beginTransmission(BME280_ADDRESS)
    $wire.write(0x88)
    $wire.endTransmission()
    $wire.requestFrom(BME280_ADDRESS,24)
    24.times do
      data[i] = $wire.read
      i += 1
    end
  
    $wire.beginTransmission(BME280_ADDRESS)
    $wire.write(0xA1)
    $wire.endTransmission()
    $wire.requestFrom(BME280_ADDRESS,1)
    data[i] = $wire.read
    i += 1
  
    $wire.beginTransmission(BME280_ADDRESS)
    $wire.write(0xE1)
    $wire.endTransmission()
    $wire.requestFrom(BME280_ADDRESS,7)
    7.times do
      data[i] = $wire.read
      i += 1  
    end
  
    @dig_T1 = (data[1] << 8) | data[0]
    @dig_T2 = (data[3] << 8) | data[2]
    @dig_T3 = (data[5] << 8) | data[4]
    @dig_P1 = (data[7] << 8) | data[6]
    @dig_P2 = (data[9] << 8) | data[8]
    @dig_P3 = (data[11]<< 8) | data[10]
    @dig_P4 = (data[13]<< 8) | data[12]
    @dig_P5 = (data[15]<< 8) | data[14]
    @dig_P6 = (data[17]<< 8) | data[16]
    @dig_P7 = (data[19]<< 8) | data[18]
    @dig_P8 = (data[21]<< 8) | data[20]
    @dig_P9 = (data[23]<< 8) | data[22]
    @dig_H1 = data[24]
    @dig_H2 = (data[26]<< 8) | data[25]
    @dig_H3 = data[27]
    @dig_H4 = (data[28]<< 4) | (0x0F & data[29])
    @dig_H5 = (data[30] << 4) | (data[29] >> 4)
    @dig_H6 = data[31]
  end

  def writeReg(reg_address, data)
    $wire.beginTransmission(BME280_ADDRESS)
    $wire.write(reg_address)
    $wire.write(data)
    $wire.endTransmission()  
  end
  
  def readReg(reg_address)
    $wire.beginTransmission(BME280_ADDRESS)
    $wire.write( reg_address )
    $wire.endTransmission()
    $wire.requestFrom( BME280_ADDRESS, 1 )
    value = $wire.read        
    return value
  end


  def readData
    i = 0
    data = Array.new
    $wire.beginTransmission(BME280_ADDRESS)
    $wire.write(0xF7)
    $wire.endTransmission()
    $wire.requestFrom(BME280_ADDRESS,8)
    8.times do
      data[i] = $wire.read
      i += 1
    end
    $bar_raw = (data[0] << 12) | (data[1] << 4) | (data[2] >> 4)
    $temp_raw = (data[3] << 12) | (data[4] << 4) | (data[5] >> 4)
    $hum_raw  = (data[6] << 8) | data[7]
  end


  def temp(adc_T)
    var1 = ((((adc_T.to_f >> 3) - (@dig_T1.to_f<<1))) * (@dig_T2).to_f) >> 11
    var2 = (((((adc_T.to_f >> 4) - (@dig_T1).to_f) * ((adc_T.to_f>>4) - (@dig_T1).to_f)) >> 12) * (@dig_T3).to_f) >> 14
  
    @t_fine = var1 + var2
    T = (@t_fine * 5 + 128) >> 8
    return T 
  end
  
  def bar(adc_P)
    var1 = ((@t_fine).to_f>>1) - 64000
    var2 = (((var1>>2) * (var1>>2)) >> 11) * (@dig_P6).to_f
    var2 = var2 + ((var1*(@dig_P5).to_f)<<1)
    var2 = (var2>>2)+((@dig_P4).to_f<<16)
    var1 = (((@dig_P3.to_f * (((var1>>2)*(var1>>2)) >> 13)) >>3) + (((@dig_P2).to_f * var1)>>1))>>18
    var1 = ((((32768+var1))*(@dig_P1).to_f)>>15)
    if (var1 == 0)
      return 0
    end
    P = ((((1048576)-adc_P.to_f)-(var2>>12)))*3125
    if(P<0x80000000)
      P = (P.to_f << 1) / ( var1)   
    else
      P = (P.to_f / var1) * 2  
    end
    var1 = ((@dig_P9).to_f * ((((P.to_f>>3) * (P.to_f>>3))>>13)))>>12
    var2 = (((P>>2)) * (@dig_P8).to_f)>>13
    P = (P + ((var1 + var2 + @dig_P7.to_f) >> 4))
    
    return P
  end

  def hum(adc_H)
    v_x1 = (@t_fine.to_f - (76800).to_f)
    v_x1 = (((((adc_H.to_f << 14)-((@dig_H4).to_f << 20).to_f - ((@dig_H5).to_f * v_x1.to_f).to_f).to_f + (16384).to_f) >> 15).to_f * (((((((v_x1 * (@dig_H6).to_f) >> 10).to_f * (((v_x1.to_f * (@dig_H3).to_f).to_f >> 11).to_f + ( 32768).to_f).to_f).to_f >> 10) + (2097152).to_f).to_f * ( @dig_H2).to_f + 8192) >> 14).to_f).to_f
     v_x1 = (v_x1.to_f - (((((v_x1.to_f >> 15).to_f * (v_x1.to_f >> 15).to_f).to_f >> 7).to_f * (@dig_H1).to_f) >> 4).to_f).to_f
     v_x1 = (v_x1.to_f < 0 ? 0 : v_x1.to_f)
     v_x1 = (v_x1.to_f > 419430400.to_f ? 419430400.to_f : v_x1.to_f)
     
     return (v_x1.to_f >> 12)   
   end
end

$wire = Wire.new( 0x0, Wire::DutyCycle_2 )
sensor = BME280.new

loop do
  sensor.readData()
  
  temp_cal = sensor.temp($temp_raw.to_f)
  bar_cal = sensor.bar($bar_raw.to_f)
  hum_cal = sensor.hum($hum_raw.to_f)
  temp_act = temp_cal / 100.0
  bar_act = bar_cal / 100.0
  hum_act = hum_cal / 1024.0
  print "TEMP : "
  print temp_act
  print " DegC  PRESS : "
  print bar_act
  print " hPa  HUM : "
  print hum_act
  print " %\n" 
  delay(1000)
end