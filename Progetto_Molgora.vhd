----------------------------------------------------------------------------------
-- Company: Polimi
-- Engineer: Molgora Roberto
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity project_reti_logiche is
    Port ( i_clk : in STD_LOGIC;
           i_rst : in STD_LOGIC;
           i_start : in STD_LOGIC;
           i_data : in STD_LOGIC_VECTOR (7 downto 0);
           o_address : out STD_LOGIC_VECTOR (15 downto 0);  
           o_done : out STD_LOGIC;
           o_en : out STD_LOGIC;
           o_we : out STD_LOGIC;
           o_data : out STD_LOGIC_VECTOR (7 downto 0));
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
type state_type is (s0, comodo3, comodo2, setta_indirizzo_lettura, aspetta_start, cerca, scrivi, leggi, comodo, nuovo_valore_pixel, setta_indirizzo_scrittura, comodo1);
signal stato_attuale : state_type := s0;
shared variable max_pixel_value : integer;
shared variable min_pixel_value : integer;
shared variable delta_value : integer;
shared variable shift_level : integer;
shared variable current_pixel_value : integer;
shared variable new_pixel_value : integer;
shared variable temp_pixel : integer;
shared variable n_rows : integer;
shared variable n_cols : integer;
shared variable n_pixel : integer;
signal address : integer;
begin
state_reg : process(i_clk, i_rst)
    begin
    if(i_rst = '1') then
                o_done <= '0';
                o_we <= '0';
                stato_attuale <= s0;
            elsif rising_edge(i_clk) then
        case stato_attuale is
        
        
        --azzero tutto e aspetta start
        when s0 => 
                    o_done <= '0';
                    max_pixel_value := 0;
                    min_pixel_value := 255;
                    delta_value := 0;
                    shift_level := 0;
                    current_pixel_value := 0;
                    new_pixel_value := 0;
                    temp_pixel := 0;
                    n_rows := 1;
                    n_cols := 1;
                    address <= 0;
                    o_en <= '0';
                    o_we <= '0';
                    o_data <= "00000000";
                    if(i_start='1') then
                    o_en <= '1';
                    stato_attuale <= setta_indirizzo_lettura;
                    end if;
                  
                    
        --indico l'indirizzo in cui voglio leggere
        when setta_indirizzo_lettura =>
                    n_pixel := n_rows * n_cols;
                    if(address < n_pixel + 2) then
                        stato_attuale <= comodo;
                    else   
                        address <= 2;
                        --imposto shift
                        delta_value := max_pixel_value - min_pixel_value + 1;
                        if(delta_value = 256)        then    shift_level := 0;
                        elsif(delta_value >= 128)    then    shift_level := 1;
                        elsif(delta_value >= 64)     then    shift_level := 2;
                        elsif(delta_value >= 32)     then    shift_level := 3;
                        elsif(delta_value >= 16)     then    shift_level := 4;
                        elsif(delta_value >= 8)      then    shift_level := 5;
                        elsif(delta_value >= 4)      then    shift_level := 6;
                        elsif(delta_value >= 2)      then    shift_level := 7;
                        elsif(delta_value = 1)       then    shift_level := 8;
                        end if;
                        --fine impostazione shift
                        stato_attuale <= setta_indirizzo_scrittura;
                    end if;
                    o_address <= std_logic_vector(to_unsigned(address, 16));
                    
        
        --fa passare un ciclo            
        when comodo =>
                    stato_attuale <= leggi;
      
        
        --leggo da memoria all'indirizzo indicato precedentemente
        when leggi =>
                    if(address = 0) then 
                        n_cols := to_integer(unsigned(i_data));
                        stato_attuale <= setta_indirizzo_lettura;
                    elsif(address = 1) then 
                        n_rows := to_integer(unsigned(i_data));
                        stato_attuale <= setta_indirizzo_lettura;
                    elsif(address > 1) then
                        stato_attuale <= cerca;
                    end if;
                    address <= address + 1;


        --controllo max e min
        when cerca =>
                    current_pixel_value := to_integer(unsigned(i_data));
                    if(min_pixel_value > current_pixel_value) then
                        min_pixel_value := current_pixel_value;
                    end if;
                    if(max_pixel_value < current_pixel_value) then
                        max_pixel_value := current_pixel_value;
                    end if;
                    stato_attuale <= setta_indirizzo_lettura;
                      
                      
        --scelgo in quale indirizzo leggere e quindi anche in quale scievere        
        when setta_indirizzo_scrittura =>
                    o_address <= std_logic_vector(to_unsigned(address, 16));
                    if(address < n_rows * n_cols + 2) then
                        stato_attuale <= comodo1;
                    else 
                        o_done <= '1';
                        o_en <= '0';
                        stato_attuale <= aspetta_start; 
                    end if;
                    
                    
        --fa passare un ciclo            
        when comodo1 =>
                    stato_attuale <= nuovo_valore_pixel;
                    
                                 
        --modifico il valore del pixel attuale
        when nuovo_valore_pixel =>
                   current_pixel_value := to_integer(unsigned(i_data));
                   
                   --temp_pixel << shift_level
                   temp_pixel := (current_pixel_value - min_pixel_value);
                   temp_pixel := to_integer(shift_left(to_unsigned(temp_pixel, 16), shift_level));
                   
                   --new_pixel_value := minimum(255, temp_pixel);
                   if(temp_pixel > 255) then            
                        new_pixel_value := 255;         
                   else                                 
                        new_pixel_value := temp_pixel;  
                   end if;  
                   
                   o_we  <= '1';
                   o_address <= std_logic_vector(to_unsigned(address + n_rows * n_cols, 16));
                   stato_attuale <= scrivi;
        
        
        --scrivo in memoria 
        when scrivi =>
                o_data <= std_logic_vector(to_unsigned(new_pixel_value, 8));
                address <= address + 1;   
                stato_attuale <= comodo2;   
        
         
       when comodo2 => 
                stato_attuale <= comodo3;   
       
       when comodo3 =>
                    o_we <= '0';
                    stato_attuale <= setta_indirizzo_scrittura;
                
                
       --sta qua finche' start non viene riportato a 0    
        when aspetta_start =>
                if(i_start = '0') then
                    o_done <= '0';   
                    stato_attuale <= s0;
                elsif(i_start = '1') then
                    stato_attuale <= aspetta_start;
                end if;
       
      end case;
      end if;
      end process;
end Behavioral;
