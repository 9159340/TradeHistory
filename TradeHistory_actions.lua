--operations with context menu

details={}

Actions = class(function(acc)
end)

function Actions:Init()
  self.t = nil --ID of table. в этой таблице будем показывать действия. аналог контекстного меню
  
  --в эти свойства передаем значения из выб
			self.account     	= nil
			self.depo	     	= nil	--счет Депо для ММВБ, например L01-00000F00. на ФОРТС не используется
			
			self.sec_code    	= nil
			self.class_code  	= nil
			
			self.qty     			= nil
			self.direction     	= nil
			self.comment		= nil
 
 	details= Details()
	details:Init()
	
	self.resultTable = nil
end


 
--clean main table
function Actions:clearTable()

  for row = self.t:GetSize(self.t.t_id), 1, -1 do
    DeleteRow(self.t.t_id, row)
  end  
  
end

-- SHOW MAIN TABLE

--show main table on screen
function Actions:showTable()

  self.t:Show()
  
end


--creates main table
function Actions:createTable()

  -- create instance of table
  local t = QTable.new()
  if not t then
    message("error!", 3)
    return
  else
    --message("table with id = " ..t.t_id .. " created", 1)
  end
  
  
  t:AddColumn("action",    QTABLE_STRING_TYPE, 40)  
  t:SetCaption('context menu: '..self.account ..' - '..self.sec_code .. ' - ' .. self.direction)
  
  return t
  
end

--создает собственный экземпляр таблицы класса, не глобальный
function Actions:createOwnTable()

	self.t = self:createTable()
	
end

function Actions:kill(t_id)

	if t_id~=nil then
		DestroyTable(t_id)
	else
		DestroyTable(self.t.t_id)
	end
  
end

function Actions:addActions()


  local r = self.t:AddLine()
  --заголовок открытых позиций
  --message(r)
  self.t:SetValue(r, 'action', "Close position")

  r = self.t:AddLine()
  self.t:SetValue(r, 'action', "Revert position")
  
  r = self.t:AddLine()
  self.t:SetValue(r, 'action', "Set stop-loss")

  r = self.t:AddLine()
  self.t:SetValue(r, 'action', "Set take-profit")
  
  r = self.t:AddLine()
  self.t:SetValue(r, 'action', "Buy 1 lot")
  
  r = self.t:AddLine()
  self.t:SetValue(r, 'action', "Sell 1 lot")
  
  r = self.t:AddLine()
  self.t:SetValue(r, 'action', "Show details")

  r = self.t:AddLine()
  self.t:SetValue(r, 'action', "Hide position")
  
  r = self.t:AddLine()
  self.t:SetValue(r, 'action', "---------------------")

  r = self.t:AddLine()
  self.t:SetValue(r, 'action', "Show trades of current session")
  
end


--главная функция класса. создает и показывает меню
function Actions:showContextMenu()
	
	self:createOwnTable()
	
	self:showTable()
	
	--строки можно добавлять только после отображения таблицы!
	self:addActions()
		
end

function Actions:executeAction(action)

	--будем возвращать таблицу, для каждого действия там будут свои поля, которые будем проверять в месте вызова данной функции
	self.resultTable = {}

	--message(action)
	if action == 'Show details' then
	
		--здесь только часть кода обработки данного события, еще часть - в файле TradeHistory.lua, функция local f_cb_cntx = function( t_id,  msg,  par1, par2)
		details.sec_code    = self.sec_code
		details.class_code  = self.class_code
		details.account     = self.account
		
		details:load()
		
		recalc_details()
		
		--на этот t_id снаружи повесим колбэк, чтобы по ESC можно было закрыть
		self.resultTable['details_t_id'] = details.t[details.key].t_id
	
	elseif action == 'Show trades of current session' then
	
		local res = self:ShowTradesOfCurrentSession()
		
		--в таблице res должно быть поле с ИД таблицы. на нее нужно повесить колбэк
		self.resultTable['trades_t_id'] = res['t_id']
		
	else
	
		--message('DUMMY. This action is being under construction')
		
	end
	
	

end

function Actions:ShowTradesOfCurrentSession()

	local res = {}
	
	local rowCount = getNumberOf('trades')
	local i = 1

	while i <= rowCount do
		
		i=i+1
	end 	
	
--[[
Описание параметров Таблицы сделок: 

Параметр 	Тип 		Описание 
trade_num 	NUMBER Номер сделки в торговой системе 
order_num  NUMBER  Номер заявки в торговой системе  
brokerref  	STRING  Комментарий, обычно: <код клиента>/<номер поручения>  
userid  		STRING  Идентификатор трейдера  
firmid  		STRING  Идентификатор дилера  
account  	STRING  Торговый счет  
price  		NUMBER  Цена  
qty  			NUMBER  Количество бумаг в последней сделке в лотах  
value  		NUMBER  Объем в денежных средствах  
accruedint  NUMBER  Накопленный купонный доход  
yield  		NUMBER  Доходность  
settlecode  STRING  Код расчетов  
cpfirmid  	STRING  Код фирмы партнера  
flags  		NUMBER  Набор битовых флагов  
price2  		NUMBER  Цена выкупа  
reporate  	NUMBER  Ставка РЕПО (%)  
client_code  STRING  Код клиента  
accrued2  	NUMBER  Доход (%) на дату выкупа  
repoterm  	NUMBER  Срок РЕПО, в календарных днях  
repovalue  	NUMBER  Сумма РЕПО  
repo2value  NUMBER  Объем выкупа РЕПО  
start_discount  			NUMBER  Начальный дисконт (%)  
lower_discount  			NUMBER  Нижний дисконт (%)  
upper_discount  			NUMBER  Верхний дисконт (%)  
block_securities  			NUMBER  Блокировка обеспечения («Да»/«Нет»)  
clearing_comission  		NUMBER  Клиринговая комиссия (ММВБ)  
exchange_comission  	NUMBER  Комиссия Фондовой биржи (ММВБ)  
tech_center_comission  NUMBER  Комиссия Технического центра (ММВБ)  
settle_date  				NUMBER  Дата расчетов  
settle_currency  			STRING  Валюта расчетов  
trade_currency  			STRING  Валюта  
exchange_code  			STRING  Код биржи в торговой системе  
station_id  					STRING  Идентификатор рабочей станции  
sec_code  					STRING  Код бумаги заявки  
class_code  				STRING  Код класса  
datetime  					TABLE  Дата и время  
bank_acc_id  				STRING  Идентификатор расчетного счета/кода в клиринговой организации  
broker_comission  		NUMBER  Комиссия брокера. Отображается с точностью до 2 двух знаков. Поле зарезервировано для будущего использования.  
linked_trade  				NUMBER  Номер витринной сделки в Торговой Системе для сделок РЕПО с ЦК и SWAP  
period  						NUMBER  Период торговой сессии. Возможные значения: 

«0» – Открытие; 
«1» – Нормальный; 
«2» – Закрытие 
 
trans_id 					NUMBER  Идентификатор транзакции 
kind  							NUMBER  Тип сделки. Возможные значения:

«1» – Обычная; 
«2» – Адресная; 
«3» – Первичное размещение; 
«4» – Перевод денег/бумаг; 
«5» – Адресная сделка первой части РЕПО; 
«6» – Расчетная по операции своп; 
«7» – Расчетная по внебиржевой операции своп; 
«8» – Расчетная сделка бивалютной корзины; 
«9» – Расчетная внебиржевая сделка бивалютной корзины; 
«10» – Сделка по операции РЕПО с ЦК; 
«11» – Первая часть сделки по операции РЕПО с ЦК; 
«12» – Вторая часть сделки по операции РЕПО с ЦК; 
«13» – Адресная сделка по операции РЕПО с ЦК; 
«14» – Первая часть адресной сделки по операции РЕПО с ЦК; 
«15» – Вторая часть адресной сделки по операции РЕПО с ЦК; 
«16» – Техническая сделка по возврату активов РЕПО с ЦК; 
«17» – Сделка по спреду между фьючерсами разных сроков на один актив; 
«18» – Техническая сделка первой части от спреда между фьючерсами; 
«19» – Техническая сделка второй части от спреда между фьючерсами; 
«20» – Адресная сделка первой части РЕПО с корзиной; 
«21» – Адресная сделка второй части РЕПО с корзиной; 
«22» – Перенос позиций срочного рынка 
 
clearing_bank_accid 	STRING Идентификатор счета в НКЦ (расчетный код) 
canceled_datetime 		TABLE Дата и время снятия сделки 
clearing_firmid 			STRING Идентификатор фирмы - участника клиринга 
system_ref 				STRING Дополнительная информация по сделке, передаваемая торговой системой 
uid 							NUMBER Идентификатор пользователя на сервере QUIK 

--]]	
	
	return res
	
end

