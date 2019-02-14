
Service = class(function(acc)
end)

function Service:Init()

  
end


--import manual trades to fifo
--функция проводит по фифо искусственные сделки из таблицы. см. функцию create_table_trades()
function Service:process_fifo_manual_deals()

	local trades = self:create_table_trades()
	
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
		message(tostring(i)..' trade has been processed. # ' .. trade.trade_num)
	end		
end


--creates manual table
function Service:create_table_trades()

	--trades[ 11 ] ['flags'] = 64 --buy
	--trades[ 11 ] ['flags'] = 68 --sell

	local trades = {}

	local num = 1

	trades[ num]  = {}			
	trades[ num ] ['trade_num'] 			= 00000000		--decimal
	trades[ num ] ['order_num'] 			= 0000000000	--decimal
	trades[ num ] ['brokerref'] 			= ''			--do not fill
	trades[ num ] ['price'] 				= 116000 		--decimal
	trades[ num ] ['qty'] 					= 1				--decimal
	trades[ num ] ['value'] 				= 153754.00		--decimal
	trades[ num ] ['flags'] 				= 64			--decimal 64 buy/ 68 sell
	trades[ num ] ['client_code'] 			= '1234567'
	trades[ num ] ['trade_currency'] 		= 'SUR'			
	trades[ num ] ['sec_code'] 				= 'RIH9'			
	trades[ num ] ['class_code'] 			= 'SPBFUT'			
	trades[ num ] ['exchange_comission'] 	= 0				--decimal
	trades[ num ] ['trans_id'] 				= 0				--decimal
	trades[ num ] ['accruedint'] 			= 0				--decimal
	trades[ num ] ['datetime'] 				= {day=10, month=10,year=2010,hour=10,min=10,sec=10 }
	trades[ num ] ['operation'] 			= 'buy' 		--this field is not present in original trade table. 
	trades[ num ] ['account'] 				= '1234567'		--string, depo code
	
	
--num=num+1

	return trades			
end


