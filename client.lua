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
            full_str = full_str..key.." "
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
        local full_str = ""
        local res = send_to_host("GET_ROW_BY_HEADER "..cmd[2].." "....cmd[3])
        if #res < 1 then
            print("None")
            return false
        end

        for key,value in pairs(res) do
            full_str = full_str..key.." "
        end
        print(string.sub(full_str, 1,-2))
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