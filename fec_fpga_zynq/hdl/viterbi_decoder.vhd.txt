library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity viterbi_decoder is
  Port (
    clk       : in  std_logic;
    reset     : in  std_logic;
    sym_in    : in  std_logic_vector(1 downto 0); -- 2-bit symbol input
    valid_in  : in  std_logic;
    data_out  : out std_logic;
    valid_out : out std_logic
  );
end viterbi_decoder;

architecture Behavioral of viterbi_decoder is
  constant TRACEBACK_DEPTH : integer := 16; -- Matches MATLAB parameter
  
  type path_metric_t is array(0 to 15) of unsigned(7 downto 0);
  type survivor_t is array(0 to 15) of std_logic_vector(TRACEBACK_DEPTH-1 downto 0);
  
  signal pm_current, pm_next : path_metric_t;
  signal surv_current, surv_next : survivor_t;
  signal dec_buffer : std_logic_vector(TRACEBACK_DEPTH-1 downto 0);
  
begin
  process(clk)
    variable bm : integer;
  begin
    if rising_edge(clk) then
      valid_out <= '0';
      
      if reset = '1' then
        pm_current <= (others => (others => '1'));
        pm_current(0) <= to_unsigned(0, 8);
        surv_current <= (others => (others => '0'));
      elsif valid_in = '1' then
        -- ACS Unit (Add-Compare-Select)
        for state in 0 to 15 loop
          -- Calculate branch metrics (Hamming distance)
          bm := (if sym_in(0) /= expected_output(state,0) then 1 else 0) + 
                (if sym_in(1) /= expected_output(state,1) then 1 else 0);
                
          -- Update path metrics
          if pm_next(state) > pm_current(state/2) + bm then
            pm_next(state) <= pm_current(state/2) + bm;
            surv_next(state) <= surv_current(state/2)(TRACEBACK_DEPTH-2 downto 0) & '0';
          else
            surv_next(state) <= surv_current(state/2 + 8)(TRACEBACK_DEPTH-2 downto 0) & '1';
          end if;
        end loop;
        
        -- Traceback decision
        data_out <= surv_current(0)(TRACEBACK_DEPTH-1);
        valid_out <= '1';
        
        pm_current <= pm_next;
        surv_current <= surv_next;
      end if;
    end if;
  end process;

  -- Function to generate expected outputs (matches encoder)
  function expected_output(state : integer; bit_pos : integer) return std_logic is
    variable reg1 : std_logic_vector(4 downto 0);
    variable reg2 : std_logic_vector(3 downto 0);
  begin
    reg1 := std_logic_vector(to_unsigned(state, 5));
    reg2 := std_logic_vector(to_unsigned(state, 4));
    
    case bit_pos is
      when 0 => return reg1(4) xor reg1(3) xor reg1(0); -- G1 = 23
      when 1 => return reg2(3) xor reg2(2) xor reg2(0);  -- G2 = 35
      when others => return '0';
    end case;
  end function;
end Behavioral;