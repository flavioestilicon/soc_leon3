library ieee;
use ieee.std_logic_1164.all;
library std;
use std.textio.all;
library grlib;
use grlib.amba.all;
use grlib.stdlib.all;
use grlib.devices.all;
library techmap;
use techmap.gencomp.all;
library gaisler;
use gaisler.misc.all;
use gaisler.libjtagcom.all;
use gaisler.jtag.all;
library work;
use work.config.all;
use work.util_tb.all;



entity jtagcom_tb is

  constant CLK_HPERIOD : time := 10 ps;
  constant STRING_SIZE : integer := 218; -- string size = index of the last element

  constant REREAD : integer := 1;
  constant TAPSEL   : integer := has_tapsel(CFG_FABTECH);

end jtagcom_tb;
architecture behavior of jtagcom_tb is


  -- input/output signals:
  signal inNRst       : std_logic:= '0';
  signal inClk        : std_logic:= '0';

  signal in_tapo      : tap_out_type;
  signal ch_tapi      : tap_in_type;
  signal tapi         : tap_in_type;
  signal in_dmao      : ahb_dma_out_type;    
  signal dmai         : ahb_dma_in_type;
  signal ch_dmai      : ahb_dma_in_type;
  signal t_r_state    : std_logic_vector(1 downto 0);
  
  signal S: std_logic_vector(STRING_SIZE-1 downto 0);
  signal U: std_ulogic_vector(STRING_SIZE-1 downto 0);
  shared variable iClkCnt : integer := 0;
  shared variable iErrCnt : integer := 0;
  
  type state_type is (shft, ahb, nxt_shft);  
  type reg_type is record
    addr  : std_logic_vector(34 downto 0);
    data  : std_logic_vector(32 downto 0);
    state : state_type;
    tck   : std_logic_vector(1 downto 0);
    tck2  : std_ulogic;    
    trst  : std_logic_vector(1 downto 0);
    tdi   : std_logic_vector(1 downto 0);
    shift : std_logic_vector(1 downto 0);
    shift2: std_ulogic;
    upd   : std_logic_vector(1 downto 0);
    upd2  : std_ulogic;
    asel  : std_logic_vector(1 downto 0);
    dsel  : std_logic_vector(1 downto 0);
    tdi2  : std_ulogic;
    seq   : std_ulogic;
    holdn : std_ulogic;
  end record;

  signal t_r : reg_type;

begin


  -- Process of clock generation
  procClkgen : process
  begin
      inClk <= '0' after CLK_HPERIOD, '1' after 2*CLK_HPERIOD;
      wait for 2*CLK_HPERIOD;
  end process procClkgen;

  -- Process of reading  
  procReadingFile : process
    file InputFile:TEXT is "e:/jtagcom_tb.txt";--open read_mode file_name;
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
    end loop;
  end process procReadingFile;
  


-- signal parsment and assignment
  inNRst <= S(0);
  in_tapo.tck <= S(1);
  in_tapo.tdi <= S(2);
  in_tapo.asel <= S(3);
  in_tapo.dsel <= S(4);
  in_tapo.reset <= S(5);
  in_tapo.shift <= S(6);
  in_tapo.upd <= S(7);
  in_dmao.start <= S(8);
  in_dmao.active <= S(9);
  in_dmao.ready <= S(10);
  in_dmao.retry <= S(11);
  in_dmao.mexc <= S(12);
  in_dmao.haddr <= S(22 downto 13);
  in_dmao.rdata <= S(54 downto 23);
  ch_tapi.tdo <= S(55);
  ch_dmai.address <= S(87 downto 56);
  ch_dmai.wdata <= S(119 downto 88);
  ch_dmai.start <= S(120);
  ch_dmai.burst <= S(121);
  ch_dmai.write <= S(122);
  ch_dmai.busy <= S(123);
  ch_dmai.irq <= S(124);
  ch_dmai.size <= S(127 downto 125);
  t_r.asel(1) <= S(128);
  t_r.asel(0) <= S(129);
  t_r.dsel(1) <= S(130);
  t_r.dsel(0) <= S(131);
  t_r.shift(1) <= S(132);
  t_r.shift(0) <= S(133);
  t_r.shift2 <= S(134);
  t_r.tck(1) <= S(135);
  t_r.tck(0) <= S(136);
  t_r.tck2 <= S(137);
  t_r.tdi(1) <= S(138);
  t_r.tdi(0) <= S(139);
  t_r.tdi2 <= S(140);
  t_r.upd(1) <= S(141);
  t_r.upd(0) <= S(142);
  t_r.upd2 <= S(143);
  t_r.seq <= S(144);
  t_r.holdn <= S(145);
  t_r.trst(1) <= S(146);
  t_r.trst(0) <= S(147);
  t_r_state <= S(149 downto 148);
  t_r.addr <= S(184 downto 150);
  t_r.data <= S(217 downto 185);

  
  tt : jtagcom generic map 
  (
    isel => TAPSEL,
    nsync => 2,
    ainst => 2,
    dinst => 3,
    reread => REREAD
  )
  port map
  (
    inNRst,
    inClk,
    in_tapo,
    tapi,
    in_dmao,
    dmai
  );


procCheck : process (inNRst,inClk, ch_tapi, ch_dmai, t_r_state)
begin

  if(t_r_state="01")    then t_r.state <= ahb;
  elsif(t_r_state="10") then t_r.state <= nxt_shft;
  else                       t_r.state <= shft;
  end if;

  if(rising_edge(inClk) and (iClkCnt>2)) then
    if(dmai.address(0) /= 'U') then
      if(ch_dmai.address/=dmai.address) then print("Err: dmai.address");  iErrCnt:=iErrCnt+1; end if;
    end if;
    if(dmai.wdata(0) /= 'U') then
      if(ch_dmai.wdata/=dmai.wdata) then print("Err: dmai.wdata");  iErrCnt:=iErrCnt+1; end if;
    end if;
    if(ch_dmai.start/=dmai.start) then print("Err: dmai.start");  iErrCnt:=iErrCnt+1; end if;
    if(ch_dmai.burst/=dmai.burst) then print("Err: dmai.burst");  iErrCnt:=iErrCnt+1; end if;
    if(ch_dmai.write/=dmai.write) then print("Err: dmai.write");  iErrCnt:=iErrCnt+1; end if;
    if(ch_dmai.busy/=dmai.busy) then print("Err: dmai.busy");  iErrCnt:=iErrCnt+1; end if;
    if(ch_dmai.irq/=dmai.irq) then print("Err: dmai.irq");  iErrCnt:=iErrCnt+1; end if;
    if(ch_dmai.size/=dmai.size) then print("Err: dmai.size");  iErrCnt:=iErrCnt+1; end if;
    if(tapi.tdo /= 'U') then
      if(ch_tapi.tdo/=tapi.tdo) then print("Err: tapi.tdo");  iErrCnt:=iErrCnt+1; end if;
    end if;
  end if;
end process procCheck;


end;
 
 