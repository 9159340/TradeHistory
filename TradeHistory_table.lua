--operations with main table
settings = {}

MainTable = class(function(acc)
end)

function MainTable:Init()
  self.t = nil --ID of table
  
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
  t:AddColumn("theorPrice",    QTABLE_DOUBLE_TYPE, self:col_vis("theorPrice"))
  
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

  
  
  t:SetCaption(caption)
  
  return t
  
end

function MainTable:createOwnTable(caption)
	
	self.t = self:createTable(caption)
end

--покажем сумму √ќ по каждой позиции
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

--пересчитывает все строки таблицы по текущей цене закрыти€
--таблица передаетс€ через параметр, т.к. функци€ используетс€
--дл€ пересчета любых таблицы, открытых скриптом - главной и детальных
function MainTable:recalc_table(par_table)
  
  --номер строки, с которой начинаютс€ открытые позиции.
  local row = 2 --иногда таблица смещаетс€ на 1 строку вниз, но алгоритму это не мешает
  
  local t_size = par_table:GetSize(par_table.t_id)
  if t_size == nil then
	return
  end
  
  --обход таблицы и обновление котировки
	while row <= t_size do

		--update price in col 'priceClose'
		if par_table:GetValue(row,'operation') ~= nil then
			--получим цену, по который закрываетс€ позици€ -- из параметров бумаги --getParamEx!
			local priceClose = helper:get_priceClose(par_table, row)
			--чтобы не запускать пересчет строки лишний раз, сделаем проверку на изменение цены
			--если цена в таблице (стара€) отличаетс€ от текущей (priceClose) - обновл€ем
			if helper:getPriceClose(par_table, row) ~= priceClose then
				--установим текущую цену в таблицу
				--последний параметр функции не заполн€ть!
				--иначе - значение не обновл€етс€:(
				par_table:SetValue(row, 'priceClose', tostring(priceClose))
				--покажем врем€ последнего обновлени€ цены 
				par_table:SetValue(row, 'timeUpdate', tostring(os.date())) 
				--рассчитаем прибыль по открытым позици€м, установим цвет текста в зависимости от прибыли (зел/красн)
				recalc:recalcPosition(par_table, row, false)
			end
		end

		--покажем сумму √ќ по каждой позиции
		self:show_collateral(par_table, row)
		
		--[[
		--show days in position. it must be here!
		local dateOpen_cell = par_table:GetValue(row,'dateOpen')
		if dateOpen_cell~=nil then
			par_table:SetValue(row, 'days',    helper:days_in_position(dateOpen_cell.image,  os.date('%Y-%m-%d'))     )
		end
		--]]

		  
		row=row+1
	end

end

--class TQOB - OFZ
--class EQOB - corp bonds
