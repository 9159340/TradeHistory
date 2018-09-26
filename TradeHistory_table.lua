--operations with main table
settings = {}

MainTable = class(function(acc)
end)

function MainTable:Init()
  self.t = nil --ID of table

  --table in memory to keep PnL and collateral
  --example
  --forts_totals_2[row.dim_client_code] = {}
  --forts_totals_2[row.dim_client_code][row.dim_class_code] = {}    
  --forts_totals_2[row.dim_client_code][row.dim_class_code]['collateral'] = 0
  --forts_totals_2[row.dim_client_code][row.dim_class_code]['PnL'] = 0
  self.totals_t = nil 
  
  settings= Settings()
  settings:Init()
  
end


 
--clean main table
function MainTable:clearTable()

  for row = self.t:GetSize(self.t.t_id), 1, -1 do
    DeleteRow(self.t.t_id, row)
  end  
  
end

-- SHOW MAIN TABLE

--show main table on screen
function MainTable:showTable()

  self.t:Show()
  
end

function MainTable:col_width(col_name)
  
	if settings.columns_width[col_name] ~= nil then
		return settings.columns_width[col_name]
	else
		return 10
	end

end

function MainTable:col_vis(col_name)
  
  if settings.columns_visibility[col_name]==true then
	return self:col_width(col_name)
  end
  return 0
end

--creates main table
function MainTable:createTable(caption)

  -- create instance of table
  local t = QTable.new()
  if not t then
    message("error!", 3)
    return
  else
    --message("table with id = " ..t.t_id .. " created", 1)
  end
  
  
  t:AddColumn("account",    QTABLE_CACHED_STRING_TYPE, self:col_vis("account"))  
  t:AddColumn("depo",    QTABLE_CACHED_STRING_TYPE, self:col_vis("depo"))  
  t:AddColumn("comment",    QTABLE_STRING_TYPE, self:col_vis("comment")) 
  t:AddColumn("secCode",    QTABLE_CACHED_STRING_TYPE, self:col_vis("secCode"))  
  
  t:AddColumn("optionType",    QTABLE_CACHED_STRING_TYPE, self:col_vis("optionType"))
  t:AddColumn("expiration",    QTABLE_STRING_TYPE, self:col_vis("expiration"))
  
  t:AddColumn("classCode",  QTABLE_CACHED_STRING_TYPE, self:col_vis("classCode"))  
  t:AddColumn("lot",  		 QTABLE_INT_TYPE, self:col_vis("lot"))
  
  t:AddColumn("dateOpen",   QTABLE_STRING_TYPE, self:col_vis("dateOpen")) 
  t:AddColumn("timeOpen",   QTABLE_STRING_TYPE, self:col_vis("timeOpen")) 
  t:AddColumn("tradeNum",   QTABLE_STRING_TYPE, self:col_vis("tradeNum"))
  
  --„ем отличаютс€ QTABLE_CACHED_STRING_TYPE и QTABLE_STRING_TYPE?  акой использовать тип дл€ вывода строки?
  --ѕри использовании QTABLE_CACHED_STRING_TYPE в €чейке таблицы хранитс€ ссылка на специальную таблицу уникальных 
  --строковых констант, котора€ заполн€етс€ по мере добавлени€ данных. Ёто экономит пам€ть при многократном 
  --использовании повтор€ющихс€ значений. Ќапример, если ¬ы хотите создать аналог таблицы всех сделок, то поле 
  --"направление сделки" может принимать значение "ѕокупка" или "ѕродажа". ¬ этом случае использование 
  --QTABLE_CACHED_STRING_TYPE дл€ столбца будет наиболее эффективным.   
  t:AddColumn("operation",  QTABLE_CACHED_STRING_TYPE, self:col_vis("operation"))      --buy/sell
  
  t:AddColumn("quantity",   QTABLE_INT_TYPE, self:col_vis("quantity"))        
  t:AddColumn("amount",     QTABLE_DOUBLE_TYPE, self:col_vis("amount"))     
  t:AddColumn("priceOpen",  QTABLE_DOUBLE_TYPE, self:col_vis("priceOpen"))
  
  t:AddColumn("dateClose",  QTABLE_STRING_TYPE, self:col_vis("dateClose"))     
  t:AddColumn("timeClose",  QTABLE_STRING_TYPE, self:col_vis("timeClose"))     
  t:AddColumn("priceClose", QTABLE_DOUBLE_TYPE, self:col_vis("priceClose"))       --here we show current price
  t:AddColumn("qtyClose",   QTABLE_INT_TYPE, self:col_vis("qtyClose"))        
  
  
  t:AddColumn("profitpt",   QTABLE_DOUBLE_TYPE, self:col_vis("profitpt"))      --in points(Ri) or currency(BR) or rubles (Si)
  t:AddColumn("profit %",   QTABLE_DOUBLE_TYPE, self:col_vis("profit %"))  
  t:AddColumn("priceOfStep",QTABLE_DOUBLE_TYPE, self:col_vis("priceOfStep"))     --price of "price's step"
  t:AddColumn("profit",     QTABLE_DOUBLE_TYPE, self:col_vis("profit"))      --rubles
  
  t:AddColumn("commission", QTABLE_DOUBLE_TYPE, self:col_vis("commission"))
  t:AddColumn("accrual",    QTABLE_DOUBLE_TYPE, self:col_vis("accrual"))
  
  
  t:AddColumn("days",       QTABLE_INT_TYPE, self:col_vis("days"))  --days in position
  
    --service fields (not shown)
  t:AddColumn("close_price_step",    QTABLE_DOUBLE_TYPE, self:col_vis("close_price_step"))   
  t:AddColumn("close_price_step_price",    QTABLE_DOUBLE_TYPE, self:col_vis("close_price_step_price"))   

  --collateral
  t:AddColumn("buyDepo",    QTABLE_DOUBLE_TYPE, self:col_vis("buyDepo"))	--for seller (amount)
  t:AddColumn("sellDepo",    QTABLE_DOUBLE_TYPE, self:col_vis("sellDepo"))	--for buyer (amount)
  
  --fur debug - shows time of last update the row
  t:AddColumn("timeUpdate",  QTABLE_STRING_TYPE, self:col_vis("timeUpdate"))     
  
  --profit by theor price for options
  t:AddColumn("theorPrice",    QTABLE_DOUBLE_TYPE, self:col_vis("theorPrice"))
  t:AddColumn("profitByTheorPricePt",    QTABLE_DOUBLE_TYPE, self:col_vis("profitByTheorPricePt"))--point
  t:AddColumn("profitByTheorPrice %",    QTABLE_DOUBLE_TYPE, self:col_vis("profitByTheorPrice %"))    --%
  t:AddColumn("profitByTheorPrice",    QTABLE_DOUBLE_TYPE, self:col_vis("profitByTheorPrice"))    --RUB

  
  
  t:SetCaption(caption)
  
  return t
  
end


function MainTable:createOwnTable(caption)
	
  self.t = self:createTable(caption)
  
end



--show collateral for each position
function MainTable:show_collateral(par_table, row)
	local class_col = par_table:GetValue(row,'classCode')
	if class_col ~= nil then
		local class = class_col.image
		if class == 'SPBFUT' or class == 'SPBOPT' then
			--exception handler is very important to prevent unexpected script stop
			--nil handler
			local secCode_col = par_table:GetValue(row,'secCode')
			if secCode_col == nil then
				return
			end
			sec = secCode_col.image
			local quantity_col = par_table:GetValue(row,'quantity')
			--nil handler
			if quantity_col == nil then
				return
			end
			local qty = tonumber(quantity_col.image)

			par_table:SetValue(row, 'buyDepo', helper:math_round( helper:buy_depo(class, sec) * qty, 2))
			par_table:SetValue(row, 'sellDepo', helper:math_round( helper:sell_depo(class, sec) * qty, 2))
		
		end
	end
end

--recalculates all rows by current closing price
-- Parameters
--  par_table - main table of robot. passes by parameter because this func may be used
--              for recalculation of any table, main or detailed
--  totals_t  - simple lua table. see this file, method createTotalsTable()
function MainTable:recalc_table( par_table, totals_t )
  
  --номер строки, с которой начинаютс€ открытые позиции.
  local row = 2 --иногда таблица смещаетс€ на 1 строку вниз, но алгоритму это не мешает
  
  local t_size = par_table:GetSize(par_table.t_id)
  if t_size == nil then
	  return
  end

  --clean totals before recalc whole table
  self:zeroTotalsTable( totals_t )

  --update price and PnL
	while row <= t_size do

		--update price in col 'priceClose'
		if par_table:GetValue(row,'operation') ~= nil then
			--get price from instrument parameters --getParamEx!
      local priceClose = helper:get_priceClose(par_table, row)
      local theorPrice = helper:get_TheorPrice(par_table, row)
			--чтобы не запускать пересчет строки лишний раз, сделаем проверку на изменение цены
			--если цена в таблице (стара€) отличаетс€ от текущей (priceClose) - обновл€ем
      if helper:getPriceClose(par_table, row) ~= priceClose 
        or helper:getTheorPrice(par_table, row) ~= theorPrice 
      then
				--put current price to a table
        --don't pass last parameter! values are not updating if it is passed
        par_table:SetValue(row, 'priceClose', tostring(priceClose))
        par_table:SetValue(row, 'theorPrice', tostring(theorPrice))
				--show last price update time
				par_table:SetValue(row, 'timeUpdate', tostring(os.date())) 
				--calculates PnL, set row color according to profit or loss (green or red)
				recalc:recalcPosition(par_table, row, false)
      end

      --recalc totals in any case, whether price has been changed or not
      if totals_t ~= nil then
        --nil may present if we run this function for details of fifo
    
        local account = par_table:GetValue(row,'account').image
        local classCode = par_table:GetValue(row,'classCode').image
        local accrual = tonumber(par_table:GetValue(row,'accrual').image)
        local buyDepo = tonumber(par_table:GetValue(row,'buyDepo').image)
        
        local PnLrub = helper:getProfit(par_table,row)

        maintable:addValuesToTotalsTable( account, classCode, buyDepo, PnLrub, accrual )
      end	
    
    end
    
    
    -- update values in TOTAL rows
    if par_table:GetValue(row,'secCode').image == 'TOTAL' then

      local classCode = par_table:GetValue(row-1,'classCode').image
      local clientCode = par_table:GetValue(row-1,'account').image

      totalsArray = maintable:findTotalsByClass(totals_t, clientCode, classCode)

      par_table:SetValue(row, 'profit', tostring( totalsArray['profit'] )) 
      par_table:SetValue(row, 'buyDepo', tostring( totalsArray['buyDepo'] )) 
      par_table:SetValue(row, 'accrual', tostring( totalsArray['accrual'] )) 

    end



		--show collaterdal for each position
		self:show_collateral(par_table, row)
		
    row=row+1
    
	end

end


--creates table in memory to keep PnL and collateral
--example
--forts_totals_2[row.dim_client_code] = {}
--forts_totals_2[row.dim_client_code][row.dim_class_code] = {}    
--forts_totals_2[row.dim_client_code][row.dim_class_code]['collateral'] = 0
--forts_totals_2[row.dim_client_code][row.dim_class_code]['PnL'] = 0
--forts_totals_2[row.dim_client_code][row.dim_class_code]['accrual'] = 0
function MainTable:createTotalsTable()
	
  self.totals_t = {}
  
end

function MainTable:addClientToTotalsTable( clientCode )
	
  if self.totals_t [ clientCode ] == nil then
    self.totals_t [ clientCode ] = {}
  end

end

function MainTable:addClassToTotalsTable( clientCode, classCode )
	
  if self.totals_t[ clientCode ] [ classCode ] == nil then
    self.totals_t[ clientCode ] [ classCode ] = {}

    self.totals_t[ clientCode ] [ classCode ] [ 'collateral' ] = 0
    self.totals_t[ clientCode ] [ classCode ] [ 'PnL' ] = 0
    self.totals_t[ clientCode ] [ classCode ] [ 'accrual' ] = 0

  end

end

function MainTable:addValuesToTotalsTable( clientCode, classCode, collateral, PnL, accrual )
  
  self:addClientToTotalsTable( clientCode )
  self:addClassToTotalsTable( clientCode, classCode )

  if collateral ~= nil then
    self.totals_t[ clientCode ] [ classCode ] [ 'collateral' ] = self.totals_t[ clientCode ] [ classCode ] [ 'collateral' ] + collateral
  end
  if PnL ~= nil then
    self.totals_t[ clientCode ] [ classCode ] [ 'PnL' ] = self.totals_t[ clientCode ] [ classCode ] [ 'PnL' ] + PnL
  end
  if accrual ~= nil then
    self.totals_t[ clientCode ] [ classCode ] [ 'accrual' ] = self.totals_t[ clientCode ] [ classCode ] [ 'accrual' ] + accrual
  end

end

function MainTable:zeroTotalsTable( totals_t )
  
  for clientCode , classes in pairs(totals_t) do
    for classCode, values in pairs(classes) do
      values [ 'collateral' ] = 0
      values [ 'PnL' ] = 0
      values [ 'accrual' ] = 0
    end
  end

end



-- searches row in totals table
-- return: table with 2 field: collateral and PnL 
function MainTable:findTotalsByClass(totals_t, clientCode, classCode)
	
    local retArray = {}
    
		for key, array_level_2 in pairs( totals_t ) do
			--message ( tostring(key) ) 			-- account. example '714547'
			--message ( tostring(array_level_2) )	-- table

			if key == clientCode then
				
				for key2, array_level_3 in pairs( array_level_2 ) do
					--message ( tostring(key2) )			-- class code. example 'SPBOPT'
					--message ( tostring(array_level_3) )	-- table

					if key2 == classCode then

		
						for key3, value4 in pairs( array_level_3 ) do
							--message ( tostring(key3) )		-- parameter name. example 'collateral', 'PnL'
							--message ( tostring(value4) )		-- parameter value, amount. example 5432.97
			
							if key3 == 'collateral' then
								retArray['buyDepo']=value4
							
							elseif key3 == 'PnL' then
								retArray['profit']=value4

							elseif key3 == 'accrual' then
								retArray['accrual']=value4

              end
							
						end
					end
				end
			end
		end
	return retArray	
end