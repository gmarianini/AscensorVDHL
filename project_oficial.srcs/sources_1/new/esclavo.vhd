library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity esclavo is
    generic (
        N_CICLOS_5SEG : natural   
    );
    port (
        CLK              : in  std_logic;
        RESET            : in  std_logic;
        INICIAR_TIEMPO   : in  std_logic;
        TIEMPO_CUMPLIDO  : out std_logic
    );
end esclavo;
architecture Behavioral of esclavo is
    signal contador : unsigned(31 downto 0) := (others => '0');
    signal activo   : std_logic := '0';
begin
    process(CLK, RESET)
    begin
        if RESET = '0' then
            contador <= (others => '0');
            activo <= '0';
        elsif rising_edge(CLK) then
            if INICIAR_TIEMPO = '1' then
                if activo = '0' then
                    activo <= '1';
                    contador <= (others => '0');
                else
                    if contador < to_unsigned(N_CICLOS_5SEG - 1, 32) then
                        contador <= contador + 1;
                    end if;
                end if;
            else
                activo <= '0';
                contador <= (others => '0');
            end if;
        end if;
    end process;
    TIEMPO_CUMPLIDO <= '1' when (activo = '1' and contador = to_unsigned(N_CICLOS_5SEG - 1, 32)) else '0';
end Behavioral;
