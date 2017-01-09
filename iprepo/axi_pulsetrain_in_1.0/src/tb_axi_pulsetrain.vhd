-- vi:se ts=4 sw=4 noet:
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all;

entity tb_axi_pulsetrain_in is

end tb_axi_pulsetrain_in;

architecture behavioral of tb_axi_pulsetrain_in is

	-- component declaration
	component axi_pulsetrain_in_v1_0_S00_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 4
		);
		port (
		pulsetrain_in : in std_logic;

		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic
		);
	end component axi_pulsetrain_in_v1_0_S00_AXI;

signal pulse_in : std_logic;

signal S_AXI_ACLK : std_logic := '1';
signal S_AXI_ARESETN : std_logic := '0';
signal S_AXI_AWADDR : std_logic_vector(3 downto 0);
signal S_AXI_AWPROT : std_logic_vector(2 downto 0);
signal S_AXI_AWVALID : std_logic := '0';
signal S_AXI_AWREADY : std_logic;
signal S_AXI_WDATA : std_logic_vector(31 downto 0);
signal S_AXI_WSTRB : std_logic_vector(3 downto 0);
signal S_AXI_WVALID : std_logic := '0';
signal S_AXI_WREADY : std_logic;
signal S_AXI_BRESP : std_logic_vector(1 downto 0);
signal S_AXI_BVALID : std_logic;
signal S_AXI_BREADY : std_logic := '0';
signal S_AXI_ARADDR : std_logic_vector(3 downto 0);
signal S_AXI_ARPROT : std_logic_vector(2 downto 0);
signal S_AXI_ARVALID : std_logic;
signal S_AXI_ARREADY : std_logic;
signal S_AXI_RDATA : std_logic_vector(31 downto 0);
signal S_AXI_RRESP : std_logic_vector(1 downto 0);
signal S_AXI_RVALID : std_logic;
signal S_AXI_RREADY : std_logic;

signal rvalue : std_logic_vector(31 downto 0);

constant PERIOD_100 : time := 10ns;
constant PERIOD_250 : time := 4ns;
constant PERIOD_156 : time := 6.4ns;	-- used to be 100% the clkmux was switching clocks (hard to see when both were in phase 250Mhz

-- converts a std_logic_vector into a hex string.
function hstr(slv: std_logic_vector) return string is
	variable hexlen: integer;
	variable longslv : std_logic_vector(67 downto 0) := (others => '0');
	variable hex : string(1 to 16);
	variable fourbit : std_logic_vector(3 downto 0);
begin
	hexlen := (slv'left+1)/4;
	if (slv'left+1) mod 4 /= 0 then
		hexlen := hexlen + 1;
	end if;
	longslv(slv'left downto 0) := slv;
	for i in (hexlen-1) downto 0 loop
		fourbit := longslv(((i*4)+3) downto (i*4));
		case fourbit is
		when "0000" => hex(hexlen-i) := '0';
		when "0001" => hex(hexlen-i) := '1';
		when "0010" => hex(hexlen-i) := '2';
		when "0011" => hex(hexlen-i) := '3';
		when "0100" => hex(hexlen-i) := '4';
		when "0101" => hex(hexlen-i) := '5';
		when "0110" => hex(hexlen-i) := '6';
		when "0111" => hex(hexlen-i) := '7';
		when "1000" => hex(hexlen-i) := '8';
		when "1001" => hex(hexlen-i) := '9';
		when "1010" => hex(hexlen-i) := 'a';
		when "1011" => hex(hexlen-i) := 'b';
		when "1100" => hex(hexlen-i) := 'c';
		when "1101" => hex(hexlen-i) := 'd';
		when "1110" => hex(hexlen-i) := 'e';
		when "1111" => hex(hexlen-i) := 'f';
		when "ZZZZ" => hex(hexlen-i) := 'z';
		when "UUUU" => hex(hexlen-i) := 'u';
		when "XXXX" => hex(hexlen-i) := 'x';
		when others => hex(hexlen-i) := '?';
		end case;
	end loop;
	return hex(1 to hexlen);
end hstr;

function calc_tkeep_width(vec: std_logic_vector) return integer is
	constant n : natural := vec'length;
begin
	for i in 0 to n-1 loop
		if (vec(i) = '0') then
			return i*8;
		end if;
	end loop;
	return n*8;
end calc_tkeep_width;

function swap_endian(vec : std_ulogic_vector) return std_ulogic_vector is
	variable result      : std_ulogic_vector(vec'range);
	constant n : natural := vec'length / 8;
begin
	for i in 0 to n-1 loop
		for j in 7 downto 0 loop
			result(8*i + j) := vec(8*(n-1-i) + j);
		end loop;
	end loop;

	return result;
end function swap_endian;

function swap_endian(vec : std_logic_vector) return std_logic_vector is
begin
	return std_logic_vector(swap_endian(std_ulogic_vector(vec)));
end function swap_endian;

-- converts a std_logic_vector into a hex string.
procedure axi_write(
	constant addr: in std_logic_vector(15 downto 0);
	constant value: in std_logic_vector;
	signal awaddr: out std_logic_vector;
	signal awvalid: out std_logic;
	signal wdata: out std_logic_vector;
	signal wvalid: out std_logic;
	signal wready: in std_logic;
	signal bready: out std_logic
	) is
 begin
	awaddr <= addr(7 downto 0);
	wdata <= value;
	awvalid <= '1';
	wvalid <= '1';
	bready <= '1';
	wait until wready = '1';
	wait for PERIOD_100;
	awvalid <= '0';
	wvalid <= '0';
	wait for PERIOD_100;
 end axi_write;

procedure axi_read(
	constant addr: in std_logic_vector(15 downto 0);
	signal value: out std_logic_vector;
	signal araddr: out std_logic_vector;
	signal arvalid: out std_logic;
	signal rdata: in std_logic_vector;
	signal rvalid: in std_logic;
	signal rready: out std_logic
	) is
begin
	araddr <= addr(araddr'left downto 0);
	arvalid <= '1';
	rready <= '1';
	wait until rvalid = '1';
	value <= rdata;
	arvalid <= '0';
	rready <= '0';
	wait for PERIOD_100;
 end axi_read;


begin

S_AXI_ACLK <= not S_AXI_ACLK after PERIOD_100/2;

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

uut: axi_pulsetrain_in_v1_0_S00_AXI
port map (
    pulsetrain_in => pulse_in,    
--	C_UDP_DATA_LEN => C_UDP_DATA_LEN,
	S_AXI_ACLK => S_AXI_ACLK,
	S_AXI_ARESETN => S_AXI_ARESETN,
	S_AXI_AWADDR	=> S_AXI_AWADDR,
	S_AXI_AWPROT	=> S_AXI_AWPROT,
	S_AXI_AWVALID => S_AXI_AWVALID,
	S_AXI_AWREADY => S_AXI_AWREADY,
	S_AXI_WDATA		=> S_AXI_WDATA,
	S_AXI_WSTRB		=> S_AXI_WSTRB,
	S_AXI_WVALID	=> S_AXI_WVALID,
	S_AXI_WREADY	=> S_AXI_WREADY,
	S_AXI_BRESP		=> S_AXI_BRESP,
	S_AXI_BVALID	=> S_AXI_BVALID,
	S_AXI_BREADY	=> S_AXI_BREADY,
	S_AXI_ARADDR	=> S_AXI_ARADDR,
	S_AXI_ARPROT	=> S_AXI_ARPROT,
	S_AXI_ARVALID => S_AXI_ARVALID,
	S_AXI_ARREADY => S_AXI_ARREADY,
	S_AXI_RDATA		=> S_AXI_RDATA,
	S_AXI_RRESP		=> S_AXI_RRESP,
	S_AXI_RVALID	=> S_AXI_RVALID,
	S_AXI_RREADY	=> S_AXI_RREADY
);

process
begin
	-- do the reset
	S_AXI_ARESETN <= '0';
	wait for PERIOD_100*20;
	S_AXI_ARESETN <= '1';

	wait for PERIOD_100*2;

--	-- write the control register
--	axi_write(x"0000", x"00000000", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);

--	-- now the data match registers
--	axi_write(x"0040", x"00000000", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"0044", x"00000000", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"0048", x"00000000", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"004c", x"01000608", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"0050", x"04060008", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"0054", x"00000100", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"0058", x"00000000", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"005c", x"00000000", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"0060", x"00000000", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"0064", x"010a0000", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"0068", x"00000201", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"006c", x"00000000", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);

--	-- now the data mask registers
--	axi_write(x"0080", x"00000000", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"0084", x"00000000", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"0088", x"00000000", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"008c", x"ffffffff", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"0090", x"ffffffff", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"0094", x"0000ffff", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"0098", x"00000000", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"009c", x"00000000", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"00a0", x"00000000", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"00a4", x"ffff0000", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"00a8", x"0000ffff", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"00ac", x"00000000", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);

--	-- now the arp response registers
--	axi_write(x"00c0", x"eeeeeeee", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"00c4", x"2100eeee", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"00c8", x"01000010", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"00cc", x"01000608", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"00d0", x"04060008", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"00d4", x"21000200", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"00d8", x"01000010", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"00dc", x"0201010a", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"00e0", x"eeeeeeee", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"00e4", x"010aeeee", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"00e8", x"00000901", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"00ec", x"00000000", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"00f0", x"00000000", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"00f4", x"00000000", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"00f8", x"00000000", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);
--	axi_write(x"00fc", x"00000000", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);

    while true loop
--	-- read a register back to test that AXI reads are working
	   axi_read(x"0000", value => rvalue, araddr => S_AXI_ARADDR, arvalid => S_AXI_ARVALID, rdata => S_AXI_RDATA, rvalid => S_AXI_RVALID, rready => S_AXI_RREADY);
        wait for 1000*PERIOD_100;
     end loop;
--	-- enable
--	axi_write(x"0000", x"00000001", awaddr => S_AXI_AWADDR, awvalid => S_AXI_AWVALID, wdata => S_AXI_WDATA, wvalid => S_AXI_WVALID, bready => S_AXI_BREADY, wready => S_AXI_WREADY);

--	wait until rising_edge(rx_clk);
--	wait for PERIOD_156;

--	-- send some data
--	rx_axis_tvalid <= '1';



--	rx_axis_tdata <= swap_endian(x"ffffffff_ffffaa01");
--	rx_axis_tkeep <= x"ff";
--	wait for PERIOD_156;
--	rx_axis_tdata <= swap_endian(x"02030405_08060001");
--	wait for PERIOD_156;
--	rx_axis_tdata <= swap_endian(x"08000604_0001aa01");
--	wait for PERIOD_156;
--	rx_axis_tdata <= swap_endian(x"02030405_0a010109");
--	wait for PERIOD_156;
--	rx_axis_tdata <= swap_endian(x"00000000_00000a01");
--	wait for PERIOD_156;
--	rx_axis_tdata <= swap_endian(x"01020000_00000000");
--	rx_axis_tkeep <= x"03";
--	wait for PERIOD_156;
--	rx_axis_tkeep <= x"00";
--	rx_axis_tdata <= (others => '0');

--	--wait for end of frame
--	wait for PERIOD_156;
--	rx_axis_tlast <= '1';
--	wait for PERIOD_156;
--	rx_axis_tvalid <= '0';
--	rx_axis_tlast <= '0';

--	wait until m_axis_tvalid = '1';
--	wait for PERIOD_156;
--	m_axis_tready <= '1';


--	wait until m_axis_tlast = '1';
--	wait for PERIOD_156;
--	m_axis_tready <= '0';

--	wait for PERIOD_156*2;

--	-- now a second frame which should not match
--	rx_axis_tvalid <= '1';

--	rx_axis_tdata <= swap_endian(x"ffffffff_ffffaa01");
--	rx_axis_tkeep <= x"ff";
--	wait for PERIOD_156;
--	rx_axis_tdata <= swap_endian(x"02030405_08060001");
--	wait for PERIOD_156;
--	rx_axis_tdata <= swap_endian(x"08000604_0001aa01");
--	wait for PERIOD_156;
--	rx_axis_tdata <= swap_endian(x"02030405_0a010109");
--	wait for PERIOD_156;
--	rx_axis_tdata <= swap_endian(x"00000000_00000a01");
--	wait for PERIOD_156;
--	rx_axis_tdata <= swap_endian(x"01010000_00000000");
--	rx_axis_tkeep <= x"03";
--	wait for PERIOD_156;
--	rx_axis_tdata <= (others => '0');
--	rx_axis_tkeep <= x"00";

--	--wait for end of frame
--	wait for PERIOD_156;
--	rx_axis_tlast <= '1';
--	wait for PERIOD_156;
--	rx_axis_tvalid <= '0';
--	rx_axis_tlast <= '0';

	wait;

end process;

end behavioral;
