local sqlite3 = require("lsqlite3")
local db = sqlite3.open(getScriptPath() .. ".\\..\\positions2.db")

--creates table in sqlite database. table has name fifo_4
function main()

   sql=[=[
          CREATE TABLE fifo_4
          (
		   rownum INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
          --это поля из таблицы trade, которая возвращается событием OnTrade
          --измерения 
          dim_client_code  TEXT,    --  Код клиента  
          dim_sec_code  TEXT,       --  Код бумаги заявки  
          dim_class_code  TEXT,     --  Код класса  
          dim_trade_num REAL,       --  Номер сделки в торговой системе 
          dim_brokerref  TEXT,      --  Комментарий, обычно: <код клиента>/<номер поручения>  
          
          --ресурсы  
          res_qty  REAL,            --  Количество бумаг в последней сделке в лотах  
          res_value  REAL,          --  Объем в денежных средствах  
           
          --реквизиты
          attr_date  TEXT,           --  Дата и время сделки, открывшей партию
          attr_time  TEXT,           --  Дата и время сделки, открывшей партию
          attr_price  REAL,          --  Цена
          attr_trade_currency  TEXT, --  Валюта  
          attr_accruedint  REAL,     --  Накопленный купонный доход  
          attr_trans_id TEXT,        --  Идентификатор транзакции 
          attr_order_num  REAL,      --  Номер заявки в торговой системе
          attr_lot REAL,             --  Количество бумаг в лоте  
          attr_exchange_comission  REAL,--  Комиссия Фондовой биржи (ММВБ)  
          
          --attributes for closing position
          close_trade_num REAL,
          close_date REAL,
          close_time REAL,
          close_price REAL,
          close_qty REAL,
          close_value REAL,   --amount
          close_price_step REAL, --price step
          close_price_step_price REAL, --value of price step for closing trade. we need this to calculate PnL
		  mult REAL, --множитель для фортс. пример: brent торгуется по 10, а котируется по 1, сумма сделки = qty*price * mult
		  
		  --direction : buy or sell
		  --схема работы
		  --dir = buy и количество > 0 - открываем лонг
		  --dir = sell и количество < 0 - закрываем лонг
		  --dir = sell и количество > 0 - открываем шорт
		  --dir = buy и количество < 0 - закрываем шорт
		  --таким образом, любая открытая позиция всегда будет с положительным знаком
		  --и так будет проще считать остатки, используя функцию SUM()
		  direction TEXT
          );          
        ]=]
         
   db:exec(sql)
 
end

 
