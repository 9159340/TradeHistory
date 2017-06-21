--����� ��������� ��� ������ � ������� deals � ������ ����������, ���� ��� ������ ��� ���, ����� ������, ��� ��� ��� ����������
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
		 
		]]..tostring(trade.trade_num)..[[   --                    REAL --����� ������ � �������� �������
		 
		--��� ����

		,]]..k..helper:get_trade_date_sql(trade)..k..[[--     TEXT      --            �������� �� ������� datetime, �������� ����� � ���� ����-��-��
		,]]..k..helper:get_trade_time(trade)..k..[[--           TEXT -- �������� �� ������� datetime
		,]]..k..robot_id..k..[[--							              TEXT -- ��������, ����� ��������� �����, �.�. ���� ���������, ��� ��� ������ � ������� OnTrade() �� ���� �� ��� ������ ���?
		,]]..k..k..[[--,canceled_date 	--	TEXT -- �������� �� ������� canceled_datetime
		,]]..k..k..[[--,canceled_time 	--	TEXT -- �������� �� ������� canceled_datetime
		,]]..k..direction..k.. [[           --	TEXT --buy/sell
		--��� ���� �����
		 
		,]]..tostring(trade.order_num)..[[--       		REAL  --����� ������ � �������� ������� 
		,]]..k..trade.brokerref..k..[[--                      	STRING  --�����������, ������: <��� �������>/<����� ���������> 
		,]]..k..trade.userid..k..[[--                          	TEXT  --������������� �������� 
		,]]..k..trade.firmid..k..[[--                           	TEXT  --������������� ������ 
		,]]..k..trade.account..k..[[--                       	TEXT  --�������� ���� 
		,]]..tostring(trade.price)..[[--                   	REAL  --���� 
		,]]..tostring(trade.qty)..[[--                     	REAL  --���������� ����� � ��������� ������ � ����� 
		,]]..tostring(trade.value)..[[--                  	REAL  --����� � �������� ��������� 
		,]]..tostring(trade.accruedint)..[[--         	REAL  --����������� �������� ����� 
		,]]..tostring(trade.yield)..[[--                     REAL  --���������� 
		,]]..k..trade.settlecode..k..[[--       				TEXT  --��� �������� 
		,]]..k..trade.cpfirmid..k..[[--                             TEXT -- ��� ����� �������� 
		,]]..tostring(trade.flags)..[[--                                    REAL  --����� ������� ������ 
		,]]..tostring(trade.price2)..[[--                                                 REAL  --���� ������ 
		,]]..tostring(trade.reporate)..[[--                            REAL  --������ ���� (%) 
		,]]..k..trade.client_code..k..[[--      TEXT  --��� ������� 
		,]]..tostring(trade.accrued2)..[[--                           REAL  --����� (%) �� ���� ������ 
		,]]..tostring(trade.repoterm)..[[--                          REAL  --���� ����, � ����������� ���� 
		,]]..tostring(trade.repovalue)..[[--                         REAL  --����� ���� 
		,]]..tostring(trade.repo2value)..[[--       REAL  --����� ������ ���� 
		,]]..tostring(trade.start_discount)..[[--                                                REAL  --��������� ������� (%) 
		,]]..tostring(trade.lower_discount)..[[--                                             REAL  --������ ������� (%) 
		,]]..tostring(trade.upper_discount)..[[--                                             REAL  --������� ������� (%) 
		,]]..tostring(trade.block_securities)..[[--                                            REAL  --���������� ����������� (���/����) 
		,]]..tostring(trade.clearing_comission)..[[--                       REAL  --����������� �������� (����) 
		,]]..tostring(trade.exchange_comission)..[[--   REAL  --�������� �������� ����� (����) 
		,]]..tostring(trade.tech_center_comission)..[[--  REAL  --�������� ������������ ������ (����) 
		,]]..tostring(trade.settle_date)..[[--                      TEXT  --���� ��������  (�������� ��� NUMBER)
		,]]..k..trade.settle_currency..k..[[--              TEXT  --������ �������� 
		,]]..k..trade.trade_currency..k..[[--              TEXT -- ������ 
		,]]..k..trade.exchange_code..k..[[--             TEXT  --��� ����� � �������� ������� 
		,]]..k..trade.station_id..k..[[--                                         TEXT  --������������� ������� ������� 
		,]]..k..trade.sec_code..k..[[--                                          TEXT  --��� ������ ������ 
		,]]..k..trade.class_code..k..[[--                        TEXT  --��� ������ 
		--,datetime..--                                       TABLE  --���� � ����� 
		,]]..k..trade.bank_acc_id..k..[[--                    TEXT  --������������� ���������� �����/���� � ����������� ����������� 
		,]]..tostring(trade.broker_comission)..[[--  REAL  --�������� �������. ������������ � ��������� �� 2 ���� ������. ���� ��������������� ��� �������� �������������. 
		,]]..tostring(trade.linked_trade)..[[--                    REAL -- ����� ��������� ������ � �������� ������� ��� ������ ���� � �� � SWAP 
		,]]..tostring(trade.period)..[[--                                                                INTEGER  --������ �������� ������. ��������� ��������:
		 
		--�0� � ��������;
		--�1� � ����������;
		--�2� � ��������
		 
		,]]..tostring(trade.trans_id)..[[--                                             REAL  --������������� ���������� -- ����������������!!!!! ��� ����������� �������� , ����� ����� ����� ���� ��������
		,]]..tostring(trade.kind)..[[--                                                                    INTEGER  --��� ������. ��������� ��������:
		 
		--�1� � �������;
		--�2� � ��������;
		--�3� � ��������� ����������;
		--�4� � ������� �����/�����;
		--�5� � �������� ������ ������ ����� ����;
		--�6� � ��������� �� �������� ����;
		--�7� � ��������� �� ����������� �������� ����;
		--�8� � ��������� ������ ���������� �������;
		--�9� � ��������� ����������� ������ ���������� �������;
		--�10� � ������ �� �������� ���� � ��;
		--�11� � ������ ����� ������ �� �������� ���� � ��;
		--�12� � ������ ����� ������ �� �������� ���� � ��;
		--�13� � �������� ������ �� �������� ���� � ��;
		--�14� � ������ ����� �������� ������ �� �������� ���� � ��;
		--�15� � ������ ����� �������� ������ �� �������� ���� � ��;
		--�16� � ����������� ������ �� �������� ������� ���� � ��;
		--�17� � ������ �� ������ ����� ���������� ������ ������ �� ���� �����;
		--�18� � ����������� ������ ������ ����� �� ������ ����� ����������;
		--�19� � ����������� ������ ������ ����� �� ������ ����� ����������;
		--�20� � �������� ������ ������ ����� ���� � ��������;
		--�21� � �������� ������ ������ ����� ���� � ��������;
		--�22� � ������� ������� �������� �����
		 
		,]]..k..trade.clearing_bank_accid..k..[[--     TEXT --������������� ����� � ��� (��������� ���)
		--  � �� ����� ��� ���� � ������� - 'canceled_datetime'                  TABLE --���� � ����� ������ ������
		,]]..k..trade.clearing_firmid..k..[[--                                               TEXT --������������� ����� - ��������� ��������
		,]]..k..trade.system_ref..k..[[--                                                      TEXT --�������������� ���������� �� ������, ������������ �������� ��������
		,]]..tostring(trade.uid)..[[--      		REAL --������������� ������������ �� ������� QUIK
		)
	
	]]
 
 --helper:save_sql_to_file(sql, 'sql.txt')
 fifo.db:exec(sql) 

end



--for debug
function load_Test_SQLite()


	local sql = [[
	insert into deals

	( --�������� ����������� ��� ��� ���� ����� rownum
		trade_num 
		--��� ����
		,date  ,time   ,robot_id  ,canceled_date ,canceled_time ,direction  
		--��� ���� �����
		,order_num  ,brokerref  ,userid     ,firmid     ,account    ,price      ,qty        ,value      
		,accruedint ,yield      ,settlecode ,cpfirmid  	,flags 	,price2 ,reporate  ,client_code      
		,accrued2 	,repoterm 	,repovalue  ,repo2value ,start_discount   ,lower_discount   
		,upper_discount   ,block_securities ,clearing_comission ,exchange_comission  ,tech_center_comission 
		,settle_date ,settle_currency   ,trade_currency    ,exchange_code     ,station_id  ,sec_code                  
		,class_code   ,bank_acc_id  ,broker_comission ,linked_trade, period ,trans_id ,kind  
		,clearing_bank_accid  ,clearing_firmid, system_ref,	uid 
	)
	
		VALUES (
			
		--�������� ��� ��������
		 
		8295358   --                    REAL --����� ������ � �������� �������
		 
		--��� ����

		,'2017-04-25'--     TEXT      --            �������� �� ������� datetime, �������� ����� � ���� ����-��-��
		,'18:02:04'--           TEXT -- �������� �� ������� datetime
		,''--							              TEXT -- ��������, ����� ��������� �����, �.�. ���� ���������, ��� ��� ������ � ������� OnTrade() �� ���� �� ��� ������ ���?
		,''--,canceled_date 	--	TEXT -- �������� �� ������� canceled_datetime
		,''--,canceled_time 	--	TEXT -- �������� �� ������� canceled_datetime
		,'sell'           --	TEXT --buy/sell
		--��� ���� �����
		 
		,261568903--       		REAL  --����� ������ � �������� ������� 
		,''--                      	STRING  --�����������, ������: <��� �������>/<����� ���������> 
		,''--                          	TEXT  --������������� �������� 
		,'SPBFUT'--                           	TEXT  --������������� ������ 
		,'SPBFUTJR0or'--                       	TEXT  --�������� ���� 
		,17.73--                   	REAL  --���� 
		,1--                     	REAL  --���������� ����� � ��������� ������ � ����� 
		,9928.96--                  	REAL  --����� � �������� ��������� 
		,0--         	REAL  --����������� �������� ����� 
		,0--                     REAL  --���������� 
		,'T1'--       				TEXT  --��� �������� 
		,''--                             TEXT -- ��� ����� �������� 
		,68--                                    REAL  --����� ������� ������ 
		,0--                                                 REAL  --���� ������ 
		,0--                            REAL  --������ ���� (%) 
		,'SPBFUTJR0or'--      TEXT  --��� ������� 
		,0--                           REAL  --����� (%) �� ���� ������ 
		,0--                          REAL  --���� ����, � ����������� ���� 
		,0--                         REAL  --����� ���� 
		,0--       REAL  --����� ������ ���� 
		,0--                                                REAL  --��������� ������� (%) 
		,0--                                             REAL  --������ ������� (%) 
		,0--                                             REAL  --������� ������� (%) 
		,0--                                            REAL  --���������� ����������� (���/����) 
		,0--                       REAL  --����������� �������� (����) 
		,2--   REAL  --�������� �������� ����� (����) 
		,0--  REAL  --�������� ������������ ������ (����) 
		,20170426--                      TEXT  --���� ��������  (�������� ��� NUMBER)
		,''--              TEXT  --������ �������� 
		,'SUR'--              TEXT -- ������ 
		,''--             TEXT  --��� ����� � �������� ������� 
		,''--                                         TEXT  --������������� ������� ������� 
		,'SVM7'--                                          TEXT  --��� ������ ������ 
		,'SPBFUT'--                        TEXT  --��� ������ 
		--,datetime..--                                       TABLE  --���� � ����� 
		,''--                    TEXT  --������������� ���������� �����/���� � ����������� ����������� 
		,0--  REAL  --�������� �������. ������������ � ��������� �� 2 ���� ������. ���� ��������������� ��� �������� �������������. 
		,0--                    REAL -- ����� ��������� ������ � �������� ������� ��� ������ ���� � �� � SWAP 
		,1--                                                                INTEGER  --������ �������� ������. ��������� ��������:
		 
		--�0� � ��������;
		--�1� � ����������;
		--�2� � ��������
		 
		,0--                                             REAL  --������������� ���������� -- ����������������!!!!! ��� ����������� �������� , ����� ����� ����� ���� ��������
		,1--                                                                    INTEGER  --��� ������. ��������� ��������:
		 
		--�1� � �������;
		--�2� � ��������;
		--�3� � ��������� ����������;
		--�4� � ������� �����/�����;
		--�5� � �������� ������ ������ ����� ����;
		--�6� � ��������� �� �������� ����;
		--�7� � ��������� �� ����������� �������� ����;
		--�8� � ��������� ������ ���������� �������;
		--�9� � ��������� ����������� ������ ���������� �������;
		--�10� � ������ �� �������� ���� � ��;
		--�11� � ������ ����� ������ �� �������� ���� � ��;
		--�12� � ������ ����� ������ �� �������� ���� � ��;
		--�13� � �������� ������ �� �������� ���� � ��;
		--�14� � ������ ����� �������� ������ �� �������� ���� � ��;
		--�15� � ������ ����� �������� ������ �� �������� ���� � ��;
		--�16� � ����������� ������ �� �������� ������� ���� � ��;
		--�17� � ������ �� ������ ����� ���������� ������ ������ �� ���� �����;
		--�18� � ����������� ������ ������ ����� �� ������ ����� ����������;
		--�19� � ����������� ������ ������ ����� �� ������ ����� ����������;
		--�20� � �������� ������ ������ ����� ���� � ��������;
		--�21� � �������� ������ ������ ����� ���� � ��������;
		--�22� � ������� ������� �������� �����
		 
		,''--     TEXT --������������� ����� � ��� (��������� ���)
		--  � �� ����� ��� ���� � ������� ,canceled_datetime                   TABLE --���� � ����� ������ ������
		,''--                                               TEXT --������������� ����� - ��������� ��������
		,''--                                                      TEXT --�������������� ���������� �� ������, ������������ �������� ��������
		,32342--      		REAL --������������� ������������ �� ������� QUIK
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