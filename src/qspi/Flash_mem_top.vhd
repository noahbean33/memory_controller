library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;


Entity Flash_mem_top is
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
	WR            :IN  std_logic   ---wr = '1'(write), '0'(read)
	




end entity;

Architecture Flash_mem_top_arch of Flash_mem_top is

end Flash_mem_top_arch;