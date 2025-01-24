library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity Display is
    Port (
        reset       : in  std_logic;
        clk         : in  std_logic;
        destino     : in  std_logic_vector(3 downto 0);
        actual      : in  std_logic_vector(3 downto 0);
        led         : out std_logic_vector(6 downto 0);  
        ctrl        : out std_logic_vector(7 downto 0);  
        modo_motor  : in  std_logic;
        modo_puerta : in  std_logic
    );
end Display;
architecture Behavioral of Display is

    constant DIV_MAX : integer := 20000;  -- 100 MHz / 5kHz = 20000
    signal div_contador   : unsigned(15 downto 0) := (others => '0');
    signal reset_contador : unsigned(2 downto 0) := (others => '0');
    signal led_reg  : std_logic_vector(6 downto 0) := (others => '1');
    signal ctrl_reg : std_logic_vector(7 downto 0) := (others => '1');
    
    function decode_pisos(nib : std_logic_vector(3 downto 0))
        return std_logic_vector is
        variable seg : std_logic_vector(6 downto 0) := (others => '1');
    begin
        case nib is
            when "0001" => seg := "0000001"; -- '0'
            when "0010" => seg := "1001111"; -- '1'
            when "0100" => seg := "0010010"; -- '2'
            when "1000" => seg := "0000110"; -- '3'
            when others => seg := "1111111"; -- Apagado
        end case;
        return seg;
    end function;
    function decode_PUERTA(b : std_logic) return std_logic_vector is
        variable seg : std_logic_vector(6 downto 0) := (others => '1');
    begin
        if b = '0' then
            seg := "0110110"; -- '0'
        else
            seg := "1001001"; -- '1'
        end if;
        return seg;
    end function;
     function decode_motor1sub(b : std_logic) return std_logic_vector is
        variable seg : std_logic_vector(6 downto 0) := (others => '1');
    begin
   
        if b = '0' then
            seg := "1111110"; -- '0'
        else
            seg := "0001101"; -- '1'
        end if;   
        return seg;
    end function;
     function decode_motor1baj(b : std_logic) return std_logic_vector is
        variable seg : std_logic_vector(6 downto 0) := (others => '1');
    begin     
     if b = '0' then
            seg := "1111110"; -- '0'
        else
            seg := "1000011"; -- '1'
        end if;
         
        return seg;
    end function;
function decode_motor2sub(b : std_logic) return std_logic_vector is
        variable seg : std_logic_vector(6 downto 0) := (others => '1');
    begin
        if b = '0' then
            seg := "1111110"; -- '0'
        else
            seg := "0011001"; -- '1'
        end if;
        return seg;
    end function;
    function decode_motor2baj(b : std_logic) return std_logic_vector is
        variable seg : std_logic_vector(6 downto 0) := (others => '1');
    begin
        if b = '0' then
            seg := "1111110"; -- '0'
        else
            seg := "1100001"; -- '1'
        end if;
        return seg;
    end function;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '0' then
                div_contador   <= (others => '0');
                reset_contador <= (others => '0');
            else
                div_contador <= div_contador + 1;
                if div_contador = to_unsigned(DIV_MAX, div_contador'length) then
                    div_contador   <= (others => '0');
                    reset_contador <= reset_contador + 1;  -- 000..111
                end if;
            end if;
        end if;
    end process;
    process(reset_contador, destino, actual, modo_puerta, modo_motor)
    begin
        ctrl_reg <= "11111111";
        led_reg  <= "1111111";

        case reset_contador is
            when "000" =>
                -- D0 => 
                ctrl_reg(0) <= '0';  
                led_reg <= decode_pisos(destino);
            when "001" =>
                -- D1 => 
                ctrl_reg(1) <= '0';
                led_reg <= decode_pisos(destino);
            when "010" =>
                -- D2 => 
                ctrl_reg(2) <= '0';
                led_reg <= decode_PUERTA(modo_puerta);

            when "011" =>
                -- D3 =>
                ctrl_reg(3) <= '0';
                led_reg <= decode_PUERTA(modo_puerta);
                
                when "100" =>
                -- D4 => 
                 if unsigned(destino) > unsigned(actual) then
                ctrl_reg(4) <= '0';
                led_reg <= decode_motor2sub(modo_motor);
                else
                 ctrl_reg(4) <= '0';
                 led_reg <= decode_motor2baj(modo_motor);
                 end if;
                when "101" =>
                 if unsigned(destino) > unsigned(actual) then
                -- D5 => 
                ctrl_reg(5) <= '0';
                led_reg <= decode_motor1sub(modo_motor);
                else
                 -- D5 =>
                ctrl_reg(5) <= '0';
                led_reg <= decode_motor1baj(modo_motor);
                end if;
                when "110" =>
                -- D6 => 
                ctrl_reg(6) <= '0';
                led_reg <= decode_pisos(actual);
                
                 when "111" =>
                -- D7 => 
                ctrl_reg(7) <= '0';
                led_reg <= decode_pisos(actual);
            when others =>
                ctrl_reg <= "11111111";
                led_reg  <= "1111111";
        end case;
    end process;
    led  <= led_reg;   
    ctrl <= ctrl_reg;  
end Behavioral;
