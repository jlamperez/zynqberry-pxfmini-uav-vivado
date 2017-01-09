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


entity tb_pulse_timer is

end tb_pulse_timer;

architecture Behavioral of tb_pulse_timer is

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
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal pulse_in : std_logic := '0';
    signal value : std_logic := '0';
    signal count : std_logic_vector(30 downto 0) := (others => '0');
    signal rdy : std_logic := '0';

begin

uut: pulse_timer
    generic map (C_WIDTH => 31)
    port map (clk => clk,
                rst => rst,
                pulse_in => pulse_in,
                value => value,
                count => count,
                rdy => rdy);

clk_proc: process

begin
    clk <= '1';
    wait for 5ns;
    clk <= '0';
    wait for 5ns;
end process;

rst <= '1', '0' after 150ns;

pulse_proc: process
begin
    pulse_in <= '1';    -- sync
    wait for 6000us;
    pulse_in <= '0';
    wait for 400us;
    pulse_in <= '1';    -- ch0 (1000)
    wait for 1000us;
    pulse_in <= '0';
    wait for 400us;
    pulse_in <= '1';    -- ch1 (1100)
    wait for 1100us;
    pulse_in <= '0';
    wait for 400us;
    pulse_in <= '1';    -- ch2 (1200)
    wait for 1200us;
    pulse_in <= '0';
    wait for 400us;
    pulse_in <= '1';    -- ch3 (1300)
    wait for 1300us;
    pulse_in <= '0';
    wait for 400us;
end process;

end Behavioral;