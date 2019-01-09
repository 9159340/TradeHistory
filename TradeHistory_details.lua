--this class shows detail of open position, i.e. deals of which it consists of
--this class creates new visual table. its structure is similar to main table

helper = {}
fifo = {}
maintable = {}--класс для работы с таблицами на форме квика

Details = class(function(acc)
end)

function Details:Init()

  helper=Helper()
  helper:Init()
  
  fifo=FIFO()
  fifo:Init()

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

  self.totals_t = {}

end

-- event handler: OnLoad
function Details:load()

  self.key = self.sec_code..'-'..self.class_code..'-'..self.account
  
  local t = maintable:createTable("OPEN POSITION DETAILS: "..self.sec_code)

  self.t[self.key] = t
  
  t:Show()
  
  self:loadPositions()  

end

function Details:loadPositions()

  --header
  local r = self.t[self.key]:AddLine()
  self.t[self.key]:SetValue(r, 'dateOpen', "DETAILS")

  --load positions
  self:loadOpenFifoPositions()
  
end

--add 1 row from FIFO to open positions table
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
	--self.t[self.key]:SetValue(row, 'priceOpen', tostring(sqliteRow.price))

	local val = sqliteRow.price
	if val == nil then
		maintable.t:SetValue(row, 'priceOpen', '')
	else
		local precision = settings:get_precision(sqliteRow.dim_sec_code)
		local priceOpen = 0
		if precision~=nil then
			priceOpen = helper:math_round(val/100000, precision)
		else
			priceOpen = helper:math_round(val/100000, 2)
		end
		self.t[self.key]:SetValue(row, 'priceOpen', tostring( priceOpen ))
		--message (val)
	end

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
	
	--show option type
	local optionType = getParamEx(sqliteRow.dim_class_code, sqliteRow.dim_sec_code, 'optiontype')
	if optionType ~= nil then
		optionType = optionType.param_image
	else
		optionType = ''
	end
	
	self.t[self.key]:SetValue(row, 'optionType', optionType)
	
	--show option theor price
	local theorprice = getParamEx(sqliteRow.dim_class_code, sqliteRow.dim_sec_code, 'theorprice')
	if theorprice ~= nil then
		theorprice = theorprice.param_image
	else
		theorprice = ''
	end
	
	self.t[self.key]:SetValue(row, 'theorPrice', theorprice)
	
	--show expiration date
	local expiration = getParamEx(sqliteRow.dim_class_code, sqliteRow.dim_sec_code, 'expdate')
	if expiration ~= nil then
		expiration = expiration.param_image
	else
		expiration = ''
	end
	
	self.t[self.key]:SetValue(row, 'expiration', tostring(expiration))	
	
end

-- add row with totals after a class
function Details:addTotalRow_details( quantity )

	local row = self.t[self.key]:AddLine()
	self.t[self.key]:SetValue(row, 'secCode', 'TOTAL')
	self.t[self.key]:SetValue(row, 'quantity',  tostring(quantity) )

end

--add open positions to the robot details table
--Parameters:
function Details:loadOpenFifoPositions()

  --get the table with positions from fifo
  
  local vt = fifo:readOpenFifoPositions_ver2(self.sec_code, self.class_code, self.account, true) --module TradeHistory_FIFO.lua
  
  local r_count = 1
  
  local quantity = 0
  
  while r_count <= table.maxn(vt) do
    
    self:addRowFromFIFO( vt[r_count] )
    
	quantity = quantity + vt[r_count].qty
	
    r_count = r_count + 1
	
  end

  self:addTotalRow_details( quantity )	

end

function Details:recalc_details()
	-- recal details by portions
    for key, details_table in pairs(self.t) do
      if details_table~=nil then
        maintable:recalc_table(details_table, self.totals_t)
      end    	
    end
end