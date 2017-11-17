module Rsa256Core(
	input i_clk,
	input i_rst,
	input         src_val,
	output logic  src_rdy,
	input [255:0] i_a,
	input [255:0] i_e,
	input [255:0] i_n,
	output logic         result_val,
	input                result_rdy,
	output logic [255:0] o_a_pow_e
);
logic src_rdy_r, src_rdy_w, result_val_r, result_val_w;
logic[255:0] o_a_pow_e_r, o_a_pow_e_w;
logic[31:0] state_r, state_w;
logic[256:0] a_r, a_w, e_r, e_w, n_r, n_w;
logic[31:0] count_r, count_w, mul_count_r, mul_count_w;
logic[256:0] ret_r, ret_w, mul_ret_r, mul_ret_w, buffer_w, buffer_r;
localparam S_IDLE = 0, S_power_mont = 1, S_mont_preprocess = 2, S_mul_mont1 = 3, 
			S_mul_mont0 = 4, S_setup = 5, S_trans = 6, S_mul_ret2zero1 = 7, S_mul_ret2zero0 = 8;
assign src_rdy = src_rdy_r;
assign result_val = result_val_r;
assign o_a_pow_e = o_a_pow_e_r;

always_comb begin
	case(state_r)
		S_IDLE:begin
			count_w = 0;
			mul_count_w = 0;
			ret_w = 1;
			mul_ret_w = 0;
			result_val_w = 0;
			a_w = a_r;
			e_w = e_r;
			n_w = n_r;
			o_a_pow_e_w = o_a_pow_e_r;
			if(src_val == 1)begin
				src_rdy_w = 1;
				state_w = S_setup;
			end
			else begin
				src_rdy_w = 0;
				state_w = S_IDLE;
			end
		end
		S_setup: begin
			count_w = count_r;
			mul_count_w = mul_count_r;
			ret_w = ret_r;
			mul_ret_w = mul_ret_r;
			result_val_w = result_val_r;
			src_rdy_w = src_rdy_r;
			a_w = i_a;
			e_w = i_e;
			n_w = i_n;
			o_a_pow_e_w = o_a_pow_e_r;
			state_w = S_mont_preprocess;
		end
		S_trans: begin
			count_w = count_r;
			mul_count_w = mul_count_r;
			ret_w = ret_r;
			mul_ret_w = mul_ret_r;
			result_val_w = result_val_r;
			src_rdy_w = src_rdy_r;
			a_w = a_r;
			e_w = e_r;
			n_w = n_r;
			if(result_rdy == 1)begin
				o_a_pow_e_w = ret_r;
				state_w = S_IDLE;
			end
			else begin
				o_a_pow_e_w = 0;
				state_w = S_trans;
			end
		end
		S_power_mont:begin
			count_w = count_r;
			mul_count_w = mul_count_r;
			ret_w = ret_r;
			mul_ret_w = mul_ret_r;
			src_rdy_w = src_rdy_r;
			a_w = a_r;
			e_w = e_r;
			n_w = n_r;
			o_a_pow_e_w = o_a_pow_e_r;
			if(count_r == 256)begin
				state_w = S_trans;
				result_val_w = 1;
			end
			else begin
				result_val_w = result_val_r;
				if(e_r[count_r] == 1)begin
					state_w = S_mul_mont1;
				end
				else begin 
					state_w = S_mul_mont0;
				end
				//state_w = S_power_mont;
			end
		end
		
		S_mont_preprocess:begin
			src_rdy_w = 0;
			a_w = a_r << 1;
			mul_count_w = mul_count_r;
			ret_w = ret_r;
			mul_ret_w = mul_ret_r;
			result_val_w = result_val_r;
			src_rdy_w = src_rdy_r;
			//a_w = a_r;
			e_w = e_r;
			n_w = n_r;
			o_a_pow_e_w = o_a_pow_e_r;
			if( (a_r << 1) >=  n_r)begin
				a_w = (a_r << 1)- n_r;
				count_w = count_r;
			end
			count_w = count_r + 1;
			if(count_w == 256)begin
				a_w = a_r;
				state_w = S_power_mont;
				count_w = 0;
			end
			else begin
				a_w = a_r;
				count_w = count_r;
				state_w = S_mont_preprocess;
			end
			
		end
		S_mul_mont1:begin
			count_w = count_r;
			result_val_w = result_val_r;
			src_rdy_w = src_rdy_r;
			a_w = a_r;
			e_w = e_r;
			n_w = n_r;
			o_a_pow_e_w = o_a_pow_e_r;
			if(mul_count_r == 256)begin
				if(mul_ret_r >= n_r)begin 
					mul_ret_w = mul_ret_r - n_r;
					ret_w = mul_ret_r - n_r;
				end
				else begin
					mul_ret_w = mul_ret_r;
					ret_w = mul_ret_r;
				end
				mul_count_w = 0;
				//mul_ret_w = 0;
				state_w = S_mul_ret2zero0;//S_mul_mont0
			end
			else begin
				ret_w = ret_r;
				//buffer = mul_ret_r + ret_r;
				
				if(a_r[mul_count_r] == 1 && (mul_ret_r[0] + ret_r[0]) == 1)begin
					mul_ret_w = (mul_ret_r + ret_r + n_r) >> 1;
				end
				else if(a_r[mul_count_r] == 1)begin
					mul_ret_w = (mul_ret_r + ret_r) >> 1;
				end
				else begin
					if(mul_ret_r[0] == 1)begin
						mul_ret_w = (mul_ret_r + n_r) >> 1;
					end
					else begin
						mul_ret_w = mul_ret_r;
					end
				end
				mul_count_w = mul_count_r + 1; 
				state_w = S_mul_mont1;
			end
		end
		S_mul_mont0:begin
			ret_w = ret_r;
			result_val_w = result_val_r;
			src_rdy_w = src_rdy_r;
			//a_w = a_r;
			e_w = e_r;
			n_w = n_r;
			o_a_pow_e_w = o_a_pow_e_r;
			if(mul_count_r == 256)begin
				if(mul_ret_r >= n_r)begin 
					mul_ret_w = mul_ret_r - n_r;
					a_w = mul_ret_r - n_r;
				end
				else begin
					mul_ret_w = mul_ret_r;
					a_w = mul_ret_r;
				end
				mul_count_w = 0;
				//mul_ret_w = 0;
				state_w = S_mul_ret2zero1;//power_mont
				count_w = count_r + 1; 
			end
			else begin
				count_w = count_r;
				//buffer = mul_ret_r + a_r;
				a_w = a_r;
				if(a_r[mul_count_r] == 1 && (mul_ret_r[0] + a_r[0])== 1)begin					
					mul_ret_w = (mul_ret_r + a_r + n_r) >> 1;
				end
				else if(a_r[mul_count_r] == 1)begin
					mul_ret_w = (mul_ret_r + a_r) >> 1;
				end
				else begin
					if(mul_ret_r[0] == 1)begin
						mul_ret_w = (mul_ret_r + n_r) >> 1;
					end
					else begin
						mul_ret_w = mul_ret_r;
					end
				end
				mul_count_w = mul_count_r + 1;
				state_w = S_mul_mont0;
			end
		end
		S_mul_ret2zero0:begin
			state_w = S_mul_mont0;
			count_w = count_r;
			mul_count_w = mul_count_r;
			ret_w = ret_r;
			mul_ret_w = 0;
			result_val_w = result_val_r;
			src_rdy_w = src_rdy_r;
			a_w = a_r;
			e_w = e_r;
			n_w = n_r;
			o_a_pow_e_w = o_a_pow_e_r;
		end
		S_mul_ret2zero1:begin
			state_w = S_power_mont;
			count_w = count_r;
			mul_count_w = mul_count_r;
			ret_w = ret_r;
			mul_ret_w = 0;
			result_val_w = result_val_r;
			src_rdy_w = src_rdy_r;
			a_w = a_r;
			e_w = e_r;
			n_w = n_r;
			o_a_pow_e_w = o_a_pow_e_r;
		end
		default: begin 
			state_w = S_IDLE;
			count_w = count_r;
			mul_count_w = mul_count_r;
			ret_w = ret_r;
			mul_ret_w = mul_ret_r;
			result_val_w = result_val_r;
			src_rdy_w = src_rdy_r;
			a_w = a_r;
			e_w = e_r;
			n_w = n_r;
			o_a_pow_e_w = o_a_pow_e_r;
			
		end
	endcase
	
end
always_ff @(posedge i_clk or negedge i_rst) begin
	if(!i_rst) begin
			o_a_pow_e_r <= o_a_pow_e_w;
			state_r <= S_IDLE;
	end 
	else begin
			src_rdy_r <= src_rdy_w;
			result_val_r <= result_val_w;
			o_a_pow_e_r <= o_a_pow_e_w;
			state_r <= state_w;
			a_r <= a_w;
			e_r <= e_w;
			n_r <= n_w;
			count_r <= count_w;
			mul_count_r <= mul_count_w;
			ret_r <= ret_w;
			mul_ret_r <= mul_ret_w;
			
	end
end

endmodule
