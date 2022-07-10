MODEM_SIDE = "top"
DATABASE_FILE = "database.txt"
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
db = DataBlockDB:new(nil, 'example_database.txt')

function encrypt(data)
    local ciphertext = ""
    local _ = 1
    for c in data:gmatch"." do
        ciphertext = ciphertext .. (bit.bxor(string.byte(c), string.byte(string.sub(ENCRYPTION_KEY,_,_)))) .. ","
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

function main()
    rednet.open(MODEM_SIDE)
    rednet.host(PROTOCOL, HOSTNAME)
    local restart_loop = false
    while true do
        local client_id, msg, prot = rednet.receive(PROTOCOL)
        local client_chal_code = CLIENT_CHAL_CODES[client_id]
        if ENABLE_ENCRYPTION then
            if client_chal_code == nil then
                if not msg == "CHALLENGE" then
                    rednet.send(client_id, "NO_CHALLENGE_CODE", PROTOCOL)
                else
                    CLIENT_CHAL_CODES[client_id] = generate_challenge_code(3)
                    rednet.send(client_id, CLIENT_CHAL_CODES[client_id], PROTOCOL)
                end
                restart_loop = true
            end
        end

        if not restart_loop then
            msg_split = split_string(msg, " ")
            if table_length(msg_split) < 2 then
                rednet.send(client_id, "INVALID_CREDENTIALS", PROTOCOL)
            else
                if not msg_split[1] == USER_NAME then
                    rednet.send(client_id, "INVALID_CREDENTIALS", PROTOCOL)
                else
                    if ENABLE_ENCRYPTION then
                        local pass_raw = decrypt(msg[2])
                        local pass_chal = string.sub(pass_raw, -3,-1)
                        local pass_real = string.sub(pass_raw, 1,-4)
        
                        if not pass_chal == CLIENT_CHAL_CODES[client_id] then
                            rednet.send(client_id, "INVALID_CREDENTIALS", PROTOCOL)
                            restart_loop = true
                        else
                            if not pass_real == USER_PASS then
                                rednet.send(client_id, "INVALID_CREDENTIALS", PROTOCOL)
                                restart_loop = true
                            end
                        end        
                    else
                        if not msg[2] == USER_PASS then
                            rednet.send(client_id, "INVALID_CREDENTIALS", PROTOCOL)
                            restart_loop = true
                        end
                    end

                    if not restart_loop then
                        CLIENT_CHAL_CODES[client_id] = nil
                        client_handler(client_id, msg_split)
                    end
                end
            end
        end
    end
end

function client_handler(client_id, msg)
    print(msg)
    rednet.send(client_id, "SUCCESS", PROTOCOL)
    return true
end