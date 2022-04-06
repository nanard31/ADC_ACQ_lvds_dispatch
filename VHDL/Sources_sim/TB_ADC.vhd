----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:30:00 09/04/2020
-- Design Name: 
-- Module Name:    TB_ADC - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments: 
-- 
-- command line count occurences
-- sort Gaus_Amp.txt | uniq -c > result.txt
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;
use STD.textio.all;


Library UNISIM;
use UNISIM.vcomponents.all;
--library NX;
--use NX.nxPackage.all;


entity TB_ADC is
end TB_ADC;

architecture Behavioral of TB_ADC is
	signal TB_Reset_n             : std_logic;
	signal TB_Reset        		  : std_logic;

	signal sys_clk_n        : std_logic;
	signal sys_clk_p        : std_logic;
	
	constant CLOCK_200_MHZ_period : time := 5 ns;
	
	constant C_Input_DelayLine  : time := 1 ns;
    constant C_Output_DelayLine : time := 17 ns;
	
	constant C_Input_DelayLine_spare  : time := 1 ns;
    constant C_Output_DelayLine_spare : time := 7 ns;

    -- signal DU_ADC_CNV_n     : std_logic_vector(0 to 3);
	-- signal o_ADC_CNV_n		: std_logic_vector(0 to 4);
    -- signal DU_ADC_SCK       : std_logic_vector(0 to 3);
    -- signal DU_Front_ADC_SDO : std_logic_vector(0 to 3);
    -- signal DU_Back_ADC_SDO  : std_logic_vector(0 to 3);

    -- signal DU_ADC_CNV_n_Delayed     : std_logic_vector(0 to 3);
    -- signal DU_ADC_SCK_Delayed       : std_logic_vector(0 to 3);
    -- signal DU_Front_ADC_SDO_Delayed : std_logic_vector(0 to 3);
    -- signal DU_Back_ADC_SDO_Delayed  : std_logic_vector(0 to 3);
	
	-- signal o_ADC_SCK_n				 : std_logic_vector(0 to 4);
	-- signal o_ADC_SCK_p				 : std_logic_vector(0 to 4);
	-- signal o_ADC_SCK_buff			: std_logic_vector(0 to 4);
	-- signal i_ADC_SDO_n				 : std_logic_vector(0 to 9);
	-- signal i_ADC_SDO_p				 : std_logic_vector(0 to 9);
	-- signal i_ADC_SDO_buf			: std_logic_vector(0 to 9);
	
	
	signal DU_ADC_CNV_n     : std_logic_vector(4 downto 0);
	signal o_ADC_CNV_n		: std_logic_vector(4 downto 0);
    signal DU_ADC_SCK       : std_logic_vector(4 downto 0);
    signal DU_Front_ADC_SDO : std_logic_vector(4 downto 0);
    signal DU_Back_ADC_SDO  : std_logic_vector(4 downto 0);

    signal DU_ADC_CNV_n_Delayed     : std_logic_vector(4 downto 0);
    signal DU_ADC_SCK_Delayed       : std_logic_vector(4 downto 0);
    signal DU_Front_ADC_SDO_Delayed : std_logic_vector(4 downto 0);
    signal DU_Back_ADC_SDO_Delayed  : std_logic_vector(4 downto 0);
	
	signal o_ADC_SCK_n				 : std_logic_vector(4 downto 0);
	signal o_ADC_SCK_p				 : std_logic_vector(4 downto 0);
	signal o_ADC_SCK_buff			: std_logic_vector(4 downto 0);
	signal i_ADC_SDO_n				 : std_logic_vector(9 downto 0);
	signal i_ADC_SDO_p				 : std_logic_vector(9 downto 0);
	signal i_ADC_SDO_buf			: std_logic_vector(9 downto 0);
	


    signal FIFO_OUT_rd_en : std_logic_vector(0 to 7);
    signal FIFO_OUT_dout  : std_logic_vector(31 downto 0);
	
	signal FIFO_OUT_rd_en_spare : std_logic_vector(0 to 7);
    signal FIFO_OUT_dout_spare  : std_logic_vector(31 downto 0);
	
begin

	TB_Reset <= not TB_Reset_n;
	
	Reset_process : process
	begin
		TB_Reset_n <= '0';
		wait for 100 ns;
		TB_Reset_n <= '1';
		wait;
	end process Reset_process;

	------------------------------
	-- Clk process definitions
	------------------------------
	Clk_in_100MHz_process : process
	begin
		sys_clk_n <= '0';
		sys_clk_p <= '1';
		wait for CLOCK_200_MHZ_period / 2;
		sys_clk_n <= '1';
		sys_clk_p <= '0';
		wait for CLOCK_200_MHZ_period / 2;
	end process;


	Inst_ramtest : entity work.ramtest
		port map(
		okUH				=>	(others => '0'),
		okHU				=>	open,
		okUHU				=>	open,
		okAA				=>	open,

		sys_clk_p			=> sys_clk_p,
		sys_clk_n			=> sys_clk_n,
		
		led					=>	open,
		
		ddr3_dq				=>	open,
		ddr3_addr			=>	open,
		ddr3_ba				=>	open,
		ddr3_ck_p			=>	open,
		ddr3_ck_n			=>	open,
		ddr3_cke			=>	open,
		ddr3_cas_n			=>	open,
		ddr3_ras_n			=>	open,
		ddr3_we_n			=>	open,
		ddr3_odt			=>	open,
		ddr3_dm				=>	open,
		ddr3_dqs_p			=>	open,
		ddr3_dqs_n			=>	open,
		ddr3_reset_n		=>	open,

		-- out
		o_ADC_CNV_n			=>	o_ADC_CNV_n,
		o_ADC_SCK_n			=>	o_ADC_SCK_n,
		o_ADC_SCK_p			=>	o_ADC_SCK_p,
		
		-- in
		
		i_ADC_SDO_p			=>	i_ADC_SDO_p,
		i_ADC_SDO_n			=>	i_ADC_SDO_n,
		
		sys_rst_sim			=>	TB_Reset
		
		);

	
	
        --------------------------------------------------------------------------------------------
        -- ADCLTC2311_Emulators
        --------------------------------------------------------------------------------------------
		
		
    p_Events_Generator : process
    begin
        FIFO_OUT_dout <= X"00000000";             -- Magic debug value
        while True loop
            wait until rising_edge(FIFO_OUT_rd_en(0));
            FIFO_OUT_dout <= std_logic_vector(unsigned(FIFO_OUT_dout) + X"0_0001");
        end loop;
    end process p_Events_Generator;		
		
	GENERATE_SDO : for I in 0 to 7 generate
		OBUFDS_sdo : OBUFDS
		generic map (
		  IOSTANDARD => "LVDS_25")
		port map (
		  O 	=> i_ADC_SDO_p(I),    -- Diff_p output (connect directly to top-level port)
		  OB 	=> i_ADC_SDO_n(I),   	-- Diff_n output (connect directly to top-level port)
		  I 	=> i_ADC_SDO_buf(i)   	-- Buffer input 
		);
		end generate GENERATE_SDO;		


	GENERATE_CLK : for I in 0 to 4 generate
		IBUFDS_clk : IBUFDS
		generic map (
		  IOSTANDARD => "LVDS_25")
		port map (
		  I 	=>	o_ADC_SCK_p(I),     	-- Diff_p output (connect directly to top-level port)
		  IB 	=>	o_ADC_SCK_n(I),   	-- Diff_n output (connect directly to top-level port)
		  O 	=>  o_ADC_SCK_buff(I)     -- Buffer input 
		);
		end generate GENERATE_CLK;			
			
		--	dispatch
		
DU_ADC_SCK(0) <= o_ADC_SCK_buff(0);
DU_ADC_SCK(1) <= o_ADC_SCK_buff(1);
DU_ADC_SCK(2) <= o_ADC_SCK_buff(2);
DU_ADC_SCK(3) <= o_ADC_SCK_buff(3);

DU_ADC_CNV_n(0) <= o_ADC_CNV_n(0);
DU_ADC_CNV_n(1) <= o_ADC_CNV_n(1);
DU_ADC_CNV_n(2) <= o_ADC_CNV_n(2);
DU_ADC_CNV_n(3) <= o_ADC_CNV_n(3);

i_ADC_SDO_buf(0) <=	DU_Front_ADC_SDO_Delayed(0);
i_ADC_SDO_buf(1) <=	DU_Back_ADC_SDO_Delayed(0);
i_ADC_SDO_buf(2) <=	DU_Front_ADC_SDO_Delayed(1);
i_ADC_SDO_buf(3) <=	DU_Back_ADC_SDO_Delayed(1);
i_ADC_SDO_buf(4) <=	DU_Front_ADC_SDO_Delayed(2);
i_ADC_SDO_buf(5) <=	DU_Back_ADC_SDO_Delayed(2);
i_ADC_SDO_buf(6) <=	DU_Front_ADC_SDO_Delayed(3);
i_ADC_SDO_buf(7) <= 	DU_Back_ADC_SDO_Delayed(3);
		
    -- Transport delay in the LVDS buffers and routes
    DU_ADC_CNV_n_Delayed(3 downto 0)     <= transport DU_ADC_CNV_n(3 downto 0) after C_Input_DelayLine;
    DU_ADC_SCK_Delayed(3 downto 0)       <= transport DU_ADC_SCK(3 downto 0) after C_Input_DelayLine;
    DU_Front_ADC_SDO_Delayed(3 downto 0) <= transport DU_Front_ADC_SDO(3 downto 0) after C_Output_DelayLine;
    DU_Back_ADC_SDO_Delayed(3 downto 0)  <= transport DU_Back_ADC_SDO(3 downto 0) after C_Output_DelayLine;

    gen_ADCLTC2311_Emulators_Parallel : for i in 0 to 3 generate
        inst_ADCLTC2311_Emulators : entity work.ADCLTC2311_Emulators
            port map(
                i_Rst_n         => TB_Reset_n,
                i_FIFO_empty    => '0',
                o_FIFO_rd_en    => FIFO_OUT_rd_en(i),
                i_FIFO_dout     => FIFO_OUT_dout,
                i_ADC_SCK       => DU_ADC_SCK_Delayed(i),
                i_ADC_CNV_n     => DU_ADC_CNV_n_Delayed(i),
                o_Front_ADC_SDO => DU_Front_ADC_SDO(i),
                o_Back_ADC_SDO  => DU_Back_ADC_SDO(i)
            );
    end generate gen_ADCLTC2311_Emulators_Parallel;	
	
	
	    --------------------------------------------------------------------------------------------
        -- ADCLTC2311_Emulators spare
        --------------------------------------------------------------------------------------------
		
		
    p_Events_Generatorspare : process
    begin
        FIFO_OUT_dout_spare <= X"00000000";             -- Magic debug value
        while True loop
            wait until rising_edge(FIFO_OUT_rd_en_spare(4));
            FIFO_OUT_dout_spare <= std_logic_vector(unsigned(FIFO_OUT_dout_spare) + X"0_0001");
        end loop;
    end process p_Events_Generatorspare;		
		
	GENERATE_SDO_spare : for I in 8 to 9 generate
		OBUFDS_sdo : OBUFDS
		generic map (
		  IOSTANDARD => "LVDS_25")
		port map (
		  O 	=> i_ADC_SDO_p(I),    -- Diff_p output (connect directly to top-level port)
		  OB 	=> i_ADC_SDO_n(I),   	-- Diff_n output (connect directly to top-level port)
		  I 	=> i_ADC_SDO_buf(i)   	-- Buffer input 
		);
		end generate GENERATE_SDO_spare;		


	GENERATE_CLK_spare : for I in 4 to 4 generate
		IBUFDS_clk : IBUFDS
		generic map (
		  IOSTANDARD => "LVDS_25")
		port map (
		  I 	=>	o_ADC_SCK_p(I),     	-- Diff_p output (connect directly to top-level port)
		  IB 	=>	o_ADC_SCK_n(I),   	-- Diff_n output (connect directly to top-level port)
		  O 	=>  o_ADC_SCK_buff(I)     -- Buffer input 
		);
		end generate GENERATE_CLK_spare;			
			
		--	dispatch
		

DU_ADC_SCK(4) <= o_ADC_SCK_buff(4);


DU_ADC_CNV_n(4) <= o_ADC_CNV_n(4);


i_ADC_SDO_buf(8) <=	DU_Front_ADC_SDO_Delayed(4);
i_ADC_SDO_buf(9) <= DU_Back_ADC_SDO_Delayed(4);
		
    -- Transport delay in the LVDS buffers and routes
    DU_ADC_CNV_n_Delayed(4)     <= transport DU_ADC_CNV_n(4) after C_Input_DelayLine_spare;
    DU_ADC_SCK_Delayed(4)       <= transport DU_ADC_SCK(4) after C_Input_DelayLine_spare;
    DU_Front_ADC_SDO_Delayed(4) <= transport DU_Front_ADC_SDO(4) after C_Output_DelayLine_spare;
    DU_Back_ADC_SDO_Delayed(4)  <= transport DU_Back_ADC_SDO(4) after C_Output_DelayLine_spare;

    gen_ADCLTC2311_Emulators_Parallel_spare : for i in 4 to 4 generate
        inst_ADCLTC2311_Emulators_spare : entity work.ADCLTC2311_Emulators
            port map(
                i_Rst_n         => TB_Reset_n,
                i_FIFO_empty    => '0',
                o_FIFO_rd_en    => FIFO_OUT_rd_en_spare(i),
                i_FIFO_dout     => FIFO_OUT_dout_spare,
                i_ADC_SCK       => DU_ADC_SCK_Delayed(i),
                i_ADC_CNV_n     => DU_ADC_CNV_n_Delayed(i),
                o_Front_ADC_SDO => DU_Front_ADC_SDO(i),
                o_Back_ADC_SDO  => DU_Back_ADC_SDO(i)
            );
    end generate gen_ADCLTC2311_Emulators_Parallel_spare;	
	
	
	
	
end Behavioral;