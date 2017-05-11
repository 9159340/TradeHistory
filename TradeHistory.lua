--отображение всех открытых позиций

local sqlite3 = require("lsqlite3")
--эта dll нужна для работы с битовыми флагами сделок. там зашито направление buy/sell
local bit = require"bit"

--пример из учебника по QLUA
dofile (getScriptPath() .. "\\quik_table_wrapper.lua")
--классы
dofile (getScriptPath() .. "\\TradeHistory_class.lua")
dofile (getScriptPath() .. "\\TradeHistory_helper.lua")
dofile (getScriptPath() .. "\\TradeHistory_settings.lua")
dofile (getScriptPath() .. "\\TradeHistory_fifo.lua")
dofile (getScriptPath() .. "\\TradeHistory_colorize.lua")
dofile (getScriptPath() .. "\\TradeHistory_recalc.lua")
dofile (getScriptPath() .. "\\TradeHistory_details.lua")
dofile (getScriptPath() .. "\\TradeHistory_table.lua") --class maintable
dofile (getScriptPath() .. "\\TradeHistory_closed.lua")
dofile (getScriptPath() .. "\\TradeHistory_deals.lua")
dofile (getScriptPath() .. "\\TradeHistory_actions.lua")

--[[
читаем позиции из sqlite, выводим их цену и считаем PnL по текущей котировке
в пунктах и в рублях. чтобы посчитать рубли, нужно получить стоимость шага цены
]]



-- классы
settings={}
helper={}
recalc={}
fifo={}
details={}
maintable={} --maintable.t - главная таблица робота
closedpos={} --класс для отображения таблицы закрытых позиций
deals={}
actions={} --контекстное меню

-- Константы --
-- Глобальные переменные --


--таблица, в которой будем хранить ИД сделок, которые уже обработаны в OnTrade()
--проблема в том, что OnTrade() вызывается более одного раза при создании сделки в терминале,
--поэтому надо проверять, что мы сделку уже обработали, чтобы не получить дубль в истории.
local processedDeals = {}

is_run = true


--checks whether deal is processed with FIFO or not
--Params:
--  num - deal number (micex)
--Returns
--  "true" if deal is not processed with FIFO
function deal_is_not_processed(num)
  for key, value in pairs(processedDeals) do
    --message(key)
    --message(value)
    if value == num then
      --if deal is in the table then it was processed. ret false
      return false
    end
  end
  --add deal number into the table
  table.insert(processedDeals, num)
  
  return true
end

--  ОТОБРАЖЕНИЕ ДАННЫХ ИЗ ФИФО В ТАБЛИЦУ РОБОТА

--добавляет одну строку в открытые позиции
function addRowFromFIFO(sqliteRow)

	if sqliteRow.dim_client_code == nil then
		return
	end
  
	local row = maintable.t:AddLine()
	maintable.t:SetValue(row, 'account', sqliteRow.dim_client_code)
	maintable.t:SetValue(row, 'depo', sqliteRow.dim_depo_code)
	maintable.t:SetValue(row, 'dateOpen', sqliteRow.dateOpen)
	maintable.t:SetValue(row, 'timeOpen', sqliteRow.timeOpen)
	maintable.t:SetValue(row, 'tradeNum', sqliteRow.dim_trade_num)
	maintable.t:SetValue(row, 'secCode', sqliteRow.dim_sec_code)
	maintable.t:SetValue(row, 'classCode', sqliteRow.dim_class_code)
	maintable.t:SetValue(row, 'operation', sqliteRow.operation)
	if sqliteRow.lot  == nil then
		maintable.t:SetValue(row, 'lot', tostring(1))
	else
		maintable.t:SetValue(row, 'lot', tostring(sqliteRow.lot))
	end
	maintable.t:SetValue(row, 'quantity', tostring(sqliteRow.qty)) --для spot это будут штуки, для фортс - по-разному, 
	maintable.t:SetValue(row, 'amount', tostring(sqliteRow.value))
	maintable.t:SetValue(row, 'priceOpen', tostring(sqliteRow.price))
	maintable.t:SetValue(row, 'dateClose', '')
	maintable.t:SetValue(row, 'timeClose', '')
	maintable.t:SetValue(row, 'priceClose', tostring(sqliteRow.price))
	maintable.t:SetValue(row, 'qtyClose', tostring(sqliteRow.qty))    --покажем то же количество, что и в позиции.
	maintable.t:SetValue(row, 'commission', sqliteRow.commiss)
	maintable.t:SetValue(row, 'profit %', 0)
	maintable.t:SetValue(row, 'profit', 0)
	maintable.t:SetValue(row, 'profitpt', 0)
	maintable.t:SetValue(row, 'days', helper:days_in_position(sqliteRow.dateOpen,  os.date('%Y-%m-%d')))
	maintable.t:SetValue(row, 'comment', sqliteRow.dim_brokerref)

	--show accrual
	if sqliteRow.dim_class_code =='TQOB' or sqliteRow.dim_class_code=='EQOB' then
		maintable.t:SetValue(row, 'accrual', tonumber(getParamEx (sqliteRow.dim_class_code, sqliteRow.dim_sec_code, 'accruedint').param_value) * tonumber(sqliteRow.qty))
		--show correct amount
		local SEC_FACE_VALUE = tonumber(getParamEx (sqliteRow.dim_class_code, sqliteRow.dim_sec_code, 'sec_face_value').param_value)
		maintable.t:SetValue(row, 'amount', tostring(SEC_FACE_VALUE * sqliteRow.qty * sqliteRow.price / 100))
	end     

end


--загружает позиции из sqlite
function load_OPEN_Positions()

  --открытые позиции
  
  local r = maintable.t:AddLine()
  --заголовок открытых позиций
  
  maintable.t:SetValue(r, 'dateOpen', "OPEN")
  maintable.t:SetValue(r, 'timeOpen', "POSITIONS")
	
  maintable.t:SetValue(r, 'dateClose', "Click")
  maintable.t:SetValue(r, 'timeClose', "here")
  maintable.t:SetValue(r, 'priceClose', "to")
  maintable.t:SetValue(r, 'qtyClose', "show")
  maintable.t:SetValue(r, 'profitpt', "CLOSED")
  maintable.t:SetValue(r, 'profit %', "POSITIONS")

  --get the table with positions from fifo
  
  --first version
  --local vt = fifo:readOpenFifoPositions() --module TradeHistory_FIFO.lua
  
	local vt, forts_totals = fifo:readOpenFifoPositions_ver2() --module TradeHistory_FIFO.lua

	local r_count = 1

	while r_count <= table.maxn(vt) do
		addRowFromFIFO(vt[r_count])
		r_count = r_count + 1 
	end 

	--show total collateral on forts
	if settings.show_total_collateral_on_forts == true then
		for k, v in pairs(forts_totals) do
			if v~= nil and v ~= 0 and v~='' then
				local row = maintable.t:AddLine()
				maintable.t:SetValue(row, 'account', k)
				maintable.t:SetValue(row, 'buyDepo', v)
				--maintable.t:SetValue(row, 'dateOpen', nil)
				--maintable.t:SetValue(row, 'dateClose', nil)
			end
		end
	end	
end



-- обработчики событий ----

function OnInit(s)

	helper= Helper()
	helper:Init()
	
	settings= Settings()
	settings:Init()

	recalc= Recalc()
	recalc:Init()
	
	fifo= FIFO()
	fifo:Init()
	
	details= Details()
	details:Init()

  maintable= MainTable()
  maintable:Init()

  closedpos=ClosedPos()
  closedpos:Init()
  
	deals= Deals()
	deals:Init()
	
	actions = Actions()
	actions:Init()  
  --create and show table
  
  maintable:createOwnTable("Trade history : OPEN POSITIONS")
  
  maintable:showTable()
  
  
  load_OPEN_Positions()
    
end


function DestroyTables()

  --сначала грохнем все детальные таблицы, если есть  
  for key, details_table in pairs(details.t) do
    
    if details_table~=nil then
      DestroyTable(details_table.t_id)
    end     
  end
  --потом закрытые позиции, если есть
  if closedpos.t~=nil then
	DestroyTable(closedpos.t.t_id)
  end
  
	--затем основную  таблицу
	DestroyTable(maintable.t.t_id)
  
	--10/05/17 добавилось контекстное меню
	if actions.t ~= nil then
		DestroyTable(actions.t.t_id)
	end
end

function OnStop(s)
  is_run = false
  DestroyTables()
  return 1000
end

function OnTrade(trade)
	
	
	local robot_id=''	--dummy
	
	--only unprocessed deals are to insert into database
	if deals:deal_is_not_processed(trade)==true then

		deals:insertTradeToDB(trade, robot_id)
		
		--порядок не менять!
    
		--добавить информацию о бумаге в таблицу securities
		fifo:saveSecurityInfo(trade.sec_code, trade.class_code)
		
		--добавить позицию в ФИФО
		fifo:makeFifo(trade)
		
	end

  --refill robot's table	
	maintable:clearTable()
	
	load_OPEN_Positions()
	
end

--details

--функция закрывает окно таблицы детализации открытых позиций. по нажатию креста и кнопки ESC
local f_cb_details = function( t_id,  msg,  par1, par2)
  
  if (msg==QTABLE_CLOSE)  then
    DestroyTable(t_id)
  end
  
	if msg==QTABLE_VKEY then
		--message(par2)
		if par2 == 27 then -- esc
			DestroyTable(t_id)
		end
		--par2 = 13 - enter
	end  
end 

--closed

--функция закрывает окно таблицы закрытых сделок. по нажатию креста и кнопки ESC
local f_cb_closed = function( t_id,  msg,  par1, par2)
  
  if (msg==QTABLE_CLOSE)  then
    DestroyTable(closedpos.t.t_id)
  end
  
	if msg==QTABLE_VKEY then
		--message(par2)
		if par2 == 27 then -- esc
			DestroyTable(closedpos.t.t_id)
		end
		--par2 = 13 - enter
	end  
end 

--функция обрабатывает события окна таблицы контекстного меню
local f_cb_cntx = function( t_id,  msg,  par1, par2)
  
	if (msg==QTABLE_CLOSE)  then
		DestroyTable(t_id)
	end

	x=GetCell(t_id, par1, par2) 
  
	--if (msg==QTABLE_LBUTTONDBLCLK) then
	--чтобы работало как контекстное меню, будем ловить однократное нажатие левой кнопки 
	if msg==QTABLE_LBUTTONDOWN then

		local action = x["image"]
		
		--после выбора пункта меню нужно закрыть таблицу
		DestroyTable(t_id)
		
		--обработаем выбранное действие
		
		resultTable = actions:executeAction(action)
		
		--далее идет вторая часть кода обработки события. Однако, не всегда это необходимо. Первая часть - в файле TradeHistory_actions.lua, функция function Actions:executeAction(action)
		
		if action == 'Show details' and resultTable['details_t_id'] ~= nil then
		
			--для этого действия мы точно знаем, что функция вернет поле resultTable['details_t_id'], в котором будет лежать идентификатор (число) таблицы детализации позиции
			--повесим колбэк, чтобы таблица детальных записей закрывалась по ESC. к сожаление, это можно сделать только в главном скрипте, т.е. здесь.
			--в классе Actions вызов SetTableNotificationCallback (resultTable['details_t_id'], f_cb_details) не дает нужного эффекта, что, в общем-то, логично.
			
			SetTableNotificationCallback (resultTable['details_t_id'], f_cb_details)		
			
		end		
		
		
	elseif msg==QTABLE_VKEY then
		--message(par2)
		if par2 == 27 then -- esc
			DestroyTable(t_id)
		end
		--par2 = 13 - enter
	end  
end 


function recalc_details()
	--message('recalc details')
    for key, details_table in pairs(details.t) do
      if details_table~=nil then
        maintable:recalc_table(details_table)
      end    	
    end
end

-- +----------------------------------------------------+
--                  MAIN
-- +----------------------------------------------------+

-- функция обратного вызова для обработки событий в таблице. вызывается из main()
--(или, другими словами, обработчик клика по таблице робота)
--параметры:
--  t_id - хэндл таблицы, полученный функцией AllocTable()
--  msg - тип события, происшедшего в таблице
--  par1 и par2 – значения параметров определяются типом сообщения msg, 
--
--функция должна располагаться перед main(), иначе - скрипт не останавливается при закрытии окна
local f_cb = function( t_id,  msg,  par1, par2)
  
  if (msg==QTABLE_CLOSE)  then
    is_run = false
    DestroyTables()
  end
  
  --обработка клика
  
	--QLUA GetCell
	--Функция возвращает таблицу, содержащую данные из ячейки в строке с ключом «key», кодом колонки «code» в таблице «t_id». 
	--Формат вызова: 
	--TABLE GetCell(NUMBER t_id, NUMBER key, NUMBER code)
	--Параметры таблицы: 
	--image – строковое представление значения в ячейке, 
	--value – числовое значение ячейки.
	--Если входные параметры были заданы ошибочно, то возвращается «nil».  
	
	--при этом par1 содержит номер строки, par2 – номер колонки, 

	x=GetCell(maintable.t.t_id, par1, par2) 
  
	if (msg==QTABLE_LBUTTONDBLCLK) then
		--message(x["image"]) --текст ячейки
		--message("QTABLE_LBUTTONDBLCLK")
		
		--пусть по дабл клику открывается детализация позиции, т.е. разворот до сделок
		if par1 == 0 then
			--это даблклик на заголовке таблицы (строке с именами колонок). его не надо обрабатывать
			return
		end

		--если щелкнули на строку OPEN POSITIONS - нужно показать закрытые позиции
		if maintable.t:GetValue(par1,'dateOpen').image == 'OPEN'
			and maintable.t:GetValue(par1,'timeOpen').image == 'POSITIONS' then
			
			closedpos:load()
			
			--чтобы можно было закрыть окно с таблицей - повесим на него обработчик колбэков
			SetTableNotificationCallback (closedpos.t.t_id, f_cb_closed)
			
		else
		
			details.sec_code    = maintable.t:GetValue(par1,'secCode').image
			details.class_code  = maintable.t:GetValue(par1,'classCode').image
			details.account     = maintable.t:GetValue(par1,'account').image
			
			details:load()
			
			recalc_details()
			
			--чтобы можно было закрыть окно с таблицей - повесим на него обработчик колбэков
			SetTableNotificationCallback (details.t[details.key].t_id, f_cb_details)
			
		end
		
	elseif msg==QTABLE_VKEY then
		--message(par2)
		if par2 == 27 then-- esc
			is_run=false
			DestroyTables()
		end
		
	--par2 = 13 - enter
	
	
	elseif msg==QTABLE_RBUTTONUP then
		
		actions.account     	= maintable.t:GetValue(par1,'account').image
		actions.depo	     		= maintable.t:GetValue(par1,'depo').image	--счет Депо для ММВБ, например L01-00000F00. на ФОРТС не используется

		actions.sec_code    	= maintable.t:GetValue(par1,'secCode').image
		actions.class_code  	= maintable.t:GetValue(par1,'classCode').image
		
		actions.qty     		= maintable.t:GetValue(par1,'quantity').image
		actions.direction     	= maintable.t:GetValue(par1,'operation').image
		actions.comment		= maintable.t:GetValue(par1,'comment').image
 			
		actions:showContextMenu()
	
			--чтобы можно было закрыть окно контекстного меню - повесим на него обработчик колбэков
		SetTableNotificationCallback (actions.t.t_id, f_cb_cntx)
	
	

	
	end  

end 


-- основная функция робота. здесь обновляется котировка и рассчитывается прибыль
function main()

  --установим обработчик событий таблицы робота
  SetTableNotificationCallback (maintable.t.t_id, f_cb)

  --эта процедура помещает пропущенные сделки в фифо. сделки заполнять вручную! (в функции create_table_trades())
  --process_fifo_manual_deals()
  --process_fifo_manual_deals_from_table_deals()
  
  while is_run do  
    --обновим PnL в главной таблице
    maintable:recalc_table(maintable.t)
    --обновим PnL во всех открытых детальных таблицах
	recalc_details()
    sleep(1000)
  end
  
end



--импорт в фифо из таблицы сделок, сохраненных в текст


function create_table_trades()

--trades[ 11 ] ['flags'] = 64 --покупка
--trades[ 11 ] ['flags'] = 68 --продажа

local trades = {}

local num = 1

trades[num] = {}			
			trades[ num ] ['trade_num'] = 9999999			
			trades[ num ] ['order_num'] = 0		--число!	
			trades[ num ] ['brokerref'] = ''			
			trades[ num ] ['price'] = 59.325			
			trades[ num ] ['qty'] = 2			
			trades[ num ] ['value'] = 118650			
			trades[ num ] ['flags'] = 68			
			trades[ num ] ['client_code'] = '99221FX'			
			trades[ num ] ['trade_currency'] = 'SUR'			
			trades[ num ] ['sec_code'] = 'USD000UTSTOM'			
			trades[ num ] ['class_code'] = 'CETS'			
			trades[ num ] ['exchange_comission'] = 0			
			trades[ num ] ['trans_id'] = 0			
			trades[ num ] ['accruedint'] = 0			
			trades[ num ] ['datetime'] = {day=24, month=05,year=2018,hour=18,min=15,sec=19 }
			
			trades[ num ] ['operation'] = 'sell' --there are no that field in original trade table. 
			
			
	return trades			
end

--функция проводит по фифо сделки из таблицы, сохраненной в текст
function process_fifo_manual_deals()

	local trades = create_table_trades()

	--тут одна проблема останется. в фифо мы получаем стоимость шага цены вот так:
    --getParamEx (trade.class_code, trade.sec_code, 'STEPPRICE').param_value..
	--т.е. при загрузке пропущенных сделок он будет неверный. хотя, если грузить сделке вечерки следующим утром, то наверное он не поменяется... проверить бы
	--29 /11/ 16
	--стоимость шага = 
	--6.537830
	--RTS
	--13.075660
	--вгоню ее руками

	local i=0
	for key, trade in pairs ( trades ) do
		fifo:makeFifo(trade)
		i=i+1
		message(trade.trade_num..'-'..tostring(i))
		
	end		
end

--trades[ 11 ] ['flags'] = 64 --покупка
--trades[ 11 ] ['flags'] = 68 --продажа

function process_fifo_manual_deals_from_table_deals()

	local k = "'"
	local sql = 'SELECT *  FROM	deals WHERE date = '..k..'2017-05-10'..k ..' AND trade_num = 0000000000 ORDER BY trade_num'

	--тут одна проблема останется. в фифо мы получаем стоимость шага цены вот так:
    --getParamEx (trade.class_code, trade.sec_code, 'STEPPRICE').param_value..
	--т.е. при загрузке пропущенных сделок он будет неверный. хотя, если грузить сделке вечерки следующим утром, то наверное он не поменяется... проверить бы
	--29 /11/ 16
	--стоимость шага = 
	--6.537830
	--RTS
	--13.075660
	--вгоню ее руками

	local i=1
	for row in fifo.db:nrows(sql) do 
	
		row.datetime = {['day']=10, ['month']=5, ['year']=2017, ['hour']=10, ['min']=10, ['sec']=10}
		row.brokerref = ''
		
		fifo:makeFifo(row)
		i=i+1
		message(row.trade_num..'-'..tostring(i))
		
	end		
end

