library ieee;
use ieee.std_logic_1164.all;
library std;
use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.amba.all;
use grlib.stdlib.all;
library techmap;
use techmap.gencomp.all;
library gaisler;
use gaisler.libiu.all;
use gaisler.libcache.all;
use gaisler.leon3.all;
library work;
use work.config.all;
use work.util_tb.all;

entity regfile_3p_tb is
  constant CLK_HPERIOD : time := 10 ps;
  constant STRING_SIZE : integer := 128; -- string size = index of the last element
  constant CFG_IRFBITS  : integer range 6 to 10 := log2(CFG_NWIN+1) + 4;
  constant CFG_IREGNUM  : integer := CFG_NWIN * 16 + 8;
  constant CFG_IRFWT     : integer := 1;--regfile_3p_write_through(memtech);

end regfile_3p_tb;
architecture behavior of regfile_3p_tb is

  -- input/output signals:
  signal inNRst       : std_logic:= '0';
  signal inClk        : std_logic:= '0';
  signal in_waddr  : std_logic_vector(7 downto 0);
  signal in_wdata  : std_logic_vector(31 downto 0);
  signal in_we  : std_logic;
  signal in_raddr1  : std_logic_vector(7 downto 0);
  signal in_re1  : std_logic;
  signal in_raddr2  : std_logic_vector(7 downto 0);
  signal in_re2  : std_logic;
  signal in_testin  : std_logic_vector(3 downto 0);
  signal ch_rdata1  : std_logic_vector(31 downto 0);
  signal rdata1  : std_logic_vector(31 downto 0);
  signal ch_rdata2  : std_logic_vector(31 downto 0);
  signal rdata2  : std_logic_vector(31 downto 0);

  
  signal U: std_ulogic_vector(STRING_SIZE-1 downto 0);
  signal S: std_logic_vector(STRING_SIZE-1 downto 0);
  shared variable iClkCnt : integer := 0;

begin

  -- Process of clock generation
  procClkgen : process
  begin
      inClk <= '0' after CLK_HPERIOD, '1' after 2*CLK_HPERIOD;
      wait for 2*CLK_HPERIOD;
  end process procClkgen;

  -- Process of reading  
  procReadingFile : process
    file InputFile:TEXT is "e:/regfile_3p_tb.txt";
    variable rdLine: line;  
    variable strLine : string(STRING_SIZE downto 1);
  begin
    while not endfile(InputFile) loop
      readline(InputFile, rdLine);
      read(rdLine, strLine);
      U <= StringToUVector(strLine);
      S <= StringToSVector(strLine);
  
      wait until rising_edge(inClk);
      --wait until falling_edge(inClk);
      iClkCnt := iClkCnt + 1;
      if(iClkCnt=3) then
        print("break");
      end if;
    end loop;
  end process procReadingFile;

  
  -- Input signals:
  inNRst <= S(0);
  in_waddr <= S(8 downto 1);
  in_wdata <= S(40 downto 9);
  in_we <= S(41);
  in_raddr1 <= S(49 downto 42);
  in_re1 <= S(50);
  in_raddr2 <= S(58 downto 51);
  in_re2 <= S(59);
  in_testin <= S(63 downto 60);
  ch_rdata1 <= S(95 downto 64);
  ch_rdata2 <= S(127 downto 96);



  tt : regfile_3p generic map
  (
    inferred,--tech      : integer range 0 to NTECH := 0;
	  CFG_IRFBITS,--abits : integer := 6; 
	  32,--dbits : integer := 8;
  	 CFG_IRFWT,--wrfst : integer := 0;
	  CFG_IREGNUM,--numregs : integer := 64;
    0--testen    : integer range 0 to 3 := 0
  )port map 
  (
    inClk,
    in_waddr,
    in_wdata,
    in_we,
    inClk,
    in_raddr1,
    in_re1,
    rdata1,
    in_raddr2,
    in_re2,
    rdata2,
    in_testin
  );


procCheck : process (inClk, ch_rdata1, ch_rdata2)
  variable iErrCnt : integer := 0;
begin
  if(rising_edge(inClk) and (iClkCnt>2)) then
    if(rdata1/="UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU") then
      if(ch_rdata1/=rdata1) then print("Err: rdata1"); iErrCnt:=iErrCnt+1;end if;
    end if;
    if(rdata2/="UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU") then
      if(ch_rdata2/=rdata2) then print("Err: rdata2"); iErrCnt:=iErrCnt+1;end if;
    end if;
  end if;
end process procCheck;

  
end;
