library IEEE;
use IEEE.STD_LOGIC_1164.all
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity Qspi_controller is
	port(
		clock	      :in  std_logic;
		reset         :in  std_logic;
		
		qspi_rst      :out  std_logic;
		qspi_dq_in    :in   std_logic_vector(3 downto 0);
		qspi_dq_out   :out  std_logic_vector(3 downto 0);
		qspi_out_en   :out  std_logic;
		qspi_clk_out  :out  std_logic;
		qspi_cs       :out  std_logic;
		

		
		data_write    :in  std_logic_vector(31 downto 0);
		data_read     :out std_logic_vector(31 downto 0);
		address_data  :in  std_logic_vector(31 downto 0);
		command_data  :in  std_logic_vector(31 downto 0);
		send_data     :in  std_logic_vector(31 downto 0)
										  
	);                                    
end Qspi_controller;

architecture Qspi_controller_arch of Qspi_controller is



-----Signals-----
signal qspi_clock     :std_logic;

--data read signals
signal qspi_dq_in_sig  :std_logic_vector(31 downto 0);
signal data_in_counter :std_logic_vector(3 downto 0);


begin
qspi_clock <= clock;
qspi_clk_out <= qspi_clock;


--Read data process
process (qspi_clock, reset) is
begin
    if (reset = '0') then
	    qspi_dq_in_sig <= (others=>'0');
	    data_in_counter <= (others=>'0');	
	elsif(rising_edge(qspi_clock)) then
	    if (Dummy cycles done = '1' and data_in_counter < X"8") then
		    data_in_counter <= data_in_counter + '1';
			qspi_dq_in_sig(3 downto 0) <= qspi_dq_in(3 downto 0);
			qspi_dq_in_sig <= qspi_dq_in_sig(27 downto 0) & qspi_dq_in_sig(31 downto 28);
		else
		    data_in_counter <= (others=>'0');
		    qspi_dq_in_sig <= qspi_dq_in_sig;
		end if;
	end if;
end process;

























end Qspi_controller_arch;
