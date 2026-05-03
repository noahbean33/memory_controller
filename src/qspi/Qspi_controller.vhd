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


begin

end Qspi_controller_arch;
