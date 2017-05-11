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

--пересчитывает прибыль
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

	local PnL = 0
	operationCell = t:GetValue(row, 'operation')
	if operationCell == nil then
		return
	end
	local operation = tostring(operationCell.image) --string: buy/sell

	if operation == 'buy' then
		PnL = priceClose - priceOpen

	else
		PnL = priceOpen - priceClose

	end

	local Total_PnL = PnL * qtyClose

	--округление до 4-х знаков после запятой
	Total_PnL = math.ceil(Total_PnL * 10000)/10000 --в пунктах


	local mult = fifo:get_mult(sec_code, class_code)

	Total_PnL = Total_PnL * mult

	t:SetValue(row, 'profitpt', tostring(Total_PnL))

	--чтобы получить проценты приходится применять извращенную конструкцию
	--сначала умножить долю на 1 млн, затем разделить на 10 тыс, потому что
	--функция ceil округляет до целого и если ее применить к доле, например 0.05 то получим НОЛЬ!

	local PnL_percent = math.ceil ((PnL*10000)/priceOpen)/100   --округл вверх до целого

	t:SetValue(row, 'profit %', tostring(PnL_percent)..'%')

	--показываем прибыль в рублях
	Recalc:rub_pnl(t, row, Total_PnL, class_code, sec_code, isClosed, mult)

	--установим цвет строки в зависимости от прибыли или убытка
	colorizer:colorize_row(t, row, PnL)  
  
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

  --показываем прибыль в рублях
  local PnLrub = 0
  if (class_code == 'SPBFUT' or class_code=='SPBOPT' ) then
  
    local priceStep         = 0
    local stepPrice_amount  = 0
	
    if isClosed then 
      --шаг цены и его стоимость берем из ФИФО
      priceStep         = t:GetValue(row,'close_price_step').image -- 0.1  or 0.01 or 1 or smth else
      stepPrice_amount  = t:GetValue(row,'close_price_step_price').image --6.44
	 else
      --шаг цены и его стоимость берем текущие, из фин инструмента
      priceStep         = getParamEx (class_code, sec_code, 'SEC_PRICE_STEP').param_value 
      stepPrice_amount  = getParamEx (class_code, sec_code, 'STEPPRICET').param_value
    end
	
    --push price of StepPrice to main table for information
    t:SetValue(row, 'priceOfStep', tostring(stepPrice_amount))

    --профит в рублях. шаг цены в знаменателе нужно умножить на мультипликатор, иначе получится херня, т.к. в вызывающей процедуре Total_PnL - это уже умноженное на мульт
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
  PnLrub = math.ceil(PnLrub*100)/100
  
  --push rub PnL to main table
  t:SetValue(row, 'profit', tostring(PnLrub))
  
end

