// SPDX-FileCopyrightText: 2023 Simone Corbetta <simone.corbetta@gmail.com>
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under the License
// is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
// or implied.  See the License for the specific language governing permissions and limitations
// under the License.
//
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

// Fixed-point adder
module FIXED_POINT_ADD
#(
    // The width of the input values
    parameter WIDTH     = 8,
    // Number of bits reserved to the fractional part. Also, the position of the binary point from
    // LSB. Must be strictly positive
    parameter FRAC_BITS = 3
)
(
    input wire                      CLK,
    input wire                      RSTN,
    // Input operand
    input wire signed [WIDTH-1:0]   VALUE_A_IN,
    input wire signed [WIDTH-1:0]   VALUE_B_IN,
    input wire                      VALID_IN,
    // Accumulator
    output wire signed [WIDTH-1:0]  VALUE_OUT,
    output wire                     VALID_OUT
);

    reg signed [WIDTH-1:0]  value_out;
    reg                     valid_out;

    always @(posedge CLK) begin
        if(!RSTN) begin
            valid_out <= 1'b0;
            value_out <= 0;
        end
        else begin
            valid_out <= 1'b0;

            if(VALID_IN) begin
                value_out <= VALUE_A_IN + VALUE_B_IN;
                valid_out <= 1'b1;
            end
        end
    end

    // Pinout
    assign VALUE_OUT    = value_out;
    assign VALID_OUT    = valid_out;
endmodule

`default_nettype wire
