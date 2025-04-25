library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_decoder is
end tb_decoder;

architecture Behavioral of tb_decoder is
  component viterbi_decoder
    Port (
      clk       : in  std_logic;
      reset     : in  std_logic;
      sym_in    : in  std_logic_vector(1 downto 0);
      valid_in  : in  std_logic;
      data_out  : out std_logic;
      valid_out : out std_logic
    );
  end component;

  signal clk      : std_logic := '0';
  signal reset    : std_logic := '1';
  signal sym_in   : std_logic_vector(1 downto 0) := "00";
  signal valid_in : std_logic := '0';
  signal data_out : std_logic;
  signal valid_out: std_logic;

  -- MATLAB reference data
  type symb_array is array(0 to 1999) of std_logic_vector(1 downto 0);
  signal matlab_symbols : symb_array;
  signal expected_bits  : std_logic_vector(0 to 999);

begin
  uut: viterbi_decoder
  port map (
    clk       => clk,
    reset     => reset,
    sym_in    => sym_in,
    valid_in  => valid_in,
    data_out  => data_out,
    valid_out => valid_out
  );

  clk <= not clk after 5 ns;

  -- Load MATLAB-generated test vectors
  process
    file symfile : text open read_mode is "decoder_input.txt";
    file bitfile : text open read_mode is "encoder_input.txt";
    variable line_in : line;
    variable sym_val : integer;
    variable i : integer := 0;
  begin
    -- Read noisy symbols
    while not endfile(symfile) loop
      readline(symfile, line_in);
      read(line_in, sym_val);
      matlab_symbols(i) <= std_logic_vector(to_unsigned(sym_val, 2));
      i := i + 1;
    end loop;

    -- Read original bits for verification
    i := 0;
    while not endfile(bitfile) loop
      readline(bitfile, line_in);
      read(line_in, sym_val);
      expected_bits(i) <= '1' when sym_val = 1 else '0';
      i := i + 1;
    end loop;

    wait;
  end process;

  -- Stimulus process
  process
    variable errors : integer := 0;
  begin
    reset <= '1';
    wait for 20 ns;
    reset <= '0';

    -- Feed noisy symbols from MATLAB
    for i in 0 to 1999 loop
      sym_in <= matlab_symbols(i);
      valid_in <= '1';
      wait until rising_edge(clk);
    end loop;

    valid_in <= '0';

    -- Check decoded bits after traceback delay
    wait for 16*10 ns; -- Traceback depth

    for i in 0 to 999-16 loop -- Account for decoder delay
      wait until rising_edge(clk) and valid_out = '1';
      assert data_out = expected_bits(i)
        report "Bit error at position " & integer'image(i)
        severity error;
      if data_out /= expected_bits(i) then
        errors := errors + 1;
      end if;
    end loop;

    report "Viterbi decoding test complete with " & integer'image(errors) & " errors";
    wait;
  end process;
end Behavioral;