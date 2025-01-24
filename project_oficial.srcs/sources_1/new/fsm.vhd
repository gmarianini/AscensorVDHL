library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fsm is
    Port (
        CLK               : in  STD_LOGIC;
        RESET             : in  STD_LOGIC;  -- Activo en '0'
        EDGE_BUTTONS      : in  STD_LOGIC_VECTOR(3 downto 0);
        Emergencia        : in  STD_LOGIC;
        TIEMPO_CUMPLIDO   : in  STD_LOGIC;  -- Para movimiento
        TIEMPO_CUMPLIDOP  : in  STD_LOGIC;  -- Para puertas
        INICIAR_TIEMPO    : out STD_LOGIC;  -- Activa el timer de movimiento
        INICIAR_TIEMPOP   : out STD_LOGIC;  -- Activa el timer de puerta
        OUT_PUERTA        : out STD_LOGIC;
        OUT_PISOS         : out STD_LOGIC_VECTOR(3 downto 0);
        OUT_MOVIMIENTO    : out STD_LOGIC;
        OUT_PISO_OBJETIVO : out STD_LOGIC_VECTOR(3 downto 0);
        LED_EMER          : out STD_LOGIC_VECTOR(11 downto 0);
        LED_PISO_ESTADOS  : out STD_LOGIC_VECTOR(3 downto 0)
    );
end fsm;

architecture Behavioral of fsm is

    type estado_type is (reposo, cerrar, marcha, abrir, emer);
    signal estado, estado_siguiente : estado_type := reposo;

    signal piso_memoria : std_logic_vector(3 downto 0) := "0001";  
    signal piso_real    : std_logic_vector(3 downto 0) := "0001";  
    signal led_estados  : std_logic_vector(3 downto 0) := (others => '0');   
    signal iniciar_tiempo_siguiente : std_logic := '0';
    signal iniciar_tiempo_puertas   : std_logic := '0';  
    signal puerta_abierta : std_logic := '1';
    signal tiempo_cumplido_prev  : std_logic := '0';
    signal tiempo_cumplido_p     : std_logic := '0';   -- Para puertas
    signal aux : std_logic := '0';

    constant C_MAX_CONTADOR : natural := 50_000_000;  -- 0.5s en un reloj de 100MHz
    signal   CONTADOR : natural range 0 to C_MAX_CONTADOR := 0;
    signal   SENAL_emer    : std_logic := '0';

begin

    process (CLK, RESET)
    begin
        if RESET = '0' then
            estado <= reposo;
            piso_memoria <= "0001";
            piso_real    <= "0001";
            puerta_abierta <= '1';
            INICIAR_TIEMPO   <= '0';
            INICIAR_TIEMPOP  <= '0';
            tiempo_cumplido_prev <= '0';
            tiempo_cumplido_p    <= '0';
            aux <= '0';

            CONTADOR <= 0;
            SENAL_emer    <= '0';

        elsif rising_edge(CLK) then
            
            if estado = emer then
                if CONTADOR < C_MAX_CONTADOR then
                    CONTADOR <= CONTADOR + 1;
                else
                    CONTADOR <= 0;
                    SENAL_emer    <= not SENAL_emer;
                end if;
            else
                
                CONTADOR <= 0;
                SENAL_emer    <= '0';
            end if;
         

            -- Guardamos estado actual => siguiente
            estado <= estado_siguiente;

            -- Para detectar flancos en TIEMPO_CUMPLIDO
            tiempo_cumplido_prev <= TIEMPO_CUMPLIDO;
            tiempo_cumplido_p    <= TIEMPO_CUMPLIDOP;

            -- Actualizamos enable de timers
            INICIAR_TIEMPO  <= iniciar_tiempo_siguiente;
            INICIAR_TIEMPOP <= iniciar_tiempo_puertas;

          
            if estado = reposo then
                if EDGE_BUTTONS(0) = '1' then
                    piso_memoria <= "0001";
                elsif EDGE_BUTTONS(1) = '1' then
                    piso_memoria <= "0010";
                elsif EDGE_BUTTONS(2) = '1' then
                    piso_memoria <= "0100";
                elsif EDGE_BUTTONS(3) = '1' then
                    piso_memoria <= "1000";
                end if;
            end if;

            if (estado = cerrar or estado = abrir) then
                if (TIEMPO_CUMPLIDOP = '1' and tiempo_cumplido_p = '0') then
                    puerta_abierta <= not puerta_abierta;
                    INICIAR_TIEMPOP <= '0';
                end if;
            end if;

            if estado = marcha then
                -- Flanco de subida
                if (TIEMPO_CUMPLIDO = '1' and tiempo_cumplido_prev = '0') then
                    aux <= '1';
                    INICIAR_TIEMPO <= '0';
                -- Flanco de bajada
                elsif (TIEMPO_CUMPLIDO = '0' and tiempo_cumplido_prev = '1') then
                    aux <= '0';
                end if;
            end if;

            if (estado = marcha) and 
               (TIEMPO_CUMPLIDO = '1' and tiempo_cumplido_prev = '0') and 
               (iniciar_tiempo_siguiente = '1') then

                if piso_real < piso_memoria then
                    piso_real <= std_logic_vector(unsigned(piso_real) sll 1);
                elsif piso_real > piso_memoria then
                    piso_real <= std_logic_vector(unsigned(piso_real) srl 1);
                end if;
            end if;

        end if;
    end process;

   
    process (estado, piso_memoria, piso_real, puerta_abierta, Emergencia, aux)
    begin
        estado_siguiente         <= estado;
        iniciar_tiempo_puertas   <= '0';
        iniciar_tiempo_siguiente <= '0';

        led_estados <= "0000";

        case estado is
            when reposo =>
                led_estados <= "0001";

                if piso_memoria /= piso_real then
                    estado_siguiente <= cerrar;
                    iniciar_tiempo_puertas <= '1';
                end if;

            when cerrar =>
                led_estados <= "0010";
                if puerta_abierta = '1' then
                    iniciar_tiempo_puertas <= '1';
                else
                    estado_siguiente <= marcha;
                    iniciar_tiempo_puertas <= '0';
                    iniciar_tiempo_siguiente <= '1'; 
                end if;

            when marcha =>
                led_estados <= "0100";

                if Emergencia = '1' then
                    estado_siguiente <= emer;
                    iniciar_tiempo_siguiente <= '0';
                else
                    if aux = '1' then
                        iniciar_tiempo_siguiente <= '0';
                    elsif aux = '0' then
                        if piso_real /= piso_memoria then
                            iniciar_tiempo_siguiente <= '1'; 
                        else
                            estado_siguiente <= abrir;
                            iniciar_tiempo_siguiente <= '0';
                        end if;
                    end if;
                end if;

            when abrir =>
                led_estados <= "1000";
                if puerta_abierta = '0' then
                    iniciar_tiempo_puertas <= '1';
                else
                    estado_siguiente <= reposo;
                    iniciar_tiempo_puertas <= '0';
                end if;

            when emer =>
                led_estados <= "1111";  
                -- Comportamiento de LED_EMER controlado por blink_emer en el proceso sincrónico
                if Emergencia = '0' then
                    estado_siguiente <= marcha;
                    iniciar_tiempo_siguiente <= '1';
                end if;

            when others =>
                estado_siguiente <= reposo;
        end case;
    end process;

    OUT_MOVIMIENTO    <= '1' when (estado = marcha) else '0';
    OUT_PUERTA        <= puerta_abierta;
    OUT_PISOS         <= piso_real;      
    OUT_PISO_OBJETIVO <= piso_memoria;  
    LED_PISO_ESTADOS  <= led_estados;

   
    LED_EMER <= (others => SENAL_emer) when (estado = emer) else (others => '0');

end Behavioral;
