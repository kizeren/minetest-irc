-- *************************
-- ** BASIC USER SETTINGS **
-- *************************

-- Server to connect on joinplayer (string, default "irc.freenode.net")
mt_irc.server = nil;

-- Port to connect on joinplayer (number, default 6667)
mt_irc.port = nil;

-- Channel to connect on joinplayer (string, default "#minetest-irc-testing")
mt_irc.channel = nil;

-- ***********************
-- ** ADVANCED SETTINGS **
-- ***********************

-- Time between chat updates in seconds (number, default 0.2).
mt_irc.dtime = nil;

-- Underlying socket timeout in seconds (number, default 1.0).
mt_irc.timeout = nil;

-- Nickname when using single conection (string, default "minetest-"..<server-id>);
--  (<server-id> is the server IP address packed as a 32 bit integer).
mt_irc.server_nick = nil;

-- Password to use when using single connection (string, default "")
mt_irc.password = nil;

-- The format of messages sent to IRC server (string, default "<$(name)> $(message)")
-- See `README.txt' for the macros supported here.
mt_irc.message_format_out = "<$(name)> $(message)";

-- The format of messages sent to IRC server (string, default "<$(name)@IRC> $(message)")
-- See `README.txt' for the macros supported here.
mt_irc.message_format_in = "<$(name)@IRC> $(message)";

-- Enable debug output (boolean, default false)
mt_irc.debug = true;

-- Whether to automatically join the channed when player joins
--  (boolean, default false)
-- For now leave this false if using autoconnect.  Bot will join channel when first user
-- types the /join command in game.
mt_irc.connect_on_join = false;

-- Whether to automatically connect to the server on mod load
--  (boolean, default false) 
mt_irc.connect_on_load = false;
