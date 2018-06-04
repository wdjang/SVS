addpath('flow-code-matlab');

A = readFlowFile('optical_flow/airplane/image063.png_image064.png.flo');
save('flow_temp.mat','A');