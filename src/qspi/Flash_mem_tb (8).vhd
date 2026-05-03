library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;

Entity Flash_mem_tb is
end entity;

Architecture Flash_mem_tb_arch of Flash_mem_tb is

component Flash_mem_top
	port(
    --clock and reset from the outside_world/testbench
	CLOCK_IN      :IN std_logic;  --100MHZ
    RESET_IN      :IN std_logic;
	
	--FLASH MEM PORTS
	CLK_FLASH     :OUT std_logic;
	RESET_FLASH   :OUT std_logic;
    CS_FLASH      :OUT std_logic;
    DQ            :INOUT std_logic_vector(3 downto 0);

	
	--User/PC/TB registers file ports
	DATA_INPUT    :IN  std_logic_vector(31 downto 0);
	DATA_OUTPUT   :OUT std_logic_vector(31 downto 0);
	Address       :IN  std_logic_vector(7  downto 0);
	WRITE_EN      :IN  std_logic;  
	READ_EN       :IN  std_logic  
								  
);                                
end component;

component flash_module 
	port(
    S          :IN    std_logic; --CS
    C          :IN    std_logic; --Clock
    HOLD_DQ3   :INOUT std_logic;  
    DQ0        :INOUT std_logic;   
    DQ1        :INOUT std_logic;   
    Vcc        :IN    std_logic_vector(31 downto 0);   
    Vpp_W_DQ2  :INOUT std_logic;   
    RESET2     :IN    std_logic  
	);
end component;
	
--signals
    --clock and reset from the outside_world/testbench
signal	clock_in_sig      : std_logic:='0';  --100MHZ
signal  reset_in_sig      : std_logic:='0';

     	--FLASH MEM PORTS
signal	clk_flash_sig     : std_logic;
signal  reset_flash_sig   : std_logic;
signal  cs_flash_sig      : std_logic;
signal  dq_sig            : std_logic_vector(3 downto 0);
	
signal	vcc_flash_sig     : std_logic_vector(31 downto 0);
	
    	--User/PC/TB registers file ports
signal	data_input_sig    : std_logic_vector(31 downto 0);
signal	data_output_sig    : std_logic_vector(31 downto 0);
signal	address_sig       : std_logic_vector(7  downto 0);
signal  write_en_sig      : std_logic;  
signal  read_en_sig       : std_logic; 	


--- new change

signal qspi_dq_in_sig       :std_logic_vector(3 downto 0);
signal qspi_dq_out_sig      :std_logic_vector(3 downto 0);
signal qspi_out_en_sig      :std_logic;
signal qspi_init_state_sig  :std_logic; -- '1' - init mode, '0'-quad mode
signal qspi_dummy_cycle_sig :std_logic; --'1' dummy cycles, '0'- no dummy

--end of signals

begin

Flash_mem_top_tb: Flash_mem_top
	port map(
    --clock and reset from the outside_world/testbench
	CLOCK_IN      => clock_in_sig,--:IN std_logic;  --100MHZ
    RESET_IN      => reset_in_sig,--:IN std_logic;
	
	--FLASH MEM PORTS
	CLK_FLASH     => clk_flash_sig,--:OUT std_logic;
	RESET_FLASH   => reset_flash_sig,--:OUT std_logic;
    CS_FLASH      => cs_flash_sig ,--:OUT std_logic;
    DQ            => dq_sig       ,--:INOUT std_logic_vector(3 downto 0);

	--User/PC/TB registers file ports
	DATA_INPUT    => data_input_sig,--:IN  std_logic_vector(31 downto 0);
	DATA_OUTPUT    => data_output_sig,--:OUT std_logic_vector(31 downto 0);
	Address       => address_sig   ,--:IN  std_logic_vector(7  downto 0);
	WRITE_EN      => write_en_sig  , --:IN  std_logic   
	READ_EN       => read_en_sig     --:IN  std_logic	
);


 

flash_module_tb: flash_module 
	port map(
    S          => cs_flash_sig,--:IN    std_logic; --CS
    C          => clk_flash_sig,--:IN    std_logic; --Clock
    HOLD_DQ3   => dq_sig(3),--:INOUT std_logic;  
    DQ0        => dq_sig(0),--:INOUT std_logic;   
    DQ1        => dq_sig(1),--:INOUT std_logic;   
    Vcc        => vcc_flash_sig,--:IN    std_logic_vector(31 downto 0);   
    Vpp_W_DQ2  => dq_sig(2),--:INOUT std_logic;   
    RESET2     => reset_flash_sig --:IN    std_logic;  
	);


vcc_flash_sig <= X"00000000",X"000000B8" after 1 us,X"000003B8" after 2 us,X"00000BB8" after 3 us;






clock_in_sig <= not clock_in_sig after 5 ns; --100MHZ
reset_in_sig <= '0', '1' after 1 us;




	--User/PC/TB registers file ports
data_input_sig    <= X"00000000", X"00000070" after 50 us,
					X"00000001" after 52 us,X"00000000"  after 53.1 us,
					X"00000006" after 80 us,X"00000001"  after 82 us,X"00000000"  after 83 us,
					X"12345678"  after 100 us,X"00800006"  after 102 us,X"00000002"  after 103 us,
					X"00000001"  after 110 us,X"00000000" after 120 us,X"0000000B" after 1500 us,
					X"00000006" after 1550 us,X"00000001"  after 1560 us,X"00000000"  after 1561 us,
					X"000000B1" after 1600 us,X"0000BFF7" after 1610 us,
					X"00000001"  after 1620 us,X"00000000"  after 1620.2 us,
					X"00000006" after 1950 us,X"00000001"  after 1960 us,X"00000000"  after 1961 us,
					X"00000081"  after 2000 us,X"000000BC" after 2010 us,
					X"00000001"  after 2020 us,X"00000000"  after 2020.2 us;


address_sig       <= X"00", X"0C" after 50 us,
					 X"10" after 52 us, X"0C" after 80 us,X"10" after 82 us,X"10" after 83 us,
					 X"00" after 100 us,X"08" after 102 us,X"0C" after 103 us,X"10" after 110 us,
					 X"0C" after 1500 us,X"0C" after 1550 us,X"10" after 1560 us,X"0C" after 1600 us,
					 X"00" after 1610 us,X"10" after 1620 us,
					 X"0C" after 1950 us,X"10" after 1960 us,
					 X"0C" after 2000 us,X"00" after 2010 us,
					 X"10" after 2020 us;


write_en_sig      <= '0', '1' after 51 us, '0' after 52 us,
					  '1' after 53 us, '0' after 53.1 us, '1' after 53.2 us, '0' after 54 us,
					  '1' after 81 us, '0' after 81.1 us,'1' after 82.1 us, '0' after 82.2 us,
					  '1' after 83 us, '0' after 83.1 us,
					  '1' after 100 us, '0' after 100.1 us,
					  '1' after 102 us, '0' after 102.1 us, 
					  '1' after 103 us, '0' after 103.1 us, 
					  '1' after 110 us, '0' after 110.1 us, 
					  '1' after 120 us, '0' after 120.1 us, 
					  '1' after 1500 us, '0' after 1500.1 us,
					  '1' after 1550 us, '0' after 1550.1 us,
					  '1' after 1560 us, '0' after 1560.1 us,
					  '1' after 1561 us, '0' after 1561.1 us,
					  '1' after 1600 us, '0' after 1600.1 us,
					  '1' after 1610 us, '0' after 1610.1 us,
					  '1' after 1620 us, '0' after 1620.1 us,
					  '1' after 1620.2 us, '0' after 1620.3 us,
					  '1' after 1950 us, '0' after 1950.1 us,
					  '1' after 1960 us, '0' after 1960.1 us,
					  '1' after 1961 us, '0' after 1961.1 us,
					  '1' after 2000 us, '0' after 2000.1 us,
					  '1' after 2010 us, '0' after 2010.1 us,
					  '1' after 2020 us, '0' after 2020.1 us,
					  '1' after 2020.2 us, '0' after 2020.3 us;
					  


read_en_sig       <= '0', '1' after 60 us, '0' after 61 us; 









end Flash_mem_tb_arch;