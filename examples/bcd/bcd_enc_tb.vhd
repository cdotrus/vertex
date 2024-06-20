library ieee;
use ieee.std_logic_1164.all;

library std;
use std.textio.all;

library amp;
use amp.prelude.all;

library vertex;
use vertex.test.all;

entity bcd_enc_tb is
    generic (
        LEN: positive := 4;
        DIGITS: positive := 2
    );
end entity;

architecture sim of bcd_enc_tb is

    -- This record is auto-generated by vertex. DO NOT EDIT.
    type bcd_enc_bfm is record
        go: logic;
        bin: logics(LEN-1 downto 0);
        bcd: logics((4*DIGITS)-1 downto 0);
        ovfl: logic;
        done: logic;
    end record;

    signal bfm: bcd_enc_bfm;

    signal clk: logic := '0';
    signal rst: logic := '0';
    signal halt: boolean := false;

    --! declare internal required testbench signals
    constant TIMEOUT_LIMIT: natural := 100;

    file events: text open write_mode is "events.log";

begin

    -- instantiate UUT
    UUT: entity work.bcd_enc
    generic map (
        LEN   => LEN,
        DIGITS => DIGITS
    ) port map (
        rst   => rst,
        clk   => clk,
        go    => bfm.go,
        bin   => bfm.bin,
        bcd   => bfm.bcd,
        done  => bfm.done,
        ovfl  => bfm.ovfl
    );

    --! generate a 50% duty cycle for 25 Mhz
    spin_clock(clk, 40 ns, halt);

    --! test reading a file filled with test vectors
    producer: process
        file inputs: text open read_mode is "inputs.txt";

        -- This procedure is auto-generated by vertex. DO NOT EDIT.
        procedure send(file fd: text) is 
            variable row: line;
        begin
            if endfile(fd) = false then
                -- drive a transaction
                readline(fd, row);
                drive(row, bfm.go);
                -- capture(events, TRACE, "DRIVE", "go", "was sent a value");
                drive(row, bfm.bin);
                -- capture(events, TRACE, "DRIVE", "bin", "was sent a value");
            end if;
        end procedure; 

    begin  
        -- initialize input signals      
        send(inputs);
        trigger_sync(clk, rst, '1', 3);
        wait until rising_edge(clk);
        
        -- drive transactions
        while endfile(inputs) = false loop
            send(inputs);
            wait until rising_edge(clk);
        end loop;

        -- wait for all outputs to be checked
        wait;
    end process;

    consumer: process
        file outputs: text open read_mode is "outputs.txt";
        variable timeout: bool;

        procedure compare(file fd: text) is
            variable row: line;
            variable expct: bcd_enc_bfm;
        begin
            if endfile(fd) = false then
                -- compare received outputs with expected outputs
                readline(fd, row);
                load(row, expct.bcd);
                assert_eq(events, bfm.bcd, expct.bcd, "bcd");
                load(row, expct.done);
                assert_eq(events, bfm.done, expct.done, "done");
                load(row, expct.ovfl);
                assert_eq(events, bfm.ovfl, expct.ovfl, "ovfl");
            end if;
        end procedure;
        
    begin
        monitor(events, clk, rst, '1', TIMEOUT_LIMIT, "rst");
        monitor(events, clk, rst, '0', TIMEOUT_LIMIT, "rst");

        while endfile(outputs) = false loop
            -- @note: should monitor detect rising edge or when = '1'? ... when = '1' will delay by a cycle, which could not be the intention
            -- @todo: have better handling of monitor process (WIP, might be good now)

            -- wait for a valid time to check
            monitor(events, clk, bfm.done, '1', TIMEOUT_LIMIT, "done");

            -- compare outputs
            compare(outputs);
            -- wait for done to be lowered before starting monitor
            wait until falling_edge(bfm.done);
        end loop;

        -- halt the simulation
       complete(halt);
    end process;

    -- concurrent captures of simulation
    stabilize(events, clk, bfm.bcd, bfm.done, '1', "done's dependency bcd");
    stabilize(events, clk, bfm.ovfl, bfm.done, '1', "done's dependency ovfl");

end architecture;