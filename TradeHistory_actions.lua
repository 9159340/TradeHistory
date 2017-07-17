--operations with context menu

details={}

Actions = class(function(acc)
end)

function Actions:Init()
  self.t = nil --ID of table. � ���� ������� ����� ���������� ��������. ������ ������������ ����
  
  --� ��� �������� �������� �������� �� ���
			self.account     	= nil
			self.depo	     	= nil	--���� ���� ��� ����, �������� L01-00000F00. �� ����� �� ������������
			
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

--������� ����������� ��������� ������� ������, �� ����������
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
  --��������� �������� �������
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


--������� ������� ������. ������� � ���������� ����
function Actions:showContextMenu()
	
	self:createOwnTable()
	
	self:showTable()
	
	--������ ����� ��������� ������ ����� ����������� �������!
	self:addActions()
		
end

function Actions:executeAction(action)

	--����� ���������� �������, ��� ������� �������� ��� ����� ���� ����, ������� ����� ��������� � ����� ������ ������ �������
	self.resultTable = {}

	--message(action)
	if action == 'Show details' then
	
		--����� ������ ����� ���� ��������� ������� �������, ��� ����� - � ����� TradeHistory.lua, ������� local f_cb_cntx = function( t_id,  msg,  par1, par2)
		details.sec_code    = self.sec_code
		details.class_code  = self.class_code
		details.account     = self.account
		
		details:load()
		
		recalc_details()
		
		--�� ���� t_id ������� ������� ������, ����� �� ESC ����� ���� �������
		self.resultTable['details_t_id'] = details.t[details.key].t_id
	
	elseif action == 'Show trades of current session' then
	
		local res = self:ShowTradesOfCurrentSession()
		
		--� ������� res ������ ���� ���� � �� �������. �� ��� ����� �������� ������
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
�������� ���������� ������� ������: 

�������� 	��� 		�������� 
trade_num 	NUMBER ����� ������ � �������� ������� 
order_num  NUMBER  ����� ������ � �������� �������  
brokerref  	STRING  �����������, ������: <��� �������>/<����� ���������>  
userid  		STRING  ������������� ��������  
firmid  		STRING  ������������� ������  
account  	STRING  �������� ����  
price  		NUMBER  ����  
qty  			NUMBER  ���������� ����� � ��������� ������ � �����  
value  		NUMBER  ����� � �������� ���������  
accruedint  NUMBER  ����������� �������� �����  
yield  		NUMBER  ����������  
settlecode  STRING  ��� ��������  
cpfirmid  	STRING  ��� ����� ��������  
flags  		NUMBER  ����� ������� ������  
price2  		NUMBER  ���� ������  
reporate  	NUMBER  ������ ���� (%)  
client_code  STRING  ��� �������  
accrued2  	NUMBER  ����� (%) �� ���� ������  
repoterm  	NUMBER  ���� ����, � ����������� ����  
repovalue  	NUMBER  ����� ����  
repo2value  NUMBER  ����� ������ ����  
start_discount  			NUMBER  ��������� ������� (%)  
lower_discount  			NUMBER  ������ ������� (%)  
upper_discount  			NUMBER  ������� ������� (%)  
block_securities  			NUMBER  ���������� ����������� (���/����)  
clearing_comission  		NUMBER  ����������� �������� (����)  
exchange_comission  	NUMBER  �������� �������� ����� (����)  
tech_center_comission  NUMBER  �������� ������������ ������ (����)  
settle_date  				NUMBER  ���� ��������  
settle_currency  			STRING  ������ ��������  
trade_currency  			STRING  ������  
exchange_code  			STRING  ��� ����� � �������� �������  
station_id  					STRING  ������������� ������� �������  
sec_code  					STRING  ��� ������ ������  
class_code  				STRING  ��� ������  
datetime  					TABLE  ���� � �����  
bank_acc_id  				STRING  ������������� ���������� �����/���� � ����������� �����������  
broker_comission  		NUMBER  �������� �������. ������������ � ��������� �� 2 ���� ������. ���� ��������������� ��� �������� �������������.  
linked_trade  				NUMBER  ����� ��������� ������ � �������� ������� ��� ������ ���� � �� � SWAP  
period  						NUMBER  ������ �������� ������. ��������� ��������: 

�0� � ��������; 
�1� � ����������; 
�2� � �������� 
 
trans_id 					NUMBER  ������������� ���������� 
kind  							NUMBER  ��� ������. ��������� ��������:

�1� � �������; 
�2� � ��������; 
�3� � ��������� ����������; 
�4� � ������� �����/�����; 
�5� � �������� ������ ������ ����� ����; 
�6� � ��������� �� �������� ����; 
�7� � ��������� �� ����������� �������� ����; 
�8� � ��������� ������ ���������� �������; 
�9� � ��������� ����������� ������ ���������� �������; 
�10� � ������ �� �������� ���� � ��; 
�11� � ������ ����� ������ �� �������� ���� � ��; 
�12� � ������ ����� ������ �� �������� ���� � ��; 
�13� � �������� ������ �� �������� ���� � ��; 
�14� � ������ ����� �������� ������ �� �������� ���� � ��; 
�15� � ������ ����� �������� ������ �� �������� ���� � ��; 
�16� � ����������� ������ �� �������� ������� ���� � ��; 
�17� � ������ �� ������ ����� ���������� ������ ������ �� ���� �����; 
�18� � ����������� ������ ������ ����� �� ������ ����� ����������; 
�19� � ����������� ������ ������ ����� �� ������ ����� ����������; 
�20� � �������� ������ ������ ����� ���� � ��������; 
�21� � �������� ������ ������ ����� ���� � ��������; 
�22� � ������� ������� �������� ����� 
 
clearing_bank_accid 	STRING ������������� ����� � ��� (��������� ���) 
canceled_datetime 		TABLE ���� � ����� ������ ������ 
clearing_firmid 			STRING ������������� ����� - ��������� �������� 
system_ref 				STRING �������������� ���������� �� ������, ������������ �������� �������� 
uid 							NUMBER ������������� ������������ �� ������� QUIK 

--]]	
	
	return res
	
end

