library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.userlib.all;

package globals is
type mem is array ( 0 to 15) of std_logic_vector(111 downto 0); --nmask + controllo
type mem_NIM is array ( 0 to 7) of std_logic_vector(4 downto 0);

type signed16bit_t is array(NATURAL RANGE <>) of signed(15 downto 0);
type signed12bit_t is array(NATURAL RANGE <>) of signed(11 downto 0);

type vector8bit_t is array(NATURAL RANGE <>) of std_logic_vector(7 downto 0);
type vector16bit_t is array(NATURAL RANGE <>) of std_logic_vector(15 downto 0);
type vector17bit_t is array(NATURAL RANGE <>) of std_logic_vector(16 downto 0);
type vector24bit_t is array(NATURAL RANGE <>) of std_logic_vector(23 downto 0);
type vector32bit_t is array(NATURAL RANGE <>) of std_logic_vector(31 downto 0);
type vector42bit_t is array(NATURAL RANGE <>) of std_logic_vector(41 downto 0);
type vector64bit_t is array(NATURAL RANGE <>) of std_logic_vector(63 downto 0);
type vector96bit_t is array(NATURAL RANGE <>) of std_logic_vector(95 downto 0);
type vector112bit_t is array(NATURAL RANGE <>) of std_logic_vector(111 downto 0);

type unsigned32bit_t is array(NATURAL RANGE <>) of unsigned(31 downto 0);
type unsigned16bit_t is array(NATURAL RANGE <>) of unsigned(15 downto 0);
type unsigned8bit_t is array(NATURAL RANGE <>) of unsigned(7 downto 0);

--NUMBER OF LINKS
constant ethlink_NODES : natural := 8;
constant nmask         : natural := 16;
constant NIM_NODES     : natural := 5;



--PARAMETERS FOR USB
constant par_init               : std_logic_vector(31 downto 0)    :=x"0FFFFFFF";
constant par_initdebug          : std_logic_vector(31 downto 0)    :=x"0FFFFFDB";

constant par_stop               : std_logic_vector(31 downto 0)    :=x"0FFFFFFF";

constant par_start   		: std_logic_vector(31 downto 0)    :=x"0FFFFFFE";
constant par_debugOn 		: std_logic_vector(31 downto 0)    :=x"0FFFFFFD";
constant par_debugOff		: std_logic_vector(31 downto 0)    :=x"0FFFFFFC";
constant par_activateClock20MHz : std_logic_vector(31 downto 0)    :=x"0FFFFFFB";


constant par_reset   		: std_logic_vector(31 downto 0)    :=x"0FFFFFF9";

constant par_setaddresspar     	: std_logic_vector(31 downto 0)    :=x"0FFFFFDE";
constant par_readparameter   	   : std_logic_vector(31 downto 0) :=x"0FFFFFDD";
constant par_setparameter     	: std_logic_vector(31 downto 0)    :=x"0FFFFFDC";

constant par_setaddressDebug    : std_logic_vector(31 downto 0)    :=x"0FFFFFDA";
constant par_readparameterDebug : std_logic_vector(31 downto 0)    :=x"0FFFFFD9";

constant par_readchokeon        : std_logic_vector(31 downto 0)    :=x"0FFFFFD8";
constant par_readchokeoff       : std_logic_vector(31 downto 0)    :=x"0FFFFFD7";
constant par_readerroron        : std_logic_vector(31 downto 0)    :=x"0FFFFFD6";
constant par_readerroroff       : std_logic_vector(31 downto 0)    :=x"0FFFFFD5";

constant par_activateFAKEchoke  : std_logic_vector(31 downto 0)     :=x"0FFFFFCF";
constant par_deactivateFAKEchoke: std_logic_vector(31 downto 0)     :=x"0FFFFFCE";

constant par_activateFAKEerror  : std_logic_vector(31 downto 0)     :=x"0FFFFFCD";
constant par_deactivateFAKEerror: std_logic_vector(31 downto 0)     :=x"0FFFFFCC";

constant par_activaterandomintensitytrigger    : std_logic_vector(31 downto 0)     :=x"0FFFFFCB";
constant par_deactivaterandomintensitytrigger  : std_logic_vector(31 downto 0)     :=x"0FFFFFCA";



--0
constant par_activateCHOKE                : std_logic_vector (31 downto 0) := x"0FFFFFF6";
constant par_deactivateCHOKE              : std_logic_vector (31 downto 0) := x"0FFFFFF5";
--1
constant par_activateERROR                : std_logic_vector (31 downto 0):= x"0FFFFFF2";
constant par_deactivateERROR              : std_logic_vector (31 downto 0):= x"0FFFFFF1";
--2
constant par_activateSOBEOB               : std_logic_vector (31 downto 0) := x"0FFFFFF0";
constant par_deactivateSOBEOB             : std_logic_vector (31 downto 0) := x"0FFFFFE7";
--3
constant par_activaterandomtrigger        : std_logic_vector (31 downto 0) := x"0FFFFFE6";
constant par_deactivaterandomtrigger      : std_logic_vector (31 downto 0) := x"0FFFFFE3";
--4
constant par_activatecalibtrigger         : std_logic_vector (31 downto 0) := x"0FFFFFE2";
constant par_deactivatecalibtrigger       : std_logic_vector (31 downto 0) := x"0FFFFFE1";
--5
constant par_activateNIMCalib             : std_logic_vector (31 downto 0) := x"0FFFFFE0";
constant par_deactivateNIMCalib           : std_logic_vector (31 downto 0) := x"0FFFFFDF";
--6
constant par_activateperiodictrigger0     : std_logic_vector(31 downto 0)  :=x"0FFFFFF4";
constant par_deactivateperiodictrigger0   : std_logic_vector(31 downto 0)  :=x"0FFFFFF3";
--7
constant par_activateperiodictrigger1     : std_logic_vector(31 downto 0)  :=x"0FFFFFD4";
constant par_deactivateperiodictrigger1   : std_logic_vector(31 downto 0)  :=x"0FFFFFD3";

constant par_activatecontroltrigger       : std_logic_vector(31 downto 0)  :=x"0FFFFFD2";
constant par_deactivatecontroltrigger     : std_logic_vector(31 downto 0)  :=x"0FFFFFD1";

--8
constant par_activatesynchtrigger         : std_logic_vector(31 downto 0)  :=x"0FFFFFED";
constant par_deactivatesynchtrigger       : std_logic_vector(31 downto 0)  :=x"0FFFFFEC";
--9
constant par_activate_primitives          : std_logic_vector(31 downto 0)  :=x"0FFFFFEA";
constant par_deactivate_primitives        : std_logic_vector(31 downto 0)  :=x"0FFFFFE8";
--a
constant par_activate_output_primitives   : std_logic_vector(31 downto 0)  :=x"0FFFFFE5";
constant par_deactivate_output_primitives : std_logic_vector(31 downto 0)  :=x"0FFFFFE4";


end globals;

