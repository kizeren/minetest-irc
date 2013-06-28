-- This file is licensed under the terms of the WTFPL license.
-- See LICENSE.txt for details.


mt_irc.hooks = {}
mt_irc.registered_hooks = {}


function mt_irc:doHook(conn)
	for name, hook in pairs(self.registered_hooks) do
		for _, func in pairs(hook) do
			conn:hook(name, func)
		end
	end
end


function mt_irc:register_hook(name, func)
	self.registered_hooks[name] = self.registered_hooks[name] or {}
	table.insert(self.registered_hooks[name], func)
end


function mt_irc.hooks.raw(line)
	if mt_irc.config.debug then
		print("RECV: "..line)
	end
end


function mt_irc.hooks.send(line)
	if mt_irc.config.debug then
		print("SEND: "..line)
	end
end


function mt_irc.hooks.chat(user, channel, message)
	if channel == mt_irc.conn.nick then
		mt_irc.conn:invoke("PrivateMessage", user, message)
	else
		local c = string.char(1)
		local found, _, action = message:find(("^%sACTION ([^%s]*)%s$"):format(c, c, c))
		if found then
			mt_irc.conn:invoke("OnChannelAction", user, channel, action)
		else
			mt_irc.conn:invoke("OnChannelChat", user, channel, message)
		end
	end
end


function mt_irc.hooks.channelChat(user, channel, message)
	local t = {
		access=user.access,
		name=user.nick,
		message=message,
		server=mt_irc.conn.host,
		port=mt_irc.conn.port,
		channel=channel
	}
	local text = mt_irc.config.format_in:expandvars(t)
	mt_irc:sendLocal(text)
end


function mt_irc.hooks.pm(user, message)
	local player_to
	local msg
	if message:sub(1, 1) == "@" then
		local found, _, player_to, message = message:find("^.([^%s]+)%s(.+)$")
		if mt_irc.joined_players and not mt_irc.joined_players[player_to] then
			mt_irc:say(user.nick, "User '"..player_to.."' has parted.")
			return
		elseif not minetest.get_player_by_name(player_to) then
			mt_irc:say(user.nick, "User '"..player_to.."' is not in the game.")
			return
		end
		local t = {
			name=user.nick,
			message=message,
			server=mt_irc.server,
			port=mt_irc.port,
			channel=mt_irc.channel
		}
		local text = mt_irc.config.format_in:expandvars(t)
		minetest.chat_send_player(player_to, "PM: "..text, false)
		mt_irc:say(user.nick, "Message sent!")
	elseif message:sub(1, 1) == "!" then
		mt_irc:bot_command(user, message:sub(2))
		return
	else
		mt_irc:say(user.nick, "Invalid command. Use '"
				..mt_irc.config.command_prefix
				.."list' to see possible commands.")
		return
	end
end


function mt_irc.hooks.kick(channel, target, prefix, reason)
	if target == mt_irc.conn.nick then
		minetest.chat_send_all("IRC: kicked from "..channel.." by "..prefix.nick..".")
		mt_irc:disconnect("Kicked")
	else
		mt_irc:sendLocal(("-!- %s was kicked from %s by %s [%s]")
				:format(target, channel, prefix.nick, reason))
	end
end


function mt_irc.hooks.notice(user, target, message)
	if not user.nick then return end --Server NOTICEs
	if target == mt_irc.conn.nick then return end
	mt_irc:sendLocal("--"..user.nick.."@IRC-- "..message)
end


function mt_irc.hooks.mode(user, target, modes, ...)
	local by = ""
	if user.nick then
		by = " by "..user.nick
	end
	local options = ""
	for _, option in pairs({...}) do
		options = options.." "..option
	end
	minetest.chat_send_all(("-!- mode/%s [%s%s]%s")
			:format(target, modes, options, by))
end


function mt_irc.hooks.nick(user, newNick)
	mt_irc:sendLocal(("-!- %s is now known as %s")
			:format(user.nick, newNick))
end


function mt_irc.hooks.join(user, channel)
	mt_irc:sendLocal(("-!- %s joined %s")
			:format(user.nick, channel))
end


function mt_irc.hooks.part(user, channel, reason)
	reason = reason or ""
	mt_irc:sendLocal(("-!- %s has left %s [%s]")
			:format(user.nick, channel, reason))
end


function mt_irc.hooks.quit(user, reason)
	mt_irc:sendLocal(("-!- %s has quit [%s]")
			:format(user.nick, reason))
end


function mt_irc.hooks.action(user, channel, message)
	mt_irc:sendLocal(("* %s@IRC %s")
			:format(user.nick, message))
end


function mt_irc.hooks.disconnect(message, isError)
	mt_irc.connected = false
	if isError then
		minetest.log("error",  "IRC: Error: Disconnected, reconnecting in one minute.")
		minetest.chat_send_all("IRC: Error: Disconnected, reconnecting in one minute.")
		minetest.after(60, mt_irc.connect)
	else
		minetest.log("action", "IRC: Disconnected.")
		minetest.chat_send_all("IRC: Disconnected.")
	end
end


function mt_irc.hooks.preregister(irc)
	if not (mt_irc.SASLUser and mt_irc.SASLPass) then return end
	local authString = mt_irc.b64e(
		("%s\x00%s\x00%s"):format(
		mt_irc.config.SASLUser,
		mt_irc.config.SASLUser,
		mt_irc.config.SASLPass)
	)
	irc:send("CAP REQ sasl")
	irc:send("AUTHENTICATE PLAIN")
	irc:send("AUTHENTICATE "..authString)
	--LuaIRC will send CAP END
end


mt_irc:register_hook("PreRegister",     mt_irc.hooks.preregister)
mt_irc:register_hook("OnRaw",           mt_irc.hooks.raw)
mt_irc:register_hook("OnSend",          mt_irc.hooks.send)
mt_irc:register_hook("OnChat",          mt_irc.hooks.chat)
mt_irc:register_hook("OnPart",          mt_irc.hooks.part)
mt_irc:register_hook("OnKick",          mt_irc.hooks.kick)
mt_irc:register_hook("OnJoin",          mt_irc.hooks.join)
mt_irc:register_hook("OnQuit",          mt_irc.hooks.quit)
mt_irc:register_hook("NickChange",      mt_irc.hooks.nick)
mt_irc:register_hook("OnChannelAction", mt_irc.hooks.action)
mt_irc:register_hook("PrivateMessage",  mt_irc.hooks.pm)
mt_irc:register_hook("OnNotice",        mt_irc.hooks.notice)
mt_irc:register_hook("OnChannelChat",   mt_irc.hooks.channelChat)
mt_irc:register_hook("OnModeChange",    mt_irc.hooks.mode)
mt_irc:register_hook("OnDisconnect",    mt_irc.hooks.disconnect)

