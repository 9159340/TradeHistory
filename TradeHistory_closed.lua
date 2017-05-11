
helper = {}
settings = {}
colorizer = {}
fifo = {}
recalc = {}
maintable = {}


ClosedPos = class(function(acc)
end)

function ClosedPos:Init()
  
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
  
  self.t = nil --здесь будет ИД таблицы
end

function ClosedPos:load()
  
  local t = maintable:createTable("CLOSED POSITIONS")
  
  t:Show()
  
  self.t = t
  
  self:loadPositions()
  
end
  
--загружает позиции из sqlite
function ClosedPos:loadPositions()

  --закрытые позиции
  
  local row = self.t:AddLine()
  --заголовок закрытых позиций
  
  self.t:SetValue(row, 'dateOpen', "CLOSED")
  self.t:SetValue(row, 'timeOpen', "POSITIONS")

  self:loadClosedFifoPositions()
  
end



--  ОТОБРАЖЕНИЕ ДАННЫХ ИЗ ФИФО В ТАБЛИЦУ РОБОТА

--добавляет одну строку в закрытые позиции
function ClosedPos:addRowFromFIFO_close(sqliteRow)

	local row = self.t:AddLine()
	self.t:SetValue(row, 'account',   sqliteRow.dim_client_code)
	self.t:SetValue(row, 'depo',   sqliteRow.dim_depo_code)
	self.t:SetValue(row, 'dateOpen',  sqliteRow.dateOpen)
	self.t:SetValue(row, 'timeOpen',  sqliteRow.timeOpen)
	self.t:SetValue(row, 'tradeNum',  sqliteRow.dim_trade_num)
	self.t:SetValue(row, 'secCode',   sqliteRow.dim_sec_code)
	self.t:SetValue(row, 'classCode', sqliteRow.dim_class_code)
	self.t:SetValue(row, 'operation', sqliteRow.operation)
	if sqliteRow.lot  == nil then
		self.t:SetValue(row, 'lot', tostring(1))
	else
		self.t:SetValue(row, 'lot', tostring(sqliteRow.lot))
	end
	self.t:SetValue(row, 'quantity', tostring(sqliteRow.quantity))
	self.t:SetValue(row, 'amount', tostring(sqliteRow.value))
	self.t:SetValue(row, 'priceOpen', tostring(sqliteRow.price))
	self.t:SetValue(row, 'dateClose', sqliteRow.close_date)
	self.t:SetValue(row, 'timeClose', sqliteRow.close_time)
	self.t:SetValue(row, 'priceClose', sqliteRow.close_price)
	self.t:SetValue(row, 'qtyClose', sqliteRow.qtyClose)
	--self.t:SetValue(row, 'amountClose', tostring(sqliteRow.close_value))    
	self.t:SetValue(row, 'commission', 0)
	--self.t:SetValue(row, 'accrual', 0)
	self.t:SetValue(row, 'profit %', 0)
	self.t:SetValue(row, 'profit', 0)
	self.t:SetValue(row, 'profitpt', 0)
	--self.t:SetValue(row, 'days', 0)
	--show days in position. 
	self.t:SetValue(row, 'days', helper:days_in_position(sqliteRow.dateOpen,  sqliteRow.close_date))
	
	self.t:SetValue(row, 'comment', sqliteRow.dim_brokerref)
	--вспомогательные. на форме не видны. нужны для расчета прибыли по закрытым позициям на фортс
	self.t:SetValue(row, 'close_price_step', sqliteRow.close_price_step)
	self.t:SetValue(row, 'close_price_step_price', sqliteRow.close_price_step_price)
	--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! RECALC
	recalc:recalcPosition(self.t, row, true)

end

--добавляет все закрытые позиции в таблицу робота
function ClosedPos:loadClosedFifoPositions()

  --get the table with positions from fifo
  local vt = fifo:readClosedFifoPositions() --module TradeHistory_FIFO.lua
  
  local r_count = 1
  
  while r_count <= table.maxn(vt) do
    
    self:addRowFromFIFO_close(vt[r_count])
    
    r_count = r_count + 1 
  end
  
end




