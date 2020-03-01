library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_uart is
	port(	rst	:	in std_logic;
			clk	:	in std_logic;
			sda	:	inout std_logic;
			scl	:	inout std_logic;
			empty :	out std_logic;
			full	:	out std_logic;
			state_led : out std_logic_vector(3 downto 0)
			);
end i2c_uart;

architecture portlink of i2c_uart is

component i2c_slave is
	generic(
		i2c_address	:	std_logic_vector(7 downto 0) := x"24"
	);
	port(	
		rst		:	in std_logic;
		clk		:	in std_logic;
		scl_in	: 	in std_logic;
		sda_in	:	in std_logic;
		scl_out	:	out std_logic;
		sda_out	:	out std_logic;
		data_to_fifo : out std_logic_vector(7 downto 0);
		data_from_fifo : in std_logic_vector(7 downto 0);
		write_fifo_en : out std_logic;
		read_fifo_en : out std_logic;
		out_fifo_full : in std_logic;
		out_fifo_empty : in std_logic;
		in_fifo_empty : in std_logic;
		reset_in_fifo : out std_logic;
		state_led : out std_logic_vector(3 downto 0)
	);
end component;

component std_fifo is
	generic(	
		constant data_width : positive := 8;
		constant fifo_depth : positive := 256
	);
	port(	
		clk		: in 	std_logic;
		rst		: in 	std_logic;
		write_en	: in 	std_logic;
		data_in	: in 	std_logic_vector(data_width - 1 downto 0);
		read_en	: in 	std_logic;
		data_out	: out	std_logic_vector(data_width - 1 downto 0);
		empty		: out std_logic;
		full		: out std_logic
	);
end component;

signal scl_in : std_logic;
signal sda_in : std_logic;
signal scl_out : std_logic;
signal sda_out : std_logic;

signal f2_rst : std_logic;
signal i2c_to_f2_rst : std_logic;

signal f1_data_in : std_logic_vector(7 downto 0);
signal f1_data_out : std_logic_vector(7 downto 0);

signal f2_data_in : std_logic_vector(7 downto 0);
signal f2_data_out : std_logic_vector(7 downto 0);

signal f1_write_en : std_logic;
signal f1_read_en : std_logic;

signal f2_write_en : std_logic;
signal f2_read_en : std_logic;

signal f1_empty : std_logic;
signal f1_full : std_logic;
signal f2_empty : std_logic;
signal f2_full : std_logic;

begin

	F1:std_fifo
			generic map(data_width => 8,
							fifo_depth => 128)
			port map(	clk => clk,
							rst => rst,
							write_en => f1_write_en,
							data_in => f1_data_in,
							read_en => f1_read_en,
							data_out => f1_data_out,
							empty => f1_empty,
							full => f1_full
							);
	
	F2:std_fifo
			generic map(data_width => 8,
							fifo_depth => 512)
			port map(	clk => clk,
							rst => f2_rst,
							write_en => f2_write_en,
							data_in => f2_data_in,
							read_en => f2_read_en,
							data_out => f2_data_out,
							empty => f2_empty,
							full => f2_full
							);
	
	SLAVE_CTL:i2c_slave
			generic map(i2c_address => x"24") 
			port map(	rst => rst,
							clk => clk,
							scl_in => scl_in,
							sda_in => sda_in,
							scl_out => scl_out,
							sda_out => sda_out,
							data_to_fifo => f1_data_in,
							data_from_fifo => f2_data_out,
							write_fifo_en => f1_write_en,
							read_fifo_en => f2_read_en,
							out_fifo_full => f1_full,
							out_fifo_empty => f1_empty,
							in_fifo_empty => f2_empty,
							reset_in_fifo => i2c_to_f2_rst,
							state_led => state_led
							);
		
	full <= f1_full;
	empty <= f1_empty;
	f2_rst <= rst or i2c_to_f2_rst;
	scl_in 	<= '0' when scl = '0' 		else '1';
	sda_in 	<= '0' when sda = '0' 		else '1';
	scl 		<= '0' when scl_out = '0' 	else 'Z';
	sda 		<= '0' when sda_out = '0' 	else 'Z';

end portlink;