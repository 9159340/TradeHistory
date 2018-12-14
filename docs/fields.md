# Подробное описание полей таблицы скрипта

  Актуальный список колонок всегда можно посмотреть в методе createTable() файла TradeHistory_table.lua  
  
  

* account		- строка, 	код счета клиента  
* depo			- строка, 	код счета депо (актуально для спот-секции)  
* comment		- строка, 	комментарий, который приходит в сделке от брокера  
* secCode		- строка, 	код фин. инструмента  
* optionType	- строка, 	тип опциона PUT/CALL  
* expiration	- строка, 	дата экспирации дериватива  
* classCode		- строка, 	код класса фин. инструмента  
* lot			- число, 	размер лота  
* dateOpen		- строка, 	дата открытия партии  
* timeOpen		- строка,	время открытия партии  
* tradeNum		- строка, 	номер сделки, открывшей партию  
* operation		- строка, 	направление сделки, buy/sell  
* quantity		- число,	количество лотов в сделке  
* amount		- число,	сумма по сделке (руб.)  
* priceOpen		- число, 	цена по сделке  
* dateClose		- строка, 	дата закрытия партии. Заполняется только в закрытых позициях  
* timeClose		- строка, 	время закрытия партии. Заполняется только в закрытых позициях  
* priceClose	- число,	цена закрытия позиции. В открытых показывается текущая цена bid/ask, в закрытых - цена сделки закрытия  
* qtyClose		- число, 	количество, на которое закрылась партия
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

  





