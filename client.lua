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
    for c in data:gmatch"." do
        ciphertext = ciphertext .. bit.bxor(string.byte(c), string.byte(string.sub(ENCRYPTION_KEY,_,_))) .. ","
        _ = _ + 1
    end
    return string.sub(ciphertext, 1,-2)
end

function decrypt(data)
    local plaintext = ""
    local _ = 1
    for c in data:gmatch"([^,]+)" do
        plaintext = plaintext .. string.char(bit.bxor(tonumber(c), string.byte(string.sub(ENCRYPTION_KEY,_,_))))
        _ = _ + 1
    end
    return plaintext
end

function connect(host, username, password)
    rednet.open(MODEM_SIDE)
    rednet.send(host, ""..username.." "..password.." list", PROTOCOL)
    c_id, msg, p = rednet.receive(PROTOCOL, 5)
    if msg == nil then
        return "TIMEOUT"
    end

    if msg == "NO_CHALLENGE_CODE" then
        if ENCRYPTION_KEYS[host] == nil then
            return "NO_ENCRYPTION_KEY"
        end
        IS_ENCRYPTED = true
        c_id, msg, p = rednet.send(host, "CHALLENGE", PROTOCOL)
        CHAL_CODE = msg
    end

    c_id, msg, p = rednet.send(host, ""..username.." "..encrypt(host, password..CHAL_CODE).." list", PROTOCOL)
    IS_CONNECTED = true
    return msg
end