//----------总线仲裁器----------//
// 0是最高优先，然后依次降低
module XT_BusArbiter #(
    parameter int DEVICE_NUM = 4
) (
    input clk,
    input [DEVICE_NUM-1:0] bus_req,
    output logic [DEVICE_NUM-1:0] bus_accept,
    output logic busy
);


  generate
    if (DEVICE_NUM == 1) begin : gen_exclusive
      assign bus_accept[0] = 1'b1;
      assign busy = 1;
    end else begin : gen_priority
      logic [$clog2(DEVICE_NUM)-1:0] current_accept;

      //----------状态机----------//
      typedef enum bit {
        IDLE = 0,
        BUSY = 1
      } bus_state_e;
      bus_state_e state;

      always_ff @(posedge clk) begin
        unique case (state)
          BUSY: begin
            if (!bus_req[current_accept]) begin
              state <= IDLE;
            end
          end
          IDLE: begin
            if (bus_req != 0) begin
              state <= BUSY;
            end
          end
          default: state <= IDLE;
        endcase
      end

      assign busy = state == BUSY;


      //----------仲裁----------//
      always_ff @(posedge clk) begin
        if (state == IDLE) begin
          if (bus_req == 0) begin
            bus_accept <= 0;
          end else begin
            for (int i = 0; i < DEVICE_NUM; ++i) begin
              if (bus_req[i]) begin
                bus_accept[i]  <= 1;
                current_accept <= i;
                break;
              end
            end
          end
        end else if (!bus_req[current_accept]) begin
          bus_accept <= 0;
        end
      end
    end
  endgenerate





endmodule
