-- Перегрузка функции message с необязательным вторым параметром
old_message = message
function message(v, i)
	old_message(tostring(v), i or 1)
end


QTable ={}
QTable.__index = QTable

-- Создать и инициализировать экземпляр таблицы QTable
function QTable.new()
	local t_id = AllocTable()
	if t_id ~= nil then
		q_table = {}
		setmetatable(q_table, QTable)
		q_table.t_id=t_id
		q_table.caption = ""
		q_table.created = false
		q_table.curr_col=0
		-- таблица с описанием параметров столбцов
		q_table.columns={}
		return q_table
	else
		return nil
	end
end

function QTable:Show()
	-- отобразить в терминале окно с созданной таблицей
	CreateWindow(self.t_id)
	if self.caption ~="" then
		-- задать заголовок для окна
		SetWindowCaption(self.t_id, self.caption)
	end
	self.created = true
end
function QTable:IsClosed()
	-- если окно с таблицей закрыто, возвращает «true»
	return IsWindowClosed(self.t_id)
end

function QTable:delete()
	-- удалить таблицу
	DestroyTable(self.t_id)
end

function QTable:GetCaption()
	if IsWindowClosed(self.t_id) then
		return self.caption
	else
		-- возвращает строку, содержащую заголовок таблицы
		return GetWindowCaption(self.t_id)
	end
end

-- Задать заголовок таблицы
function QTable:SetCaption(s)
	self.caption = s
	if not IsWindowClosed(self.t_id) then
		res = SetWindowCaption(self.t_id, tostring(s))
	end
end

-- Добавить описание столбца <name> типа <c_type> в таблицу
-- <ff> – функция форматирования данных для отображения
function QTable:AddColumn(name, c_type, width, ff )
	local col_desc			= {}
	self.curr_col			= self.curr_col+1
	col_desc.c_type 		= c_type
	col_desc.format_function= ff
	col_desc.id 			= self.curr_col
	self.columns[name] 		= col_desc
	-- <name> используется в качестве заголовка таблицы
	AddColumn(self.t_id, self.curr_col, name, true, c_type, width)
end

function QTable:Clear()
	-- очистить таблицу
	Clear(self.t_id)
end

-- Установить значение в ячейке
--row - Номер строки (начинается с нуля)
function QTable:SetValue(row, col_name, data)
	local col_ind = self.columns[col_name].id or nil
	if col_ind == nil then
		return false
	end
	-- если для столбца задана функция форматирования, то она используется
	local ff = self.columns[col_name].format_function
	
	if type(ff) == "function" then
		-- в качестве строкового представления используется
		-- результат выполнения функции форматирования
		SetCell(self.t_id, row, col_ind, ff(data), data)
		return true
	else
		--SetCell(self.t_id, row, col_ind, tostring(data), data)
		--ЕНС убрал последний параметр, с ним не работает!
		SetCell(self.t_id, row, col_ind, tostring(data))
	end
end

function QTable:AddLine()
	-- добавляет в конец таблицы пустую строчку и возвращает ее номер
	return InsertRow(self.t_id, -1)
end

--ЕНС добавляет строку в указанную позицию
function QTable:InsertLine(key)
  -- добавляет в конец таблицы пустую строчку и возвращает ее номер
  return InsertRow(self.t_id, key)
end

function QTable:GetSize()
	-- возвращает размер таблицы
	return GetTableSize(self.t_id)
end

-- Получить данные из ячейки по номеру строки и имени столбца
function QTable:GetValue(row, name)
	local t={}
	local col_ind = self.columns[name].id
	if col_ind == nil then
		return nil
	end
	t = GetCell(self.t_id, row, col_ind)
	return t
end

-- Задать координаты окна
function QTable:SetPosition(x, y, dx, dy)
	return SetWindowPos(self.t_id, x, y, dx, dy)
end

-- Функция возвращает координаты окна
function QTable:GetPosition()
	top, left, bottom, right = GetWindowRect(self.t_id)
	return top, left, right-left, bottom-top
end

