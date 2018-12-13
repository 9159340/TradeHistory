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

--���������� ������� �������� ������ ����, ��������������� �� ������ ������
--���������
-- client_code - in - string - ��� �����
-- sec_code - in - string - ��� ������
-- class_code - in - string - ��� ������
-- comment - in - string - ������ ����������� (��� "/", �������� ��� �������� get_deal_comment() )
-- isShort - in - integer - 0/1 long/short
function FIFO:getRestsFIFO(client_code, sec_code, class_code, comment, isShort)

	local sql=
	[[
		SELECT
				  --���������
				  dim_client_code
				 ,dim_depo_code
				, dim_sec_code
				, dim_class_code
				, dim_trade_num
				, dim_brokerref
				,
				   --�������
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
	-- ������������� ��������� � ������
    sql = string.gsub (sql, '&sec_code', sec_code)
	sql = string.gsub (sql, '&class_code', class_code)
    sql = string.gsub (sql, '&client_code', client_code)
    sql = string.gsub (sql, '&comment', comment)
  
    --������ ������� (���� �� ����)
    if isShort == 1 or isShort == true then
      sql = string.gsub (sql, 'fifo_long_3', 'fifo_short_3')
    end
    
	local rests={}	--������� ��������
	  
	local r_count = 1
	for row in self.db:nrows(sql) do 
	  
		rests[r_count] = {}
		rests[r_count]['dim_client_code'] = row.dim_client_code
		rests[r_count]['dim_depo_code'] = row.dim_depo_code
		rests[r_count]['dim_sec_code']    = row.dim_sec_code  
		rests[r_count]['dim_class_code']  = row.dim_class_code  
		rests[r_count]['dim_trade_num']   = row.dim_trade_num 
		rests[r_count]['dim_brokerref']   = row.dim_brokerref

		  --�������
		rests[r_count]['qty']         	  = row.qty  
		rests[r_count]['value']       	  = row.value

		r_count = r_count + 1
	end

	return rests  
end


--��������� ����������� ������
function FIFO:what_is_the_direction(trade)
    if helper:bit_set(trade.flags, 2) then
      return 'sell'
    else
      return 'buy'
    end
end


--[[��������� �������� �������
--]]
function FIFO:decrease_short(trade)

	local comment = self:get_deal_comment(trade.brokerref)
	
	local sec_code = substitute_sec_code(trade.sec_code)
	
    local restShort = self:getRestsFIFO(trade.client_code, sec_code, trade.class_code, comment, 1)
      
      --���������� �� ������, �� ������� ����� ������� �����
      
      local qty = trade.qty	--� �����
      
      --������� ����� �� �������� �� ��������
      local rest_count = 1
      
      local k="'"
      
      while rest_count <= table.maxn(restShort) and qty > 0 do
        
        --��������� ����������, ������ ���� ��� �� �������
        if restShort[rest_count]['qty'] ~= 0 then
        
          --����������� �������� ��� ������    
          local factor = 1
        
          --������� � ������ �������������, ������� �������� �� -1
          if -1*restShort[rest_count]['qty'] >= qty then 
            -- ������� ������ ������, ��� ��� ���� �������
            factor = qty / (-1*restShort[rest_count]['qty'])
          else
            factor = 1
          end
          
          --����������, �� ������� ��������� ������� ����
          local qty_decreased = -1*restShort[rest_count]['qty'] * factor
          --���������, �� ������� ��������� ������� ����
          local value_decreased = -1*restShort[rest_count]['value'] * factor
          
          --����� ������ � ������� ������
          local sql='INSERT INTO fifo_short_3 '..
          '(dim_client_code, dim_depo_code, dim_sec_code, dim_class_code, dim_trade_num, dim_brokerref,'.. 
          'res_qty, res_value, '..
          'close_trade_num, close_date, close_time, close_price, close_qty, close_value, close_price_step, close_price_step_price'..
          ')'..
          ' VALUES('.. 
                  --���������
                  k..restShort[rest_count]['dim_client_code']      ..k..','..
				  k..restShort[rest_count]['dim_depo_code']        ..k..','..
                  k..restShort[rest_count]['dim_sec_code']         ..k..','..  
                  k..restShort[rest_count]['dim_class_code']       ..k..','..  
                  restShort[rest_count]['dim_trade_num']           ..','..
                  k..restShort[rest_count]['dim_brokerref']        ..k..' ,'..
  
                  --�������
                  qty_decreased                ..','..  
                  value_decreased              ..','..
  
                  --��������� - �� ������, ������� ��������� �������
                  
                  --'close_trade_num, close_date, close_time, close_price, close_qty, close_value, close_price_step, close_price_step_price
                  
                  trade.trade_num..','.. 
                  k..helper:get_trade_date_sql(trade)..k..','..
                  k..helper:get_trade_time(trade)..k..','..
                  trade.price..','..
                  qty_decreased..','.. -- ��� ���������� ����������� �� �������
                  qty_decreased*trade.value/trade.qty..','.. --����� ����������� ������, ��������������� ����������, ������� ����� �� ��������
                  getParamEx (trade.class_code, trade.sec_code, 'SEC_PRICE_STEP').param_value..','..
                  getParamEx (trade.class_code, trade.sec_code, 'STEPPRICE').param_value..
                   
                  ');'          
          --message(sql)                     
           self.db:exec(sql)          
          
          -- ��������, ����� �� ����� ��� ������ "�������, ��������������� ��������� ������" . ���� ���������� ����� ��� ������� ����������� . ����� ���� ����� ������.
          
          qty  = qty - qty_decreased      
        end
          
        rest_count = rest_count + 1
        
      end 

  return qty
end

--[[������� ��� ��������� ������� �������
���������
	db - in - ���������� � �����
	trade - in - ������
	qty - in - number - ���������� ����� �������� ������ ���������� �� ������, �� ������� ����� ������� ����.
--]]
function FIFO:increase_long(trade, qty)

  local k="'"

  local mult = self:get_mult(trade.sec_code, trade.class_code)
  
  local sec_code = substitute_sec_code(trade.sec_code)
  
  local comment = self:get_deal_comment(trade.brokerref)
  
  --� ������� �������� �� ������ ����� ��������� ���, ��������� � ���, ��� ��� ���� ����� nil
  if trade.trans_id == nil then
    trans_id = ''
  else
    trans_id = trade.trans_id
  end

  local sql='INSERT INTO fifo_long_3 '..
  --���������� ����, ������� ����� ���������
  '(dim_client_code, dim_depo_code, dim_sec_code, dim_class_code, dim_trade_num,dim_brokerref,'..
  'res_qty, res_value,'..
  'attr_date, attr_time, attr_price, attr_trade_currency, attr_accruedint, attr_trans_id,'..
  'attr_order_num,attr_lot,attr_exchange_comission)'..

  ' VALUES('..
    
  --���������
  k..trade.client_code      ..k..','..--  ��� �������
  k..trade.account      ..k..','..--  ��� ����
  k..sec_code         ..k..','..--  ��� ������ ������  
  k..trade.class_code       ..k..','..--  ��� ������  
  trade.trade_num           ..','.. --  ����� ������ � �������� ������� 
  k..comment 		        ..k..' ,'..--  �����������,'.. ������: <��� �������>/<����� ���������>
  
  --�������
  qty     ..','..  
  qty * trade.price * mult ..','..	
  
  --���������  
  k..helper:get_trade_date_sql(trade)..k..','..--  ���� � �����
  k..helper:get_trade_time(trade)..k..','..--  ���� � �����
  trade.price               ..','.. --  ����
  k..trade.trade_currency..k..','..--  ������
  trade.accruedint          ..','..--  ����������� �������� �����
  k..trans_id..k      		..','..--  ������������� ����������
  trade.order_num           ..','..--  ����� ������ � �������� �������  
  getParamEx (trade.class_code, sec_code, 'LOTSIZE').param_value  ..','..  
  trade.exchange_comission  ..--  �������� �������� ����� (����)  
  ');'          
                
  self.db:exec(sql)  
end

--[[��������� ������� �������
--]]
function FIFO:decrease_long(trade)
  --��������
  --�������� ������� �������� ������� �������
  --���������� ���������� (�� ������), �� ������� ����� ������� ������� �������
  --��������� ������� �������
  --���������� ���������� ����� �� ������, ������� �������� ����� �������� �������
  --(���� ���-�� ��������, �� �� ��� ���������� ����������� ����) 

  local comment = self:get_deal_comment(trade.brokerref)
  
  local sec_code = substitute_sec_code(trade.sec_code)
  
  --������� �������� ������� �������
  local restLong = self:getRestsFIFO(trade.client_code, sec_code, trade.class_code, comment, 0)
  
  --���������� �� ������, �� ������� ����� ������� �����
  --local qty = trade.qty * what_is_the_multiplier(trade.class_code, sec_code)
  local qty = trade.qty
  
  --������� ����� �� �������� �� ��������
  local rest_count = 1
  
  local k="'"
  
  while rest_count <= table.maxn(restLong) and qty > 0 do
    
    --��������� ����������, ������ ���� ��� �� �������
    if restLong[rest_count]['qty'] ~= 0 then
    
      --����������� �������� ��� ������    
      local factor = 1
    
      if restLong[rest_count]['qty'] >= qty then 
        -- ������� ������ ������, ��� ��� ���� �������
        factor = qty / restLong[rest_count]['qty']
      else
        factor = 1
      end
      
      --����� �����
      
      local qty_decreased = restLong[rest_count]['qty'] * factor
      local value_decreased = restLong[rest_count]['value'] * factor
      --message(restLong[rest_count]['dim_brokerref'])
      --����� ������ � ������� ������
      --message(restLong[rest_count]['dim_brokerref'])
      
      local sql='INSERT INTO fifo_long_3 '..
      '(dim_client_code, dim_depo_code, dim_sec_code, dim_class_code, dim_trade_num, dim_brokerref,'.. 
      'res_qty, res_value, '..
      'close_trade_num, close_date, close_time, close_price, close_qty, close_value, close_price_step, close_price_step_price'..
      ')'..
      ' VALUES('.. 
              --���������
              k..restLong[rest_count]['dim_client_code']      ..k..','..
			  k..restLong[rest_count]['dim_depo_code']      ..k..','..
              k..restLong[rest_count]['dim_sec_code']         ..k..','..  
              k..restLong[rest_count]['dim_class_code']       ..k..','..  
              restLong[rest_count]['dim_trade_num']           ..','..
              k..restLong[rest_count]['dim_brokerref']        ..k..','..

              --�������
              -1*qty_decreased                ..','..  
              -1*value_decreased              ..','..

              --��������� - ������ ������, ������� ���������
              
              --'close_trade_num, close_date, close_time, close_price, close_qty, close_value, close_price_step, close_price_step_price
              
              trade.trade_num..','.. 
              k..helper:get_trade_date_sql(trade)..k..','..
              k..helper:get_trade_time(trade)..k..','..
              trade.price..','..
              qty_decreased..','.. --������������, �.�. ��� ���������� ����������� �� �������
              qty_decreased*trade.value/trade.qty..','..
			  
			  
              getParamEx (trade.class_code, sec_code, 'SEC_PRICE_STEP').param_value..','..
              getParamEx (trade.class_code, sec_code, 'STEPPRICE').param_value..
               
              ');'          
      --message(sql)                     
       self.db:exec(sql)            
      -- ��������, ����� �� ����� ��� ��������� "�������, ��������������� ��������� ������"        
      
      qty  = qty - qty_decreased      
    end
      
    rest_count = rest_count + 1
    
  end 
  
  return qty
  
end

--[[������� ��� ��������� �������� �������
--]]
function FIFO:increase_short(trade, qty)

    local k="'"
    
	local mult = self:get_mult(trade.sec_code, trade.class_code)
	
	local sec_code = substitute_sec_code(trade.sec_code)
	
	local comment = self:get_deal_comment(trade.brokerref)
	
	--� ������� �������� �� ������ ����� ��������� ���, ��������� � ���, ��� ��� ���� ����� nil
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
				--���������
				k..trade.client_code      	..k..','..--  ��� �������
				k..trade.account      		..k..','..--  ��� ����
				k..sec_code         			..k..','..--  ��� ������ ������  
				k..trade.class_code       	..k..','..--  ��� ������  
				trade.trade_num           	..','.. 	  --  ����� ������ � �������� ������� 
				k..comment		          		..k..','..--  �����������,'.. ������: <��� �������>/<����� ���������>
            
				--�������
				-1*qty                 ..','..--  ���������� ����� � ��������� ������ � �����  
				-1 * qty * trade.price * mult   ..','..	
				
				--���������  
				k..helper:get_trade_date_sql(trade)..k..','..--  ���� � �����
				k..helper:get_trade_time(trade)..k..','..--  ���� � �����
				trade.price               ..','.. 	--  ����
				k..trade.trade_currency..k..','..	--  ������
				trade.accruedint          ..','..	--  ����������� �������� �����
				k..trans_id..k      	  ..','..	--  ������������� ����������
				trade.order_num           ..','..	--  ����� ������ � �������� �������  
				getParamEx (trade.class_code, sec_code, 'LOTSIZE').param_value ..','..  
				trade.exchange_comission  ..		--  �������� �������� ����� (����)  
            ');'          
                       
     self.db:exec(sql)  
        
  
end

--[[�������� ��� ������
��� ���������, ��������, �� �������� �����, ����� ������� � ��� � ���� ������� ������� � TOM, � �������/�������� �� TOD.
����� ��� ��������� � TOM, ������ ��� ��� ����������� ����
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
--�������� ������ �� ����
--Parameters:
--	db - in - sqlite db connection - ����������� � ���� sqlite
--  trade - in - lua table - ������� � ����������� ������ �� ������� OnTrade()
function FIFO:makeFifo(trade)

    --��������� ����������� ������
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

--  ����������� ������ �� ���� � ������� ������

--�������� ��� �������� ������� �� ������ �� sqlite � ���������� ������� Lua,
--�� ������� ����� ������� ����������� � ������� ������� ������
--Parameters:
--	
--  totals_t - simple lua table from TradeHistory_table class. it is needed to keep total PnL and Collateral by account and class_code
function FIFO:readOpenFifoPositions_ver2(sec_code, class_code, account, isDetails, totals_t)

  --��������
  --������� ���������� �������, ��������������� � ��� ����� �� ������ ������, ����� �������� ���� � ����� ������
  --(��� � ����� �������� ����������)
  --�� ����������� ���������� ������� �������� ����� � ���������� � ����������� �������� ���� � �������
  --(��� ��� ����������� ����������� ���� ������, ������� ������� �������)
  --(������ ������� ������)
  --������� �� ������������� ������� ��� ��� ����, ���� �������� ������� ����� ��� ��������� ���� � ���� ����������
  --(��� ����� ������ ��� ����������, ������ ��� �����)  
  --(���� ���������� ����� ��� ����������) 

	local  sql = 
	[[
		SELECT
		subq.operation AS operation
		
		--���������
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
		--�������
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

--���������� ����� ������� �� �������� Long ��� Short � ����������� �� ����������
function FIFO:QueryTextOpenFifoPositions_ver3(sec_code, class_code, account, isDetails, isShort)

  --��������
  --������� ���������� �������, ��������������� � ��� ����� �� ������ ������, ����� �������� ���� � ����� ������
  --(��� � ����� �������� ����������)
  --�� ����������� ���������� ������� �������� ����� � ���������� � ����������� �������� ���� � �������
  --(��� ��� ����������� ����������� ���� ������, ������� ������� �������)
  --(������ ������� ������)
  --������� �� ������������� ������� ��� ��� ����, ���� �������� ������� ����� ��� ��������� ����
  --(��� ����� ������ ��� ����������, ������ ��� �����)  
	local k = "'"

	local operation = ''
	if isShort == 1 or isShort == true then
		operation = 'sell'
	else
		operation = 'buy'
	end

	local  sql = ' SELECT ' ..k.. operation ..k.. ' AS operation ' .. [[
        
           --���������
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
        
           --�������
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
                              --���������
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
                               --�������
                            , SUM(qty)            AS qty
                            , SUM(value)          AS value
							, SUM(commiss)          AS commiss
                            
                            , SUM(value)/SUM(qty)/coalesce(sec.mult, lot) AS price
                            
                            , MIN(attr_date)      AS attr_date
                            , MIN(attr_time)      AS attr_time
                    FROM
                              (
                                        SELECT
                                                  --���������
                                                  dim_client_code
												  ,dim_depo_code
                                                , dim_sec_code
                                                , dim_class_code
                                                , dim_brokerref
                                                , dim_trade_num
                                                
                                                   --�������
                                                , &sign * SUM(res_qty)             AS qty
                                                , &sign * SUM(res_value)           AS value
												, SUM(attr_exchange_comission)     AS commiss
												--bugfix. ���� � ��� ���� ������� �� null, � �������� ����, ��� ������ ������,
												--�� ����� �������� �� ������ ��, ��� ����.
												--���� ����� ������ ������ � ����/�������, �� � ������� ������ � ���� ����� 
												--������ ������ ������ ������
												--� ���� � ���� ����� 0, �� ������� ����������� � ������ ����� ���� � ����� � ���� ������, ��� ����
												
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
	

    --������ ������� (���� �� ����)
	if isShort == 1 or isShort == true then
		sql = string.gsub (sql, 'fifo_long_3', 'fifo_short_3')
		sql = string.gsub (sql, '&sign', '-1')
	else
		sql = string.gsub (sql, '&sign', '1')
	end

  return sql

end




--not ready!!! � ������� - ������� ����� �������������� ����� ������������� �������, ��������
--��� ����� � ������ (buy Si, buy BR) 
--��� ���� ��������� (buy USD, sell Si)
function FIFO:QueryTextOpenFifoPositions_Synthetic()

  -- ������������� ������� ��������� ��� 2 ��������� + ������ totals
  --����������� ����� ������� �� �����������, �.�.
  --���� ������� ���� � � ��� ������ ������� "syn_", �� ��� ���������.
  --��������� ����� �������� �� ������ ���������� ����� � ����� �������,
  --�.�. long+short �� ������ ������� ������ ���������, ������� ��������
  --�� ����� �� ����� ��������� (long + short) �����.
  
  local  sql = [[
      SELECT 
		'buy' as operation,
        --���������
        q1.dim_client_code  as dim_client_code,
		q1.dim_depo_code as dim_depo_code,
        q1.dim_sec_code     as dim_sec_code,  
        q1.dim_class_code   as dim_class_code,  
        q1.dim_brokerref    as dim_brokerref,
        q1.attr_date        as dateOpen,
        q1.attr_time        as timeOpen,
          
        --�������
        q1.qty              as qty,  
        q1.value            as value,
        q1.price            as price, --average price of position
          
        --other
        securities.lotsize  as lot    --info. has the meaning only for spot
        
      FROM
        (
        SELECT 
          
         --���������
          dim_client_code,
		  dim_depo_code,
          dim_sec_code,  
          dim_class_code,  
          dim_brokerref,
          
          --�������
          SUM(qty) AS qty,  
          SUM(value) AS value,
          AVG(attr_price) AS price,
          
          MIN(attr_date) as attr_date, 
          MIN(attr_time) as attr_time
                     
        FROM
        
        (
          SELECT 
          
            --���������
            dim_client_code,
			dim_depo_code,
            dim_sec_code,  
            dim_class_code,  
            dim_brokerref,
            dim_trade_num,
          
            --�������
            
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

--�������� ��� �������� ������� �� ������ �� sqlite � ���������� ������� Lua,
--�� ������� ����� ������� ����������� � ������� ������� ������
--Parameters:
--	db - in - sqlite db connection - ����������� � ���� sqlite
function FIFO:readClosedFifoPositions()

   local sql = 
  [[
    SELECT
          subq.operation AS operation
        ,
           --���������
          subq.dim_client_code AS dim_client_code
		, subq.dim_depo_code AS dim_depo_code
        , subq.dim_sec_code    AS dim_sec_code
        , subq.dim_class_code  AS dim_class_code
        , subq.dim_brokerref   AS dim_brokerref
        , subq.dim_trade_num   AS dim_trade_num
        ,
           --�������
          subq.quantity AS quantity
        , subq.qtyClose AS qtyClose
        , subq.value    AS value
        ,
           --���������
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
      --���������
      vt[r_count]['dim_client_code']=row.dim_client_code
	  vt[r_count]['dim_depo_code']=row.dim_depo_code
      vt[r_count]['dim_sec_code']  =row.dim_sec_code
      vt[r_count]['dim_class_code']=row.dim_class_code  
      vt[r_count]['dim_brokerref']=row.dim_brokerref
      vt[r_count]['dim_trade_num']=row.dim_trade_num
      
      --�������
      vt[r_count]['quantity'] = row.quantity
      vt[r_count]['qtyClose'] = row.qtyClose  
      vt[r_count]['value'] = row.value
      
      --���������
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

--���������� ����� ������� �� �������� Long
function FIFO:QueryTextClosedFifoPositionsLong()

  local sql = 
  [[
    SELECT
          'buy' AS operation
           --���������
        , ClosedPos.dim_client_code AS dim_client_code
		, ClosedPos.dim_depo_code AS dim_depo_code
        , ClosedPos.dim_sec_code AS dim_sec_code
        , ClosedPos.dim_class_code AS dim_class_code
        , ClosedPos.dim_brokerref AS dim_brokerref
        , OpenPos.dim_trade_num AS dim_trade_num
        
           --�������
        , OpenPos.res_qty        AS quantity
        , -1*ClosedPos.res_qty   AS qtyClose
        , -1*ClosedPos.res_value AS value
        
           --���������
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

--���������� ����� ������� �� �������� Short
function FIFO:QueryTextClosedFifoPositionsShort()

    local sql = 
  [[
    SELECT
          'sell' AS operation
        ,
           --���������
          ClosedPos.dim_client_code AS dim_client_code
		  ,ClosedPos.dim_depo_code AS dim_depo_code
        , ClosedPos.dim_sec_code AS dim_sec_code
        , ClosedPos.dim_class_code AS dim_class_code
        , ClosedPos.dim_brokerref AS dim_brokerref
        , OpenPos.dim_trade_num AS dim_trade_num
        ,
           --�������
          -1*OpenPos.res_qty  AS quantity
        , ClosedPos.res_qty   AS qtyClose
        , ClosedPos.res_value AS value
        ,
           --���������
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



 
 
--�������� ���������� � ������ � ������� securities
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
        getParamEx (class_code, sec_code, 'lotsize').param_value..					--��������������. ��� ����� ������ ��� � �������. ���� ����������� �����, �� mult ����� ����� ����� ���� (�� ������� ��������� mult ��� ����� ������������ ���, ���� ������ ��� � �������)
        ');'
              
        self.db:exec(sql)
    end
  
end

--�������� �������������� ��� �����. ��� ��������� ������� - ��� ������ ����
--��� ����� �� ��� �������� � ������� securities
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


