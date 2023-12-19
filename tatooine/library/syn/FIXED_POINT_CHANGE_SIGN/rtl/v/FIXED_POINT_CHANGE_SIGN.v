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

// Changes the sign of the incoming value to the target one. This can be used in different contexts,
// e.g. to share ALUs for odd-symmetric functions
module FIXED_POINT_CHANGE_SIGN
#(
    // Input data width
    parameter WIDTH         = 8,
    // Number of fractional bits
    parameter FRAC_BITS     = 3
)
(
    input wire                      CLK,
    input wire                      RSTN,
    // 1'b0 -> we want positive, 1'b1 -> we want negative
    input wire                      TARGET_SIGN,
    input wire signed [WIDTH-1:0]   VALUE_IN,
    input wire                      VALID_IN,
    output wire signed [WIDTH-1:0]  VALUE_OUT,
    output wire                     VALID_OUT
);

     reg signed [WIDTH-1:0]     value_out;
     reg                        valid_out;
     wire                       sign;
     wire                       sign_match;
     wire signed [WIDTH-1:0]    value_converted;
     wire                       valid_converted;
     wire signed [WIDTH-1:0]    fixed_point_minus_one;
     wire                       valid_in_filtered;

    // As usual, the MSB hints about the negative number
    assign sign = VALUE_IN[WIDTH-1];

    // Special number
    assign fixed_point_minus_one = { {WIDTH-FRAC_BITS{1'b1}}, {FRAC_BITS{1'b0}} };

    // Multiplication run only when required, this also simplifies mux later
    assign valid_in_filtered = VALID_IN & ~sign_match;

    // Compute 2's complement conversion
    FIXED_POINT_MUL #(
        .WIDTH      (WIDTH),
        .FRAC_BITS  (FRAC_BITS)
    )
    FIXED_POINT_MUL_0 (
        .CLK        (CLK),
        .RSTN       (RSTN),
        .VALUE_A_IN (VALUE_IN),
        .VALUE_B_IN (fixed_point_minus_one),
        .VALID_IN   (valid_in_filtered),
        .VALUE_OUT  (value_converted),
        .VALID_OUT  (valid_converted)
    );

    // When sign of incoming value already matches the desired one, discard all computations
    assign sign_match = (sign & TARGET_SIGN) | (!sign & !TARGET_SIGN);

    always @(posedge CLK) begin
        if(!RSTN) begin
            valid_out <= 1'b0;
        end
        else begin
            valid_out <= 1'b0;

            if(VALID_IN && sign_match) begin
                value_out <= VALUE_IN;
                valid_out <= 1'b1;
            end
            else if(valid_converted) begin
                value_out <= value_converted;
                valid_out <= 1'b1;
            end
        end
    end

    // Pinout
    assign VALUE_OUT    = value_out;
    assign VALID_OUT    = valid_out;
endmodule

`default_nettype wire
