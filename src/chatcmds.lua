-- This file is licensed under the terms of the WTFPL license.
-- See LICENSE.txt for details.

-- Note: This file does NOT conatin every chat command, only general ones.
-- Feature-specific commands (like /join) are in their own files.


minetest.register_chatcommand("irc_msg", {
	params = "<name> <message>",
	description = "Send a private message to an IRC user",
	privs = {shout=true},
	func = function(name, param)
		if not mt_irc.connected then
			minetest.chat_send_player(name, "Not connected to IRC. Use /irc_connect to connect.")
			return
		end
		local found, _, toname, message = param:find("^([^%s#&]+)%s(.+)")
		if not found then
			minetest.chat_send_player(name, "Invalid usage, see /help irc_msg.")
			return
		end
		mt_irc:queueMsg(mt_irc.msgs.playerMessage(toname, name, message))
		minetest.chat_send_player(name, "Message sent!")
	end
})


minetest.register_chatcommand("irc_connect", {
	description = "Connect to the IRC server.",
	privs = {irc_admin=true},
	func = function(name, param)
		if mt_irc.connected then
			minetest.chat_send_player(name, "You are already connected to IRC.")
			return
		end
		minetest.chat_send_player(name, "IRC: Connecting...")
		mt_irc:connect()
	end
})


minetest.register_chatcommand("irc_disconnect", {
	description = "Disconnect from the IRC server.",
	privs = {irc_admin=true},
	func = function(name, param)
		if not mt_irc.connected then
			minetest.chat_send_player(name, "You are not connected to IRC.")
			return
		end
		mt_irc:disconnect("Manual disconnect.")
	end
})


minetest.register_chatcommand("irc_reconnect", {
	description = "Reconnect to the IRC server.",
	privs = {irc_admin=true},
	func = function(name, param)
		if not mt_irc.connected then
			minetest.chat_send_player(name, "You are not connected to IRC.")
			return
		end
		mt_irc:disconnect("Reconnecting...")
		mt_irc:connect()
	end
})


local oldme = minetest.chatcommands["me"].func
minetest.chatcommands["me"].func = function(name, param)
	oldme(name, param)
	mt_irc:say(("* %s %s"):format(name, param))
end

