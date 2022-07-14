--[[ 
    DataBlock - Easy and lightweight database framework
    Created by: Jamie
    2022
--]]

--[[ 
    =====================[ SETUP ]=====================

    You will need to create a file that will have the starting
    headers already added, comma separated. For example:

    id,first_name,last_name,money

    This needs to be saved in the file and the file location referenced 
    when creating a new DataBlockDB object. It's smooth sailing after that. 
--]]


DataBlockDB = {filename = nil}

function DataBlockDB:new(o, filename)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self._filename = filename
    self._headers = {}
    self._db = {}
    self:parse_db()
    return o
end

function DataBlockDB:table_length(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function DataBlockDB:table_to_comma_string(T, id_in_value)
    local _full_string = ""
    for _last_id=1,self:table_length(T) do
        for key, value in pairs(T) do
            if id_in_value then
                if value == _last_id then
                    _full_string = _full_string .. key .. ","
                end
            else
                if key == _last_id then
                    _full_string = _full_string .. value .. ","
                end
            end
        end
    end
    return string.sub(_full_string,1,-2)
end

function DataBlockDB:parse_db()
    local _headers = {}
    local _db = {}
    f = io.open(self._filename, 'r+')
    
    io.input(f)
    local headers_raw = io.read()
    local _ = 1
    for header in string.gmatch(headers_raw, '([^,]+)') do
        _headers[header] = _
        _ = _ + 1
    end

    local _row_id = 1
    for line in io.lines() do
        local _ = 1
        local _pre_db = {}
        for data in string.gmatch(line, '([^,]+)') do
            _pre_db[_] = data
            _ = _ + 1
        end
        _db[_row_id] = _pre_db
        _row_id = _row_id + 1
    end
    io.close(f)
    self._headers = _headers
    self._db = _db
    return {headers=_headers, db=_db}
end

function DataBlockDB:dump_db()
    io.open(self._filename, 'w'):close()
    f = io.open(self._filename, 'a')
    io.output(f)
    io.write(self:table_to_comma_string(self._headers, true).."\n")

    for _table_id, _table in pairs(self._db) do
        io.write(self:table_to_comma_string(_table, false).."\n")
    end
    io.close(f)
    return self._db
end

function DataBlockDB:get_header_id(header)
    for key,value in pairs(self._headers) do
        if key == header then
            return value
        end
    end
    return nil
end

function DataBlockDB:find_row_by_header(header, header_value)
    local _h_id = nil
    for key, value in pairs(self._headers) do
        if key == header then
            _h_id = value
        end
    end
    if _h_id == nil then
        return nil
    end
    for _table_id, _table in pairs(self._db) do
        for _value_id, _value in pairs(_table) do
            if _value_id == _h_id and _value == header_value then
                return {table_id=_table_id, table=_table}
            end
        end
    end
    return {}
end

function DataBlockDB:find_rows_by_header(header, header_value)
    local _h_id = nil
    for key, value in pairs(self._headers) do
        if key == header then
            _h_id = value
        end
    end
    if _h_id == nil then
        return nil
    end

    local _tables = {}
    for _table_id, _table in pairs(self._db) do
        for _value_id, _value in pairs(_table) do
            if _value_id == _h_id and _value == header_value then
                table.insert(_tables, {table_id=_table_id, table=_table})
            end
        end
    end
    if self:table_length(_tables) == 0 then
        return {}
    end
    return _tables
end

function DataBlockDB:delete_row_by_header(header, header_value)
    local _h_id = nil
    for key, value in pairs(self._headers) do
        if key == header then
            _h_id = value
        end
    end
    if _h_id == nil then
        return nil
    end

    for _table_id, _table in pairs(self._db) do
        for _value_id, _value in pairs(_table) do
            if _value_id == _h_id and _value == header_value then
                table.remove(self._db, _table_id)
                self:dump_db(self._filename, headers, self._db)
                return true
            end
        end
    end
    return false
end

function DataBlockDB:update_row_by_header(find_header, find_value, update_header, update_value)
    local _row = self:find_row_by_header(find_header, find_value)
    if _row.table == nil then
        return false
    end

    for key, value in pairs(self._headers) do
        if key == find_header then
            _h_id = value
        end
    end
    if _h_id == nil then
        return false
    end

    for key, value in pairs(self._headers) do
        if key == update_header then
            _h_id = value
        end
    end
    if _h_id == nil then
        return false
    end

    self._db[_row.table_id][self:get_header_id(update_header)] = update_value
    self:dump_db()
    return true
end

function DataBlockDB:insert(data)
    if #data ~= #self._headers then
        return false
    end
    table.insert(self._db, data)
    self:dump_db()
    return true
end