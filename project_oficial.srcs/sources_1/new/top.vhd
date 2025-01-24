library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
    port (
        CLK             : in  std_logic;
        RESET           : in  std_logic;
        boton           : in  std_logic_vector(3 downto 0);
        Emergencia      : in  std_logic;
       LED_EMER  :out std_logic_vector(11 downto 0) ;
      LED_PISO_ESTADOS : out std_logic_vector(3 downto 0) ;
       led : OUT STD_LOGIC_VECTOR (6 downto 0);
        ctrl : out std_logic_vector (7 downto 0)     
    );
end top;




architecture Behavioral of top is

    -- Señales internas para conectar la FSM con el esclavo
    signal iniciar_tiempo : std_logic;
    signal iniciar_tiempo_p : std_logic;
    signal tiempo_cumplido : std_logic;
    signal tiempo_cumplidop : std_logic;
     signal tiempo_emergencia : std_logic;
     signal iniciar_emergencia : std_logic;
    -- Señales para almacenar los valores sincronizados
    signal sync_buttons      : std_logic_vector(3 downto 0); -- Salidas sincronizadas de los botones
    
   
    signal edge_detected     : std_logic_vector(3 downto 0); -- Salidas de flancos
    signal piso_objetivo_signal : std_logic_vector(3 downto 0);
   signal  actual_signal :  std_logic_vector (3 downto 0);
       
       signal motor_signal:  std_logic;   --El modo_motor es si subimos, bajamos o nos paramos   
      signal  puerta_signal :  std_logic;
    
        -- Señales para sincronizar y detectar el flanco
  
    
component fsm
    Port (
        CLK              : in  STD_LOGIC;
        RESET            : in  STD_LOGIC;
        EDGE_BUTTONS     : in  STD_LOGIC_VECTOR(3 downto 0);
        Emergencia       : in  STD_LOGIC;
        TIEMPO_CUMPLIDO  : in  STD_LOGIC;
        TIEMPO_CUMPLIDOP : in  STD_LOGIC;
        
        INICIAR_TIEMPOP  : out STD_LOGIC;
        INICIAR_TIEMPO   : out STD_LOGIC;
        
        OUT_PUERTA       : out STD_LOGIC;
        OUT_PISOS        : out STD_LOGIC_VECTOR(3 downto 0);
        OUT_MOVIMIENTO   : out STD_LOGIC;
        OUT_PISO_OBJETIVO : out STD_LOGIC_VECTOR(3 downto 0); -- Nueva salida
         LED_EMER : out STD_LOGIC_VECTOR(11 downto 0);
        LED_PISO_ESTADOS : out std_logic_vector(3 downto 0) 
    );
end component;

component esclavo
    generic (
        N_CICLOS_5SEG : natural -- Ajusta este valor según la frecuencia de reloj y el tiempo deseado
    );
    port (
        CLK              : in  std_logic;
        RESET            : in  std_logic;
        INICIAR_TIEMPO   : in  std_logic;
        TIEMPO_CUMPLIDO  : out std_logic
    );
end component;
component SYNCHRNZR
    port(
    CLK : in std_logic;
    ASYNC_IN : in std_logic;
    SYNC_OUT : out std_logic
    );
    end component;
component EDGETCTR
    port(
    CLK : in std_logic;
    SYNC_IN : in std_logic;
    EDGE : out std_logic
);
end component;
component Display
   Port ( 
        reset : in std_logic;
        clk : in std_logic;
        destino : IN STD_LOGIC_VECTOR (3 downto 0);    
        actual : in std_logic_vector (3 downto 0);
        led : OUT STD_LOGIC_VECTOR (6 downto 0);
        ctrl : out std_logic_vector (7 downto 0);          
        modo_motor: in std_logic;   --El modo_motor es si subimos, bajamos o nos paramos   
        modo_puerta : in std_logic
        
    );
    end component;
begin
    fsm_inst : entity work.fsm
        port map (
            CLK             => CLK,
            RESET           => RESET,
            EDGE_BUTTONS    => edge_detected,
            Emergencia      => Emergencia,
            TIEMPO_CUMPLIDO => tiempo_cumplido,
            TIEMPO_CUMPLIDOP => tiempo_cumplidop,
           
            INICIAR_TIEMPOP => iniciar_tiempo_p,
            INICIAR_TIEMPO  => iniciar_tiempo,
            
            OUT_PUERTA      => puerta_signal,
            OUT_PISOS       => actual_signal,
            OUT_MOVIMIENTO  => motor_signal,
            OUT_PISO_OBJETIVO => piso_objetivo_signal,
            LED_EMER=> LED_EMER,
             LED_PISO_ESTADOS => LED_PISO_ESTADOS
        );
        
            esclavo_inst : entity work.esclavo
        generic map (
            N_CICLOS_5SEG => 200_000_000   -- Ajusta según la frecuencia de reloj 2 segundos
        )
        port map (
            CLK             => CLK,
            RESET           => RESET,
            INICIAR_TIEMPO  => iniciar_tiempo_p,
            TIEMPO_CUMPLIDO => tiempo_cumplidop
        );
    esclavo_movimiento : entity work.esclavo
        generic map (
            N_CICLOS_5SEG => 500_000_000   -- Ajusta según la frecuencia de reloj 5 segundos a 100 MHz
        )
        port map (
            CLK             => CLK,
            RESET           => RESET,
            INICIAR_TIEMPO  => iniciar_tiempo,
            TIEMPO_CUMPLIDO => tiempo_cumplido
        );
         
        -- Instancia del Sincronizador para el botón 0
    synchronizer_0 : SYNCHRNZR
        port map (
        CLK      => CLK,
        ASYNC_IN => boton(0),  -- Entrada asíncrona (botón 0)
        SYNC_OUT => sync_buttons(0)   -- Salida sincronizada
    );

        -- Instancia del Sincronizador para el botón 1
    synchronizer_1 : SYNCHRNZR
        port map (
        CLK      => CLK,
        ASYNC_IN => boton(1),  -- Entrada asíncrona (botón 1)
        SYNC_OUT => sync_buttons(1)   -- Salida sincronizada
    );

    -- Instancia del Sincronizador para el botón 2
    synchronizer_2 : SYNCHRNZR
        port map (
        CLK      => CLK,
        ASYNC_IN => boton(2),  -- Entrada asíncrona (botón 2)
        SYNC_OUT => sync_buttons(2)   -- Salida sincronizada
    );

        -- Instancia del Sincronizador para el botón 3
    synchronizer_3 : SYNCHRNZR
        port map (
        CLK      => CLK,
        ASYNC_IN => boton(3),  -- Entrada asíncrona (botón 3)
        SYNC_OUT => sync_buttons(3)   -- Salida sincronizada
    );

        -- Instancia del Sincronizador para la señal de Emergencia
    
        
        -- Instancia del Edge Detector para el botón 0
    EDGETCTR_0 : EDGETCTR
    port map (
        CLK        => CLK,
        SYNC_IN  => sync_buttons(0),
        EDGE   => edge_detected(0)
    );

-- Instancia del Edge Detector para el botón 1
EDGETCTR_1 : EDGETCTR
    port map (
        CLK        => CLK,
        SYNC_IN  => sync_buttons(1),
        EDGE   => edge_detected(1)
    );

-- Instancia del Edge Detector para el botón 2
EDGETCTR_2 : EDGETCTR
    port map (
        CLK        => CLK,
        SYNC_IN  => sync_buttons(2),
        EDGE   => edge_detected(2)
    );

-- Instancia del Edge Detector para el botón 3
EDGETCTR_3 : EDGETCTR
    port map (
        CLK        => CLK,
        SYNC_IN  => sync_buttons(3),
        EDGE   => edge_detected(3)
    );
    
    -- Instancia del Edge Detector para la señal sincronizada de Emergencia
Display_1 : Display
    port map (
       reset =>RESET,
        clk =>CLK,
        destino => piso_objetivo_signal,
        actual => actual_signal,
        led =>led,
        ctrl =>ctrl,    
        modo_motor =>  motor_signal,  
        modo_puerta => puerta_signal
        
        
    );
     
end Behavioral;
