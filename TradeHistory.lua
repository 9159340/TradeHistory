--����������� ���� �������� �������

--Features.
--1. �� �������� ����� ��� ����������� ���������� �� ���������� � ��������� "������", �.�. TOM
--		������� - � TOM ���� �����������; ��� ���������� ���� ����, � TOD ������ �� ������������� �������
--		���� ����������� ������ ��� USDRUB_TOD
--		������ ����������� �������� substitute_sec_code() � ������ fifo
--
--2. 


local sqlite3 = require("lsqlite3")
--��� dll ����� ��� ������ � �������� ������� ������. ��� ������ ����������� buy/sell
local bit = require"bit"

--������ �� �������� �� QLUA
dofile (getScriptPath() .. "\\quik_table_wrapper.lua")
--������
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

--�������� ������������ ����
dofile (getScriptPath() .. "\\TradeHistory_actions.lua")
--��� �� ������� ������������ ����, ������� ����� �������
--����� ����� ����� ��� ����, ����� ������ ����������� ���������:
--"������ �������� DestroyTable �� ������� ��������� ������� ���� �� �������"!
--����� ���� ���� ����������� ������, ����� ��������� ��������� ����� � ������� �����.
id_context_to_kill = nil
--�������� ������������ ���� �����


--[[
������ ������� �� sqlite, ������� �� ���� � ������� PnL �� ������� ���������
� ������� � � ������. ����� ��������� �����, ����� �������� ��������� ���� ����
]]



-- ������
settings={}
helper={}
recalc={}
fifo={}
details={}
maintable={} --maintable.t - ������� ������� ������
closedpos={} --����� ��� ����������� ������� �������� �������
deals={}
actions={} --����������� ����

-- ��������� --
-- ���������� ���������� --


--�������, � ������� ����� ������� �� ������, ������� ��� ���������� � OnTrade()
--�������� � ���, ��� OnTrade() ���������� ����� ������ ���� ��� �������� ������ � ���������,
--������� ���� ���������, ��� �� ������ ��� ����������, ����� �� �������� ����� � �������.
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

--  ����������� ������ �� ���� � ������� ������

--��������� ���� ������ � �������� �������
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
	maintable.t:SetValue(row, 'quantity', tostring(sqliteRow.qty)) --��� spot ��� ����� �����, ��� ����� - ��-�������, 
	maintable.t:SetValue(row, 'amount', tostring(sqliteRow.value))
	maintable.t:SetValue(row, 'priceOpen', tostring(sqliteRow.price))
	maintable.t:SetValue(row, 'dateClose', '')
	maintable.t:SetValue(row, 'timeClose', '')
	maintable.t:SetValue(row, 'priceClose', tostring(sqliteRow.price))
	maintable.t:SetValue(row, 'qtyClose', tostring(sqliteRow.qty))    --������� �� �� ����������, ��� � � �������.
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
	
	--������� ��� �������
	local optionType = getParamEx(sqliteRow.dim_class_code, sqliteRow.dim_sec_code, 'optiontype')
	if optionType ~= nil then
		optionType = optionType.param_image
	else
		optionType = ''
	end
	
	maintable.t:SetValue(row, 'optionType', optionType)
	
	--������� ���� ���� �������
	local theorprice = getParamEx(sqliteRow.dim_class_code, sqliteRow.dim_sec_code, 'theorprice')
	if theorprice ~= nil then
		theorprice = theorprice.param_image
	else
		theorprice = ''
	end
	
	maintable.t:SetValue(row, 'theorPrice', theorprice)	
	
	--show date of expiration
	local expiration = getParamEx(sqliteRow.dim_class_code, sqliteRow.dim_sec_code, 'expdate')
	if expiration ~= nil then
		expiration = expiration.param_image
	else
		expiration = ''
	end
	
	maintable.t:SetValue(row, 'expiration', tostring(expiration))	
	
end

-- adds row with totals after a class
local function addTotalRow()
	
	local row = maintable.t:AddLine()
	maintable.t:SetValue(row, 'secCode', 'TOTAL')

end

--adds row for totals with all clients accounts within one class
local function addGrandTotalRow()
	
	local row = maintable.t:AddLine()
	maintable.t:SetValue(row, 'secCode', 'GRAND TOTAL')

end

--load open positions from sqlite database
function load_OPEN_Positions()

	maintable:clearTable()
	
  local r = maintable.t:AddLine()

  --row with header
  
  maintable.t:SetValue(r, 'dateOpen', "OPEN")
  maintable.t:SetValue(r, 'timeOpen', "POSITIONS")
	
  maintable.t:SetValue(r, 'dateClose', "Click")
  maintable.t:SetValue(r, 'timeClose', "here")
  maintable.t:SetValue(r, 'priceClose', "to")
  maintable.t:SetValue(r, 'qtyClose', "show")
  maintable.t:SetValue(r, 'profitpt', "CLOSED")
  maintable.t:SetValue(r, 'profit %', "POSITIONS")
  colorizer:colorize_class(maintable.t, r)
  
  --get the table with positions from fifo
  
  --if self.groupByClass = true then we need to group row by class codes
 
	local newRow = nil
	
	if settings.groupByClass  == true then
	
		--read class visibility settings from table and show positions according to visibility
		local class_count = 1
		while class_count <= table.maxn(settings.filter_by_class) do
		
			local class_code_to_show = settings.filter_by_class[class_count]['class']
			
			local allow_show_class = settings.filter_by_class[class_count]['show']
			
			class_count = class_count + 1
			
			newRow = maintable.t:AddLine()
			maintable.t:SetValue(newRow, 'secCode', class_code_to_show)--��������� ������ � ������ ������ (���� �������)
			colorizer:colorize_class(maintable.t, newRow)
			
			if allow_show_class == true then
			
				local total_profit = 0
				
				local r_count = 1
				local vt, forts_totals = fifo:readOpenFifoPositions_ver2(nil, class_code_to_show, nil, false, maintable.totals_t)

				--next 2 vars are purposed to track if the class has been changed
				local last_key = ''
				local current_key = ''

				local table_size = table.maxn(vt)
				--message('class_code_to_show '.. class_code_to_show ..', table_size = ' .. tostring(table_size) )
				
				local keysCounter = 1

				while r_count <= table_size do
					
					current_key = getCurrentRowKey( vt[r_count] )

					--message(tostring(r_count) .. vt[r_count].dim_class_code .. ' current key ' ..current_key)

					addRowFromFIFO(vt[r_count])

					last_key = current_key

					r_count = r_count + 1 
					
					if r_count > table_size then
						addTotalRow()
						do break end
					end

					if last_key ~= getCurrentRowKey( vt[r_count] ) then
						--add totals row
						
						addTotalRow()
						current_key = getCurrentRowKey( vt[r_count] )
						keysCounter = keysCounter + 1
					end	
					
				end 
			
				if keysCounter > 1 then
					--message ('grand')
					addGrandTotalRow()
				end

				--empty row as delimiter
				newRow = maintable.t:AddLine()

			end
			
		end

	else
	  
		local vt, forts_totals = fifo:readOpenFifoPositions_ver2() --module TradeHistory_FIFO.lua

		local r_count = 1

		while r_count <= table.maxn(vt) do
			addRowFromFIFO(vt[r_count])
			r_count = r_count + 1 
		end 
		
		addTotalRow()	

	end

	maintable:recalc_table(maintable.t, maintable.totals_t)


end

-- returns string like that: '714547-SPBOPT'
function getCurrentRowKey(row)
	return row.dim_client_code .. '-' .. row.dim_class_code
end




-- event's handlers ----

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
	maintable:createTotalsTable()
	maintable:showTable()

    load_OPEN_Positions()
    
end


function DestroyTables()

  --kill details tables (if exists)
  for key, details_table in pairs(details.t) do
    
    if details_table~=nil then
      DestroyTable(details_table.t_id)
    end     
  end
  --kill closed positions tables (if exists)
  if closedpos.t~=nil then
	DestroyTable(closedpos.t.t_id)
  end
  
	--kill main table
	DestroyTable(maintable.t.t_id)
  
	--10/05/17 context menu has been added
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
		
		--dont change sequence!
    
		--add info about security into 'securities' table
		fifo:saveSecurityInfo(trade.sec_code, trade.class_code)
		
		--post trade to fifo
		fifo:makeFifo(trade)
		
	end

  --refill robot's main table	
	
	load_OPEN_Positions()
	
end

-- +----------------------------------------------------+
--                  DETAILS
-- +----------------------------------------------------+

--closes details table window. press red cross or ESC
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

-- +----------------------------------------------------+
--                  CLOSED POSITIONS
-- +----------------------------------------------------+

--������� ��������� ���� ������� �������� ������. �� ������� ������ � ������ ESC
local f_cb_closed = function( t_id,  msg,  par1, par2)
	--closes closed trades table window. press red cross or ESC
	if msg==QTABLE_CLOSE  then
		DestroyTable(closedpos.t.t_id)
	elseif msg==QTABLE_VKEY then
		--message(par2)
		if par2 == 27 then -- esc
			DestroyTable(closedpos.t.t_id)
		end
		--par2 = 13 - enter
	end  
end 


-- +----------------------------------------------------+
--                  ACTIONS
-- +----------------------------------------------------+

local f_cb_cntx = function( t_id,  msg,  par1, par2)
	--*������� ������������ ������� ���� ������� ������������ ����

	if (msg==QTABLE_CLOSE)  then
		--DestroyTable(t_id)
		actions:kill()
	end

	x=GetCell(t_id, par1, par2) 
  
	--if (msg==QTABLE_LBUTTONDBLCLK) then
	--����� �������� ��� ����������� ����, ����� ������ ����������� ������� ����� ������ 
	if msg==QTABLE_LBUTTONDOWN then

		local action = x["image"]
		
		--���������� ��������� ��������
		actions:executeAction(action)
		
		--����� ���� ������ ����� ���� ��������� �������. ������, �� ������ ��� ����������. ������ ����� - � ����� TradeHistory_actions.lua, ������� function Actions:executeAction(action)
		if action == 'Show details' and actions.resultTable ~= nil and actions.resultTable['details_t_id'] ~= nil then
		
			--��� ����� �������� �� ����� �����, ��� ������� ������ ���� resultTable['details_t_id'], � ������� ����� ������ ������������� (�����) ������� ����������� �������
			--������� ������, ����� ������� ��������� ������� ����������� �� ESC. � ���������, ��� ����� ������� ������ � ������� �������, �.�. �����.
			--� ������ Actions ����� SetTableNotificationCallback (resultTable['details_t_id'], f_cb_details) �� ���� ������� �������, ���, � �����-��, �������.
			
			SetTableNotificationCallback (actions.resultTable['details_t_id'], f_cb_details)		
			
		end		
		
		--����� ������ ������ ���� ����� ������� �������
		--��� ������ ������!
		--DestroyTable(t_id)
		--actions:kill()
		--������� ������ � �������� �����
		id_context_to_kill = t_id
		
	elseif msg==QTABLE_VKEY then
		--message(par2)
		if par2 == 27 then -- esc
			--DestroyTable(t_id)
			actions:kill()
		end
		--par2 = 13 - enter
	end  
end 


-- +----------------------------------------------------+
--                  MAIN
-- +----------------------------------------------------+

-- ������� ��������� ������ ��� ��������� ������� � �������. ���������� �� main()
--(���, ������� �������, ���������� ����� �� ������� ������)
--���������:
--  t_id - ����� �������, ���������� �������� AllocTable()
--  msg - ��� �������, ������������ � �������
--  par1 � par2 � �������� ���������� ������������ ����� ��������� msg, 
--
--������� ������ ������������� ����� main(), ����� - ������ �� ��������������� ��� �������� ����
local f_cb = function( t_id,  msg,  par1, par2)
  --*������� ������ ������������� ����� main(), ����� - ������ �� ��������������� ��� �������� ���� (���������)
  if (msg==QTABLE_CLOSE)  then
    is_run = false
    DestroyTables()
  end
  
  --��������� �����
  
	--QLUA GetCell
	--������� ���������� �������, ���������� ������ �� ������ � ������ � ������ �key�, ����� ������� �code� � ������� �t_id�. 
	--������ ������: 
	--TABLE GetCell(NUMBER t_id, NUMBER key, NUMBER code)
	--��������� �������: 
	--image � ��������� ������������� �������� � ������, 
	--value � �������� �������� ������.
	--���� ������� ��������� ���� ������ ��������, �� ������������ �nil�.  
	
	--��� ���� par1 �������� ����� ������, par2 � ����� �������, 

	x=GetCell(maintable.t.t_id, par1, par2) 
  
	if (msg==QTABLE_LBUTTONDBLCLK) then
		--message(x["image"]) --����� ������
		--message("QTABLE_LBUTTONDBLCLK")
		
		--����� �� ���� ����� ����������� ����������� �������, �.�. �������� �� ������
		if par1 == 0 then
			--��� �������� �� ��������� ������� (������ � ������� �������). ��� �� ���� ������������
			return
		end

		--���� �������� �� ������ CLOSED POSITIONS - ����� �������� �������� �������
		if maintable.t:GetValue(par1,'profitpt').image == 'CLOSED'
			 and maintable.t:GetValue(par1,'profit %').image == 'POSITIONS' then
			
			closedpos:load()
			
			--����� ����� ���� ������� ���� � �������� - ������� �� ���� ���������� ��������
			SetTableNotificationCallback (closedpos.t.t_id, f_cb_closed)
			
	
		else
		
			details.sec_code    = maintable.t:GetValue(par1,'secCode').image
			details.class_code  = maintable.t:GetValue(par1,'classCode').image
			details.account     = maintable.t:GetValue(par1,'account').image
			
			details:load()
			
			details:recalc_details()
			
			--����� ����� ���� ������� ���� � �������� - ������� �� ���� ���������� ��������
			SetTableNotificationCallback (details.t[details.key].t_id, f_cb_details)
			
		end
	
	elseif msg==QTABLE_LBUTTONUP then
		
		--��� ������� ����� ������ ���� � ������ � ������ ������ ����� ����������� �������/����������� ������� ����� ������
		local cell = maintable.t:GetValue(par1,'secCode')
		if cell == nil then
			message('nil')
		end
		local class_code = cell.image
		if class_code == 'TQBR' 
		or class_code == 'CETS'
		or class_code == 'SPBFUT'
		or class_code == 'SPBOPT'
		or class_code == 'EQOB'
		or class_code == 'TQOB'
		or class_code == 'TQDE'
		or class_code == 'TQTF'
		then
			-- collapse/expand content of the class (positions) on the left mouse btn click
			local class_row = settings:getRowFromFilterByClassByCode( class_code )
			if class_row['show'] == false then
				class_row['show'] = true
			elseif class_row['show'] == true then
				class_row['show'] = false
			end
			load_OPEN_Positions()
		end
		
	elseif msg==QTABLE_VKEY then

		if par2 == 27 then-- esc
			is_run=false
			DestroyTables()
		end
		
	--par2 = 13 - enter
	
	elseif msg==QTABLE_RBUTTONUP then
		
		actions.account     	= maintable.t:GetValue(par1,'account').image
		actions.depo	     	= maintable.t:GetValue(par1,'depo').image	--���� ���� ��� ����, �������� L01-00000F00. �� ����� �� ������������

		actions.sec_code    	= maintable.t:GetValue(par1,'secCode').image
		actions.class_code  	= maintable.t:GetValue(par1,'classCode').image
		
		actions.qty     		= maintable.t:GetValue(par1,'quantity').image
		actions.direction     	= maintable.t:GetValue(par1,'operation').image
		actions.comment			= maintable.t:GetValue(par1,'comment').image
 			
		actions:showContextMenu()
	
		--����� ����� ���� ������� ���� ������������ ���� - ������� �� ���� ���������� ��������
		SetTableNotificationCallback (actions.t.t_id, f_cb_cntx)
		
	end  

end 


-- �������� ������� ������. ����� ����������� ��������� � �������������� �������
function main()

  --��������� ���������� ������� ������� ������
  SetTableNotificationCallback (maintable.t.t_id, f_cb)

  --��� ��������� �������� ����������� ������ � ����. ������ ��������� �������! (� ������� create_table_trades())
  --process_fifo_manual_deals()
  
  --pro_cess_fifo_manual_deals_from_table_deals() --��� �����-�� ������� ����������� ����
  
  while is_run do  
    --������� PnL � ������� �������
    maintable:recalc_table(maintable.t, maintable.totals_t)
    --������� PnL �� ���� �������� ��������� ��������
	details:recalc_details()
	--�������� ������������ ����
	if id_context_to_kill ~= nil then
		actions:kill(id_context_to_kill)
		id_context_to_kill = nil
	end
    sleep(1000)
  end
  
end



--import manual trades to fifo

--creates manual table
function create_table_trades()

	--trades[ 11 ] ['flags'] = 64 --buy
	--trades[ 11 ] ['flags'] = 68 --sell

	local trades = {}

	local num = 1

	trades[ num]  = {}			
	trades[ num ] ['trade_num'] 			= 9997			--decimal
	trades[ num ] ['order_num'] 			= 0				--decimal
	trades[ num ] ['brokerref'] 			= ''			--do not fill
	trades[ num ] ['price'] 				= 61.96 		--decimal
	trades[ num ] ['qty'] 					= 1				--decimal
	trades[ num ] ['value'] 				= 61960			--decimal
	trades[ num ] ['flags'] 				= 68			--decimal 64 buy/ 68 sell
	trades[ num ] ['client_code'] 			= 'asf'
	trades[ num ] ['trade_currency'] 		= 'SUR'			
	trades[ num ] ['sec_code'] 				= 'asf'			
	trades[ num ] ['class_code'] 			= 'CETS'			
	trades[ num ] ['exchange_comission'] 	= 0				--decimal
	trades[ num ] ['trans_id'] 				= 0				--decimal
	trades[ num ] ['accruedint'] 			= 0				--decimal
	trades[ num ] ['datetime'] 				= {day=25, month=10,year=2018,hour=10,min=00,sec=07 }
	trades[ num ] ['operation'] 			= 'sell' 		--this field is not present in original trade table. 
	trades[ num ] ['account'] 				= 'asdf'		--string, depo code
	
	
	
	return trades			
end

--������� �������� �� ���� ������������� ������ �� �������. ��. ������� create_table_trades()
function process_fifo_manual_deals()

	local trades = create_table_trades()
	
	--��� ���� �������� ���������. � ���� �� �������� ��������� ���� ���� ��� ���:
    --getParamEx (trade.class_code, trade.sec_code, 'STEPPRICE').param_value..
	--�.�. ��� �������� ����������� ������ �� ����� ��������. ����, ���� ������� ������ ������� ��������� �����, �� �������� �� �� ����������... ��������� ��
	--29 /11/ 16
	--��������� ���� = 
	--6.537830
	--RTS
	--13.075660
	--����� �� ������

	local i=0
	for key, trade in pairs ( trades ) do
		fifo:makeFifo(trade)
		i=i+1
		message(tostring(i)..' trade has been processed. # ' .. trade.trade_num)
	end		
end

--trades[ 11 ] ['flags'] = 64 --�������
--trades[ 11 ] ['flags'] = 68 --�������

--�������� �� ���� ������, ������� ��� ���� � ����. ����� ���� �� ������������
function pro_cess_fifo_manual_deals_from_table_deals()

	local k = "'"
	local sql = 'SELECT *  FROM	deals WHERE date = '..k..'2017-05-10'..k ..' AND trade_num = 0000000000 ORDER BY trade_num'

	local i=1
	for row in fifo.db:nrows(sql) do 
	
		row.datetime = {['day']=10, ['month']=5, ['year']=2017, ['hour']=10, ['min']=10, ['sec']=10}
		row.brokerref = ''
		
		fifo:makeFifo(row)
		i=i+1
		message(row.trade_num..'-'..tostring(i))
		
	end		
end

