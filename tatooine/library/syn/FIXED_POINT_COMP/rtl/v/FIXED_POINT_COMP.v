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

// Fixed-point comparator
module FIXED_POINT_COMP
#(
    // Input data width
    parameter WIDTH         = 8,
    // Number of fractional bits
    parameter FRAC_BITS     = 3
)
(
    input wire signed [WIDTH-1:0]   VALUE_A_IN,
    input wire signed [WIDTH-1:0]   VALUE_B_IN,
    // Outputs are relative to ordered  VALUE_A_IN op VALUE_B_IN  
    output wire                     GT,
    output wire                     EQ,
    output wire                     LT
);

    // To save space, derive the third operation
    wire gt;
    wire eq;
    wire lt;

    assign gt = ( VALUE_A_IN > VALUE_B_IN ? 1'b1 : 1'b0 );
    assign eq = ( VALUE_A_IN == VALUE_B_IN ? 1'b1 : 1'b0 );
    assign lt = ~gt & ~eq;

    // Pinout
    assign GT = gt;
    assign EQ = eq;
    assign LT = lt;
endmodule

`default_nettype wire
