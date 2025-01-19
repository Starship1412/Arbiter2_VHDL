library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity arbiter is
	port (
		clk : in std_logic;
		reset : in std_logic;
		cmd : in std_logic;
		req : in std_logic_vector(2 downto 0);
		gnt : out std_logic_vector(2 downto 0);
		n1, n2, n3 : out signed(2 downto 0)
	);
end arbiter;

architecture behavioral of arbiter is
	type state_type is (IDLE, READY_1, READY_2, GO);
	signal current_state, next_state : state_type := IDLE;
	signal counter : unsigned(1 downto 0) := to_unsigned(0, 2);
	signal req_temp, req_delayed, gnt_temp : std_logic_vector(2 downto 0) := (others => '0');
	signal n1_temp, n2_temp, n3_temp : signed(2 downto 0) := to_signed(0, 3);
begin
	gnt <= gnt_temp;
	n1 <= n1_temp;
	n2 <= n2_temp;
	n3 <= n3_temp;
	process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				req_delayed <= (others => '0');
				current_state <= IDLE;
			else
				req_delayed <= req;
				current_state <= next_state;
			end if;
		end if;
	end process;

	process(current_state, cmd)
	begin
		case current_state is
			when IDLE =>
				gnt_temp <= "000";
				counter <= to_unsigned(0, counter'length);
				if reset = '0' then
					if cmd = '1' then
						req_temp <= (others => '0');
						next_state <= READY_1;
					else
						if falling_edge(cmd) then
							req_temp <= req_delayed;
						end if;
						next_state <= IDLE;
					end if;
				else
					n1_temp <= to_signed(0, n1_temp'length);
					n2_temp <= to_signed(0, n2_temp'length);
					n3_temp <= to_signed(0, n3_temp'length);
					req_temp <= (others => '0');
					next_state <= IDLE;
				end if;
			when READY_1 =>
				gnt_temp <= "000";
 				if cmd = '0' then
 					if falling_edge(cmd) then
 						req_temp <= req_delayed;
 					end if;
 					if counter /= 2 then
						counter <= counter + 1;
						next_state <= READY_2;
					else
						counter <= to_unsigned(0, counter'length);
						next_state <= GO;
					end if;
				else
					counter <= to_unsigned(0, counter'length);
 					next_state <= READY_1;
				end if;
			when READY_2 =>
				gnt_temp <= "000";
				if cmd = '0' then
 					if falling_edge(cmd) then
 						req_temp <= req_delayed;
 					end if;
					if counter = 2 then
						counter <= to_unsigned(0, counter'length);
						next_state <= GO;
					else
						counter <= counter + 1;
						next_state <= READY_1;
					end if;
				else
					counter <= to_unsigned(0, counter'length);
					next_state <= READY_2;
				end if;
			when GO =>
				if cmd = '0' then
				    next_state <= IDLE;
				    if falling_edge(cmd) then
 						req_temp <= req_delayed;
 					end if;
					if req_temp = "000" then
  						gnt_temp <= "000";
					elsif req_temp = "001" then
						gnt_temp <= "001";
					elsif req_temp = "010" then
						gnt_temp <= "010";
					elsif req_temp = "100" then
						gnt_temp <= "100";
					elsif req_temp = "011" then
						if n1_temp <= n2_temp then
 							gnt_temp <= "001";
							n1_temp <= n1_temp + 1;
							n2_temp <= n2_temp - 1;
						else
							gnt_temp <= "010";
							n1_temp <= n1_temp - 1;
							n2_temp <= n2_temp + 1;
						end if;
					elsif req_temp = "101" then
						if n1_temp <= n3_temp then
							gnt_temp <= "001";
							n1_temp <= n1_temp + 1;
							n3_temp <= n3_temp - 1;
 						else
							gnt_temp <= "100";
							n1_temp <= n1_temp - 1;
							n3_temp <= n3_temp + 1;
						end if;
					elsif req_temp = "110" then
						if n2_temp <= n3_temp then
							gnt_temp <= "010";
							n2_temp <= n2_temp + 1;
							n3_temp <= n3_temp - 1;
						else
							gnt_temp <= "100";
							n2_temp <= n2_temp - 1;
							n3_temp <= n3_temp + 1;
						end if;
					elsif req_temp = "111" then
						if n1_temp <= n2_temp and n1_temp <= n3_temp then
							gnt_temp <= "001";
							n1_temp <= n1_temp + 2;
							n2_temp <= n2_temp - 1;
							n3_temp <= n3_temp - 1;
						elsif n2_temp <= n1_temp and n2_temp <= n3_temp then
							gnt_temp <= "010";
							n1_temp <= n1_temp - 1;
							n2_temp <= n2_temp + 2;
							n3_temp <= n3_temp - 1;
						elsif n3_temp <= n1_temp and n3_temp <= n2_temp then
							gnt_temp <= "100";
							n1_temp <= n1_temp - 1;
							n2_temp <= n2_temp - 1;
							n3_temp <= n3_temp + 2;
						end if;
					end if;
				else
					counter <= to_unsigned(0, counter'length);
					next_state <= READY_1;
				end if;
		end case;
	end process;
end behavioral;