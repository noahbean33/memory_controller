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
signal qspi_clock                 :std_logic;
signal qspi_clock_cnt             :std_logic_vector(1 downto 0);
signal clock_en                   :std_logic;
signal clock_en_cnt               :std_logic_vector(2 downto 0);
signal clock_en_rising_edge       :std_logic;
signal clock_en_cnt_rising_edge   :std_logic_vector(2 downto 0);


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

--quad nonvolatile data
signal initiate_nonvol        :std_logic;
signal start_nonvol_out       :std_logic;
signal send_quad_nonvol_done  :std_logic;
signal output_nonvol_sig      :std_logic_vector(15 downto 0);
signal nonvol_out_counter     :std_logic_vector(2 downto 0); 
signal qspi_dq_nonvol_out     :std_logic_vector(3 downto 0);

--main state machine
type main_state_m is (initial,read_command_data_register1,read_status_register,fast_read,write_enable,
                      read_command_data_register2,write_data_to_the_qspi,write_16bits_command,write_8bits_command,
					  sector_erase);
signal main_sm:main_state_m;

--initialization state machine
type initialization_state_m is (initial,send_command_we,wait_before_next_cmd,send_cmd_nonvol,send_single_data,done);
signal initialization_sm:initialization_state_m;

signal wait_counter             :std_logic_vector(7 downto 0);
signal command_we_singel        :std_logic_vector(7 downto 0);
signal counter_data             :std_logic_vector(7 downto 0);
signal qspi_singel_initial      :std_logic;
signal nonvol_reg_cmd           :std_logic_vector(7 downto 0);
signal nonvol_reg_singel        :std_logic_vector(15 downto 0);
signal initialization_sm_done   :std_logic;








begin
qspi_clk_out <= qspi_clock;


--clock enable process
process (clock, reset) is
begin
    if (reset = '0') then
        clock_en <= '0';
		clock_en_cnt <= "000";
	elsif(falling_edge (clock)) then
	    if (clock_en_cnt < "100") then
            clock_en_cnt <= clock_en_cnt +'1';
		    clock_en <= '0';
		else
		    clock_en_cnt <= "000";
		    clock_en <= '1';
		end if;
	end if;
end process;


--clock enable process
process (clock, reset) is
begin
    if (reset = '0') then
        clock_en_rising_edge <= '0';
		clock_en_cnt_rising_edge <= "000";
	elsif(rising_edge(clock)) then 
	    if (clock_en_cnt_rising_edge < "100") then
            clock_en_cnt_rising_edge <= clock_en_cnt_rising_edge +'1';
		    clock_en_rising_edge <= '0';
		else
		    clock_en_cnt_rising_edge <= "000";
		    clock_en_rising_edge <= '1';
		end if;
	end if;
end process;


--clock QSPI flash - 25MHZ process
process (clock, reset) is
begin
    if (reset = '0') then
        qspi_clock <= '0';
		qspi_clock_cnt <= "00";
	elsif(falling_edge(clock)) then
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
	    if (clock_en_rising_edge = '1') then
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
	elsif(falling_edge(clock)) then
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
	elsif(falling_edge(clock)) then
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
				address_counter <= "000";
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
		output_data_sig <= X"00000000";  --32bit data
		data_out_counter <= "0000";
		start_data_out <= '0';
		send_quad_data_done <= '0';
		qspi_dq_data_out <= (others=> '0');
	elsif(falling_edge(clock)) then
	    if (clock_en = '1') then
            if (initiate_data = '1') then
				data_out_counter <= data_out_counter + '1';
				if (data_out_counter = "0000") then
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
				data_out_counter <= "0000";
				start_data_out <= '0';
				send_quad_data_done <= '0';
			end if;
		end if;
	end if;
end process;


--Send Quad nonvolatile data process (16 bits)
process (clock, reset) is
begin
    if (reset = '0') then
		output_nonvol_sig <= X"0000";  --16bit data nonvolatile register
		nonvol_out_counter <= "000";
		start_nonvol_out <= '0';
		send_quad_nonvol_done <= '0';
		qspi_dq_nonvol_out <= (others=> '0');
	elsif(falling_edge(clock)) then
	    if (clock_en = '1') then
            if (initiate_nonvol = '1') then
				nonvol_out_counter <= nonvol_out_counter + '1';
				if (nonvol_out_counter = "000") then
				    output_nonvol_sig <= data_write(15 downto 0);
					qspi_dq_nonvol_out <= (others=> '0');
					start_nonvol_out <= '1';
					send_quad_nonvol_done <= '0';
				elsif (nonvol_out_counter => "001" and nonvol_out_counter =<"100" ) then
				    if (nonvol_out_counter = "001") then
					    qspi_dq_nonvol_out <= output_nonvol_sig(7 downto 4); --LSB
					elsif(nonvol_out_counter = "010") then
					    qspi_dq_nonvol_out <= output_nonvol_sig(3 downto 0);
					elsif(nonvol_out_counter = "011") then
						qspi_dq_nonvol_out <= output_nonvol_sig(15 downto 12); --MSB
					elsif(nonvol_out_counter = "100") then
						qspi_dq_nonvol_out <= output_nonvol_sig(11 downto 8);
						start_nonvol_out <= '0';
					    send_quad_nonvol_done <= '1';
					else
						qspi_dq_nonvol_out <= qspi_dq_nonvol_out;
						start_nonvol_out <= '1';
					    send_quad_nonvol_done <= '0';
					end if;
				else
				    qspi_dq_nonvol_out <= qspi_dq_nonvol_out;
			        output_nonvol_sig <= output_nonvol_sig;
				    nonvol_out_counter <= nonvol_out_counter;
				    start_nonvol_out <= start_nonvol_out;
				    send_quad_nonvol_done <= send_quad_nonvol_done;
				end if;
			else
			    qspi_dq_nonvol_out <= qspi_dq_nonvol_out;
			    output_nonvol_sig <= output_nonvol_sig;
				nonvol_out_counter <= "000";
				start_nonvol_out <= '0';
				send_quad_nonvol_done <= '0';
			end if;
		end if;
	end if;
end process;


--main state machine
process (clock, reset) is
begin
    if (reset = '0') then
        main_sm <= initial;
	elsif(falling_edge(clock)) then
	    if (clock_en = '1') then
            case main_sm is
				when initial =>
				    if (Send_data(0) = '1' and initialization_sm_done = '1') then
						main_sm <= read_command_data_register1;
					else
						main_sm <= initial;
					end if;
					
				when read_command_data_register1 =>
				    if (command_data = X"05" or command_data = X"70") then
						main_sm <= read_status_register;
					elsif (command_data = X"0B") then
					    main_sm <= fast_read;
					elsif (command_data = X"06") then
					    main_sm <= write_enable;
					else
						main_sm <= read_command_data_register1;
					end if;
					
				when read_status_register =>
					if (done_read = '1') then
						main_sm <= initial;
					else
						main_sm <= read_status_register;
					end if;
				
				when fast_read =>
					if (done_read = '1') then
						main_sm <= initial;
					else
						main_sm <= fast_read;
					end if;
					
				when write_enable =>
				    if (Send_data(0) = '1' ) then
						main_sm <= read_command_data_register2;
					else
						main_sm <= write_enable;
					end if;
				
				when read_command_data_register2 =>
					if (command_data = X"02") then
						main_sm <= write_data_to_the_qspi;
					elsif (command_data = X"B1") then --write nonvolatile register
					    main_sm <= write_16bits_command;
					elsif (command_data = X"61" or command_data = X"81") then --write volatile or enhanched volatile registers
					    main_sm <= write_8bits_command
					elsif (command_data = X"D8") then
					    main_sm <= sector_erase;
					else
						main_sm <= read_command_data_register2;
					end if;
				
				when write_data_to_the_qspi =>
					if (done_write = '1') then
						main_sm <= initial;
					else
						main_sm <= write_data_to_the_qspi;
					end if;
				when write_16bits_command =>
					if (done_write = '1') then
						main_sm <= initial;
					else
						main_sm <= write_16bits_command;
					end if;
				when write_8bits_command =>
					if (done_write = '1') then
						main_sm <= initial;
					else
						main_sm <= write_8bits_command;
					end if;
				when sector_erase =>
					if (done_write = '1') then
						main_sm <= initial;
					else
						main_sm <= sector_erase;
					end if;
					
				when others => main_sm <= initial;
							
		end if;
	end if;
end process;



--main state machine
process (clock, reset) is
begin
    if (reset = '0') then
        done_read <= '0';
		done_write <= '0';
		initiate_add <= '0';
		initiate_cmd <= '0';
		initiate_data <= '0';
		initiate_nonvol <= '0';
		qspi_dq_out(3 downto 0) <= "0000";
		qspi_cs <= '1';
		qspi_out_en <= '1'; --write
	elsif(falling_edge(clock)) then
	    if (clock_en = '1') then
            case main_sm is
				when initial =>
				    done_read <= '0';
		            done_write <= '0';
		            initiate_add <= '0';
		            initiate_cmd <= '0';
		            initiate_data <= '0';
		            initiate_nonvol <= '0';
				if (initialization_sm != initial and initialization_sm != done) then
				
				
				when read_command_data_register1 =>
				when read_status_register =>
				when fast_read =>
				when write_enable =>
				when read_command_data_register2 =>
				when write_data_to_the_qspi =>
				when write_16bits_command =>
				when write_8bits_command =>
				when sector_erase =>
				when others => 
							
			
		end if;
	end if;
end process;




--initialization state machine
process (clock, reset) is
begin
    if (reset = '0') then
	    initialization_sm <= initial;
        wait_counter <= X"00";
		counter_data <= X"00";
		qspi_singel_initial <= '0';
		command_we_singel <= X"06"; --write enable command
		nonvol_reg_cmd <= X"B1"; --write nonvolatile register
		nonvol_reg_singel <= X"F7AF"; --sending AFF7h to the nonvol reg 
	    initialization_sm_done <= '0';
	elsif(falling_edge(clock)) then
	    if (clock_en = '1') then
            case initialization_sm is
				when initial =>
                    if (wait_counter = X"FF") then
					    wait_counter <= X"00";
					    initialization_sm <= send_command_we;
					else
					    initialization_sm <= initial;
					    wait_counter <= wait_counter + '1';
					end if;
					
				when send_command_we =>
					if (counter_data = X"09") then
					    initialization_sm <= wait_before_next_cmd;
						counter_data <= X"00";
						qspi_singel_initial <= '0';
					else
					    qspi_singel_initial <= command_we_singel(7);
						command_we_singel <= command_we_singel(6 downto 0)& command_we_singel(7);
						counter_data <= counter_data + '1';
						initialization_sm <= send_command_we;
					end if;
					
				when wait_before_next_cmd =>
				    qspi_singel_initial <= '0';
                    if (wait_counter = X"B0") then
					    wait_counter <= X"00";
					    initialization_sm <= send_cmd_nonvol;
					else
					    initialization_sm <= wait_before_next_cmd;
					    wait_counter <= wait_counter + '1';
					end if;
					
				when send_cmd_nonvol =>
					if (counter_data = X"09") then
					    initialization_sm <= send_single_data;
						counter_data <= X"00";
						qspi_singel_initial <= '0';
					else -- counter_data < X"09"
					    qspi_singel_initial <= nonvol_reg_cmd(7);
						nonvol_reg_cmd <= nonvol_reg_cmd(6 downto 0)& nonvol_reg_cmd(7);
						counter_data <= counter_data + '1';
						initialization_sm <= send_cmd_nonvol;
					end if;
				
				when send_single_data =>
					if (counter_data = X"10") then
					    initialization_sm <= done;
						counter_data <= X"00";
						qspi_singel_initial <= '0';
					else -- counter_data < X"10"
					    qspi_singel_initial <= nonvol_reg_singel(15);
						nonvol_reg_singel <= nonvol_reg_singel(14 downto 0)& nonvol_reg_singel(15);
						counter_data <= counter_data + '1';
						initialization_sm <= send_single_data;
					end if;
				
				when done =>
                        initialization_sm <= done;
						qspi_singel_initial <= '0';
						initialization_sm_done <= '1';
				when others => initialization_sm <= done;
							
			
		end if;
	end if;
end process;


















end Qspi_controller_arch;
