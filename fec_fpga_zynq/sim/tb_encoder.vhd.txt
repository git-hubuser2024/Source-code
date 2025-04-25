library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use std.textio.all;

entity tb_encoder is
end tb_encoder;

architecture Behavioral of tb_encoder is
  component conv_encoder
    Port (
      clk      : in  std_logic;
      reset    : in  std_logic;
      data_in  : in  std_logic;
      valid_in : in  std_logic;
      data_out : out std_logic_vector(1 downto 0)
    );
  end component;

  signal clk      : std_logic := '0';
  signal reset    : std_logic := '1';
  signal data_in  : std_logic := '0';
  signal valid_in : std_logic := '0';
  signal data_out : std_logic_vector(1 downto 0);

  -- MATLAB-generated test vectors
  type bit_array is array(0 to 999) of integer;
  signal input_bits  : bit_array;
  signal output_pairs: bit_array;

begin
  uut: conv_encoder
  port map (
    clk      => clk,
    reset    => reset,
    data_in  => data_in,
    valid_in => valid_in,
    data_out => data_out
  );

  -- Clock generation
  clk <= not clk after 5 ns;

  -- Load test vectors from MATLAB
  process
    file infile  : text open read_mode is "encoder_input.txt";
    file outfile : text open read_mode is "expected_encoder_output.txt";
    variable inline, outline : line;
    variable bit_val : integer;
    variable i : integer := 0;
  begin
    -- Read input bits
    while not endfile(infile) loop
      readline(infile, inline);
      read(inline, bit_val);
      input_bits(i) <= bit_val;
      i := i + 1;
    end loop;

    -- Read expected outputs
    i := 0;
    while not endfile(outfile) loop
      readline(outfile, outline);
      read(outline, bit_val);
      output_pairs(i) <= bit_val;
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

    -- Feed MATLAB-generated inputs
    for i in 0 to 999 loop
      data_in <= '1' when input_bits(i) = 1 else '0';
      valid_in <= '1';
      wait until rising_edge(clk);

      -- Check against MATLAB outputs
      if i mod 2 = 1 then -- Check every pair
        assert data_out = std_logic_vector(to_unsigned(output_pairs(i/2), 2))
          report "Mismatch at i=" & integer'image(i)
          severity error;
        if data_out /= std_logic_vector(to_unsigned(output_pairs(i/2), 2)) then
          errors := errors + 1;
        end if;
      end if;
    end loop;

    valid_in <= '0';
    report "Test complete with " & integer'image(errors) & " errors";
    wait;
  end process;
end Behavioral;