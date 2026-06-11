import "CoreLibs/graphics"
import "CoreLibs/utilities/where"
import "CoreLibs/object"

local gfx <const> = playdate.graphics
local net <const> = playdate.network

playdate.display.setRefreshRate(50)

local status_str = "Not Connected"

function networkStatus()
    local status = net.getStatus()

    if status == net.kStatusConnected then
        status_str = "Connected"
    elseif status == net.kStatusNotAvailable then
        status_str = "Not Available"
    end
end

local tcp_done = false
local http_done = false
local time_done = false
local tcp_result = ""
local http_result = ""
local time_result = ""
local http_waiting = false
local http_data_received = false
local http_conn = nil
time_waiting = false
local start_time <const> = playdate.getCurrentTimeMilliseconds()

local RUN_TCP <const> = true
local RUN_HTTP <const> = true
local RUN_TIME <const> = true

function timeLog(text)
    now = playdate.getCurrentTimeMilliseconds()
    elapsed = now - start_time
    print(string.format("[%i] %s", elapsed, text))
end

function headersRead()
    timeLog("HTTP headersRead called")

    local response = http_conn:getResponseStatus()
    timeLog(string.format("\tHTTP GET getResponseStatus: %i", response))


end

function connectionClosed()
    timeLog("HTTP connectionClosed called")
end

function requestComplete()
    -- This will be called when a request is complete or a request timeout occurs
    local err = http_conn:getError()
    timeLog("HTTP requestComplete called, error="..(err or "nil"))

    if err ~= nil and err ~= "Connection closed" then
        http_done = true
        http_result = err
    end
end

function requestCallback()
    timeLog("HTTP requestCallback called, "..http_conn:getBytesAvailable().." bytes are available for reading")

    -- Show initial progress
    local current, total = http_conn:getProgress()
    timeLog(string.format("\tHTTP GET getProgress: %i / %i", current, total))

    -- check the number of bytes available to read
    local bytes = http_conn:getBytesAvailable()
    timeLog(string.format("\tHTTP GET getBytesAvailable: %i", bytes))

    -- read that number of bytes
    http_result = http_conn:read(bytes)
    timeLog(string.format("\tHTTP data received: %s", http_result))

    -- Show final progress
    current, total = http_conn:getProgress()
    timeLog(string.format("\tHTTP GET getProgress: %i / %i", current, total))

    timeLog("Response headers")
    printTable(http_conn:getResponseHeaders())

    http_data_received = true

end

function playdate.update()
    networkStatus()

    gfx.clear()
    t = string.format(
        "Status: %s\nTCP: %s\nHTTP: %s\nTime: %s\nTCP Complete: %s\nHTTP Complete: %s\nTime Complete: %s",
        status_str,
        tcp_result, http_result, time_result,
        tcp_done, http_done, time_done
    )
    gfx.drawTextInRect(t, 10, 10, 380, 220)

    if RUN_TCP and not tcp_done then

        local tcp_conn = net.tcp.new("localhost", 65431)

        -- If the user disallows the connection tcp_conn will be false
        assert(tcp_conn, "The user needs to allows this")

        tcp_conn:setConnectTimeout(2)

        -- example of an anonymous function callback
        tcp_conn:setConnectionClosedCallback(function ()
            timeLog("TCP connection was closed")
        end)

        local write_result, write_error
        local write_complete = false

        tcp_conn:open(function (connected, open_error)

            -- this is called when the connection opens or times out
            timeLog(string.format("TCP connected: %s Error: %s", tostring(connected), tostring(open_error)))

            if not connected then
                tcp_result = open_error
            else
                write_result, tcp_result = tcp_conn:write("PING")
                timeLog(string.format("TCP write: %s Result: %s", tostring(write_result), tostring(tcp_result)))
            end

            write_complete = true
        end)

        while not write_complete do
            local wait_time = 100
            timeLog(string.format("TCP Waiting %i ms for TCP open & write to complete…", wait_time))
            playdate.wait(wait_time)
        end

        if write_result then
            tcp_result = ""

            local bytes = tcp_conn:getBytesAvailable()
            local timeout = 0
            while bytes == 0 and timeout < 5 do
                timeLog("TCP Waiting for data…")
                playdate.wait(200)
                timeout += 1
                bytes = tcp_conn:getBytesAvailable()
            end

            while bytes > 0 do
                timeLog("TCP Bytes available from server: " .. bytes)
                local bytes_read, num_bytes_read = tcp_conn:read(bytes)
                tcp_result = tcp_result .. bytes_read
                timeLog(string.format("TCP Read %i from the server", num_bytes_read))
                bytes = tcp_conn:getBytesAvailable()
            end

            if tcp_result == "" then
                tcp_result = "TCP No Data received"
            end

            tcp_conn:close()

        end

        tcp_done = true
    end

    if RUN_HTTP and not http_done then

        if not http_waiting then

            http_conn = net.http.new("localhost", 65433, false, "HTTP Demo")
            assert(http_conn, "The user needs to allows this")

            http_conn:setHeadersReadCallback(headersRead)
            http_conn:setConnectionClosedCallback(connectionClosed)
            http_conn:setRequestCompleteCallback(requestComplete)
            http_conn:setRequestCallback(requestCallback)

            http_conn:setConnectTimeout(2)
            http_conn:setKeepAlive(true)

            -- Send a GET request
            local get_request, get_error = http_conn:get("/PING")
            assert(get_request, get_error)

            http_waiting = true

        else
            -- we're waiting for the data to be received
            if http_data_received then

                -- With keep-alive enabled close has to be explicitly called
                timeLog("Calling close()")
                http_conn:close()
                http_done = true
            else
                local wait_time = 100
                timeLog(string.format("HTTP Waiting %i ms for data…: %s", wait_time, http_conn:getError() or "OK"))
                playdate.wait(wait_time)
            end
        end
    end

    if RUN_TIME and not time_done then
        
        if not time_waiting then
            
            playdate.getServerTime(function(time, error)
                timeLog("getServerTime callback called")
                if time ~= nil then
                    time_result = time
                else
                    time_result = error
                end
                time_done = true
            end)
            
            time_waiting = true
        end
    end

end
