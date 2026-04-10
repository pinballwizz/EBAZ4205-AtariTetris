---------------------------------------------------------------------------------
--                           Tetris - EBAZ4205
--                           Code from MiSTer-X
--
--                          Modified for EBAZ4205 
--                            by pinballwiz.org 
--                               04/04/2026
---------------------------------------------------------------------------------
-- Keyboard inputs :
--   5 : Add coin
--   LEFT Ctrl   : Start 1 or 2 players and Rotate
--   RIGHT arrow : Move Right
--   LEFT arrow  : Move Left
--   DOWN arrow  : Move Down
--
--   Use Dipswitch to select arcade or vga monitor
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;
---------------------------------------------------------------------------------
entity tetris_ebaz4205 is
port(
	clock_50    : in std_logic;
   	I_RESET     : in std_logic;
	O_VIDEO_R	: out std_logic_vector(2 downto 0); 
	O_VIDEO_G	: out std_logic_vector(2 downto 0);
	O_VIDEO_B	: out std_logic_vector(1 downto 0);
	O_HSYNC		: out std_logic;
	O_VSYNC		: out std_logic;
	O_AUDIO_L 	: out std_logic;
	O_AUDIO_R 	: out std_logic;
	greenLED 	: out std_logic;
	redLED 	    : out std_logic;
   	ps2_clk     : in std_logic;
	ps2_dat     : inout std_logic;
	joy         : in std_logic_vector(8 downto 0);
	dipsw       : in std_logic_vector(4 downto 0);
	led         : out std_logic_vector(7 downto 0)
);
end tetris_ebaz4205;
------------------------------------------------------------------------------
architecture struct of tetris_ebaz4205 is
 
 signal	clock_24        : std_logic;
 signal	clock_14p3      : std_logic;
 signal	clock_18        : std_logic;
 signal	clock_9         : std_logic;
 --
 signal video_i         : std_logic_vector(15 downto 0);
 signal video_o         : std_logic_vector(15 downto 0);
 signal dblscan         : std_logic;
 signal oRGB            : std_logic_vector(7 downto 0);
 signal hblank          : std_logic;
 signal vblank	        : std_logic;
 signal pclk	        : std_logic;
 signal h_sync          : std_logic;
 signal v_sync	        : std_logic;
 signal h_sync_o        : std_logic;
 signal v_sync_o        : std_logic;
 signal hpos            : std_logic_vector(8 downto 0);
 signal vpos            : std_logic_vector(8 downto 0);
 signal pout            : std_logic_vector(7 downto 0);
 --
 signal audio           : std_logic_vector(15 downto 0);
 signal audio_pwm       : std_logic;
 --
 signal INP             : std_logic_vector(10 downto 0);
 --
 signal reset           : std_logic;
 --
 signal SW_LEFT         : std_logic;
 signal SW_RIGHT        : std_logic;
 signal SW_UP           : std_logic;
 signal SW_DOWN         : std_logic;
 signal SW_FIRE         : std_logic;
 signal SW_BOMB         : std_logic;
 signal SW_COIN         : std_logic;
 signal P1_START        : std_logic;
 signal P2_START        : std_logic;
 --
 signal kbd_intr        : std_logic;
 signal kbd_scancode    : std_logic_vector(7 downto 0);
 signal joy_BBBBFRLDU   : std_logic_vector(9 downto 0);
 --
 constant CLOCK_FREQ    : integer := 27E6;
 signal counter_clk     : std_logic_vector(25 downto 0);
 signal clock_4hz       : std_logic;
 signal AD              : std_logic_vector(15 downto 0);
---------------------------------------------------------------------------
component tetris_clocks
port(
  clk_out1          : out    std_logic;
  clk_out2          : out    std_logic;
  clk_out3          : out    std_logic;
  clk_in1           : in     std_logic
 );
end component;
---------------------------------------------------------------------------
begin

reset       <= not I_RESET; -- reset active = '1'  
greenLED    <= '1'; -- turn off leds
redLED      <= '1';
dblscan     <= dipsw(4); -- set dipswitch for arcade or vga video output
---------------------------------------------------------------------------
Clocks: tetris_clocks
    port map (
        clk_in1   => clock_50,
        clk_out1  => clock_24,
        clk_out2  => clock_18,
	    clk_out3  => clock_14p3
    );
---------------------------------------------------------------------------
-- Clock Divide

process (clock_18)
begin
 if rising_edge(clock_18) then
	clock_9  <= not clock_9;
 end if;
end process;
---------------------------------------------------------------------------
-- Inputs

SW_LEFT    <= joy_BBBBFRLDU(2) when dipsw(0) = '0' else not joy(0);
SW_RIGHT   <= joy_BBBBFRLDU(3) when dipsw(0) = '0' else not joy(1);
SW_UP      <= joy_BBBBFRLDU(0) when dipsw(0) = '0' else not joy(2);
SW_DOWN    <= joy_BBBBFRLDU(1) when dipsw(0) = '0' else not joy(3);
SW_FIRE    <= joy_BBBBFRLDU(4) when dipsw(0) = '0' else not joy(4);
SW_BOMB    <= joy_BBBBFRLDU(8) when dipsw(0) = '0' else not joy(5);
SW_COIN    <= joy_BBBBFRLDU(7) when dipsw(0) = '0' else not joy(6);
P1_START   <= joy_BBBBFRLDU(5) when dipsw(0) = '0' else not joy(7);
P2_START   <= joy_BBBBFRLDU(6) when dipsw(0) = '0' else not joy(8);

INP <= "11" & not SW_COIN & not SW_LEFT & not SW_RIGHT & not SW_DOWN & not SW_FIRE & not SW_LEFT & not SW_RIGHT & not SW_DOWN & not SW_FIRE;
---------------------------------------------------------------------------
-- Main

pm : entity work.FPGA_ATETRIS
port map (
RESET => reset,
MCLK  => clock_14p3,
HPOS  => hpos,
VPOS  => vpos,
PCLK  => pclk,
POUT  => pout,
AOUT  => audio,
INP   => INP,
AD    => AD
);
----------------------------------------------------------------------------
-- Sync

HVGEN : entity work.hvgen
port map(
	HPOS => hpos,
	VPOS => vpos,
	PCLK => pclk,
	iRGB => pout,
	oRGB => oRGB,
	HBLK => hblank,
	VBLK => vblank,
	HSYN => h_sync,
	VSYN => v_sync,
	HOFFS => "000000111"
);
-----------------------------------------------------------------
video_i <= oRGB & oRGB;
-----------------------------------------------------------------
-- scan doubler

vga_scandbl : entity work.vga_scandbl
	port map (
		CLK       => pclk,
		CLK_X2	  => clock_14p3,
		I_HSYNC	  => h_sync,
		I_VSYNC	  => v_sync,
		O_HSYNC	  => h_sync_o,
		O_VSYNC	  => v_sync_o,
		I_VIDEO	  => video_i,
		O_VIDEO	  => video_o
	);
------------------------------------------------------------------------------
-- vga output

 O_VIDEO_R  <= oRGB(7 downto 5) when dblscan = '0' else video_o(7 downto 5);
 O_VIDEO_G  <= oRGB(4 downto 2) when dblscan = '0' else video_o(4 downto 2);
 O_VIDEO_B  <= oRGB(1 downto 0) when dblscan = '0' else video_o(1 downto 0);
 O_HSYNC    <= h_sync when dblscan = '0' else h_sync_o;
 O_VSYNC    <= v_sync when dblscan = '0' else v_sync_o;
------------------------------------------------------------------------------
-- get scancode from keyboard

keyboard : entity work.io_ps2_keyboard
port map (
  clk       => clock_9,
  kbd_clk   => ps2_clk,
  kbd_dat   => ps2_dat,
  interrupt => kbd_intr,
  scancode  => kbd_scancode
);
------------------------------------------------------------------------------
-- translate scancode to joystick

joystick : entity work.kbd_joystick
port map (
  clk           => clock_9,
  kbdint        => kbd_intr,
  kbdscancode   => std_logic_vector(kbd_scancode), 
  joy_BBBBFRLDU => joy_BBBBFRLDU 
);
------------------------------------------------------------------------------
-- dac

    dac : entity work.dac
    generic map(
      msbi_g  => 15
    )
    port  map(
      clk_i   => clock_18,
      res_n_i => I_RESET,
      dac_i   => audio,
      dac_o   => audio_pwm
    );

    O_AUDIO_L <= audio_pwm;
    O_AUDIO_R <= audio_pwm;
-------------------------------------------------------------------------------
-- debug

process(reset, clock_24)
begin
  if reset = '1' then
   clock_4hz <= '0';
   counter_clk <= (others => '0');
  else
    if rising_edge(clock_24) then
      if counter_clk = CLOCK_FREQ/8 then
        counter_clk <= (others => '0');
        clock_4hz <= not clock_4hz;
        led(7 downto 0) <= not AD(11 downto 4);
      else
        counter_clk <= counter_clk + 1;
      end if;
    end if;
  end if;
end process;	
-------------------------------------------------------------------------------
end struct;