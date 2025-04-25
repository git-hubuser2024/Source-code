library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fec_top is
  Port (
    -- Zynq AXI-Stream Interface
    aclk          : in  std_logic;
    aresetn       : in  std_logic;
    s_axis_tdata  : in  std_logic_vector(7 downto 0);
    s_axis_tvalid : in  std_logic;
    s_axis_tready : out std_logic;
    m_axis_tdata  : out std_logic_vector(7 downto 0);
    m_axis_tvalid : out std_logic;
    m_axis_tready : in  std_logic
  );
end fec_top;

architecture Behavioral of fec_top is
  component conv_encoder
    Port (
      clk      : in  std_logic;
      reset    : in  std_logic;
      data_in  : in  std_logic;
      valid_in : in  std_logic;
      data_out : out std_logic_vector(1 downto 0)
    );
  end component;

  signal encoder_in   : std_logic;
  signal encoder_out  : std_logic_vector(1 downto 0);
  signal encoder_valid: std_logic;
  
  signal reset : std_logic;
begin
  reset <= not aresetn;

  -- Convolutional Encoder Instance (matches MATLAB's convenc())
  encoder: conv_encoder
  port map (
    clk      => aclk,
    reset    => reset,
    data_in  => s_axis_tdata(0), -- LSB bit input
    valid_in => s_axis_tvalid,
    data_out => encoder_out
  );

  -- Output Processing
  process(aclk)
  begin
    if rising_edge(aclk) then
      if reset = '1' then
        m_axis_tvalid <= '0';
      else
        -- Pack 4 encoder outputs into 1 byte
        m_axis_tdata <= "000000" & encoder_out;
        m_axis_tvalid <= s_axis_tvalid; -- Follow input valid
      end if;
    end if;
  end process;

  s_axis_tready <= m_axis_tready; -- Flow control
end Behavioral;