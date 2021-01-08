if not ngx.var.arg_info_hash then
    ngx.say("empty info_hash")
    ngx.exit(ngx.HTTP_BAD_REQUEST)
end
if not ngx.var.arg_peer_id then
	ngx.say("empty peer_id")
    ngx.exit(ngx.HTTP_BAD_REQUEST)
end

local ev = ngx.var.arg_event
if ev then
    if not ev ~= "completed" and not ev ~= "started" and not ev ~= "stopped" then
        ngx.say("d14:failure reason13:invalid evente")
        ngx.exit(ngx.HTTP_OK)
    end
end
