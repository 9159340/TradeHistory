--класс сохраняет все сделки в таблицу deals и заодно определяет, есть там сделка или нет, чтобы понять, что она уже обработана
helper = {}
settings = {}
fifo = {}
Deals = class(function(acc)
end)

function Deals:Init()

  helper=Helper()
  helper:Init()
  
  settings=Settings()
  settings:Init()
  
	fifo= FIFO()
	fifo:Init()  
  
end


--returns True if deal is not present in our database
function Deals:deal_is_not_processed(trade)
	local k = "'"
--here we are cheking deal presence in SQLite database (table "deals")

	local sql = 'select trade_num from deals where date = '.. k..helper:get_trade_date_sql(trade)..k .. ' and trade_num='..tostring(trade.trade_num)
	
	local r_count = 0
	for row in fifo.db:nrows(sql) do 
		r_count = r_count + 1
	end
	
	if r_count==0 then
		return true
	else
		return false
	end
end

function Deals:insertTradeToDB(trade, robot_id)

--message(trade.trade_num)
	local k="'" --quote symbol
	
         --         k..helper:get_trade_date_sql(trade)..k..','..
         --         k..helper:get_trade_time(trade)..k..','..
				  
				  
	local direction = fifo:what_is_the_direction(trade) --buy/sell
	
	local sql=

	[[	insert into deals

	( --all fields except 'rownum' because rownum is autoincrement
		
		trade_num 
		 
		--my fields (not present in object 'trade')
		,date          
		,time          
		,robot_id      
		,canceled_date 
		,canceled_time 
		,direction  
		--end of my fields
		 
		,order_num  
		,brokerref  
		,userid     
		,firmid     
		,account    
		,price      
		,qty        
		,value      
		,accruedint 
		,yield      
		,settlecode 
		,cpfirmid  
		,flags            
		,price2           
		,reporate         
		,client_code      
		,accrued2         
		,repoterm         
		,repovalue         
		,repo2value       
		,start_discount   
		,lower_discount   
		,upper_discount   
		,block_securities   
		,clearing_comission 
		,exchange_comission   
		,tech_center_comission 
		,settle_date       
		,settle_currency   
		,trade_currency    
		,exchange_code     
		,station_id                
		,sec_code                  
		,class_code   

		,bank_acc_id  
		,broker_comission 
		,linked_trade
		,period 
		,trans_id
		,kind 
		 
		,clearing_bank_accid  
		,clearing_firmid,system_ref
		,uid
	
	)
	
	VALUES 
	
	(
			
		--Parameter 	Type	 Descr
		 
		]]..tostring(trade.trade_num)..[[   --                    REAL --Номер сделки в торговой системе
		 
		--мои поля

		,]]..k..helper:get_trade_date_sql(trade)..k..[[--     TEXT      --            получаем из таблицы datetime, наверное сразу в виде гггг-мм-дд
		,]]..k..helper:get_trade_time(trade)..k..[[--           TEXT -- получаем из таблицы datetime
		,]]..k..robot_id..k..[[--							              TEXT -- наверное, будем заполнять потом, т.к. пока непонятно, как это делать в событии OnTrade() да надо ли это делать там?
		,]]..k..k..[[--,canceled_date 	--	TEXT -- получаем из таблицы canceled_datetime
		,]]..k..k..[[--,canceled_time 	--	TEXT -- получаем из таблицы canceled_datetime
		,]]..k..direction..k.. [[           --	TEXT --buy/sell
		--мои поля конец
		 
		,]]..tostring(trade.order_num)..[[--       		REAL  --Номер заявки в торговой системе 
		,]]..k..trade.brokerref..k..[[--                      	STRING  --Комментарий, обычно: <код клиента>/<номер поручения> 
		,]]..k..trade.userid..k..[[--                          	TEXT  --Идентификатор трейдера 
		,]]..k..trade.firmid..k..[[--                           	TEXT  --Идентификатор дилера 
		,]]..k..trade.account..k..[[--                       	TEXT  --Торговый счет 
		,]]..tostring(trade.price)..[[--                   	REAL  --Цена 
		,]]..tostring(trade.qty)..[[--                     	REAL  --Количество бумаг в последней сделке в лотах 
		,]]..tostring(trade.value)..[[--                  	REAL  --Объем в денежных средствах 
		,]]..tostring(trade.accruedint)..[[--         	REAL  --Накопленный купонный доход 
		,]]..tostring(trade.yield)..[[--                     REAL  --Доходность 
		,]]..k..trade.settlecode..k..[[--       				TEXT  --Код расчетов 
		,]]..k..trade.cpfirmid..k..[[--                             TEXT -- Код фирмы партнера 
		,]]..tostring(trade.flags)..[[--                                    REAL  --Набор битовых флагов 
		,]]..tostring(trade.price2)..[[--                                                 REAL  --Цена выкупа 
		,]]..tostring(trade.reporate)..[[--                            REAL  --Ставка РЕПО (%) 
		,]]..k..trade.client_code..k..[[--      TEXT  --Код клиента 
		,]]..tostring(trade.accrued2)..[[--                           REAL  --Доход (%) на дату выкупа 
		,]]..tostring(trade.repoterm)..[[--                          REAL  --Срок РЕПО, в календарных днях 
		,]]..tostring(trade.repovalue)..[[--                         REAL  --Сумма РЕПО 
		,]]..tostring(trade.repo2value)..[[--       REAL  --Объем выкупа РЕПО 
		,]]..tostring(trade.start_discount)..[[--                                                REAL  --Начальный дисконт (%) 
		,]]..tostring(trade.lower_discount)..[[--                                             REAL  --Нижний дисконт (%) 
		,]]..tostring(trade.upper_discount)..[[--                                             REAL  --Верхний дисконт (%) 
		,]]..tostring(trade.block_securities)..[[--                                            REAL  --Блокировка обеспечения («Да»/«Нет») 
		,]]..tostring(trade.clearing_comission)..[[--                       REAL  --Клиринговая комиссия (ММВБ) 
		,]]..tostring(trade.exchange_comission)..[[--   REAL  --Комиссия Фондовой биржи (ММВБ) 
		,]]..tostring(trade.tech_center_comission)..[[--  REAL  --Комиссия Технического центра (ММВБ) 
		,]]..tostring(trade.settle_date)..[[--                      TEXT  --Дата расчетов  (приходит тип NUMBER)
		,]]..k..trade.settle_currency..k..[[--              TEXT  --Валюта расчетов 
		,]]..k..trade.trade_currency..k..[[--              TEXT -- Валюта 
		,]]..k..trade.exchange_code..k..[[--             TEXT  --Код биржи в торговой системе 
		,]]..k..trade.station_id..k..[[--                                         TEXT  --Идентификатор рабочей станции 
		,]]..k..trade.sec_code..k..[[--                                          TEXT  --Код бумаги заявки 
		,]]..k..trade.class_code..k..[[--                        TEXT  --Код класса 
		--,datetime..--                                       TABLE  --Дата и время 
		,]]..k..trade.bank_acc_id..k..[[--                    TEXT  --Идентификатор расчетного счета/кода в клиринговой организации 
		,]]..tostring(trade.broker_comission)..[[--  REAL  --Комиссия брокера. Отображается с точностью до 2 двух знаков. Поле зарезервировано для будущего использования. 
		,]]..tostring(trade.linked_trade)..[[--                    REAL -- Номер витринной сделки в Торговой Системе для сделок РЕПО с ЦК и SWAP 
		,]]..tostring(trade.period)..[[--                                                                INTEGER  --Период торговой сессии. Возможные значения:
		 
		--«0» – Открытие;
		--«1» – Нормальный;
		--«2» – Закрытие
		 
		,]]..tostring(trade.trans_id)..[[--                                             REAL  --Идентификатор транзакции -- ПОЛЬЗОВАТЕЛЬСКИЙ!!!!! при программном создании , чтобы потом можно было отловить
		,]]..tostring(trade.kind)..[[--                                                                    INTEGER  --Тип сделки. Возможные значения:
		 
		--«1» – Обычная;
		--«2» – Адресная;
		--«3» – Первичное размещение;
		--«4» – Перевод денег/бумаг;
		--«5» – Адресная сделка первой части РЕПО;
		--«6» – Расчетная по операции своп;
		--«7» – Расчетная по внебиржевой операции своп;
		--«8» – Расчетная сделка бивалютной корзины;
		--«9» – Расчетная внебиржевая сделка бивалютной корзины;
		--«10» – Сделка по операции РЕПО с ЦК;
		--«11» – Первая часть сделки по операции РЕПО с ЦК;
		--«12» – Вторая часть сделки по операции РЕПО с ЦК;
		--«13» – Адресная сделка по операции РЕПО с ЦК;
		--«14» – Первая часть адресной сделки по операции РЕПО с ЦК;
		--«15» – Вторая часть адресной сделки по операции РЕПО с ЦК;
		--«16» – Техническая сделка по возврату активов РЕПО с ЦК;
		--«17» – Сделка по спреду между фьючерсами разных сроков на один актив;
		--«18» – Техническая сделка первой части от спреда между фьючерсами;
		--«19» – Техническая сделка второй части от спреда между фьючерсами;
		--«20» – Адресная сделка первой части РЕПО с корзиной;
		--«21» – Адресная сделка второй части РЕПО с корзиной;
		--«22» – Перенос позиций срочного рынка
		 
		,]]..k..trade.clearing_bank_accid..k..[[--     TEXT --Идентификатор счета в НКЦ (расчетный код)
		--  я не делал это поле в таблице - 'canceled_datetime'                  TABLE --Дата и время снятия сделки
		,]]..k..trade.clearing_firmid..k..[[--                                               TEXT --Идентификатор фирмы - участника клиринга
		,]]..k..trade.system_ref..k..[[--                                                      TEXT --Дополнительная информация по сделке, передаваемая торговой системой
		,]]..tostring(trade.uid)..[[--      		REAL --Идентификатор пользователя на сервере QUIK
		)
	
	]]
 
 --helper:save_sql_to_file(sql, 'sql.txt')
 fifo.db:exec(sql) 

end



--for debug
function load_Test_SQLite()


	local sql = [[
	insert into deals

	( --придется перечислить тут все поля кроме rownum
		trade_num 
		--мои поля
		,date  ,time   ,robot_id  ,canceled_date ,canceled_time ,direction  
		--мои поля конец
		,order_num  ,brokerref  ,userid     ,firmid     ,account    ,price      ,qty        ,value      
		,accruedint ,yield      ,settlecode ,cpfirmid  	,flags 	,price2 ,reporate  ,client_code      
		,accrued2 	,repoterm 	,repovalue  ,repo2value ,start_discount   ,lower_discount   
		,upper_discount   ,block_securities ,clearing_comission ,exchange_comission  ,tech_center_comission 
		,settle_date ,settle_currency   ,trade_currency    ,exchange_code     ,station_id  ,sec_code                  
		,class_code   ,bank_acc_id  ,broker_comission ,linked_trade, period ,trans_id ,kind  
		,clearing_bank_accid  ,clearing_firmid, system_ref,	uid 
	)
	
		VALUES (
			
		--Параметр Тип Описание
		 
		8295358   --                    REAL --Номер сделки в торговой системе
		 
		--мои поля

		,'2017-04-25'--     TEXT      --            получаем из таблицы datetime, наверное сразу в виде гггг-мм-дд
		,'18:02:04'--           TEXT -- получаем из таблицы datetime
		,''--							              TEXT -- наверное, будем заполнять потом, т.к. пока непонятно, как это делать в событии OnTrade() да надо ли это делать там?
		,''--,canceled_date 	--	TEXT -- получаем из таблицы canceled_datetime
		,''--,canceled_time 	--	TEXT -- получаем из таблицы canceled_datetime
		,'sell'           --	TEXT --buy/sell
		--мои поля конец
		 
		,261568903--       		REAL  --Номер заявки в торговой системе 
		,''--                      	STRING  --Комментарий, обычно: <код клиента>/<номер поручения> 
		,''--                          	TEXT  --Идентификатор трейдера 
		,'SPBFUT'--                           	TEXT  --Идентификатор дилера 
		,'SPBFUTJR0or'--                       	TEXT  --Торговый счет 
		,17.73--                   	REAL  --Цена 
		,1--                     	REAL  --Количество бумаг в последней сделке в лотах 
		,9928.96--                  	REAL  --Объем в денежных средствах 
		,0--         	REAL  --Накопленный купонный доход 
		,0--                     REAL  --Доходность 
		,'T1'--       				TEXT  --Код расчетов 
		,''--                             TEXT -- Код фирмы партнера 
		,68--                                    REAL  --Набор битовых флагов 
		,0--                                                 REAL  --Цена выкупа 
		,0--                            REAL  --Ставка РЕПО (%) 
		,'SPBFUTJR0or'--      TEXT  --Код клиента 
		,0--                           REAL  --Доход (%) на дату выкупа 
		,0--                          REAL  --Срок РЕПО, в календарных днях 
		,0--                         REAL  --Сумма РЕПО 
		,0--       REAL  --Объем выкупа РЕПО 
		,0--                                                REAL  --Начальный дисконт (%) 
		,0--                                             REAL  --Нижний дисконт (%) 
		,0--                                             REAL  --Верхний дисконт (%) 
		,0--                                            REAL  --Блокировка обеспечения («Да»/«Нет») 
		,0--                       REAL  --Клиринговая комиссия (ММВБ) 
		,2--   REAL  --Комиссия Фондовой биржи (ММВБ) 
		,0--  REAL  --Комиссия Технического центра (ММВБ) 
		,20170426--                      TEXT  --Дата расчетов  (приходит тип NUMBER)
		,''--              TEXT  --Валюта расчетов 
		,'SUR'--              TEXT -- Валюта 
		,''--             TEXT  --Код биржи в торговой системе 
		,''--                                         TEXT  --Идентификатор рабочей станции 
		,'SVM7'--                                          TEXT  --Код бумаги заявки 
		,'SPBFUT'--                        TEXT  --Код класса 
		--,datetime..--                                       TABLE  --Дата и время 
		,''--                    TEXT  --Идентификатор расчетного счета/кода в клиринговой организации 
		,0--  REAL  --Комиссия брокера. Отображается с точностью до 2 двух знаков. Поле зарезервировано для будущего использования. 
		,0--                    REAL -- Номер витринной сделки в Торговой Системе для сделок РЕПО с ЦК и SWAP 
		,1--                                                                INTEGER  --Период торговой сессии. Возможные значения:
		 
		--«0» – Открытие;
		--«1» – Нормальный;
		--«2» – Закрытие
		 
		,0--                                             REAL  --Идентификатор транзакции -- ПОЛЬЗОВАТЕЛЬСКИЙ!!!!! при программном создании , чтобы потом можно было отловить
		,1--                                                                    INTEGER  --Тип сделки. Возможные значения:
		 
		--«1» – Обычная;
		--«2» – Адресная;
		--«3» – Первичное размещение;
		--«4» – Перевод денег/бумаг;
		--«5» – Адресная сделка первой части РЕПО;
		--«6» – Расчетная по операции своп;
		--«7» – Расчетная по внебиржевой операции своп;
		--«8» – Расчетная сделка бивалютной корзины;
		--«9» – Расчетная внебиржевая сделка бивалютной корзины;
		--«10» – Сделка по операции РЕПО с ЦК;
		--«11» – Первая часть сделки по операции РЕПО с ЦК;
		--«12» – Вторая часть сделки по операции РЕПО с ЦК;
		--«13» – Адресная сделка по операции РЕПО с ЦК;
		--«14» – Первая часть адресной сделки по операции РЕПО с ЦК;
		--«15» – Вторая часть адресной сделки по операции РЕПО с ЦК;
		--«16» – Техническая сделка по возврату активов РЕПО с ЦК;
		--«17» – Сделка по спреду между фьючерсами разных сроков на один актив;
		--«18» – Техническая сделка первой части от спреда между фьючерсами;
		--«19» – Техническая сделка второй части от спреда между фьючерсами;
		--«20» – Адресная сделка первой части РЕПО с корзиной;
		--«21» – Адресная сделка второй части РЕПО с корзиной;
		--«22» – Перенос позиций срочного рынка
		 
		,''--     TEXT --Идентификатор счета в НКЦ (расчетный код)
		--  я не делал это поле в таблице ,canceled_datetime                   TABLE --Дата и время снятия сделки
		,''--                                               TEXT --Идентификатор фирмы - участника клиринга
		,''--                                                      TEXT --Дополнительная информация по сделке, передаваемая торговой системой
		,32342--      		REAL --Идентификатор пользователя на сервере QUIK
		)
	
	]]
	
	db:exec(sql)


end

--for debug
function send_buy()

	local SecCodeBox = 'VBM7' --VTBR
	local ClassCode = 'SPBFUT'
	local ClientBox = 'OPEN32366'
	local DepoBox = 'SPBFUTJR0or'
	local lastPrice = getParamEx(ClassCode, SecCodeBox, "last").param_value + 0
	local minStepPrice = getParamEx(ClassCode, SecCodeBox, "SEC_PRICE_STEP").param_value + 0
	local LotToTrade = 1
	local trans_id = 645412
	
	transactions:orderWithId(SecCodeBox, ClassCode, "B", ClientBox, DepoBox, tostring(tonumber(lastPrice) + 60 * minStepPrice), LotToTrade, trans_id)
	
end

--for debug
function send_sell()

	local SecCodeBox = 'VBM7' --VTBR
	local ClassCode = 'SPBFUT'
	local ClientBox = 'OPEN32366'
	local DepoBox = 'SPBFUTJR0or'
	local lastPrice = getParamEx(ClassCode, SecCodeBox, "last").param_value + 0
	local minStepPrice = getParamEx(ClassCode, SecCodeBox, "SEC_PRICE_STEP").param_value + 0
	local LotToTrade = 1
	local trans_id = 787236
	
	transactions:orderWithId(SecCodeBox, ClassCode, "S", ClientBox, DepoBox, tostring(tonumber(lastPrice) - 60 * minStepPrice), LotToTrade, trans_id)

end