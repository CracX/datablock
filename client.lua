MODEM_SIDE = "top"
PROTOCOL = "DBDB"
ENCRYPTION_KEYS = {}
ENCRYPTION_KEYS[2] = "9f8jhf98hu9f48jf934u8fhe9"

-- DYNAMIC - DO NOT CHANGE
IS_CONNECTED = false
IS_ENCRYPTED = false
CHAL_CODE = nil
HOST = nil
USER_NAME = nil
USER_PASS = nil
HEADERS = nil

function split_string(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

function encrypt(host_id, data)
    local ciphertext = ""
    local _ = 1
    data = ""..data
    for c in data:gmatch"." do
        ciphertext = ciphertext .. bit.bxor(string.byte(c), string.byte(string.sub(ENCRYPTION_KEYS[host_id],_,_))) .. ","
        _ = _ + 1
    end
    return string.sub(ciphertext, 1,-2)
end

function decrypt(host_id, data)
    local plaintext = ""
    local _ = 1
    data = ""..data
    for c in data:gmatch"([^,]+)" do
        plaintext = plaintext .. string.char(bit.bxor(tonumber(c), string.byte(string.sub(ENCRYPTION_KEYS[host_id],_,_))))
        _ = _ + 1
    end
    return plaintext
end

function get_chal_code()
    rednet.send(HOST, "CHALLENGE", PROTOCOL)
    local c_id, msg, p = rednet.receive(PROTOCOL, 5)
    CHAL_CODE = msg
    return CHAL_CODE
end

function send_to_host(msg)
    if not IS_CONNECTED then
        return false
    end
    if not IS_ENCRYPTED then
        rednet.send(HOST, ""..USER_NAME.." "..USER_PASS.." "..msg, PROTOCOL)
        return true
    else
        rednet.send(HOST, ""..USER_NAME.." "..encrypt(HOST,USER_PASS..get_chal_code()).." "..msg, PROTOCOL)
        return true
    end
end

function connect(host, username, password)
    local MESSAGE = nil
    rednet.open(MODEM_SIDE)
    if ENCRYPTION_KEYS[host] ~= nil then
        IS_ENCRYPTED = true
        rednet.send(host, "CHALLENGE", PROTOCOL)
        local c_id, msg, p = rednet.receive(PROTOCOL, 5)
        if msg == nil then
            rednet.send(host, "CHALLENGE", PROTOCOL)
            c_id, msg, p = rednet.receive(PROTOCOL, 5)
        end
        CHAL_CODE = msg
        rednet.send(host, ""..username.." "..encrypt(host,password..CHAL_CODE).." CONNECT", PROTOCOL)
        local c_id, msg, p = rednet.receive(PROTOCOL, 5)
        MESSAGE = msg
    else
        rednet.send(host, ""..username.." "..password.." CONNECT", PROTOCOL)
        local c_id, msg, p = rednet.receive(PROTOCOL, 5)
        MESSAGE = msg
    end

    if MESSAGE == nil then
        return "TIMEOUT"
    end

    if MESSAGE == "NO_CHALLENGE_CODE" then
        return "NO_ENCRYPTION_KEY"
    end

    if MESSAGE == "INVALID_CREDENTIALS" then
        return "INVALID_CREDENTIALS"
    end
    IS_CONNECTED = true
    HOST = host
    USER_NAME = username
    USER_PASS = password
    get_headers()
    return MESSAGE
end

function get_headers()
    send_to_host("HEADERS")
    local c_id, msg, p = rednet.receive(PROTOCOL, 5)
    HEADERS = msg
    return msg
end

function print_headers()
    local full_headers = ""
    for key,value in pairs(HEADERS) do
        full_headers = full_headers..value.." "
    end
    print(string.sub(full_headers, 1,-2))
end

function command_handler(cmd)
    if cmd[1] == "connect" then
        if IS_CONNECTED then
            print("[!] You are already connected")
            return false
        end
        if #cmd < 4 then
            print("[!] Usage: connect <host_id> <username> <password>")
            return false
        end
        local res = connect(tonumber(cmd[2]), cmd[3], cmd[4])
        print("[*] Got message: "..res)
        return true
    end

    if cmd[1] == "disconnect" then
        if not IS_CONNECTED then
            print("[!] You are not connected")
            return false
        end

        IS_CONNECTED = false
        IS_ENCRYPTED = false
        CHAL_CODE = nil
        HOST = nil
        USER_NAME = nil
        USER_PASS = nil
        print("[*] Disconnected")
        return true

    end

    if cmd[1] == "headers" then
        if not IS_CONNECTED then
            print("[!] You are not connected")
            return false
        end
        local full_str = ""
        for key,value in pairs(get_headers()) do
            full_str = full_str..value.." "
        end
        print(string.sub(full_str, 1,-2))
        return true
    end

    if cmd[1] == "get_row" then
        if not IS_CONNECTED then
            print("[!] You are not connected")
            return false
        end

        if #cmd < 3 then
            print("[!] Usage: get_row <header> <value>")
            return false
        end
        send_to_host("GET_ROW_BY_HEADER "..cmd[2].." "..cmd[3])
        local c_id, msg, p = rednet.receive(PROTOCOL, 5)
        
        if msg.table == nil then
            print("None")
            return false
        end

        if #msg.table == 0 then
            print("None")
            return false
        end

        print_headers()

        local full_str = ""
        for key,value in pairs(msg.table) do
            full_str = full_str..value.." "
        end
        print(string.sub(full_str, 1,-2))
        return true
    end

    if cmd[1] == "get_rows" then
        if not IS_CONNECTED then
            print("[!] You are not connected")
            return false
        end

        if #cmd < 3 then
            print("[!] Usage: get_rows <header> <value>")
            return false
        end
        send_to_host("GET_ROWS_BY_HEADER "..cmd[2].." "..cmd[3])
        local c_id, msg, p = rednet.receive(PROTOCOL, 5)
        
        if msg == nil then
            print("None")
            return false
        end

        if #msg == 0 then
            print("None")
            return false
        end

        print_headers()
        local full_str = ""
        for _key,_value in pairs(msg) do
            for key,value in pairs(_value.table) do
                full_str = full_str..value.." "
            end
            print(string.sub(full_str, 1,-2))
            full_str = ""
        end
        return true
    end

    if cmd[1] == "get_all_rows" then
        if not IS_CONNECTED then
            print("[!] You are not connected")
            return false
        end

        send_to_host("GET_ALL_ROWS")
        local c_id, msg, p = rednet.receive(PROTOCOL, 5)
        
        if #msg == 0 then
            print("None")
            return false
        end
        print_headers()

        for _, _table in pairs(msg) do
            local full_str = ""
            for __, _value in pairs(_table) do
                full_str = full_str.._value.." "
            end
            print(full_str)
        end
        return true
    end

    if cmd[1] == "delete_row" then
        if not IS_CONNECTED then
            print("[!] You are not connected")
            return false
        end

        if #cmd < 3 then
            print("[!] Usage: delete_row <header> <value>")
            return false
        end
        send_to_host("DELETE_ROW_BY_HEADER "..cmd[2].." "..cmd[3])
        local c_id, msg, p = rednet.receive(PROTOCOL, 5)
        
        if msg == false then
            print("Could not find row to delete")
            return false
        end

        print("Row deleted")
        return true
    end

    if cmd[1] == "update_row" then
        if not IS_CONNECTED then
            print("[!] You are not connected")
            return false
        end

        if #cmd < 5 then
            print("[!] Usage: update_row <header_to_find> <value_to_find> <header_to_update> <value_to_update>")
            return false
        end
        send_to_host("UPDATE_ROW_BY_HEADER "..cmd[2].." "..cmd[3].." "..cmd[4].." "..cmd[5])
        local c_id, msg, p = rednet.receive(PROTOCOL, 5)
        
        if msg == false then
            print("Could not update row")
            return false
        end

        print("Row updated")
        return true
    end

    if cmd[1] == "insert" then
        if not IS_CONNECTED then
            print("[!] You are not connected")
            return false
        end

        if #cmd < 2 then
            print("[!] Usage: insert column1,column2,column3...")
            return false
        end
        send_to_host("INSERT "..cmd[2])
        local c_id, msg, p = rednet.receive(PROTOCOL, 5)
        
        if msg == false then
            print("Could not insert data")
            return false
        end

        print("Data inserted")
        return true
    end

    print("[!] Unknown command: "..cmd[1])
    return false
end

function client_loop()
    while true do
        if IS_CONNECTED then
            io.stdout:write("DB ["..HOST.."]>")
        else
            io.stdout:write("DB >")
        end
        local inp = io.stdin:read()
        local inp_split = split_string(inp, " ")

        if inp == "exit" or inp == "quit" then
            break
        end
        command_handler(inp_split)
    end
    print("Bye")
    return true
end

client_loop()