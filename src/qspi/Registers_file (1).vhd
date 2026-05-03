library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity Registers_file is
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
end Registers_file;

architecture registers_file_arch of registers_file is


--signals
signal data_write_sig      :std_logic_vector(31 downto 0);
signal data_read_sig       :std_logic_vector(31 downto 0);
signal address_data_sig    :std_logic_vector(31 downto 0);
signal command_data_sig    :std_logic_vector(31 downto 0);
signal send_data_sig       :std_logic_vector(31 downto 0);



begin

data_write <= data_write_sig;  
data_read_sig <= data_read;  
address_data <= address_data_sig;
command_data <= command_data_sig;
send_data <= send_data_sig;   


process(reset,clock,read_en,data_write_sig,data_read_sig,address_data_sig,command_data_sig,send_data_sig) --read registers
begin
    if(reset = '0') then
	    data_output <= (others=>'0');
	elsif(rising_edge(clock)) then
	    if(read_en = '1') then
		    case address is
				when x"00" => data_output <= data_write_sig  ;
				when x"04" => data_output <= data_read_sig   ;
				when x"08" => data_output <= address_data_sig;
				when x"0C" => data_output <= command_data_sig;
				when x"10" => data_output <= send_data_sig   ;
				
				when others=> data_output <= x"12345678";
			end case;
		end if;
	end if;
end process;



process(reset,clock,write_en) --write registers
begin
    if(reset = '0') then
	    data_write_sig   <= (others=>'0');  
	    address_data_sig <= (others=>'0');
	    command_data_sig <= (others=>'0');
	    send_data_sig    <= (others=>'0');
	
	
	elsif(rising_edge(clock)) then
	    if(write_en = '1') then
		    case address is
				when x"00" => data_write_sig   <= data_input;
				when x"08" => address_data_sig <= data_input;
				when x"0C" => command_data_sig <= data_input;
				when x"10" => send_data_sig    <= data_input;
				
				when others=> null;
			end case;
		end if;
	end if;
end process;


end registers_file_arch;