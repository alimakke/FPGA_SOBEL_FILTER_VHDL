library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package image_pkg is

    type image_t is array (natural range <>, natural range <>)
        of std_logic_vector(7 downto 0);

end package image_pkg;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.image_pkg.all;


entity image_filter is
    generic ( N : integer := 64; M : integer := 64 );
    port (
        clk             : in  std_logic;
        pixel_in        : in  std_logic_vector(7 downto 0);
        pixel_in_valid  : in  std_logic;
        pixel_out       : out std_logic_vector(7 downto 0);
        pixel_out_valid : out std_logic
    );
end image_filter;

architecture Behavioral of image_filter is

    type line_buffer_t is array (0 to M-1) of std_logic_vector(7 downto 0);
    signal LB1 : line_buffer_t := (others => (others => '0'));  
    signal LB2 : line_buffer_t := (others => (others => '0'));  

    signal row : integer range 0 to N-1 := 0;
    signal col : integer range 0 to M-1 := 0;

    
    signal P1, P2, P3 : std_logic_vector(7 downto 0) := (others => '0');
    signal P4, P5, P6 : std_logic_vector(7 downto 0) := (others => '0');
    signal P7, P8, P9 : std_logic_vector(7 downto 0) := (others => '0');

    
    signal start_calculation : std_logic := '0';
    signal mask_left         : std_logic := '0';  
    signal mask_right        : std_logic := '0';  

    
    signal gx_reg   : signed(10 downto 0) := (others => '0');
    signal gy_reg   : signed(10 downto 0) := (others => '0');
    signal valid_s2 : std_logic := '0';

    
    signal pixel_out_r       : std_logic_vector(7 downto 0) := (others => '0');
    signal pixel_out_valid_r : std_logic := '0';

begin
    process(clk)
    begin
        if rising_edge(clk) then
            start_calculation <= '0';

            if pixel_in_valid = '1' then


                P1 <= P2;  P2 <= P3;  P3 <= LB2(col);  
                P4 <= P5;  P5 <= P6;  P6 <= LB1(col);  
                P7 <= P8;  P8 <= P9;  P9 <= pixel_in;   
                LB2(col) <= LB1(col);
                LB1(col) <= pixel_in;


                mask_right <= '0';
                mask_left  <= '0';
                if col = 0 then
                    mask_right <= '1';
                end if;
                if col = 1 then
                    mask_left <= '1';
                end if;


                if (row >= 2 and col >= 1) or (row >= 3 and col = 0) then
                    start_calculation <= '1';
                end if;


                if col = M-1 then
                    col <= 0;
                    if row = N-1 then
                        row <= 0;
                    else
                        row <= row + 1;
                    end if;
                else
                    col <= col + 1;
                end if;

            end if;
        end if;
    end process;



    process(clk)
        variable q1, q2, q3 : signed(10 downto 0);
        variable q4, q5, q6 : signed(10 downto 0);
        variable q7, q8, q9 : signed(10 downto 0);
    begin
        if rising_edge(clk) then
            valid_s2 <= start_calculation;

            if start_calculation = '1' then
                q1 := signed(resize(unsigned(P1), 11));
                q2 := signed(resize(unsigned(P2), 11));
                q3 := signed(resize(unsigned(P3), 11));
                q4 := signed(resize(unsigned(P4), 11));
                q5 := signed(resize(unsigned(P5), 11));
                q6 := signed(resize(unsigned(P6), 11));
                q7 := signed(resize(unsigned(P7), 11));
                q8 := signed(resize(unsigned(P8), 11));
                q9 := signed(resize(unsigned(P9), 11));

                if mask_left = '1' then
                    q1 := (others => '0');
                    q4 := (others => '0');
                    q7 := (others => '0');
                end if;
                if mask_right = '1' then
                    q3 := (others => '0');
                    q6 := (others => '0');
                    q9 := (others => '0');
                end if;

                gx_reg <= (q3 + shift_left(q6, 1) + q9)
                        - (q1 + shift_left(q4, 1) + q7);

                gy_reg <= (q7 + shift_left(q8, 1) + q9)
                        - (q1 + shift_left(q2, 1) + q3);
            end if;
        end if;
    end process;

 
    process(clk)
        variable ax, ay, s : unsigned(11 downto 0);
    begin
        if rising_edge(clk) then
            pixel_out_valid_r <= valid_s2;

            if valid_s2 = '1' then
                ax := unsigned(resize(abs(gx_reg), 12));
                ay := unsigned(resize(abs(gy_reg), 12));
                s  := ax + ay;
		s := shift_right(ax + ay, 2);   

                if s > 255 then
                    pixel_out_r <= (others => '1');
                else
                    pixel_out_r <= std_logic_vector(s(7 downto 0));
                end if;
            end if;
        end if;
    end process;

    pixel_out       <= pixel_out_r;
    pixel_out_valid <= pixel_out_valid_r;

end Behavioral;