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

function connect(host, username, password)
    local MESSAGE = nil
    rednet.open(MODEM_SIDE)
    if ENCRYPTION_KEYS[host] ~= nil then
        IS_ENCRYPTED = true
        rednet.send(host, "CHALLENGE", PROTOCOL)
        local c_id, msg, p = rednet.receive(PROTOCOL, 5)
        CHAL_CODE = msg
        rednet.send(host, ""..username.." "..encrypt(host,password..CHAL_CODE).." list", PROTOCOL)
        local c_id, msg, p = rednet.receive(PROTOCOL, 5)
        MESSAGE = msg
    else
        rednet.send(host, ""..username.." "..password.." list", PROTOCOL)
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
    return MESSAGE
end