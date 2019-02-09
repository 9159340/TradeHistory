Helper = class(function(acc)
end)

function Helper:Init()
  
end

--возвращает дату сделки в строковом формате '06.11.2016'
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

--возвращает дату сделки в строковом формате SQL '2016-11-06' (для правильной сортировки в таблицах)
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

--возвращает время сделки в строковом формате '10:26:13'
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



--обертка, чтобы с гарантией получить число
function Helper:getQtyClose(t,row)
  local res = false
  local val = nil
  res, val = check_nil(t, row, 'qtyClose')
  if res == true then
	return 0
  end
  return val  
end

--обертка, чтобы с гарантией получить число
function Helper:getQuantity(t,row)
  local res = false
  local val = nil
  res, val = check_nil(t, row, 'quantity')
  if res == true then
	return 0
  end
  return val  
end

--обертка, чтобы с гарантией получить число
--параметры
--	t - in - таблица робота
--	row - in - number - номер строки таблицы
function Helper:getPriceClose(t,row)
  local res = false
  local val = nil
  res, val = check_nil(t, row, 'priceClose')
  if res == true then
	return 0
  end
  return val  
end

--обертка, чтобы с гарантией получить число
function Helper:getPriceOpen(t,row)
  local res = false
  local val = nil
  res, val = check_nil(t, row, 'priceOpen')
  if res == true then
	return 0
  end
  return val
end

-- parameters
--  t - table - main table of robot
--  row - number - number of row in table
--  column - string - name of column in table
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



--записывает текст запроса в файл. нужна для отладки
function Helper:save_sql_to_file(sql, filename)
   -- Пытается открыть файл в режиме "чтения/записи"
   f = io.open(getScriptPath().."\\"..filename,"r+");
   -- Если файл не существует
   if f == nil then 
      -- Создает файл в режиме "записи"
      f = io.open(getScriptPath().."\\"..filename,"w"); 
      -- Закрывает файл
      --f:close();
      -- Открывает уже существующий файл в режиме "чтения/записи"
      --f = io.open(getScriptPath().."\\sql.txt","r+");
   end;
   -- Записывает в файл 2 строки
   --f:write("Line1\nLine2"); -- "\n" признак конца строки
   
   f:write(sql); -- "\n" признак конца строки
   
   
   -- Сохраняет изменения в файле
   f:flush();
   -- Встает в начало файла 
      -- 1-ым параметром задается относительно чего будет смещение: "set" - начало, "cur" - текущая позиция, "end" - конец файла
      -- 2-ым параметром задается смещение
   --f:seek("set",0);
   -- Перебирает строки файла, выводит их содержимое в сообщениях
   --for line in f:lines() do message(tostring(line));end
   -- Закрывает файл
   f:close();
end



--функция возвращает true, если бит [index] установлен в 1 (взято из примеров some_callbacks.lua)
--пример вызова для определения направления
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

--выполняет округление с заданной точностью
--math.round(3.27893, 2) -- должно вернуть 3.28
function Helper:math_round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end
 



--возвращает цену для колонки "Цена закрытия"
--Параметры
--  par_t - in - table - т.к. может быть открыта не только основная таблица, а еще таблица деталей, то пришлось добавить параметр
--  row - вх - число - номер строки в таблице робота
function Helper:get_priceClose(par_t, row)

  local priceClose = 0
  local class_code = par_t:GetValue(row,'classCode').image
  local sec_code = par_t:GetValue(row,'secCode').image
  
  if par_t:GetValue(row,'operation').image == 'buy' then
    priceClose = tonumber(getParamEx (class_code, sec_code, 'bid').param_value)
    
  elseif par_t:GetValue(row,'operation').image == 'sell' then
    priceClose = tonumber(getParamEx (class_code, sec_code, 'offer').param_value)
    
  end

  --после завершения торгов биды и офферы будут равны нулю, поэтому берем last
  if priceClose == nil or priceClose == 0 then

    priceClose = tonumber(getParamEx (class_code, sec_code, 'last').param_value)
  end
  
  --если нет last, попробуем получить close
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
  --rounding
	local precision = settings:get_precision( sec_code )

	if precision~=nil then
		priceClose = self:math_round(priceClose, precision)
	else
		priceClose = self:math_round(priceClose, 2)
	end
  
  return priceClose

end


--calculates datediff in days. пока без учета високосных лет
--Параметры
--	startDate- вх - дата - формат даты: 2016-05-28 (т.к. как в SQL)
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

--returns theor price from table
-- parameters
--  t - table - main table of robot
--  row - number - number of row in table
function Helper:getTheorPrice(t,row)
  local res = false
  local val = nil
  res, val = check_nil(t, row, 'theorPrice')
  if res == true then
	return 0
  end
  return val  
end


--returns theor price from instrument
--Параметры
--  par_t - in - table - т.к. может быть открыта не только основная таблица, а еще таблица деталей, то пришлось добавить параметр
--  row - вх - число - номер строки в таблице робота
function Helper:get_TheorPrice(par_t, row)

  local res = 0
  local class_code = par_t:GetValue(row,'classCode').image
  local sec_code = par_t:GetValue(row,'secCode').image

  res = tonumber(getParamEx (class_code, sec_code, 'theorprice').param_value)

  if res == nil then
    res = 0
  end
  --rounding
  --priceClose = math.ceil(priceClose*10000)/10000
  res = self:math_round(res, 4)
  
  return res

end


--returns profit RUB from table
-- parameters
--  t - table - main table of robot
--  row - number - number of row in table
function Helper:getProfit(t,row)
  local res = false
  local val = nil
  res, val = check_nil(t, row, 'profit')
  if res == true then
	return 0
  end
  return val  
end

--returns profit in points from table
-- parameters
--  t - table - main table of robot
--  row - number - number of row in table
function Helper:getProfitpt(t,row)
  local res = false
  local val = nil
  res, val = check_nil(t, row, 'profitpt')
  if res == true then
	return 0
  end
  return val  
end