LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD_UNSIGNED.ALL;

ENTITY PLL IS
    GENERIC(PHSE : INTEGER := 32;
            TRACK : STD_LOGIC := '1';
            MSB : INTEGER := PHSE - 1;
            INITIAL : STD_LOGIC_VECTOR (MSB DOWNTO 0) := (OTHERS => '0');
            GLITCH : STD_LOGIC := '1'
           );
    PORT(iclk, ld, ce, input : IN STD_LOGIC;
         lgcoeff : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
         step : IN STD_LOGIC_VECTOR (MSB - 1 DOWNTO 0);
         oclk : OUT STD_LOGIC;
         phase : OUT STD_LOGIC_VECTOR (PHSE DOWNTO 0);
         err : OUT STD_LOGIC_VECTOR (1 DOWNTO 0) := "00"
        );
END ENTITY;

ARCHITECTURE behavior OF PLL IS
CONSTANT corr : STD_LOGIC_VECTOR (MSB - 1 DOWNTO 0) := '1' & (OTHERS => '0');
CONSTANT freq : STD_LOGIC_VECTOR (MSB - 3 DOWNTO 0) := (OTHERS => '0');

SIGNAL agree : STD_LOGIC := '0';
SIGNAL lead, perr : STD_LOGIC;
SIGNAL ctr, fcorr, rstep : STD_LOGIC_VECTOR (MSB DOWNTO 0);
SIGNAL pcorr : STD_LOGIC_VECTOR (MSB DOWNTO 0) := (OTHERS => '0');

SIGNAL inter : STD_LOGIC_VECTOR (1 DOWNTO 0);

BEGIN
    perr <= '1' WHEN ctr(MSB) /= input ELSE '0';
    phase <= ctr;

    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(iclk) THEN
            IF ce THEN
                IF input AND ctr(MSB) THEN
                    agree <= '1';
                ELSIF NOT input AND NOT ctr(MSB) THEN
                    agree <= '0';
                END IF;
            END IF;
        END IF;
    END PROCESS;

    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(iclk) THEN
            IF agree THEN
                lead <= NOT ctr(MSB) AND input;
            ELSE
                lead <= ctr(MSB) AND NOT input;
            END IF;
        END IF;
    END PROCESS;

    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(iclk) THEN
            pcorr <= corr SLR lgcoeff;
        END IF;
    END PROCESS;

    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(iclk) THEN
            IF ce THEN
                IF NOT perr THEN
                    ctr <= ctr + rstep;
                ELSIF lead THEN
                    IF NOT GLITCH OR rstep > pcorr THEN
                        ctr <= ctr + rstep - pcorr;
                    END IF;
                ELSE
                    ctr <= ctr + rstep + pcorr;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(iclk) THEN
            fcorr <= ("001" & freq) SLR 2 * lgcoeff;
        END IF;
    END PROCESS;

    PROCESS(ALL)
    BEGIN
        IF ld THEN
            rstep <= '0' & step;
        ELSIF ce AND TRACK AND perr THEN
            IF lead THEN
                rstep <= rstep - fcorr;
            ELSE
                rstep <= rstep + fcorr;
            END IF;
        END IF;
    END PROCESS;

    PROCESS(ALL)
    BEGIN
        IF ce THEN
            inter <= "11" WHEN lead ELSE "01";
            err <= NOT perr WHEN "00" ELSE inter;
        END IF;
    END PROCESS;
END ARCHITECTURE;