--этот класс отображает детали открытой позиции, т.е. сделок, из которых она состоит
--он создает новую визуальную таблицу, структура которой аналогична главной таблице.

helper = {}
settings = {}
colorizer = {}
fifo = {}
recalc = {}
maintable = {}--класс для работы с таблицами на форме квика

Details = class(function(acc)
end)

function Details:Init()

  helper=Helper()
  helper:Init()
  
  settings= Settings()
  settings:Init()
  
  colorizer=Colorizer()
  colorizer:Init()
  
  fifo=FIFO()
  fifo:Init()

  recalc= Recalc()
  recalc:Init()

  maintable= MainTable()
  maintable:Init()
  
  self.sec_code = nil
  self.class_code = nil
  self.account = nil
  
  --ID of table
  --это будет таблица таблиц
  --работаем с ней так:
  --self.key = self.sec_code..'-'..self.class_code..'-'..self.account -- это в load
  --self.t[self.key] = новая таблица
  self.t = {}
  self.key = nil

end

function Details:load()

  self.key = self.sec_code..'-'..self.class_code..'-'..self.account
  
  local t = maintable:createTable("OPEN POSITION DETAILS: "..self.sec_code)
  
  self.t[self.key] = t
  
  t:Show()
  
  self:loadPositions()  

end

function Details:loadPositions()

  --открытые позиции
  
  local r = self.t[self.key]:AddLine()
  --заголовок открытых позиций
  
  self.t[self.key]:SetValue(r, 'dateOpen', "DETAILS")
  
  
  self:loadOpenFifoPositions()
  
  
end

--  ОТОБРАЖЕНИЕ ДАННЫХ ИЗ ФИФО В ТАБЛИЦУ РОБОТА

--добавляет одну строку в открытые позиции
function Details:addRowFromFIFO(sqliteRow)

	local row = self.t[self.key]:AddLine()
	self.t[self.key]:SetValue(row, 'account', sqliteRow.dim_client_code)
	self.t[self.key]:SetValue(row, 'depo', sqliteRow.dim_depo_code)
	self.t[self.key]:SetValue(row, 'dateOpen', sqliteRow.dateOpen)
	self.t[self.key]:SetValue(row, 'timeOpen', sqliteRow.timeOpen)
	self.t[self.key]:SetValue(row, 'tradeNum', sqliteRow.dim_trade_num)
	self.t[self.key]:SetValue(row, 'secCode', sqliteRow.dim_sec_code)
	self.t[self.key]:SetValue(row, 'classCode', sqliteRow.dim_class_code)
	self.t[self.key]:SetValue(row, 'operation', sqliteRow.operation)
	if sqliteRow.lot  == nil then
		self.t[self.key]:SetValue(row, 'lot', tostring(1))
	else
		self.t[self.key]:SetValue(row, 'lot', tostring(sqliteRow.lot))
	end
	self.t[self.key]:SetValue(row, 'quantity', tostring(sqliteRow.qty)) --для spot это будут штуки, для фортс - по-разному, 
	self.t[self.key]:SetValue(row, 'amount', tostring(sqliteRow.value))
	self.t[self.key]:SetValue(row, 'priceOpen', tostring(sqliteRow.price))
	self.t[self.key]:SetValue(row, 'dateClose', '')
	self.t[self.key]:SetValue(row, 'timeClose', '')
	self.t[self.key]:SetValue(row, 'priceClose', tostring(sqliteRow.price))
	self.t[self.key]:SetValue(row, 'qtyClose', tostring(sqliteRow.qty))    --покажем то же количество, что и в позиции.

	self.t[self.key]:SetValue(row, 'commission', sqliteRow.commiss)
	
	self.t[self.key]:SetValue(row, 'profit %', 0)
	self.t[self.key]:SetValue(row, 'profit', 0)
	self.t[self.key]:SetValue(row, 'profitpt', 0)
	
	self.t[self.key]:SetValue(row, 'comment', sqliteRow.dim_brokerref)
    
	--show days in position. 
	self.t[self.key]:SetValue(row, 'days', helper:days_in_position(sqliteRow.dateOpen,  os.date('%Y-%m-%d')))
		
	--show accrual
	if sqliteRow.dim_class_code =='TQOB' or sqliteRow.dim_class_code=='EQOB' then
		self.t[self.key]:SetValue(row, 'accrual', tonumber(getParamEx (sqliteRow.dim_class_code, sqliteRow.dim_sec_code, 'accruedint').param_value) * tonumber(sqliteRow.qty))
		--show correct amount
		local SEC_FACE_VALUE = tonumber(getParamEx (sqliteRow.dim_class_code, sqliteRow.dim_sec_code, 'sec_face_value').param_value)
		self.t[self.key]:SetValue(row, 'amount', tostring(SEC_FACE_VALUE * sqliteRow.qty * sqliteRow.price / 100))
	end      
end

--добавляет все открытые позиции в таблицу робота
--Parameters:
function Details:loadOpenFifoPositions()

  --get the table with positions from fifo
  
  --local vt = fifo:readOpenFifoPositions() --module TradeHistory_FIFO.lua
  
  local vt, forts_totals = fifo:readOpenFifoPositions_ver2(self.sec_code, self.class_code, self.account, true) --module TradeHistory_FIFO.lua
  
  local r_count = 1
  
  while r_count <= table.maxn(vt) do
    
    self:addRowFromFIFO(vt[r_count])
    
    r_count = r_count + 1 
  end
    
	--show total collateral on forts
	if settings.show_total_collateral_on_forts == true then
		for k, v in pairs(forts_totals) do
			if v~= nil and v ~= 0 and v~='' then
				local row = self.t[self.key]:AddLine()
				self.t[self.key]:SetValue(row, 'account', k)
				self.t[self.key]:SetValue(row, 'buyDepo', v)
			end
		end
	end	
	
end

