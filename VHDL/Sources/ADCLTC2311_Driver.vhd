
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity ADCLTC2311_Driver is
    port(
        -- Reset and Clocks
        i_Rst_n      : in  std_logic;             -- General Reset, negative polarity
        i_Clk_100MHz : in  std_logic;             -- State Machine clock
        -- Control
        i_Enable     : in  std_logic;             -- Enable flag to allow sampling
        o_Ready      : out std_logic;             -- Ready flag when data register is up to date
        o_Data_Reg   : out std_logic_vector(15 downto 0); -- Output data register from conversion
        -- ADC SPI
        o_ADC_SCK    : out std_logic;             -- SPI Serial Clock
        o_ADC_CNV_n  : out std_logic;             -- SPI Convert Input, negative polarity
        i_ADC_SDO    : in  std_logic              -- SPI Slave Data Output (MISO)
    );
end ADCLTC2311_Driver;

architecture RTL of ADCLTC2311_Driver is

    -- State Machine
    type state_type is (S_Idle, S_Acquisition, S_Conversion, S_End_Delay);
    signal state : state_type;

    -- ADC Control Registers
    signal SPI_Conversion_cnt : unsigned(1 downto 0);
    signal SPI_Bit_Number_cnt : unsigned(3 downto 0); -- 16-bit standard SPI protocol
    signal SPI_Received_Data  : std_logic_vector(15 downto 0);

begin

    ------------------------------------------------------------------------------------------------------------------------------------------------------------
    --
    -- ADC SPI Protocol, deserializing data from Slave Data Output (SDO)
    --
    ------------------------------------------------------------------------------------------------------------------------------------------------------------

    o_ADC_SCK <= i_Clk_100MHz;                    -- Serial Clock is always enable for now

    p_ADC_SPI_Protocol : process(i_Rst_n, i_Clk_100MHz)
    begin
        if i_Rst_n = '0' then
            o_Ready     <= '0';                   -- No new value
            o_Data_Reg  <= (others => '0');       -- Clear output
            o_ADC_CNV_n <= '0';                   -- No conversion requested

            SPI_Conversion_cnt <= "00";
            SPI_Bit_Number_cnt <= X"F";           -- Send MSB first
            SPI_Received_Data  <= (others => '0'); -- Empty buffer
            state              <= S_Idle;         -- Start in idle state
        elsif rising_edge(i_Clk_100MHz) then
            -- FSM
            case state is                         -- FSM_freq = 100MHz, here sampling at here sampling at 4.54 MHz
                when S_Idle =>
                    -- Internal registers initialization
                    SPI_Conversion_cnt <= "00";
                    SPI_Bit_Number_cnt <= X"F";   -- Send MSB first
                    SPI_Received_Data  <= (others => '0'); -- Empty buffer

                    if i_Enable = '1' then        -- Start a new acquisition only if enable
                        state <= S_Acquisition;
                    else
                        o_ADC_CNV_n <= '0';       -- No conversion requested
                        o_Ready     <= '0';       -- No new value
                        o_Data_Reg  <= (others => '0'); -- Clear output if no measure
                    end if;
                ----------------------------------------------------------------------------------
                when S_Acquisition =>
                    if SPI_Conversion_cnt = "11" then -- Wait for at least 9.5ns, SCK Quiet Time from CNV_n falling edge
                        o_Ready     <= '0';       -- No new value
                        o_ADC_CNV_n <= '0';       -- Start new conversion
                        state       <= S_Conversion;
                    else                          -- Wait for at least 25ns with CNV_n in high state, here 3 cycles
                        o_ADC_CNV_n <= '1';       -- Start new sampling
                    end if;
                    SPI_Conversion_cnt <= SPI_Conversion_cnt + "1";
                ----------------------------------------------------------------------------------
                when S_Conversion =>
                    -- Store Data register bit
                    SPI_Received_Data <= SPI_Received_Data(14 downto 0) & i_ADC_SDO; -- Store the newly measured bit

                    -- Bits are received in descending order from bit #15 to bit #0
                    SPI_Bit_Number_cnt <= SPI_Bit_Number_cnt - "1";

                    -- Check if end of conversion
                    if SPI_Bit_Number_cnt = X"0" then
                        state <= S_End_Delay;     -- All bits have been sent
                    end if;
                ----------------------------------------------------------------------------------
                when S_End_Delay =>
                    -- Wait for at least 19.1ns, SCK Delay Time to CNV rising edge
                    -- Equivalent to 1 cycle in S_End_Delay and 1 cycle in S_Idle, then re-start
                    o_Ready    <= '1';            -- Data registers are up to date, all requested values have been converted
                    o_Data_Reg <= SPI_Received_Data;
                    state      <= S_Idle;
                ----------------------------------------------------------------------------------
                when others =>
                    state <= S_Idle;
            end case;
        end if;
    end process p_ADC_SPI_Protocol;

end architecture RTL;
