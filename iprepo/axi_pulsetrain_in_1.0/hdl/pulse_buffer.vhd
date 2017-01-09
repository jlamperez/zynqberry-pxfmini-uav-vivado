----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.10.2014 19:38:52
-- Design Name: 
-- Module Name: pulse_buffer - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pulse_buffer is
    Port ( clk : in std_logic;
           rst : in std_logic;
           pulse_in : in STD_LOGIC;
           rdy : out STD_LOGIC;
           pulse_data : out STD_LOGIC_VECTOR (31 downto 0);
           rd : in STD_LOGIC);
end pulse_buffer;

architecture Behavioral of pulse_buffer is

component pulse_timer
    Generic (C_WIDTH: integer);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           pulse_in : in STD_LOGIC;
           value : out STD_LOGIC;
           count : out STD_LOGIC_VECTOR (C_WIDTH-1 downto 0);
           rdy : out STD_LOGIC
           );
end component;

    signal fifo_full : std_logic;
    signal fifo_empty : std_logic;
    signal pulse_data_out : std_logic_vector (31 downto 0) := (others => '0');
    signal wr_en : std_logic := '0';
    signal rd_en : std_logic := '0';
    signal got_pulse : std_logic := '0';
    
    signal rd_count,wr_count : std_logic_vector(8 downto 0);
      
begin

pt: pulse_timer
    generic map (C_WIDTH => 31)
    port map (clk => clk,
                rst => rst,
                pulse_in => pulse_in,
                value => pulse_data_out(31),
                count => pulse_data_out(30 downto 0),
                rdy => got_pulse);
                
-- Instantiate a FIFO
   FIFO_SYNC_MACRO_inst : FIFO_SYNC_MACRO
   generic map (
      DEVICE => "7SERIES",            -- Target Device: "VIRTEX5, "VIRTEX6", "7SERIES" 
      ALMOST_FULL_OFFSET => X"0080",  -- Sets almost full threshold
      ALMOST_EMPTY_OFFSET => X"0080", -- Sets the almost empty threshold
      DATA_WIDTH => 32,   -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      FIFO_SIZE => "18Kb")            -- Target BRAM, "18Kb" or "36Kb" 
   port map (
--      ALMOSTEMPTY => open,   -- 1-bit output almost empty
--      ALMOSTFULL => open,     -- 1-bit output almost full
      DO => pulse_data,                     -- Output data, width defined by DATA_WIDTH parameter
      EMPTY => fifo_empty,               -- 1-bit output empty
      FULL => fifo_full,                 -- 1-bit output full
      RDCOUNT => rd_count,           -- Output read count, width determined by FIFO depth
--      RDERR => open,               -- 1-bit output read error
      WRCOUNT => wr_count,           -- Output write count, width determined by FIFO depth
--      WRERR => open,               -- 1-bit output write error
      CLK => clk,                   -- 1-bit input clock
      DI => pulse_data_out,                     -- Input data, width defined by DATA_WIDTH parameter
      RDEN => rd_en,                 -- 1-bit input read enable
      RST => rst,                   -- 1-bit input reset
      WREN => wr_en                  -- 1-bit input write enable
   );
   -- End of FIFO_SYNC_MACRO_inst instantiation

    -- Circular buffer semantics, we read when requested and not empty, or if the buffer is full
    rd_en <= (rd and not fifo_empty) or (fifo_full);
    --rd_en <= '0';
    wr_en <= got_pulse;
    	
	rdy <= not fifo_empty;		

end Behavioral;
