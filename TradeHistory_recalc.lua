helper = {}
colorizer = {}
fifo = {}

Recalc = class(function(acc)
end)

function Recalc:Init()
  helper=Helper()
  helper:Init()
  colorizer=Colorizer()
  colorizer:Init()
  fifo=FIFO()
  fifo:Init()
  
end

-- recalculates PnL
-- Parameters
function Recalc:recalcPosition(t, row, isClosed)

	if row == nil then
		return
	end
	local priceOpen = 	helper:getPriceOpen(t, row)
	local priceClose = 	helper:getPriceClose(t, row)

	local qtyClose = 		helper:getQtyClose(t, row)

	secCodeCell = t:GetValue(row,'secCode')
	if secCodeCell == nil then
		return
	end
	local sec_code =  secCodeCell.image
	classCodeCell = t:GetValue(row,'classCode')
	if classCodeCell == nil then
		return
	end
	local class_code =  classCodeCell.image

	--message(sec_code)
	--message(class_code)

	operationCell = t:GetValue(row, 'operation')
	if operationCell == nil then
		return
	end

	local PnL = 0
	
	local operation = tostring(operationCell.image) --string: buy/sell

	if operation == 'buy' then
		PnL = priceClose - priceOpen
	else
		PnL = priceOpen - priceClose
	end

	local Total_PnL = PnL * qtyClose

	--round to 2 digits after dot
	Total_PnL = math.ceil(Total_PnL * 100)/100 --in points
	
	local mult = fifo:get_mult(sec_code, class_code)

	Total_PnL = Total_PnL * mult
	
	t:SetValue(row, 'profitpt', tostring(Total_PnL))
	
	--чтобы получить проценты приходится применять извращенную конструкцию
	--сначала умножить долю на 1 млн, затем разделить на 10 тыс, потому что
	--функция ceil округляет до целого и если ее применить к доле, например 0.05 то получим НОЛЬ!
	local PnL_percent = math.ceil ((PnL*10000)/priceOpen)/100   --round up to integer
	t:SetValue(row, 'profit %', tostring(PnL_percent)..'%')

	--show PnL in RUB
	local PnLrub = Recalc:rub_pnl(t, row, Total_PnL, class_code, sec_code, isClosed, mult)
	t:SetValue(row, 'profit', tostring(PnLrub))	

	--set row color according to profit or loss (green or red)
	colorizer:colorize_row(t, row, PnL)
	

	--OPTIONS
	if class_code == 'SPBOPT' then
		local theorPrice = 	helper:getTheorPrice(t, row)
		local PnLtheor = 0 --  by theor price for options
		if operation == 'buy' then
			PnLtheor = theorPrice - priceOpen
		else
			PnLtheor = priceOpen - theorPrice
		end		
		local Total_PnL_theor = PnLtheor * qtyClose

		--round to 2 digits after dot
		Total_PnL_theor = math.ceil(Total_PnL_theor * 100)/100 --in points
		Total_PnL_theor = Total_PnL_theor * mult
		t:SetValue(row, 'profitByTheorPricePt', tostring(Total_PnL_theor))

		-- PnL %
		local PnL_percent_theor = math.ceil ((PnLtheor*10000)/priceOpen)/100   --round up to integer
		t:SetValue(row, 'profitByTheorPrice %', tostring(PnL_percent_theor)..'%')		

		-- PnL RUB
		local PnLrub = Recalc:rub_pnl(t, row, Total_PnL_theor, class_code, sec_code, isClosed, mult)

		--push rub PnL to main table
		t:SetValue(row, 'profitByTheorPrice', tostring(PnLrub))			
	end	
  
end





--this function evaluates PnL in RUB
--Parameters:
--  t           - in - table   - ID of main table
--  row         - in - numeric - number of row in table
--  Total_PnL   - in - numeric - PnL in points or currency
--  class_code  - in - string  - security class code
--  sec_code    - in - string  - security code
--  isClosed    - in - book    - position type: open/closed
--  mult        - in - numeric - multiplier for security
function Recalc:rub_pnl(t, row, Total_PnL, class_code, sec_code, isClosed, mult)

  --show PnL in RUB
  local PnLrub = 0
  if (class_code == 'SPBFUT' or class_code=='SPBOPT' ) then
  
    local priceStep         = 0
    local stepPrice_amount  = 0
	
    if isClosed then 
      --we should get price step and it's value from FIFO
      priceStep         = t:GetValue(row,'close_price_step').image -- 0.1  or 0.01 or 1 or smth else
      stepPrice_amount  = t:GetValue(row,'close_price_step_price').image --6.44
	 else
      --we should get price step and it's value from instrument parameters
      priceStep         = getParamEx (class_code, sec_code, 'SEC_PRICE_STEP').param_value 
      stepPrice_amount  = getParamEx (class_code, sec_code, 'STEPPRICET').param_value
    end
	
    --push price of StepPrice to main table for information
    t:SetValue(row, 'priceOfStep', tostring(stepPrice_amount))

    --PnL in RUB. шаг цены в знаменателе нужно умножить на мультипликатор, иначе получится херня, т.к. в вызывающей процедуре Total_PnL - это уже умноженное на мульт
	PnLrub = (Total_PnL / (priceStep*mult)) * stepPrice_amount

  else
    --spot
   if class_code =='TQOB' or class_code == 'TQOD' or class_code =='EQOB' then --bonds
		PnLrub = Total_PnL * 10
	else
		PnLrub = Total_PnL
	end	
  end

  --round to 2 digits after dot  
  return math.ceil(PnLrub*100)/100

end

