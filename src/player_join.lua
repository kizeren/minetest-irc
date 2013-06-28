-- This file is licensed under the terms of the WTFPL license.
-- See LICENSE.txt for details.

-- This file is optional. If you want all players to be joined remove it.


mt_irc.joined_players = {}


function mt_irc:player_part(name)
	if not self.joined_players[name] then
		minetest.chat_send_player(name, "IRC: You are not in the channel.")
		return
	end
	self.joined_players[name] = nil
	minetest.chat_send_player(name, "IRC: You are now out of the channel.")
end
 
function mt_irc:player_join(name)
	if self.joined_players[name] then
		minetest.chat_send_player(name, "IRC: You are already in the channel.")
		return
	end
	self.joined_players[name] = true
	minetest.chat_send_player(name, "IRC: You are now in the channel.")
end


minetest.register_chatcommand("join", {
	description = "Join the IRC channel",
	privs = {shout=true},
	func = function(name, param)
		mt_irc:player_join(name)
	end
})
 
minetest.register_chatcommand("part", {
	description = "Part the IRC channel",
	privs = {shout=true},
	func = function(name, param)
		mt_irc:player_part(name)
	end
})
 
minetest.register_chatcommand("who", {
	description = "Tell who is currently on the channel",
	privs = {},
	func = function(name, param)
		local s = ""
		for name, _ in pairs(mt_irc.joined_players) do
			s = s..", "..name
		end
		minetest.chat_send_player(name, "Players On Channel:"..s)
	end
})


 
mt_irc:register_bot_command("who", {
	description = "Tell who is playing",
	func = function(user, args)
		local s = ""
		for name, _ in pairs(mt_irc.joined_players) do
			s = s.." "..name
		end
		mt_irc:say(user.nick, "Players On Channel:"..s)
	end
})

 
minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	mt_irc.joined_players[name] = mt_irc.config.auto_join
end)
 
 
minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	mt_irc.joined_players[name] = nil
end)

function mt_irc:sendLocal(message)
        for name, _ in pairs(self.joined_players) do
		minetest.chat_send_player(name, message, false)
	end
end

