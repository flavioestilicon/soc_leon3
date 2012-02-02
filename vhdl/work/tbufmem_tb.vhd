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
use gaisler.leon3.all;
use gaisler.libiu.all;
library work;
use work.config.all;
use work.util_tb.all;

entity tbufmem_tb is
  constant CLK_HPERIOD : time := 10 ps;
  constant STRING_SIZE : integer := 278; -- string size = index of the last element

end tbufmem_tb;
architecture behavior of tbufmem_tb is

  -- input/output signals:
  signal inNRst       : std_logic:= '0';
  signal inClk        : std_logic:= '0';
  signal in_tbi : tracebuf_in_type;
  signal ch_tbo : tracebuf_out_type;
  signal tbo    : tracebuf_out_type;
  
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
    file InputFile:TEXT is "e:/tbufmem_tb.txt";
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
  in_tbi.addr <= S(12 downto 1);
  in_tbi.data(63 downto 0) <= S(76 downto 13);
  in_tbi.data(127 downto 64) <= S(140 downto 77);
  in_tbi.enable <= S(141);
  in_tbi.write <= S(145 downto 142);
  in_tbi.diag <= S(149 downto 146);
  ch_tbo.data <= S(277 downto 150);



  tt : tbufmem generic map
  (
    inferred,--tech      : integer range 0 to NTECH := 0;
    CFG_ITBSZ,
    0--testen    : integer range 0 to 3 := 0
  )port map 
  (
    inClk,
    in_tbi,
    tbo
  );


procCheck : process (inClk, ch_tbo)
  variable iErrCnt : integer := 0;
  variable iChkCnt1 : integer := 0;
  variable iChkCnt2 : integer := 0;
  variable iChkCnt3 : integer := 0;
begin
  if(rising_edge(inClk) and (iClkCnt>2)) then
    if(((tbo.data(127)='U')or(tbo.data(95)='U')) and ((tbo.data(63)/='U')and(tbo.data(31)/='U')) )then
      iChkCnt1 := iChkCnt1+1;
      if(ch_tbo.data(63 downto 0)/=tbo.data(63 downto 0)) then print("Err: tbo.data(63 downto 0)"); iErrCnt:=iErrCnt+1;end if;
    elsif(((tbo.data(127)/='U')and(tbo.data(95)/='U')) and ((tbo.data(63)='U')or(tbo.data(31)='U')) )then
      iChkCnt2 := iChkCnt2+1;
      if(ch_tbo.data(127 downto 64)/=tbo.data(127 downto 64)) then print("Err: tbo.data(127 downto 64)"); iErrCnt:=iErrCnt+1;end if;
    elsif((tbo.data(127)/='U') and (tbo.data(95)/='U') and (tbo.data(63)/='U') and (tbo.data(31)/='U') )then
      iChkCnt3 := iChkCnt3+1;
      if(ch_tbo.data/=tbo.data) then print("Err: tbo.data"); iErrCnt:=iErrCnt+1;end if;
    end if;
  end if;
end process procCheck;

  
end;
