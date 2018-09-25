Settings = class(function(acc)
end)
function Settings:Init()

	--group positions by instrument classes
	
	self.groupByClass = true
	
	--������ �� ������� �����. ��������, ����� �� ����� �� ��������� �������� � ������������� �������
	--������ ���� ����� �������� ������ ������ � ������������ �� �������
	--�������� �������� - ��� - ���������� ��������� �������
	self.filter_by_class = {}
	self.filter_by_class['SPBFUT']=true
	self.filter_by_class['SPBOPT']=true
	self.filter_by_class['TQBR']=false --�����
	self.filter_by_class['EQOB']=false --���� ���������
	self.filter_by_class['TQOB']=false --���
	self.filter_by_class['TQDE']=false --��������� ����� (���������)
	self.filter_by_class['CETS']=false
	self.filter_by_class['TQTF']=false --ETF
	
	self.db_path = getScriptPath() .. "\\positions2.db"
	
	self.dark_theme = false
	
	--depreciated
	self.show_total_collateral_on_forts = true		--last rows show totals of collateral on FORTS by client_code

	self.show_totals = true --show total PnL after a class
	
	self.columns_visibility = {}
	
  --column visibility settings

  self.columns_visibility["account"]=true
  self.columns_visibility["depo"]=false --depo account for MICEX
  self.columns_visibility["comment"]=false
  self.columns_visibility["secCode"]=true
  self.columns_visibility["classCode"]=true
  self.columns_visibility["lot"]=false
  self.columns_visibility["dateOpen"]=false
  self.columns_visibility["timeOpen"]=false
  self.columns_visibility["tradeNum"]=false
  self.columns_visibility["operation"]=true
  self.columns_visibility["quantity"]=true
  self.columns_visibility["amount"]=true
  self.columns_visibility["priceOpen"]=true
  self.columns_visibility["dateClose"]=true
  self.columns_visibility["timeClose"]=false
  self.columns_visibility["priceClose"]=true
  self.columns_visibility["qtyClose"]=true
  self.columns_visibility["profitpt"]=true
  self.columns_visibility["profit %"]=true
  self.columns_visibility["priceOfStep"]=false
  self.columns_visibility["profit"]=true
  self.columns_visibility["commission"]=false
  self.columns_visibility["accrual"]=true
  self.columns_visibility["days"]=true
  self.columns_visibility["close_price_step"]=false
  self.columns_visibility["close_price_step_price"]=false
  self.columns_visibility["buyDepo"]=true
  self.columns_visibility["sellDepo"]=true
  self.columns_visibility["timeUpdate"]=false
  self.columns_visibility["optionType"]=true
  self.columns_visibility["expiration"]=true
  self.columns_visibility["theorPrice"]=true
  self.columns_visibility["profitByTheorPricePt"]=true
  self.columns_visibility['profitByTheorPrice %'] = true
  self.columns_visibility["profitByTheorPrice"]=true 

--	column width settings


	self.columns_width = {}
	
	self.columns_width['account'] =  7
	self.columns_width['depo'] =  7
	self.columns_width['comment'] = 10
	self.columns_width['secCode'] = 15
	self.columns_width['classCode'] = 8
	self.columns_width['lot'] = 7
	self.columns_width['dateOpen'] = 10
	self.columns_width['timeOpen'] = 10
	self.columns_width['tradeNum'] = 5
	self.columns_width['operation'] = 5
	self.columns_width['quantity'] = 7
	self.columns_width['amount'] = 7
	self.columns_width['priceOpen'] = 10 
	self.columns_width['dateClose'] = 10
	self.columns_width['timeClose'] = 10
	self.columns_width['priceClose'] = 10
	self.columns_width['qtyClose'] = 7
	self.columns_width['profitpt'] = 10
	self.columns_width['profit %'] = 8
	self.columns_width['priceOfStep'] = 7
	self.columns_width['profit'] = 10
	self.columns_width['commission'] = 7
	self.columns_width['accrual'] = 7
	self.columns_width['days'] = 7
	self.columns_width['close_price_step'] = 7
	self.columns_width['close_price_step_price'] = 7
	self.columns_width['buyDepo'] = 9
	self.columns_width['sellDepo'] = 7
	self.columns_width['timeUpdate'] = 7
	self.columns_width['optionType'] = 5
	self.columns_width['expiration'] = 10
	self.columns_width['theorPrice'] = 7
	self.columns_width['profitByTheorPricePt'] = 10
	self.columns_width['profitByTheorPrice %'] = 9
	self.columns_width['profitByTheorPrice'] = 10

end