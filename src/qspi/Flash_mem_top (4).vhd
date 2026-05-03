library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;


Entity Flash_mem_top is
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
	ADDRESS       :IN  std_logic_vector(7  downto 0);
	WRITE_EN      :IN  std_logic;  
	READ_EN       :IN  std_logic  
);
end entity;

Architecture Flash_mem_top_arch of Flash_mem_top is

--components
component Qspi_controller
	port(
		clock	         :in  std_logic; --100MHZ
		reset            :in  std_logic;
		
		qspi_rst         :out  std_logic;
		qspi_dq_in       :in   std_logic_vector(3 downto 0);
		qspi_dq_out      :out  std_logic_vector(3 downto 0);
		qspi_out_en      :out  std_logic;
		qspi_clk_out     :out  std_logic; --25MHZ
		qspi_cs          :out  std_logic;
		qspi_init_state  :out  std_logic; -- '1' - init mode, '0'-quad mode
		qspi_dummy_cycle :out std_logic; --'1' dummy cycles, '0'- no dummy

		
		data_write       :in  std_logic_vector(31 downto 0);
		data_read        :out std_logic_vector(31 downto 0);
		address_data     :in  std_logic_vector(31 downto 0);
		command_data     :in  std_logic_vector(31 downto 0);
		send_data        :in  std_logic_vector(31 downto 0)
										  
	);                                    
end component;

component Registers_file
	port(
		clock	      :in std_logic;
		reset         :in std_logic;
		
			--User/PC/TB registers file ports
	    data_input    :in  std_logic_vector(31 downto 0);
	    data_output   :out std_logic_vector(31 downto 0);
	    address       :in  std_logic_vector(7  downto 0);
	    write_en      :in  std_logic;
	    read_en       :in  std_logic;
		
		data_write     :out std_logic_vector(31 downto 0);
		data_read      :in  std_logic_vector(31 downto 0);
		address_data   :out std_logic_vector(31 downto 0);
		command_data   :out std_logic_vector(31 downto 0);
		send_data      :out std_logic_vector(31 downto 0)
										  
	);                                    
end component;

---signals

--flash signals
signal cs_flash_sig  		:std_logic;
signal qspi_dq_in_sig       :std_logic_vector(3 downto 0);
signal qspi_dq_out_sig      :std_logic_vector(3 downto 0);
signal qspi_out_en_sig      :std_logic;
signal qspi_init_state_sig  :std_logic; -- '1' - init mode, '0'-quad mode
signal qspi_dummy_cycle_sig :std_logic; --'1' dummy cycles, '0'- no dummy

--register file signals
signal data_write_sig       :std_logic_vector(31 downto 0);
signal data_read_sig        :std_logic_vector(31 downto 0);
signal address_data_sig     :std_logic_vector(31 downto 0);
signal command_data_sig     :std_logic_vector(31 downto 0);
signal send_data_sig        :std_logic_vector(31 downto 0);

		

begin


CS_FLASH <= cs_flash_sig;


DQ(3 downto 0) <= qspi_dq_out_sig when ((qspi_out_en_sig = '1') and (cs_flash_sig = '0') and (qspi_init_state_sig = '0')and (qspi_dummy_cycle_sig = '0')) 
                  else "1ZZ"&qspi_dq_out_sig(0) when ((qspi_out_en_sig = '1') and (cs_flash_sig = '0') and (qspi_init_state_sig = '1')and (qspi_dummy_cycle_sig = '0'))
				  else "ZZZZ";   
qspi_dq_in_sig<= DQ(3 downto 0) when ((qspi_out_en_sig = '0') and (cs_flash_sig = '0')) else "0000";





Qspi_controller_top: Qspi_controller
	port map(
		clock	         => CLOCK_IN,--:in  std_logic; --100MHZ
		reset            => RESET_IN,--:in  std_logic;

		qspi_rst         => RESET_FLASH,--:out  std_logic;
		qspi_dq_in       => qspi_dq_in_sig,--:in   std_logic_vector(3 downto 0);
		qspi_dq_out      => qspi_dq_out_sig,--:out  std_logic_vector(3 downto 0);
		qspi_out_en      => qspi_out_en_sig,--:out  std_logic;
		qspi_clk_out     => CLK_FLASH,--:out  std_logic; --25MHZ
		qspi_cs          => cs_flash_sig,--:out  std_logic;
		qspi_init_state  => qspi_init_state_sig,--:out  std_logic; -- '1' - init mode, '0'-quad mode
		qspi_dummy_cycle => qspi_dummy_cycle_sig,--:out std_logic; --'1' dummy cycles, '0'- no dummy


		data_write       => data_write_sig  ,--:in  std_logic_vector(31 downto 0);
		data_read        => data_read_sig   ,--:out std_logic_vector(31 downto 0);
		address_data     => address_data_sig,--:in  std_logic_vector(31 downto 0);
		command_data     => command_data_sig,--:in  std_logic_vector(31 downto 0);
		send_data        => send_data_sig    --:in  std_logic_vector(31 downto 0)
										  
	);                                    


Registers_file_top: Registers_file
	port map(
		clock	      => CLOCK_IN,--:in std_logic;
		reset         => RESET_IN,--:in std_logic;
		
			--User/PC/TB registers file ports
	    data_input     => DATA_INPUT,--:in  std_logic_vector(31 downto 0);
	    data_output    => DATA_OUTPUT,--:out std_logic_vector(31 downto 0);
	    address        => ADDRESS   ,--:in  std_logic_vector(7  downto 0);
	    write_en       => WRITE_EN  ,--:in  std_logic;
	    read_en        => READ_EN   ,--:in  std_logic;

		data_write     => data_write_sig  ,--:out std_logic_vector(31 downto 0);
		data_read      => data_read_sig   ,--:in  std_logic_vector(31 downto 0);
		address_data   => address_data_sig,--:out std_logic_vector(31 downto 0);
		command_data   => command_data_sig,--:out std_logic_vector(31 downto 0);
		send_data      => send_data_sig    --:out std_logic_vector(31 downto 0)
										  
	);                                    







end Flash_mem_top_arch;