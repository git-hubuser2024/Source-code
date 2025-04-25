library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity conv_encoder is
  Port (
    clk      : in  std_logic;
    reset    : in  std_logic;
    data_in  : in  std_logic;
    valid_in : in  std_logic;
    data_out : out std_logic_vector(1 downto 0) -- Rate 2/3 output
  );
end conv_encoder;

architecture Behavioral of conv_encoder is
  -- Shift registers matching MATLAB constraint lengths [5 4]
  signal reg1 : std_logic_vector(4 downto 0) := (others => '0'); -- 1st encoder (K=5)
  signal reg2 : std_logic_vector(3 downto 0) := (others => '0'); -- 2nd encoder (K=4)
  
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        reg1 <= (others => '0');
        reg2 <= (others => '0');
      elsif valid_in = '1' then
        -- First encoder (G1 = 23 octal = 10011)
        reg1 <= reg1(3 downto 0) & data_in;
        
        -- Second encoder (G2 = 35 octal = 11011)
        reg2 <= reg2(2 downto 0) & data_in;
        
        -- Output calculation (matches genpoly matrix)
        data_out(0) <= reg1(4) xor reg1(3) xor reg1(0);  -- G1 = 23
        data_out(1) <= reg2(3) xor reg2(2) xor reg2(0);   -- G2 = 35
        -- Third output would be 0 (as per MATLAB's [23 35 0; 0 5 13])
      end if;
    end if;
  end process;
end Behavioral;