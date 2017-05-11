-- ���������� ������� message � �������������� ������ ����������
old_message = message
function message(v, i)
	old_message(tostring(v), i or 1)
end


QTable ={}
QTable.__index = QTable

-- ������� � ���������������� ��������� ������� QTable
function QTable.new()
	local t_id = AllocTable()
	if t_id ~= nil then
		q_table = {}
		setmetatable(q_table, QTable)
		q_table.t_id=t_id
		q_table.caption = ""
		q_table.created = false
		q_table.curr_col=0
		-- ������� � ��������� ���������� ��������
		q_table.columns={}
		return q_table
	else
		return nil
	end
end

function QTable:Show()
	-- ���������� � ��������� ���� � ��������� ��������
	CreateWindow(self.t_id)
	if self.caption ~="" then
		-- ������ ��������� ��� ����
		SetWindowCaption(self.t_id, self.caption)
	end
	self.created = true
end
function QTable:IsClosed()
	-- ���� ���� � �������� �������, ���������� �true�
	return IsWindowClosed(self.t_id)
end

function QTable:delete()
	-- ������� �������
	DestroyTable(self.t_id)
end

function QTable:GetCaption()
	if IsWindowClosed(self.t_id) then
		return self.caption
	else
		-- ���������� ������, ���������� ��������� �������
		return GetWindowCaption(self.t_id)
	end
end

-- ������ ��������� �������
function QTable:SetCaption(s)
	self.caption = s
	if not IsWindowClosed(self.t_id) then
		res = SetWindowCaption(self.t_id, tostring(s))
	end
end

-- �������� �������� ������� <name> ���� <c_type> � �������
-- <ff> � ������� �������������� ������ ��� �����������
function QTable:AddColumn(name, c_type, width, ff )
	local col_desc			= {}
	self.curr_col			= self.curr_col+1
	col_desc.c_type 		= c_type
	col_desc.format_function= ff
	col_desc.id 			= self.curr_col
	self.columns[name] 		= col_desc
	-- <name> ������������ � �������� ��������� �������
	AddColumn(self.t_id, self.curr_col, name, true, c_type, width)
end

function QTable:Clear()
	-- �������� �������
	Clear(self.t_id)
end

-- ���������� �������� � ������
--row - ����� ������ (���������� � ����)
function QTable:SetValue(row, col_name, data)
	local col_ind = self.columns[col_name].id or nil
	if col_ind == nil then
		return false
	end
	-- ���� ��� ������� ������ ������� ��������������, �� ��� ������������
	local ff = self.columns[col_name].format_function
	
	if type(ff) == "function" then
		-- � �������� ���������� ������������� ������������
		-- ��������� ���������� ������� ��������������
		SetCell(self.t_id, row, col_ind, ff(data), data)
		return true
	else
		--SetCell(self.t_id, row, col_ind, tostring(data), data)
		--��� ����� ��������� ��������, � ��� �� ��������!
		SetCell(self.t_id, row, col_ind, tostring(data))
	end
end

function QTable:AddLine()
	-- ��������� � ����� ������� ������ ������� � ���������� �� �����
	return InsertRow(self.t_id, -1)
end

--��� ��������� ������ � ��������� �������
function QTable:InsertLine(key)
  -- ��������� � ����� ������� ������ ������� � ���������� �� �����
  return InsertRow(self.t_id, key)
end

function QTable:GetSize()
	-- ���������� ������ �������
	return GetTableSize(self.t_id)
end

-- �������� ������ �� ������ �� ������ ������ � ����� �������
function QTable:GetValue(row, name)
	local t={}
	local col_ind = self.columns[name].id
	if col_ind == nil then
		return nil
	end
	t = GetCell(self.t_id, row, col_ind)
	return t
end

-- ������ ���������� ����
function QTable:SetPosition(x, y, dx, dy)
	return SetWindowPos(self.t_id, x, y, dx, dy)
end

-- ������� ���������� ���������� ����
function QTable:GetPosition()
	top, left, bottom, right = GetWindowRect(self.t_id)
	return top, left, right-left, bottom-top
end

