local sqlite3 = require("lsqlite3")
local db = sqlite3.open(getScriptPath() .. ".\\..\\positions2.db")

--creates table in sqlite database. table has name fifo_4
function main()

   sql=[=[
          CREATE TABLE fifo_4
          (
		   rownum INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
          --��� ���� �� ������� trade, ������� ������������ �������� OnTrade
          --��������� 
          dim_client_code  TEXT,    --  ��� �������  
          dim_sec_code  TEXT,       --  ��� ������ ������  
          dim_class_code  TEXT,     --  ��� ������  
          dim_trade_num REAL,       --  ����� ������ � �������� ������� 
          dim_brokerref  TEXT,      --  �����������, ������: <��� �������>/<����� ���������>  
          
          --�������  
          res_qty  REAL,            --  ���������� ����� � ��������� ������ � �����  
          res_value  REAL,          --  ����� � �������� ���������  
           
          --���������
          attr_date  TEXT,           --  ���� � ����� ������, ��������� ������
          attr_time  TEXT,           --  ���� � ����� ������, ��������� ������
          attr_price  REAL,          --  ����
          attr_trade_currency  TEXT, --  ������  
          attr_accruedint  REAL,     --  ����������� �������� �����  
          attr_trans_id TEXT,        --  ������������� ���������� 
          attr_order_num  REAL,      --  ����� ������ � �������� �������
          attr_lot REAL,             --  ���������� ����� � ����  
          attr_exchange_comission  REAL,--  �������� �������� ����� (����)  
          
          --attributes for closing position
          close_trade_num REAL,
          close_date REAL,
          close_time REAL,
          close_price REAL,
          close_qty REAL,
          close_value REAL,   --amount
          close_price_step REAL, --price step
          close_price_step_price REAL, --value of price step for closing trade. we need this to calculate PnL
		  mult REAL, --��������� ��� �����. ������: brent ��������� �� 10, � ���������� �� 1, ����� ������ = qty*price * mult
		  
		  --direction : buy or sell
		  --����� ������
		  --dir = buy � ���������� > 0 - ��������� ����
		  --dir = sell � ���������� < 0 - ��������� ����
		  --dir = sell � ���������� > 0 - ��������� ����
		  --dir = buy � ���������� < 0 - ��������� ����
		  --����� �������, ����� �������� ������� ������ ����� � ������������� ������
		  --� ��� ����� ����� ������� �������, ��������� ������� SUM()
		  direction TEXT
          );          
        ]=]
         
   db:exec(sql)
 
end

 
