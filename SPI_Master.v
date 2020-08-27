//SPI Master module
module SPI_Master(input wire i_clk,
						input wire i_rst_n,
						input wire i_miso,
						input wire i_tx_Enable,
						input wire [7:0] i_data_tx,
						output reg [7:0] o_data_rx,
						output reg o_mosi,
						output reg o_rx_ready,
						output reg o_spi_cs,
						output wire o_spi_clk,
						output reg [2:0] Counter_tx,
						output reg [2:0] Counter_rx,
						output reg Tx_busy);
	
	reg [7:0] Data_received_tmp;
	
	
	
	reg SPI_clk_Enable;
	reg i_tx_Enable1, i_tx_Enable2;
	wire i_tx_trigger;
	
	always @(posedge i_clk or negedge i_rst_n)
		begin
			if(!i_rst_n)
				begin
					i_tx_Enable1<=1'b0;
					i_tx_Enable2<=1'b0;
				end
			else 
				begin
					i_tx_Enable1<=i_tx_Enable;
					i_tx_Enable2<=i_tx_Enable1;
				end
		end
	assign i_tx_trigger=((~i_tx_Enable2)& i_tx_Enable1);
	always @(posedge i_clk or negedge i_rst_n)
		begin
			if (!i_rst_n)
				Tx_busy<=1'b0;
			else if ((o_spi_cs)&i_tx_trigger)
				Tx_busy<=1'b1;
			else if ((!o_spi_cs)&&(Counter_tx==3'b000)) //Counter_tx is very important
				Tx_busy<=1'b0;
			else
				Tx_busy<=Tx_busy;
		end
		
	always @(negedge i_clk or negedge i_rst_n)
		begin
			if(!i_rst_n)
				begin
					SPI_clk_Enable<=1'b0;
					o_mosi<=1'b0;
					o_spi_cs<=1'b1;
					Counter_tx<=3'b000;
					
				end
			else if (Tx_busy==1'b1)
				begin
					o_mosi<=i_data_tx[Counter_tx];
					Counter_tx<=Counter_tx+1'b1;
					SPI_clk_Enable<=1'b1;
					o_spi_cs<=1'b0;
				end
			else
				begin
					SPI_clk_Enable<=1'b0;
					o_mosi<=1'b0;
					o_spi_cs<=1'b1;
					Counter_tx<=3'b000;
				end

		end
	always @(posedge i_clk or negedge i_rst_n)
		begin
			if (!i_rst_n)
				begin
					Data_received_tmp<=8'b0000_0000;  // The code is not required.
					o_data_rx<=8'b0000_0000;
					Counter_rx<=3'b000;
					o_rx_ready<=1'b0;
				end
			else if (Tx_busy)
				begin
					Counter_rx<=Counter_rx+1'b1;
					Data_received_tmp<={Data_received_tmp[6:0], i_miso};
					if (Counter_rx==3'b111)
						begin
						o_data_rx<={Data_received_tmp[6:0],i_miso};
						o_rx_ready<=1'b1;
						end
				end
			else
				begin
					Counter_rx<=3'b000;
					Data_received_tmp<=8'b0000_0000;
				end
				
		end
	assign o_spi_clk=SPI_clk_Enable&i_clk;
						
endmodule