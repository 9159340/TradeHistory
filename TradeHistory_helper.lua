Helper = class(function(acc)
end)

function Helper:Init()
  
end

--���������� ���� ������ � ��������� ������� '06.11.2016'
function Helper:get_trade_date(trade)

  local z = ''
  
  local day = ''
  
  if trade.datetime.day<10 then 
    z = '0' 
  else
    z = ''
  end
  day = z..tostring(trade.datetime.day)
   
  local month = ''
  
  if trade.datetime.month<10 then 
    z = '0' 
  else
    z = ''
  end
  month = z..tostring(trade.datetime.month)

  return day..'.'..month..'.'..tostring(trade.datetime.year)
end

--���������� ���� ������ � ��������� ������� SQL '2016-11-06' (��� ���������� ���������� � ��������)
function Helper:get_trade_date_sql(trade)

  local z = ''
  
  local day = ''
  
  if trade.datetime.day<10 then 
    z = '0' 
  else
    z = ''
  end
  day = z..tostring(trade.datetime.day)
   
  local month = ''
  
  if trade.datetime.month<10 then 
    z = '0' 
  else
    z = ''
  end
  month = z..tostring(trade.datetime.month)

  return tostring(trade.datetime.year)..'-'..month..'-'..day
end

--���������� ����� ������ � ��������� ������� '10:26:13'
function Helper:get_trade_time(trade)
  
  local z = ''
  
  local hour = ''
  
  if trade.datetime.hour<10 then 
    z = '0' 
  else
    z = ''
  end
  hour = z..tostring(trade.datetime.hour)
   
  local min = ''
  
  if trade.datetime.min<10 then 
    z = '0' 
  else
    z = ''
  end
  min = z..tostring(trade.datetime.min)

  local sec = ''
  
  if trade.datetime.sec<10 then 
    z = '0' 
  else
    z = ''
  end
  sec = z..tostring(trade.datetime.sec)
  
  return hour..':'..min..':'..sec
end



--�������, ����� � ��������� �������� �����
function Helper:getQtyClose(t,row)
  local res = false
  local val = nil
  res, val = check_nil(t, row, 'qtyClose')
  if res == true then
	return 0
  end
  return val  
end

--�������, ����� � ��������� �������� �����
function Helper:getQuantity(t,row)
  local res = false
  local val = nil
  res, val = check_nil(t, row, 'quantity')
  if res == true then
	return 0
  end
  return val  
end

--�������, ����� � ��������� �������� �����
--���������
--	t - in - ������� ������
--	row - in - number - ����� ������ �������
function Helper:getPriceClose(t,row)
  local res = false
  local val = nil
  res, val = check_nil(t, row, 'priceClose')
  if res == true then
	return 0
  end
  return val  
end

--�������, ����� � ��������� �������� �����
function Helper:getPriceOpen(t,row)
  local res = false
  local val = nil
  res, val = check_nil(t, row, 'priceOpen')
  if res == true then
	return 0
  end
  return val
end

function check_nil(t, row, column)
  if t == nil then
	return true, nil
  end
  local cell = t:GetValue(row, column)
  if cell == nil then
    return true, nil
  end
  local val = tonumber(cell.image)
  if val == nil then
    return true, nil
  end
  return false, val
end



--���������� ����� ������� � ����. ����� ��� �������
function Helper:save_sql_to_file(sql, filename)
   -- �������� ������� ���� � ������ "������/������"
   f = io.open(getScriptPath().."\\"..filename,"r+");
   -- ���� ���� �� ����������
   if f == nil then 
      -- ������� ���� � ������ "������"
      f = io.open(getScriptPath().."\\"..filename,"w"); 
      -- ��������� ����
      --f:close();
      -- ��������� ��� ������������ ���� � ������ "������/������"
      --f = io.open(getScriptPath().."\\sql.txt","r+");
   end;
   -- ���������� � ���� 2 ������
   --f:write("Line1\nLine2"); -- "\n" ������� ����� ������
   
   f:write(sql); -- "\n" ������� ����� ������
   
   
   -- ��������� ��������� � �����
   f:flush();
   -- ������ � ������ ����� 
      -- 1-�� ���������� �������� ������������ ���� ����� ��������: "set" - ������, "cur" - ������� �������, "end" - ����� �����
      -- 2-�� ���������� �������� ��������
   --f:seek("set",0);
   -- ���������� ������ �����, ������� �� ���������� � ����������
   --for line in f:lines() do message(tostring(line));end
   -- ��������� ����
   f:close();
end



--������� ���������� true, ���� ��� [index] ���������� � 1 (����� �� �������� some_callbacks.lua)
--������ ������ ��� ����������� �����������
--if bit_set(flags, 2) then
--		t["sell"]=1
--	else
--		t["buy"] = 1
--	end
--
function Helper:bit_set( flags, index )
  local n=1
  n=bit.lshift(1, index)
  if bit.band(flags, n) ~=0 then
    return true
  else
    return false
  end
end

--��������� ���������� � �������� ���������
--math.round(3.27893, 2) -- ������ ������� 3.28
function Helper:math_round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end
 



--���������� ���� ��� ������� "���� ��������"
--���������
--  par_t - in - table - �.�. ����� ���� ������� �� ������ �������� �������, � ��� ������� �������, �� �������� �������� ��������
--  row - �� - ����� - ����� ������ � ������� ������
function Helper:get_priceClose(par_t, row)

  local priceClose = 0
  local class_code = par_t:GetValue(row,'classCode').image
  local sec_code = par_t:GetValue(row,'secCode').image
  
  if par_t:GetValue(row,'operation').image == 'buy' then
    priceClose = tonumber(getParamEx (class_code, sec_code, 'bid').param_value)
    
  elseif par_t:GetValue(row,'operation').image == 'sell' then
    priceClose = tonumber(getParamEx (class_code, sec_code, 'offer').param_value)
    
  end

  --����� ���������� ������ ���� � ������ ����� ����� ����, ������� ����� last
  if priceClose == nil or priceClose == 0 then

    priceClose = tonumber(getParamEx (class_code, sec_code, 'last').param_value)
  end
  
  --���� ��� last, ��������� �������� close
  if priceClose == nil or priceClose == 0 then
  
    priceClose = tonumber(getParamEx (class_code, sec_code, 'close').param_value)
  end
--message(tostring(priceClose == nil))
--message(tostring(priceClose))
  if priceClose == nil or priceClose == 0 then
  
    priceClose = tonumber(getParamEx (class_code, sec_code, 'lcloseprice').param_value) --official close price (when session is over)
	--message('12')
  end

  if priceClose == nil then
    priceClose = 0
  end
  --����������
  --priceClose = math.ceil(priceClose*10000)/10000
  priceClose = self:math_round(priceClose, 4)
  
  return priceClose

end


--��������� ���������� ���� ����� ������. ���� ��� ����� ���������� ���
--���������
--	startDate- �� - ���� - ������ ����: 2016-05-28 (�.�. ��� � SQL)
function Helper:days_in_position(startDate, endDate)
--message('<'..endDate..'>')
	if startDate==nil or endDate ==nil 
		or startDate=='' or endDate =='' 
		or startDate==' ' or endDate ==' ' then
		return nil
	end
	
	
	
	local y1 = tonumber(string.sub(startDate,1,4))
	local m1 = tonumber(string.sub(startDate,6,7))
	local d1 = tonumber(string.sub(startDate,9,10))

	local y2 = tonumber(string.sub(endDate,1,4))
	local m2 = tonumber(string.sub(endDate,6,7))
	local d2 = tonumber(string.sub(endDate,9,10))

	
	
	--http://bot4sale.ru/blog-menu/qlua/spisok-statej/368-lua-time.html
	
	datetime1 = { year = y1,
                   month = m1,
                   day = d1
                  }

	seconds1 = os.time(datetime1)
	--message(tostring(seconds1))	
	
	datetime2 = { year = y2,
                   month = m2,
                   day = d2
                  }

	seconds2 = os.time(datetime2)
	
	--message(tostring(  (seconds2-seconds1)/86400  ))
	
	if seconds1==nil or seconds2==nil then 
	return 0
	end
	
	return (tonumber(seconds2)-tonumber(seconds1))/86400
	
end

--searches value in array (table with 2 columns: key and value)
--returns key (row number)
function Helper:find_in_array(t, str)

  for k, v in pairs(t) do
    if v == str then 
		return k 
	end
  end
  return nil

end


function Helper:buy_depo(class, sec)
	local buyDepo_cell = getParamEx(class, sec, 'buydepo')
	if buyDepo_cell ~= nil then
		return tonumber(buyDepo_cell.param_value)
	else
		return 0
	end
end

function Helper:sell_depo(class, sec)
	local sellDepo_cell = getParamEx(class, sec, 'selldepo')
	if sellDepo_cell ~= nil then
		return tonumber(sellDepo_cell.param_value)
	else
		return 0
	end
end			
			