library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;

Entity Flash_mem_tb is
end entity;

Architecture Flash_mem_tb_arch of Flash_mem_tb is

component Flash_mem_top
	port(
    --clock and reset from the outside_world/testbench
	CLOCK_IN      :IN std_logic;  --25MHZ
    RESET_IN      :IN std_logic;
	
	--FLASH MEM PORTS
	CLK_FLASH     :OUT std_logic;
    CS_FLASH      :OUT std_logic;
    DQ            :INOUT std_logic_vector(3 downto 0);
	
	--User/PC/TB registers file ports
	DATA_INPUT    :IN  std_logic_vector(31 downto 0);
	DATA_OUTUT    :OUT std_logic_vector(31 downto 0);
	Address       :IN  std_logic_vector(7  downto 0);
	WRITE_EN      :IN  std_logic;  
	READ_EN       :IN  std_logic  
								  
);                                
end component;



--signals
    --clock and reset from the outside_world/testbench
signal	clock_in_sig      : std_logic:='0';  --25mhz
signal  reset_in_sig      : std_logic:='0';

     	--FLASH MEM PORTS
signal	clk_flash_sig     : std_logic;
signal  cs_flash_sig      : std_logic;
signal  dq_sig            : std_logic_vector(3 downto 0);
	
    	--User/PC/TB registers file ports
signal	data_input_sig    : std_logic_vector(31 downto 0);
signal	data_outut_sig    : std_logic_vector(31 downto 0);
signal	address_sig       : std_logic_vector(7  downto 0);
signal  write_en_sig      : std_logic;  
signal  read_en_sig       : std_logic; 	


--end of signals

begin

Flash_mem_top_tb: Flash_mem_top
	port map(
    --clock and reset from the outside_world/testbench
	CLOCK_IN      => clock_in_sig,--:IN std_logic;  --25MHZ
    RESET_IN      => reset_in_sig,--:IN std_logic;
	
	--FLASH MEM PORTS
	CLK_FLASH     => clk_flash_sig,--:OUT std_logic;
    CS_FLASH      => cs_flash_sig ,--:OUT std_logic;
    DQ            => dq_sig       ,--:INOUT std_logic_vector(3 downto 0);
	
	--User/PC/TB registers file ports
	DATA_INPUT    => data_input_sig,--:IN  std_logic_vector(31 downto 0);
	DATA_OUTUT    => data_outut_sig,--:OUT std_logic_vector(31 downto 0);
	Address       => address_sig   ,--:IN  std_logic_vector(7  downto 0);
	WRITE_EN      => write_en_sig  , --:IN  std_logic   
	READ_EN       => read_en_sig     --:IN  std_logic	
);


clock_in_sig <= not clock_in_sig after 20 ns; --25MHZ
reset_in_sig <= '0', '1' after 1 us;


















end Flash_mem_tb_arch;