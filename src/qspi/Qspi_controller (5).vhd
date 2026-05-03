library IEEE;
use IEEE.STD_LOGIC_1164.all
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity Qspi_controller is
	port(
		clock	      :in  std_logic; --100MHZ
		reset         :in  std_logic;
		
		qspi_rst      :out  std_logic;
		qspi_dq_in    :in   std_logic_vector(3 downto 0);
		qspi_dq_out   :out  std_logic_vector(3 downto 0);
		qspi_out_en   :out  std_logic;
		qspi_clk_out  :out  std_logic; --25MHZ
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
signal qspi_clock_cnt :std_logic_vector(1 downto 0);
signal clock_en       :std_logic;
signal clock_en_cnt   :std_logic_vector(2 downto 0);


--data read signals
signal qspi_dq_in_sig  :std_logic_vector(31 downto 0);
signal data_in_counter :std_logic_vector(3 downto 0);

--quad command
signal initiate_cmd         :std_logic;
signal start_cmd_out        :std_logic;
signal send_quad_cmd_done   :std_logic;
signal command_data_sig     :std_logic_vector(7 downto 0);
signal command_counter      :std_logic_vector(1 downto 0); 
signal qspi_dq_cmd_out      :std_logic_vector(3 downto 0);

--quad address
signal initiate_add         :std_logic;
signal start_add_out        :std_logic;
signal send_quad_add_done   :std_logic;
signal address_data_sig     :std_logic_vector(23 downto 0);
signal address_counter      :std_logic_vector(2 downto 0); 
signal qspi_dq_add_out      :std_logic_vector(3 downto 0);

--quad data
signal initiate_data        :std_logic;
signal start_data_out       :std_logic;
signal send_quad_data_done  :std_logic;
signal output_data_sig      :std_logic_vector(31 downto 0);
signal data_out_counter     :std_logic_vector(3 downto 0); 
signal qspi_dq_data_out     :std_logic_vector(3 downto 0);




begin
qspi_clk_out <= qspi_clock;


--clock enable process
process (clock, reset) is
begin
    if (reset = '0') then
        clock_en <= '0';
		clock_en_cnt <= "000";
	elsif(rising_edge(clock)) then
	    if (clock_en_cnt < "100") then
            clock_en_cnt <= clock_en_cnt +'1';
		    clock_en <= '0';
		else
		    clock_en_cnt <= "000";
		    clock_en <= '1';
		end if;
	end if;
end process;

--clock QSPI flash - 25MHZ process
process (clock, reset) is
begin
    if (reset = '0') then
        qspi_clock <= '0';
		qspi_clock_cnt <= "00";
	elsif(rising_edge(clock)) then
	    if (qspi_clock_cnt < "10") then
            qspi_clock_cnt <= qspi_clock_cnt +'1';
		    qspi_clock <= '0';
		elsif (qspi_clock_cnt = "10" and qspi_clock_cnt = "11") then 
		    qspi_clock_cnt <= qspi_clock_cnt +'1';
		    qspi_clock <= '1';
		else
		    qspi_clock <= qspi_clock;
			qspi_clock_cnt <= qspi_clock_cnt;
		end if;
	end if;
end process;





--Read data process
process (clock, reset) is
begin
    if (reset = '0') then
	    qspi_dq_in_sig <= (others=>'0');
	    data_in_counter <= (others=>'0');	
	elsif(rising_edge(clock)) then
	    if (clock_en = '1') then
	        if (Dummy cycles done = '1' and data_in_counter < X"8") then
		        data_in_counter <= data_in_counter + '1';
		    	qspi_dq_in_sig(3 downto 0) <= qspi_dq_in(3 downto 0);
		    	qspi_dq_in_sig <= qspi_dq_in_sig(27 downto 0) & qspi_dq_in_sig(31 downto 28);
		    else
		        data_in_counter <= (others=>'0');
		        qspi_dq_in_sig <= qspi_dq_in_sig;
		    end if;
		end if;
	end if;
end process;


--Send Quad command process
process (clock, reset) is
begin
    if (reset = '0') then
		command_data_sig <= X"00";
		command_counter <= "00";
		start_cmd_out <= '0';
		send_quad_cmd_done <= '0';
		qspi_dq_cmd_out <= (others=> '0');
	elsif(rising_edge(clock)) then
	    if (clock_en = '1') then
            if (initiate_cmd = '1') then
				command_counter <= command_counter + '1';
				if (command_counter = "00") then
				    command_data_sig <= command_data(7 downto 0);
					qspi_dq_cmd_out <= (others=> '0');
					start_cmd_out <= '1';
					send_quad_cmd_done <= '0';
				elsif (command_counter = "01") then
				    qspi_dq_cmd_out <= command_data_sig(7 downto 4);
				    start_cmd_out <= '1';
					send_quad_cmd_done <= '0';
				elsif (command_counter = "10") then
				    qspi_dq_cmd_out <= command_data_sig(3 downto 0);
				    start_cmd_out <= '0';
					send_quad_cmd_done <= '1';
				else
				    qspi_dq_cmd_out <= qspi_dq_cmd_out;
			        command_data_sig <= command_data_sig;
				    command_counter <= command_counter;
				    start_cmd_out <= start_cmd_out;
				    send_quad_cmd_done <= send_quad_cmd_done;
				end if;
			else
			    qspi_dq_cmd_out <= qspi_dq_cmd_out;
			    command_data_sig <= command_data_sig;
				command_counter <= "00";
				start_cmd_out <= '0';
				send_quad_cmd_done <= '0';
			end if;
		end if;
	end if;
end process;


--Send Quad address process
process (clock, reset) is
begin
    if (reset = '0') then
		address_data_sig <= X"000000";  --24 bit address
		address_counter <= "000";
		start_add_out <= '0';
		send_quad_add_done <= '0';
		qspi_dq_add_out <= (others=> '0');
	elsif(rising_edge(clock)) then
	    if (clock_en = '1') then
            if (initiate_add = '1') then
				address_counter <= address_counter + '1';
				if (address_counter = "000") then
				    address_data_sig <= address_data(23 downto 0);
					qspi_dq_add_out <= (others=> '0');
					start_add_out <= '1';
					send_quad_add_done <= '0';
				elsif (address_counter => "001" and address_counter =<"110" ) then
				    qspi_dq_add_out <= address_data_sig(23 downto 20);
					address_data_sig <= address_data_sig(19 downto 0)&address_data_sig(23 downto 20);
				    if (address_counter = "110") then
				        start_add_out <= '0';
					    send_quad_add_done <= '1';
					else
					   	start_add_out <= '1';
					    send_quad_add_done <= '0';
					end if;
				else
				    qspi_dq_add_out <= qspi_dq_add_out;
			        address_data_sig <= address_data_sig;
				    address_counter <= address_counter;
				    start_add_out <= start_add_out;
				    send_quad_add_done <= send_quad_add_done;
				end if;
			else
			    qspi_dq_add_out <= qspi_dq_add_out;
			    address_data_sig <= address_data_sig;
				address_counter <= "00";
				start_add_out <= '0';
				send_quad_add_done <= '0';
			end if;
		end if;
	end if;
end process;



--Send Quad data process
process (clock, reset) is
begin
    if (reset = '0') then
		output_data_sig <= X"00000000";  --32bit address
		data_out_counter <= "0000";
		start_data_out <= '0';
		send_quad_data_done <= '0';
		qspi_dq_data_out <= (others=> '0');
	elsif(rising_edge(clock)) then
	    if (clock_en = '1') then
            if (initiate_data = '1') then
				data_out_counter <= data_out_counter + '1';
				if (data_out_counter = "000") then
				    output_data_sig <= data_write(31 downto 0);
					qspi_dq_data_out <= (others=> '0');
					start_data_out <= '1';
					send_quad_data_done <= '0';
				elsif (data_out_counter => "0001" and data_out_counter =<"1000" ) then
				    qspi_dq_data_out <= output_data_sig(31 downto 28);
					output_data_sig <= output_data_sig(27 downto 0)&output_data_sig(31 downto 28);
				    if (data_out_counter = "1000") then
				        start_data_out <= '0';
					    send_quad_data_done <= '1';
					else
					   	start_data_out <= '1';
					    send_quad_data_done <= '0';
					end if;
				else
				    qspi_dq_data_out <= qspi_dq_data_out;
			        output_data_sig <= output_data_sig;
				    data_out_counter <= data_out_counter;
				    start_data_out <= start_data_out;
				    send_quad_data_done <= send_quad_data_done;
				end if;
			else
			    qspi_dq_data_out <= qspi_dq_data_out;
			    output_data_sig <= output_data_sig;
				data_out_counter <= "00";
				start_data_out <= '0';
				send_quad_data_done <= '0';
			end if;
		end if;
	end if;
end process;















end Qspi_controller_arch;
