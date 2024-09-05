import godan::*;

// This interface is automatically @generated by Verb.
// It is not intended for manual editing.
interface bcd_enc_bfm #(
    parameter int LEN,
    parameter int DIGITS
);
    logic go;
    logic[LEN-1:0] bin;
    logic[(4*DIGITS)-1:0] bcd;
    logic done;
    logic ovfl;
endinterface

module bcd_enc_tb #(
    parameter int LEN = 4,
    parameter int DIGITS = 2
);

    // instantiate the set of signals to communicate with the hw dut
    bcd_enc_bfm #(
        .LEN(LEN),
        .DIGITS(DIGITS)
    ) bfm();
    
    // instantiate the set of signals to communicate with the sw model
    bcd_enc_bfm #(
        .LEN(LEN),
        .DIGITS(DIGITS)
    ) mdl();

    int events = $fopen("events.log", "w");
    
    // instantiate the device under test
    bcd_enc #(
        .LEN(LEN),
        .DIGITS(DIGITS)
    ) dut (
        .rst(rst),
        .clk(clk),
        .go(bfm.go),
        .bin(bfm.bin),
        .bcd(bfm.bcd),
        .done(bfm.done),
        .ovfl(bfm.ovfl)
    );

    logic clk = 1'b0;
    logic rst = 1'b0;
    logic halt = 1'b0;

    time period = 40ns;
    localparam int TIMEOUT_LIMIT = 100;

    // generate a clock with 50% duty cycle
    `spin_clock(clk, period, halt);

    // drive incoming transactions
    always begin: producer 
        int inputs = $fopen("inputs.txt", "r");

        // send initial inputs and perform power-on reset
        send(inputs);
        `trigger_sync(clk, rst, 1'b1, 3);

        while(!$feof(inputs)) begin
            send(inputs);
            @(negedge clk);
        end
        wait(0);
    end

    // check outgoing transactions for correctness
    always begin: consumer
        int outputs = $fopen("outputs.txt", "r");

        `monitor(events, clk, rst, 1'b1, TIMEOUT_LIMIT, "rst");
        `monitor(events, clk, rst, 1'b0, TIMEOUT_LIMIT, "rst");

        while(!$feof(outputs)) begin
            // wait for valid time to check
            `monitor(events, clk, bfm.done, 1'b1, TIMEOUT_LIMIT, "done");
            // compare outputs
            compare(events, outputs);
            // wait until falling edge of done signal to check for next outputs
            @(negedge bfm.done);
        end
        `complete(events, halt);
    end

    `stabilize(events, clk, bfm.bcd, bfm.done, 1'b1, "done's dependency bcd");
    `stabilize(events, clk, bfm.ovfl, bfm.done, 1'b1, "done's dependency ovfl");

    // This task is automatically @generated by Verb.
    // It is not intended for manual editing.
    task send(int i);
        automatic string row;
        if(!$feof(i)) begin
            $fgets(row, i);
            `drive(row, bfm.go);
            `drive(row, bfm.bin);
        end
    endtask

    // This task is automatically @generated by Verb.
    // It is not intended for manual editing.
    task compare(int e, int o);
        automatic string row;
        if(!$feof(o)) begin
            $fgets(row, o);
            `load(row, mdl.bcd);
            `assert_eq(e, bfm.bcd, mdl.bcd, "bcd");
            `load(row, mdl.done);
            `assert_eq(e, bfm.done, mdl.done, "done");
            `load(row, mdl.ovfl);
            `assert_eq(e, bfm.ovfl, mdl.ovfl, "ovfl");
        end
    endtask

endmodule