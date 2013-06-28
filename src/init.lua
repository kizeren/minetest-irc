
-- This file is licensed under the terms of the WTFPL license.
-- See LICENSE.txt for details.


mt_irc = {
	connected = false,
	cur_time = 0,
	message_buffer = {},
	recent_message_count = 0,
	modpath = minetest.get_modpath("irc")
}

-- To find LuaIRC and LuaSocket
package.path = mt_irc.modpath.."/?/init.lua;"
		..mt_irc.modpath.."/irc/?.lua;"
		..mt_irc.modpath.."/?.lua;"
		..package.path
package.cpath = mt_irc.modpath.."/lib?.so;"
		..mt_irc.modpath.."/?.dll;"
		..package.cpath

local irc = require('irc')

dofile(mt_irc.modpath.."/config.lua")
dofile(mt_irc.modpath.."/messages.lua")
dofile(mt_irc.modpath.."/hooks.lua")
dofile(mt_irc.modpath.."/callback.lua")
dofile(mt_irc.modpath.."/chatcmds.lua")
dofile(mt_irc.modpath.."/botcmds.lua")
dofile(mt_irc.modpath.."/player_join.lua")
dofile(mt_irc.modpath.."/util.lua")

minetest.register_privilege("irc_admin", {
	description = "Allow IRC administrative tasks to be performed.",
	give_to_singleplayer = true
})


minetest.register_globalstep(function(dtime) return mt_irc:step(dtime) end)

function mt_irc:step(dtime)
	if not self.connected then return end

	-- Tick down the recent message count
	self.cur_time = self.cur_time + dtime
	if self.cur_time >= self.config.interval then
		if self.recent_message_count > 0 then
			self.recent_message_count = self.recent_message_count - 1
		end
		self.cur_time = self.cur_time - self.config.interval
	end

	self.conn:think()

	-- Send messages in the buffer
	if #self.message_buffer > 10 then
		minetest.log("error", "IRC: Message buffer overflow, clearing.")
		self.message_buffer = {}
	elseif #self.message_buffer > 0 then
		for i=1, #self.message_buffer do
			if self.recent_message_count > 4 then break end
			self.recent_message_count = self.recent_message_count + 1
			local msg = table.remove(self.message_buffer, 1) --Pop the first message
			self:send(msg)
		end
	end
end


function mt_irc:connect()
	if self.connected then
		minetest.log("error", "IRC: Ignoring attempt to connect when already connected.")
		return
	end
	self.conn = irc.new({
		nick = self.config.nick,
		username = "Minetest",
		realname = "Minetest"
	})
	self:doHook(self.conn)
	good, message = pcall(
	function()
		mt_irc.conn:connect({
			host = mt_irc.config.server,
			port = mt_irc.config.port,
			pass = mt_irc.config.password,
			timeout = mt_irc.config.timeout,
			secure = mt_irc.config.secure
		})
	end)

	if not good then
		minetest.log("error", "IRC: Connection error: "..self.config.server..": "..message)
		return
	end

	if self.config.NSPass then
		self:say("NickServ", "IDENTIFY "..self.config.NSPass)
	end

	self.conn:join(self.config.channel, self.config.key)
	self.connected = true
	minetest.log("action", "IRC: Connected!")
	minetest.chat_send_all("IRC: Connected!")
end


function mt_irc:disconnect(message)
	--The OnDisconnect hook will clear self.connected and print a disconnect message
	self.conn:disconnect(message)
end


function mt_irc:say(to, message)
	if not message then
		message = to
		to = self.config.channel
	end
	to = to or self.config.channel

	self:queueMsg(self.msgs.privmsg(to, message))
end


function mt_irc:send(line)
	self.conn:send(line)
end


if mt_irc.config.auto_connect then
	mt_irc:connect()
end

