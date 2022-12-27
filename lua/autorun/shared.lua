local chatDelay = 0.3

local colors = {}
colors.black 	= Color( 0, 0, 0 )
colors.white 	= Color( 255, 255, 255 )
colors.red 		= Color( 255, 0, 0 )
colors.orange	= Color( 255, 125, 0 )
colors.yellow 	= Color( 255, 255, 0 )
colors.green 	= Color( 0, 255, 0 )
colors.cyan 	= Color( 0, 255, 255 )
colors.blue 	= Color( 0, 0, 255 )
	
	
if ( SERVER ) then
	hook.Add( "Initialize", "StasisAIInit", function()
		util.AddNetworkString( "AIResponse" )
	end )
	
	--==================================================
	-- AI Config
	--==================================================
	StasisAI = {}
	
	StasisAI.Config = {}

	StasisAI.Config.AllowedTeams = {
		["Fleet Admiral"] = true,
		["Fleet Commander"] = true,
		["Fleet Officer"] = true,
		["93rd Chief Engineer"] = true,
		["93rd Mechanical Engineer"] = true,
		["93rd Medical Engineer"] = true,
		["93rd Officer"] = true,
		["93rd Recruit"] = true
	}
	
	StasisAI.Config.AllowedUserGroups = {
		["superadmin"] = true,
		["admin"] = true,
		["seniorevent"] = true,
		["event"] = true,
		["user"] = true,
	}
	
	StasisAI.Config.ChatCommand = "Cabal,"
	
	StasisAI.Config.Prefix = "[C.A.B.A.L]"
	StasisAI.Config.PrefixColor = Color( 150, 0, 255 )

	StasisAI.Config.Systems = {
		["scanners"] = {
			Name 	= "Scanning System",
			Status 	= true,
			HostileTeams = {
				["B1 Battledroid"] = true,
				["B2 Super Battledroid"] = true,
				["Sith"] = true,
			},
			Delay = 18
		},
		["hyperdrive"] = {
			Name	= "Hyperdrive System",
			Status 	= true
		}
	}
	
	
	--==================================================
	-- Utility
	--==================================================
	local function AIPrefix()
		return { StasisAI.Config.PrefixColor, StasisAI.Config.Prefix .. " " }
	end

	local meta = FindMetaTable( "Player" )
	
	function meta:CanUseAI()
		local team 		= team.GetName( self:Team() )
		local usergroup = self:GetUserGroup()
		
		return StasisAI.Config.AllowedTeams[ team ] or StasisAI.Config.AllowedUserGroups[ usergroup ]
	end
	
	function meta:AIResponse( tbl )
		net.Start( "AIResponse" )
			net.WriteTable( table.Add( AIPrefix(), tbl ) )
		net.Send( self )
	end
	
	function meta:AIError( tbl )
		self:AIResponse( table.Add( { colors.red, "Error: " }, tbl ) )
	end
	
	function AIBroadcast( tbl )
		net.Start( "AIResponse" )
			net.WriteTable( tbl )
		net.Broadcast()
	end
	
	
	--==================================================
	-- AI Functions
	--==================================================	
	local function Ping( ply )
		ply:AIResponse( { Color( 50, 200, 50 ), "Pong!" } )
	end
	
	local function IsOnline( system )
		local system = StasisAI.Config.Systems[ system ]
		
		if ( system ) then
			return system.Status
		else
			print( "ERROR: SYSTEM NOT FOUND: " .. system )
		end
	end
	
	-- Ship Status
	function meta:Status()
		local online = true
		local count = 0
		
		for k, v in pairs( StasisAI.Config.Systems ) do
			local color
			local msg
			if ( v.Status ) then
				color = colors.green
				msg = "Online"
			else
				color = colors.red
				msg = "Offline"
			end
			
			timer.Simple( count * chatDelay, function()
				self:AIResponse( { colors.white, v.Name, color, ": " .. msg .. "" } )
			end )
			
			count = count + 1
		end
	end
	
	-- Ship Scan
	function meta:Scan()
		if ( IsOnline( "scanners" ) ) then
			local scanners = StasisAI.Config.Systems[ "scanners" ]
			self:AIResponse( { colors.orange, "-= Beginning ship-wide scan of all entities =-" })
			
			timer.Simple( scanners.Delay * 0.25, function()
				self:AIResponse( { colors.orange, "-= Scan progress : 25% =-" } )
			end )
			
			timer.Simple( scanners.Delay * 0.5, function()
				self:AIResponse( { colors.orange, "-= Scan progress : 50% =-" } )
			end )
			
			timer.Simple( scanners.Delay * 0.75, function()
				self:AIResponse( { colors.orange, "-= Scan progress : 75% =-" } )
			end )
			
			timer.Simple( scanners.Delay, function()
				self:AIResponse( { colors.orange, "-= Scan complete =-" } )
			end )
			
			timer.Simple( scanners.Delay + 1, function()
				self:AIResponse( { colors.orange, "-= Beginning scan report =-" } )
			end )
			
			timer.Simple( scanners.Delay + 1.5, function()
				local hostiles = 0
				
				for _,v in ipairs( player.GetAll() ) do
					if ( scanners.HostileTeams[ team.GetName( v:Team() ) ] ) then
						hostiles = hostiles + 1
					end
				end
				
				local col = colors.green
				local msg = "hostiles"
				if ( hostiles > 0 ) then
					if ( hostiles == 1 ) then
						msg = "hostile"
					end
					col = colors.red
				end
				
				self:AIResponse( { col, tostring( hostiles ), colors.white, " " .. msg .. " detected" } )
			end )
			
			timer.Simple( scanners.Delay + 2, function()
				self:AIResponse( { colors.orange, "-= Scan report completed =-" } )
			end )
		end
	end
	
	
	--==================================================
	-- Hook
	--==================================================
	hook.Add( "PlayerSay", "StasisAI", function( ply, text, bTeam )
		local params 	= string.Split( string.lower( text ), " " )
		local cmd	= table.remove( params, 1 )
		local paramStr = table.concat( params, " " )
		
		-- Cabal keyword
		if ( cmd == string.lower( StasisAI.Config.ChatCommand ) ) then
			ply:ChatPrint( "CABAL RECEIVED" )
			
			if ( !ply:CanUseAI() ) then
				ply:AIError( { colors.white, "Insufficient clearance level" })
				return
			end
			
			if ( string.find( paramStr, "status" ) ) then
				ply:Status()
				return
			end
			
			if ( string.find( paramStr, "scan the ship" ) ) then
				ply:Scan()
				return
			end
		end
	end )
	
	
else
	--==================================================
	-- Output AI message
	--==================================================
	net.Receive( "AIResponse", function( len, ply )
		local response = net.ReadTable()
		timer.Simple( chatDelay, function()
			chat.AddText( unpack( response ) )
		end )
	end )
	
	
end