----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.10.2014 15:59:06
-- Design Name: 
-- Module Name: pulse_test - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pulse_timer is
    Generic (C_WIDTH : integer range 8 to 32 := 31);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           pulse_in : in STD_LOGIC;
           value : out std_logic;
           count : out STD_LOGIC_VECTOR (C_WIDTH-1 downto 0);
           rdy : out STD_LOGIC
           );
end pulse_timer;

architecture Behavioral of pulse_timer is

    signal r_end_pulse: std_logic;
    signal r_prev_input: std_logic;
    signal r_pulse_in : std_logic;
    signal r_value : std_logic;
    signal r_count : std_logic_vector(C_WIDTH-1 downto 0);
    signal r_seq : std_logic_vector(10 downto 0);
begin

    -- hookup the outputs
    rdy <= r_end_pulse;
    count <= r_count;
--    count(C_WIDTH-1 downto 11) <= (others => '0');
--    count(10 downto 0) <= r_seq;
    value <= r_value;
    
seq_ctr : process(clk,rst, r_end_pulse)
    variable seq : unsigned(10 downto 0);
    begin
        if(rst='1') then
            seq := (others => '0');
            r_seq <= (others => '0');
        elsif rising_edge(clk) then
            if (r_end_pulse='1') then
                seq := seq + 1;
            end if;
            r_seq <= std_logic_vector(seq);
        end if;
        
    end process;
    
-- count length of pulses
pulse_counter: process(clk,rst, r_pulse_in, pulse_in, r_prev_input)
        variable tick_count:unsigned(C_WIDTH-1 downto 0) := (others => '0');
    begin
        if(rst='1') then
            tick_count := (others => '0');
            r_value <= '0';
            r_count <= (others => '0');
            r_prev_input <= '0';
            r_pulse_in <= '0';
            r_end_pulse <= '0';
        elsif rising_edge(clk) then
            r_pulse_in <= pulse_in;        
            r_prev_input <= r_pulse_in;
            
            if r_pulse_in /= r_prev_input then
                -- reset the counter
                -- latch the value and count
                r_value <= r_prev_input;
                r_count <= std_logic_vector(tick_count+1);
                
                tick_count := (others => '0');
                -- Signal the availability of a pulse
                r_end_pulse <= '1';
            else
                tick_count := tick_count+1;                
                r_value <= r_value;
                r_count <= r_count;
                r_end_pulse <= '0';
            end if;
            
        end if;
          
    end process;
    
end Behavioral;
