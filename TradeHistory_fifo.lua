helper = {}
settings = {}
maintable={}
FIFO = class(function(acc)
end)

function FIFO:Init()

  helper=Helper()
  helper:Init()
  
  settings=Settings()
  settings:Init()
  
  maintable= MainTable()
  maintable:Init()

  self.db = sqlite3.open(settings.db_path)
  
end



--FIFO


--returns comment from trade without prefixes
--Parameters
--	brokerref - in - string - comment
function FIFO:get_deal_comment(brokerref)
	local comment = ''
	--comment like that: "99221FX/", is written by broker (on SELT/CETS)
	local j = string.find(brokerref, '/')
	if j ~= nil then
		--if we've got symbol "/"
		--if there is another slash after first - this is the comment
		if string.sub(brokerref, j+1, j+1)=='/' then
			comment = string.sub(brokerref, j+2)
		else
			--if we've got only one slash this is comment of broker
			--in that case we should discard it
		end
	end
	return comment
end

--возвращает таблицу остатков партий фифо, отсортированную по номеру сделки
--Параметры
-- client_code - in - string - код счета
-- sec_code - in - string - код бумаги
-- class_code - in - string - код класса
-- comment - in - string - чистый комментарий (без "/", получаем его функцией get_deal_comment() )
-- isShort - in - integer - 0/1 long/short
function FIFO:getRestsFIFO(client_code, sec_code, class_code, comment, isShort)

	local sql=
	[[
		SELECT
				  --измерения
				  dim_client_code
				 ,dim_depo_code
				, dim_sec_code
				, dim_class_code
				, dim_trade_num
				, dim_brokerref
				,
				   --ресурсы
				  SUM(res_qty)   AS qty
				, SUM(res_value) AS value
		FROM
				  fifo_long_3
		WHERE
				  dim_client_code 	= '&client_code'
				  AND dim_sec_code  = '&sec_code'
				  AND dim_class_code= '&class_code'
				  AND dim_brokerref = '&comment'
		GROUP BY
				  dim_client_code
				 ,dim_depo_code
				, dim_sec_code
				, dim_class_code
				, dim_trade_num
				, dim_brokerref
		HAVING    
				SUM(res_qty)       <> 0
				AND SUM(res_value) <> 0
		ORDER BY
				  dim_trade_num
	]]
	-- устанавливаем параметры в запрос
    sql = string.gsub (sql, '&sec_code', sec_code)
	sql = string.gsub (sql, '&class_code', class_code)
    sql = string.gsub (sql, '&client_code', client_code)
    sql = string.gsub (sql, '&comment', comment)
  
    --замена таблицы (лонг на шорт)
    if isShort == 1 or isShort == true then
      sql = string.gsub (sql, 'fifo_long_3', 'fifo_short_3')
    end
    
	local rests={}	--таблица остатков
	  
	local r_count = 1
	for row in self.db:nrows(sql) do 
	  
		rests[r_count] = {}
		rests[r_count]['dim_client_code'] = row.dim_client_code
		rests[r_count]['dim_depo_code'] = row.dim_depo_code
		rests[r_count]['dim_sec_code']    = row.dim_sec_code  
		rests[r_count]['dim_class_code']  = row.dim_class_code  
		rests[r_count]['dim_trade_num']   = row.dim_trade_num 
		rests[r_count]['dim_brokerref']   = row.dim_brokerref

		  --ресурсы
		rests[r_count]['qty']         	  = row.qty  
		rests[r_count]['value']       	  = row.value

		r_count = r_count + 1
	end

	return rests  
end


--определим направление сделки
function FIFO:what_is_the_direction(trade)
    if helper:bit_set(trade.flags, 2) then
      return 'sell'
    else
      return 'buy'
    end
end


--[[уменьшить короткую позицию
--]]
function FIFO:decrease_short(trade)

	local comment = self:get_deal_comment(trade.brokerref)
	
	local sec_code = substitute_sec_code(trade.sec_code)
	
    local restShort = self:getRestsFIFO(trade.client_code, sec_code, trade.class_code, comment, 1)
      
      --количество из сделки, на которое можно закрыть шорты
      
      local qty = trade.qty	--в лотах
      
      --счетчик цикла по остаткам из регистра
      local rest_count = 1
      
      local k="'"
      
      while rest_count <= table.maxn(restShort) and qty > 0 do
        
        --списываем количество, только если оно не нулевое
        if restShort[rest_count]['qty'] ~= 0 then
        
          --коэффициент списания для партии    
          local factor = 1
        
          --остатки в шортах отрицательные, поэтому умножаем на -1
          if -1*restShort[rest_count]['qty'] >= qty then 
            -- остаток партии больше, чем нам надо списать
            factor = qty / (-1*restShort[rest_count]['qty'])
          else
            factor = 1
          end
          
          --количество, на которое уменьшаем позицию шорт
          local qty_decreased = -1*restShort[rest_count]['qty'] * factor
          --стоимость, на которую уменьшаем позицию шорт
          local value_decreased = -1*restShort[rest_count]['value'] * factor
          
          --пишем приход в регистр шортов
          local sql='INSERT INTO fifo_short_3 '..
          '(dim_client_code, dim_depo_code, dim_sec_code, dim_class_code, dim_trade_num, dim_brokerref,'.. 
          'res_qty, res_value, '..
          'close_trade_num, close_date, close_time, close_price, close_qty, close_value, close_price_step, close_price_step_price'..
          ')'..
          ' VALUES('.. 
                  --измерения
                  k..restShort[rest_count]['dim_client_code']      ..k..','..
				  k..restShort[rest_count]['dim_depo_code']        ..k..','..
                  k..restShort[rest_count]['dim_sec_code']         ..k..','..  
                  k..restShort[rest_count]['dim_class_code']       ..k..','..  
                  restShort[rest_count]['dim_trade_num']           ..','..
                  k..restShort[rest_count]['dim_brokerref']        ..k..' ,'..
  
                  --ресурсы
                  qty_decreased                ..','..  
                  value_decreased              ..','..
  
                  --реквизиты - из сделки, которая закрывает позицию
                  
                  --'close_trade_num, close_date, close_time, close_price, close_qty, close_value, close_price_step, close_price_step_price
                  
                  trade.trade_num..','.. 
                  k..helper:get_trade_date_sql(trade)..k..','..
                  k..helper:get_trade_time(trade)..k..','..
                  trade.price..','..
                  qty_decreased..','.. -- это количество дублируется из ресурса
                  qty_decreased*trade.value/trade.qty..','.. --сумма закрывающей сделки, пропорционально количеству, которое пошло на закрытие
                  getParamEx (trade.class_code, trade.sec_code, 'SEC_PRICE_STEP').param_value..','..
                  getParamEx (trade.class_code, trade.sec_code, 'STEPPRICE').param_value..
                   
                  ');'          
          --message(sql)                     
           self.db:exec(sql)          
          
          -- подумать, нужно ли здесь еще ресурс "Выручка, пропорционально списанной партии" . этот показатель нужен для анализа результатов . может быть позже сделаю.
          
          qty  = qty - qty_decreased      
        end
          
        rest_count = rest_count + 1
        
      end 

  return qty
end

--[[открыть или увеличить длинную позицию
параметры
	db - in - соединение с базой
	trade - in - сделка
	qty - in - number - оставшееся после закрытия шортов количество из сделки, на которое нужно открыть лонг.
--]]
function FIFO:increase_long(trade, qty)

  local k="'"

  local mult = self:get_mult(trade.sec_code, trade.class_code)
  
  local sec_code = substitute_sec_code(trade.sec_code)
  
  local comment = self:get_deal_comment(trade.brokerref)
  
  --у брокера Открытие на Едином Счете возникает баг, связанный с тем, что это поле равно nil
  if trade.trans_id == nil then
    trans_id = ''
  else
    trans_id = trade.trans_id
  end

  local sql='INSERT INTO fifo_long_3 '..
  --перечислим поля, которые будем добавлять
  '(dim_client_code, dim_depo_code, dim_sec_code, dim_class_code, dim_trade_num,dim_brokerref,'..
  'res_qty, res_value,'..
  'attr_date, attr_time, attr_price, attr_trade_currency, attr_accruedint, attr_trans_id,'..
  'attr_order_num,attr_lot,attr_exchange_comission)'..

  ' VALUES('..
    
  --измерения
  k..trade.client_code      ..k..','..--  Код клиента
  k..trade.account      ..k..','..--  Код депо
  k..sec_code         ..k..','..--  Код бумаги заявки  
  k..trade.class_code       ..k..','..--  Код класса  
  trade.trade_num           ..','.. --  Номер сделки в торговой системе 
  k..comment 		        ..k..' ,'..--  Комментарий,'.. обычно: <код клиента>/<номер поручения>
  
  --ресурсы
  qty     ..','..  
  qty * trade.price * mult ..','..	
  
  --реквизиты  
  k..helper:get_trade_date_sql(trade)..k..','..--  Дата и время
  k..helper:get_trade_time(trade)..k..','..--  Дата и время
  trade.price               ..','.. --  Цена
  k..trade.trade_currency..k..','..--  Валюта
  trade.accruedint          ..','..--  Накопленный купонный доход
  k..trans_id..k      		..','..--  Идентификатор транзакции
  trade.order_num           ..','..--  Номер заявки в торговой системе  
  getParamEx (trade.class_code, sec_code, 'LOTSIZE').param_value  ..','..  
  trade.exchange_comission  ..--  Комиссия Фондовой биржи (ММВБ)  
  ');'          
                
  self.db:exec(sql)  
end

--[[уменьшить длинную позицию
--]]
function FIFO:decrease_long(trade)
  --алгоритм
  --получает таблицу остатков длинных позиций
  --определяет количество (из сделки), на которое можно закрыть длинные позиции
  --закрывает длинные позиции
  --возвращает количество бумаг из сделки, которое осталось после закрытия позиций
  --(если что-то осталось, то на это количество открывается шорт) 

  local comment = self:get_deal_comment(trade.brokerref)
  
  local sec_code = substitute_sec_code(trade.sec_code)
  
  --таблица остатков длинных позиций
  local restLong = self:getRestsFIFO(trade.client_code, sec_code, trade.class_code, comment, 0)
  
  --количество из сделки, на которое можно закрыть лонги
  --local qty = trade.qty * what_is_the_multiplier(trade.class_code, sec_code)
  local qty = trade.qty
  
  --счетчик цикла по остаткам из регистра
  local rest_count = 1
  
  local k="'"
  
  while rest_count <= table.maxn(restLong) and qty > 0 do
    
    --списываем количество, только если оно не нулевое
    if restLong[rest_count]['qty'] ~= 0 then
    
      --коэффициент списания для партии    
      local factor = 1
    
      if restLong[rest_count]['qty'] >= qty then 
        -- остаток партии больше, чем нам надо списать
        factor = qty / restLong[rest_count]['qty']
      else
        factor = 1
      end
      
      --гасим лонги
      
      local qty_decreased = restLong[rest_count]['qty'] * factor
      local value_decreased = restLong[rest_count]['value'] * factor
      --message(restLong[rest_count]['dim_brokerref'])
      --пишем расход в регистр лонгов
      --message(restLong[rest_count]['dim_brokerref'])
      
      local sql='INSERT INTO fifo_long_3 '..
      '(dim_client_code, dim_depo_code, dim_sec_code, dim_class_code, dim_trade_num, dim_brokerref,'.. 
      'res_qty, res_value, '..
      'close_trade_num, close_date, close_time, close_price, close_qty, close_value, close_price_step, close_price_step_price'..
      ')'..
      ' VALUES('.. 
              --измерения
              k..restLong[rest_count]['dim_client_code']      ..k..','..
			  k..restLong[rest_count]['dim_depo_code']      ..k..','..
              k..restLong[rest_count]['dim_sec_code']         ..k..','..  
              k..restLong[rest_count]['dim_class_code']       ..k..','..  
              restLong[rest_count]['dim_trade_num']           ..','..
              k..restLong[rest_count]['dim_brokerref']        ..k..','..

              --ресурсы
              -1*qty_decreased                ..','..  
              -1*value_decreased              ..','..

              --реквизиты - только сделка, которая закрывает
              
              --'close_trade_num, close_date, close_time, close_price, close_qty, close_value, close_price_step, close_price_step_price
              
              trade.trade_num..','.. 
              k..helper:get_trade_date_sql(trade)..k..','..
              k..helper:get_trade_time(trade)..k..','..
              trade.price..','..
              qty_decreased..','.. --необязателен, т.к. это количество дублируется из ресурса
              qty_decreased*trade.value/trade.qty..','..
			  
			  
              getParamEx (trade.class_code, sec_code, 'SEC_PRICE_STEP').param_value..','..
              getParamEx (trade.class_code, sec_code, 'STEPPRICE').param_value..
               
              ');'          
      --message(sql)                     
       self.db:exec(sql)            
      -- подумать, нужно ли здесь еще измерения "Выручка, пропорционально списанной партии"        
      
      qty  = qty - qty_decreased      
    end
      
    rest_count = rest_count + 1
    
  end 
  
  return qty
  
end

--[[открыть или увеличить короткую позицию
--]]
function FIFO:increase_short(trade, qty)

    local k="'"
    
	local mult = self:get_mult(trade.sec_code, trade.class_code)
	
	local sec_code = substitute_sec_code(trade.sec_code)
	
	local comment = self:get_deal_comment(trade.brokerref)
	
	--у брокера Открытие на Едином Счете возникает баг, связанный с тем, что это поле равно nil
	if trade.trans_id == nil then
		trans_id = ''
	else
		trans_id = trade.trans_id
	end
		
    local sql=
		'INSERT INTO fifo_short_3 '.. [[
			(	dim_client_code, 
				dim_depo_code,
				dim_sec_code,
				dim_class_code,
				dim_trade_num,
				dim_brokerref,
				res_qty,
				res_value,
				attr_date,
				attr_time,
				attr_price,
				attr_trade_currency,
				attr_accruedint,
				attr_trans_id,
				attr_order_num,
				attr_lot,
				attr_exchange_comission)
    
            VALUES
				(
				]] ..
				--измерения
				k..trade.client_code      	..k..','..--  Код клиента
				k..trade.account      		..k..','..--  Код депо
				k..sec_code         			..k..','..--  Код бумаги заявки  
				k..trade.class_code       	..k..','..--  Код класса  
				trade.trade_num           	..','.. 	  --  Номер сделки в торговой системе 
				k..comment		          		..k..','..--  Комментарий,'.. обычно: <код клиента>/<номер поручения>
            
				--ресурсы
				-1*qty                 ..','..--  Количество бумаг в последней сделке в лотах  
				-1 * qty * trade.price * mult   ..','..	
				
				--реквизиты  
				k..helper:get_trade_date_sql(trade)..k..','..--  Дата и время
				k..helper:get_trade_time(trade)..k..','..--  Дата и время
				trade.price               ..','.. 	--  Цена
				k..trade.trade_currency..k..','..	--  Валюта
				trade.accruedint          ..','..	--  Накопленный купонный доход
				k..trans_id..k      	  ..','..	--  Идентификатор транзакции
				trade.order_num           ..','..	--  Номер заявки в торговой системе  
				getParamEx (trade.class_code, sec_code, 'LOTSIZE').param_value ..','..  
				trade.exchange_comission  ..		--  Комиссия Фондовой биржи (ММВБ)  
            ');'          
                       
     self.db:exec(sql)  
        
  
end

--[[заменить код бумаги
это требуется, например, на валютном рынке, когда позиция у нас в этом скрипте ведется в TOM, а продаем/покупаем мы TOD.
лучше все приводить к TOM, потому что там ликвидность выше
--]]
function substitute_sec_code(sec_code)
	if sec_code == 'USD000000TOD' then
		return 'USD000UTSTOM'
	elseif sec_code == 'EUR_RUB__TOD' then
		return 'EUR_RUB__TOM'
	else
		return sec_code
	end
end
--проводит сделку по ФИФО
--Parameters:
--	db - in - sqlite db connection - подключение к базе sqlite
--  trade - in - lua table - таблица с реквизитами сделки из события OnTrade()
function FIFO:makeFifo(trade)

    --определим направление сделки
  local direction = self:what_is_the_direction(trade) 

	local comment = self:get_deal_comment(trade.brokerref)

  if direction == 'buy' then
  
    --buy. decrease short
    local qty = self:decrease_short(trade)    
    
    --buy. increase long
    if qty > 0 then
      self:increase_long(trade, qty)
    end
    
  elseif direction == 'sell' then
  
    --sell. decrease long
    local qty = self:decrease_long(trade)     
    
    --sell. increase short
    if qty > 0 then
      self:increase_short(trade, qty)
    end
    
  end
    
end

--  ОТОБРАЖЕНИЕ ДАННЫХ ИЗ ФИФО В ТАБЛИЦУ РОБОТА

--получает все открытые позиции из таблиц бд sqlite и возвращает таблицу Lua,
--из которой потом позиции переносятся в главную таблицу робота
--Parameters:
--	
--  totals_t - simple lua table from TradeHistory_table class. it is needed to keep total PnL and Collateral by account and class_code
function FIFO:readOpenFifoPositions_ver2(sec_code, class_code, account, isDetails, totals_t)

  --алгоритм
  --выбрать незакрытые позиции, сгруппированные в том числе по номеру сделки, чтобы получить дату и время сделки
  --(это в самом глубоком подзапросе)
  --из полученного подзапроса выбрать агрегаты суммы и количества и минимальные значения даты и времени
  --(это для отображения минимальной даты сделки, которая открыла позицию)
  --(запрос второго уровня)
  --выбрать из получившегося запроса все его поля, плюс добавить таблицу бумаг для получения лота и даты экспирации
  --(лот нужен больше для информации, причем для спота)  
  --(дата экспирации нужна для сортировки) 

	local  sql = 
	[[
		SELECT
		subq.operation AS operation
		
		--измерения
		, subq.dim_client_code AS dim_client_code
		, subq.dim_depo_code AS dim_depo_code
		, subq.dim_sec_code    AS dim_sec_code
		, subq.dim_class_code  AS dim_class_code
		, subq.dim_brokerref   AS dim_brokerref
	]]

	if isDetails then							
		sql = sql .. ', subq.dim_trade_num AS dim_trade_num'
	end
	
	sql = sql .. [[  		
		, subq.dateOpen        AS dateOpen
		, subq.timeOpen        AS timeOpen
		--ресурсы
		, subq.qty   AS qty
		, subq.value AS value
		, subq.price AS price
		, subq.commiss AS commiss
		--other
		,subq.lot AS lot --info. has the meaning only for spot
		FROM
		(
	]] ..

	self:QueryTextOpenFifoPositions_ver3(sec_code, class_code, account, isDetails, false) .. 
	' UNION ALL ' .. 
	self:QueryTextOpenFifoPositions_ver3(sec_code, class_code, account, isDetails, true) ..
	' ) AS subq ' ..

	[[ 
		ORDER BY       
    subq.dim_client_code,
    subq.dim_class_code,
    subq.mat_date,
    subq.dim_sec_code,  
    subq.dateOpen,
		subq.timeOpen,
		subq.dim_brokerref 
	]]

	if isDetails then							
		sql = sql .. ', subq.dim_trade_num'
	end

	--helper:save_sql_to_file(sql, 'open_pos.sql')

  --this function returns simple lua table
	local vt = {}

    local collateral = 0

	local r_count = 1
	for row in self.db:nrows(sql) do 

		vt[r_count] = {}

		vt[r_count]['operation']=row.operation
		--dimensions
		vt[r_count]['dim_client_code']=row.dim_client_code
		vt[r_count]['dim_depo_code']=row.dim_depo_code
		vt[r_count]['dim_sec_code']  =row.dim_sec_code
		vt[r_count]['dim_class_code']=row.dim_class_code  
		vt[r_count]['dim_brokerref']=row.dim_brokerref

		if isDetails then							
			vt[r_count]['dim_trade_num']=row.dim_trade_num
		end	  

		--resources
		vt[r_count]['qty'] = row.qty  
		vt[r_count]['value'] = row.value
		vt[r_count]['commiss'] = row.commiss

		--attributes
		if vt[r_count]['dim_class_code']=='SPBFUT' or vt[r_count]['dim_class_code']=='SPBOPT' 
			or vt[r_count]['dim_class_code']=='CETS' 
			then
			vt[r_count]['price']=math.ceil(row.price*10000)/10000
		else
			vt[r_count]['price']=math.ceil(row.price*100)/100
		end

		vt[r_count]['dateOpen']=row.dateOpen
		vt[r_count]['timeOpen']=row.timeOpen
		vt[r_count]['lot'] = row.lot      

		r_count = r_count + 1
	end      

	--message('rows in closed pos '..tostring(#vt))
	--message(vt[1]['dim_trade_num'])
	return vt 

end

--возвращает текст запроса по регистру Long или Short в зависимости от параметров
function FIFO:QueryTextOpenFifoPositions_ver3(sec_code, class_code, account, isDetails, isShort)

  --алгоритм
  --выбрать незакрытые позиции, сгруппированные в том числе по номеру сделки, чтобы получить дату и время сделки
  --(это в самом глубоком подзапросе)
  --из полученного подзапроса выбрать агрегаты суммы и количества и минимальные значения даты и времени
  --(это для отображения минимальной даты сделки, которая открыла позицию)
  --(запрос второго уровня)
  --выбрать из получившегося запроса все его поля, плюс добавить таблицу бумаг для получения лота
  --(лот нужен больше для информации, причем для спота)  
	local k = "'"

	local operation = ''
	if isShort == 1 or isShort == true then
		operation = 'sell'
	else
		operation = 'buy'
	end

	local  sql = ' SELECT ' ..k.. operation ..k.. ' AS operation ' .. [[
        
           --измерения
        , q1.dim_client_code AS dim_client_code
		    , q1.dim_depo_code AS dim_depo_code
		  
        , q1.dim_sec_code    AS dim_sec_code
        , q1.dim_class_code  AS dim_class_code
        , q1.dim_brokerref   AS dim_brokerref
	]]
		
	if isDetails then							
		sql = sql .. ', q1.dim_trade_num AS dim_trade_num'

	end
	sql = sql .. [[		
        , q1.attr_date       AS dateOpen
        , q1.attr_time       AS timeOpen
        
           --ресурсы
        , q1.qty   AS qty
        , q1.value AS value
		    , q1.commiss AS commiss
        , coalesce(q1.price, 0) AS price
         --average price of position
          --other
        , securities.lotsize AS lot --info. has the meaning only for spot
        , securities.mat_date AS mat_date
        FROM
          (
                    SELECT
                              --измерения
                              dim_client_code
							, dim_depo_code
                            , dim_sec_code
                            , dim_class_code
                            , dim_brokerref
		]]
	if isDetails then							
		sql = sql .. ', dim_trade_num'

	end							
    sql = sql .. [[
                               --ресурсы
                            , SUM(qty)            AS qty
                            , SUM(value)          AS value
							, SUM(commiss)          AS commiss
                            
                            , SUM(value)/SUM(qty)/coalesce(sec.mult, lot) AS price
                            
                            , MIN(attr_date)      AS attr_date
                            , MIN(attr_time)      AS attr_time
                    FROM
                              (
                                        SELECT
                                                  --измерения
                                                  dim_client_code
												  ,dim_depo_code
                                                , dim_sec_code
                                                , dim_class_code
                                                , dim_brokerref
                                                , dim_trade_num
                                                
                                                   --ресурсы
                                                , &sign * SUM(res_qty)             AS qty
                                                , &sign * SUM(res_value)           AS value
												, SUM(attr_exchange_comission)     AS commiss
												--bugfix. если в эти поля запишем не null, а например ноль, или пустую строку,
												--то потом получаем не совсем то, что надо.
												--если будет пустая строка в дате/времени, то в таблице робота в этих полях 
												--увидим именно пустую строку
												--а если в цене будет 0, то средняя посчитается с учетом этого нуля и будет в разы меньше, чем надо
												
                                                , MIN(case when attr_date='' then NULL else attr_date end)  AS attr_date
                                                , MIN(case when attr_time='' then NULL else attr_time end)  AS attr_time
												, MAX(attr_lot) as lot
                                        FROM
                                                  fifo_long_3
										WHERE
                                                1=1
												&dim_client_code
                                                &dim_sec_code
                                                &dim_class_code
												
                                        GROUP BY
                                                  dim_client_code
												, dim_depo_code
                                                , dim_sec_code
                                                , dim_class_code
                                                , dim_brokerref
                                                , dim_trade_num
                                        HAVING    
												SUM(res_qty)       <> 0
                                                AND SUM(res_value) <> 0 ) AS q0

									left join securities sec on sec.sec_code = substr(q0.dim_sec_code,1,2)
										and sec.class_code = q0.dim_class_code
																	
                    GROUP BY
                              dim_client_code
							              , dim_depo_code
                            , dim_sec_code
                            , dim_class_code
                            , dim_brokerref ]]

  if isDetails then							
  	sql = sql .. ', dim_trade_num'

  end
	  sql = sql .. [[ ) AS q1
          LEFT JOIN
                    securities
          ON
                    securities.sec_code       = q1.dim_sec_code
                    AND securities.class_code = q1.dim_class_code

  ]]
  
  --set up the parameters
	if sec_code ~= nil then
		sql = string.gsub(sql, '&dim_sec_code', 'AND dim_sec_code = '..k..sec_code..k..'')
	else
		sql = string.gsub(sql, '&dim_sec_code', '')
	end  
	
	if 	class_code ~= nil then
		sql = string.gsub(sql, '&dim_class_code', 'AND dim_class_code = '..k..class_code..k..'')
	else
		sql = string.gsub(sql, '&dim_class_code', '')
	end  

	if account ~= nil then
		sql = string.gsub(sql, '&dim_client_code', 'AND dim_client_code = '..k..account..k..'')
	else
		sql = string.gsub(sql, '&dim_client_code', '')
	end  
	

    --замена таблицы (лонг на шорт)
	if isShort == 1 or isShort == true then
		sql = string.gsub (sql, 'fifo_long_3', 'fifo_short_3')
		sql = string.gsub (sql, '&sign', '-1')
	else
		sql = string.gsub (sql, '&sign', '1')
	end

  return sql

end




--not ready!!! в проекте - сделать вывод арифметической суммы синтетической позиции, например
--для нефти в рублях (buy Si, buy BR) 
--для синт облигации (buy USD, sell Si)
function FIFO:QueryTextOpenFifoPositions_Synthetic()

  -- синтетическая позиция выводится как 2 отдельные + строка totals
  --различаются такие позиции по комментарию, т.е.
  --если коммент есть и в нем указан префикс "syn_", то это синтетика.
  --Синтетика может состоять из любого количества бумаг и любых позиций,
  --т.е. long+short по разным бумагам вполне допустимы, поэтому собирать
  --ее будем из обоих регистров (long + short) сразу.
  
  local  sql = [[
      SELECT 
		'buy' as operation,
        --измерения
        q1.dim_client_code  as dim_client_code,
		q1.dim_depo_code as dim_depo_code,
        q1.dim_sec_code     as dim_sec_code,  
        q1.dim_class_code   as dim_class_code,  
        q1.dim_brokerref    as dim_brokerref,
        q1.attr_date        as dateOpen,
        q1.attr_time        as timeOpen,
          
        --ресурсы
        q1.qty              as qty,  
        q1.value            as value,
        q1.price            as price, --average price of position
          
        --other
        securities.lotsize  as lot    --info. has the meaning only for spot
        
      FROM
        (
        SELECT 
          
         --измерения
          dim_client_code,
		  dim_depo_code,
          dim_sec_code,  
          dim_class_code,  
          dim_brokerref,
          
          --ресурсы
          SUM(qty) AS qty,  
          SUM(value) AS value,
          AVG(attr_price) AS price,
          
          MIN(attr_date) as attr_date, 
          MIN(attr_time) as attr_time
                     
        FROM
        
        (
          SELECT 
          
            --измерения
            dim_client_code,
			dim_depo_code,
            dim_sec_code,  
            dim_class_code,  
            dim_brokerref,
            dim_trade_num,
          
            --ресурсы
            
            SUM(res_qty) AS qty,  
            SUM(res_value) AS value,
            AVG(attr_price) AS price,
          
            MIN(attr_date) as attr_date, 
            MIN(attr_time) as attr_time           
          
          FROM
              fifo_long_3  
          GROUP BY
            dim_client_code,
			dim_depo_code,
            dim_sec_code,  
            dim_class_code,  
            dim_brokerref,
            dim_trade_num
       
          HAVING 
            SUM(res_qty) <> 0  
            AND SUM(res_value) <> 0
          
          ORDER BY
            dim_client_code,
            dim_sec_code,  
            dim_class_code,  
            dim_brokerref
             
          ) as q0
    
         GROUP BY
          dim_client_code,
		  dim_depo_code,
          dim_sec_code,  
          dim_class_code,  
          dim_brokerref
          
        ) as q1
    
     
        left join securities
        ON securities.sec_code    = q1.dim_sec_code
        AND securities.class_code = q1.dim_class_code

        ]]
  
  
    return sql
     
end

--получает все закрытые позиции из таблиц бд sqlite и возвращает таблицу Lua,
--из которой потом позиции переносятся в главную таблицу робота
--Parameters:
--	db - in - sqlite db connection - подключение к базе sqlite
function FIFO:readClosedFifoPositions()

   local sql = 
  [[
    SELECT
          subq.operation AS operation
        ,
           --измерения
          subq.dim_client_code AS dim_client_code
		, subq.dim_depo_code AS dim_depo_code
        , subq.dim_sec_code    AS dim_sec_code
        , subq.dim_class_code  AS dim_class_code
        , subq.dim_brokerref   AS dim_brokerref
        , subq.dim_trade_num   AS dim_trade_num
        ,
           --ресурсы
          subq.quantity AS quantity
        , subq.qtyClose AS qtyClose
        , subq.value    AS value
        ,
           --реквизиты
          subq.price                  AS price
        , subq.dateOpen               AS dateOpen
        , subq.timeOpen               AS timeOpen
        , subq.close_trade_num        AS close_trade_num
        , subq.close_date             AS close_date
        , subq.close_time             AS close_time
        , subq.close_price            AS close_price
        , subq.close_qty              AS close_qty
        , subq.close_value            AS close_value
        , subq.close_price_step       AS close_price_step
        , subq.close_price_step_price AS close_price_step_price
        , subq.lot                    AS lot
  FROM
          (
  ]] ..
	     
		 	self:QueryTextClosedFifoPositionsLong() .. ' UNION ALL ' .. self:QueryTextClosedFifoPositionsShort() .. ' ) AS subq ' .. 
		 
  [[
    ORDER BY
        subq.close_date,
        subq.close_time,
        subq.dim_trade_num,
        subq.dim_client_code,
        subq.dim_sec_code,  
        subq.dim_class_code,  
        subq.dim_brokerref
  ]]
  
    
	--helper:save_sql_to_file(sql, 'closed_pos.sql')
	
   local vt = {}
      
   local r_count = 1
   for row in self.db:nrows(sql) do 
      
      --message(tostring(r_count))
      vt[r_count] = {}

      vt[r_count]['operation']=row.operation
      --измерения
      vt[r_count]['dim_client_code']=row.dim_client_code
	  vt[r_count]['dim_depo_code']=row.dim_depo_code
      vt[r_count]['dim_sec_code']  =row.dim_sec_code
      vt[r_count]['dim_class_code']=row.dim_class_code  
      vt[r_count]['dim_brokerref']=row.dim_brokerref
      vt[r_count]['dim_trade_num']=row.dim_trade_num
      
      --ресурсы
      vt[r_count]['quantity'] = row.quantity
      vt[r_count]['qtyClose'] = row.qtyClose  
      vt[r_count]['value'] = row.value
      
      --реквизиты
      vt[r_count]['price']= math.ceil(row.price*1000)/1000
      vt[r_count]['dateOpen']=row.dateOpen
      vt[r_count]['timeOpen']=row.timeOpen
      
      vt[r_count]['close_trade_num']=row.close_trade_num
      vt[r_count]['close_date']=row.close_date
      vt[r_count]['close_time']=row.close_time
      vt[r_count]['close_price']=row.close_price
      vt[r_count]['close_qty']=row.close_qty
      vt[r_count]['close_value']=row.close_value
      vt[r_count]['close_price_step']=row.close_price_step
      vt[r_count]['close_price_step_price']=row.close_price_step_price          
      
      vt[r_count]['lot'] = row.lot      
      
      
      r_count = r_count + 1
   end      
   
      --message('rows in closed pos '..tostring(#vt))
      --message(vt[1]['dim_trade_num'])
   return vt  
  
end

--возвращает текст запроса по регистру Long
function FIFO:QueryTextClosedFifoPositionsLong()

  local sql = 
  [[
    SELECT
          'buy' AS operation
           --измерения
        , ClosedPos.dim_client_code AS dim_client_code
		, ClosedPos.dim_depo_code AS dim_depo_code
        , ClosedPos.dim_sec_code AS dim_sec_code
        , ClosedPos.dim_class_code AS dim_class_code
        , ClosedPos.dim_brokerref AS dim_brokerref
        , OpenPos.dim_trade_num AS dim_trade_num
        
           --ресурсы
        , OpenPos.res_qty        AS quantity
        , -1*ClosedPos.res_qty   AS qtyClose
        , -1*ClosedPos.res_value AS value
        
           --реквизиты
        , OpenPos.attr_price AS price
        , OpenPos.attr_date  AS dateOpen
        , OpenPos.attr_time  AS timeOpen
        , ClosedPos.close_trade_num AS close_trade_num
        , ClosedPos.close_date AS close_date
        , ClosedPos.close_time AS close_time
        , ClosedPos.close_price AS close_price
        , ClosedPos.close_qty AS close_qty
        , ClosedPos.close_value AS close_value
        , ClosedPos.close_price_step AS close_price_step
        , ClosedPos.close_price_step_price AS close_price_step_price
        , securities.lotsize AS lot
  FROM
          fifo_long_3 AS ClosedPos
			
			LEFT JOIN fifo_long_3 AS OpenPos
				ON	
					OpenPos.dim_trade_num = ClosedPos.dim_trade_num
					AND OpenPos.res_qty   > 0
			LEFT JOIN securities
				ON
                    securities.sec_code       = ClosedPos.dim_sec_code
                    AND securities.class_code = ClosedPos.dim_class_code
  WHERE
          ClosedPos.res_qty < 0
  ]]

   
	return sql  
	
end

--возвращает текст запроса по регистру Short
function FIFO:QueryTextClosedFifoPositionsShort()

    local sql = 
  [[
    SELECT
          'sell' AS operation
        ,
           --измерения
          ClosedPos.dim_client_code AS dim_client_code
		  ,ClosedPos.dim_depo_code AS dim_depo_code
        , ClosedPos.dim_sec_code AS dim_sec_code
        , ClosedPos.dim_class_code AS dim_class_code
        , ClosedPos.dim_brokerref AS dim_brokerref
        , OpenPos.dim_trade_num AS dim_trade_num
        ,
           --ресурсы
          -1*OpenPos.res_qty  AS quantity
        , ClosedPos.res_qty   AS qtyClose
        , ClosedPos.res_value AS value
        ,
           --реквизиты
          OpenPos.attr_price AS price
        , OpenPos.attr_date  AS dateOpen
        , OpenPos.attr_time  AS timeOpen
        , ClosedPos.close_trade_num AS close_trade_num
        , ClosedPos.close_date AS close_date
        , ClosedPos.close_time AS close_time
        , ClosedPos.close_price AS close_price
        , ClosedPos.close_qty AS close_qty
        , ClosedPos.close_value AS close_value
        , ClosedPos.close_price_step AS close_price_step
        , ClosedPos.close_price_step_price AS close_price_step_price
        , securities.lotsize AS lot
    FROM
          fifo_short_3 AS ClosedPos
          LEFT JOIN
                    fifo_short_3 AS OpenPos
          ON
                    OpenPos.dim_trade_num = ClosedPos.dim_trade_num
                    AND OpenPos.res_qty   < 0
          LEFT JOIN
                    securities
          ON
                    securities.sec_code       = ClosedPos.dim_sec_code
                    AND securities.class_code = ClosedPos.dim_class_code
    WHERE
          ClosedPos.res_qty > 0
          
        ]]  

     return sql
  
end



 
 
--добавить информацию о бумаге в таблицу securities
function FIFO:saveSecurityInfo(sec_code, class_code)

    local k = "'"
    local sql='SELECT sec_code FROM securities WHERE sec_code = '..k..sec_code..k..' AND class_code = '..k..class_code..k
  
    --at first let's try to find this security in table
    local found = false      
    for row in self.db:nrows(sql) do 
      found = true
      break
    end
   
    if not found then   
    
		local sql='INSERT INTO securities VALUES('..
           
        k..sec_code..k..','..  
        k..class_code..k..','..
        k..getParamEx (class_code, sec_code, 'shortname').param_image..k..','..
        k..getParamEx (class_code, sec_code, 'longname').param_image..k..','..
        k..getParamEx (class_code, sec_code, 'mat_date').param_image..k..','..
        getParamEx (class_code, sec_code, 'sec_face_value').param_value..','..
        k..getParamEx (class_code, sec_code, 'sec_face_unit').param_image..k..','..
        getParamEx (class_code, sec_code, 'lotsize').param_value..','..
        k..getParamEx (class_code, sec_code, 'sectype').param_image..k..','..  
        getParamEx (class_code, sec_code, 'sec_price_step').param_value..','..
        getParamEx (class_code, sec_code, 'lotsize').param_value..					--мультипликатор. для фортс бумаги уже в таблице. если добавляется новая, то mult пусть будет равен лоту (из функции получения mult все равно возвращается лот, если бумаги нет в таблице)
        ');'
              
        self.db:exec(sql)
    end
  
end

--получает мультипликатор для фортс. для остальных классов - это размер лота
--для фортс он уже прописан в таблице securities
function FIFO:get_mult(sec_code, class_code)

	local mult = 1
	if class_code ~= 'SPBFUT' and class_code ~= 'SPBOPT' then
		mult = getParamEx (class_code, sec_code, 'lotsize').param_value
		--message(sec_code)
		--message(mult)
		if mult == nil then
			return 1
		end
		return mult
	end
	
	local k = "'"
	
	local sc = string.sub(sec_code,1,2)
	
	local sql='SELECT mult FROM securities WHERE sec_code ='..k..sc..k..' AND class_code = '..k..class_code..k
	for row in self.db:nrows(sql) do 
		mult = row.mult
		if mult == nil then
			return 1
		end
		return mult
	end
	return 1
end


