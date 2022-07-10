MODEM_SIDE = "top"
DATABASE_FILE = "example_database.txt"
PROTOCOL = "DBDB"
HOSTNAME = "WORKGROUP"
READ_ONLY = false

USER_NAME = "DB_USER"
USER_PASS = "default"

-- WARNING: Encryption only protects against replay attacks, but does not protect against reading the sent commands and the recieved data
ENABLE_ENCRYPTION = true
ENCRYPTION_KEY = "9f8jhf98hu9f48jf934u8fhe9"
CLIENT_CHAL_CODES = {}

require "datablockdb"
db = DataBlockDB:new(nil, DATABASE_FILE)

function encrypt(data)
    local ciphertext = ""
    local _ = 1
    data = ""..data
    for c in data:gmatch"." do
        ciphertext = ciphertext .. (bit.bxor(string.byte(c), string.byte(string.sub(ENCRYPTION_KEY,_,_)))) .. ","
        _ = _ + 1
    end
    return string.sub(ciphertext, 1,-2)
end

function decrypt(data)
    local plaintext = ""
    local _ = 1
    data = ""..data
    for c in data:gmatch"([^,]+)" do
        plaintext = plaintext .. string.char(bit.bxor(tonumber(c), string.byte(string.sub(ENCRYPTION_KEY,_,_))))
        _ = _ + 1
    end
    return plaintext
end

function table_length(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

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

function generate_challenge_code(size)
    size = size or 3
    math.randomseed(os.time())
    local code = math.floor(math.random() * 1000)
    if string.len(""..code) > size then
        code = code - 1
    end
    return code
end

function log(client_id, message)
    print("[Client #"..client_id.."] "..message)
    return true
end

function main()
    rednet.open(MODEM_SIDE)
    local event, sender, message, protocol = os.pullEvent("rednet_message")
    if protocol ~= PROTOCOL then
        log(sender, "Failed to connected with protocol "..protocol)
        return false
    end
    log(sender, "Connected with protocol "..protocol)

    msg_split = split_string(message, ' ')
    if message == "CHALLENGE" then
        log(sender, "Generated new challenge code")
        CLIENT_CHAL_CODES[sender] = generate_challenge_code(3)
        rednet.send(sender, CLIENT_CHAL_CODES[sender], PROTOCOL)
        return true
    end

    if ENABLE_ENCRYPTION and CLIENT_CHAL_CODES[sender] == nil then
        log(sender, "No challenge code found")
        rednet.send(sender, "NO_CHALLENGE_CODE", PROTOCOL)
        return false
    end
    local raw_user, raw_pass = msg_split[1], msg_split[2]

    if ENABLE_ENCRYPTION then
        raw_pass = decrypt(raw_pass)
        -- TODO: Add password length requirements 
        local raw_pass_challenge, raw_pass_real = string.sub(raw_pass, -3, -1), string.sub(raw_pass, 1, -4)
        if raw_user ~= USER_NAME or raw_pass_real ~= USER_PASS then
            log(sender, "Sent invalid credentials")
            rednet.send(sender, "INVALID_CREDENTIALS", PROTOCOL)
            return false
        end
    else
        if raw_user ~= USER_NAME or raw_pass ~= USER_PASS then
            log(sender, "Sent invalid credentials")
            rednet.send(sender, "INVALID_CREDENTIALS", PROTOCOL)
            return false
        end
    end
    CLIENT_CHAL_CODES[sender] = nil
    table.remove(msg_split, 1)
    table.remove(msg_split, 1)
    rednet.send(sender, "INVALID_CREDENTIALS", PROTOCOL)
    log(sender, "Sent: ".. message)
end

log("SERVER", "Started listening...")
while true do
    main()
end