addpath('flow-code-matlab');

%% DB path
db_path = './Test';
db_list = dir(db_path);
db_list = db_list(3:end);

%% Destination path
dst_path = './data';

%% Main
% For each sequence
for db_id = 1:length(db_list)
    % Make result directories
    result_dir = fullfile('./color_map',db_list(db_id).name);
    if ~exist(result_dir,'dir')
        continue;
    end
    dst_dir = fullfile(dst_path,db_list(db_id).name,'optical_flow_colormap');
    if ~exist(dst_dir,'dir')
        mkdir(dst_dir);
    end

    % Make list of frames
    frame_list = dir(fullfile(result_dir,'*.png'));

    for frame_id = 1:length(frame_list)
        disp(frame_id);
        src_path = fullfile(result_dir,frame_list(frame_id).name);
        trg_path = fullfile(dst_dir,frame_list(frame_id).name);
        
        movefile(src_path,trg_path);
    end
end


% img_1 = imread('sintel1.png');
% img_2 = imread('sintel2.png');
% 
% deepflow2(img_1,img_2)

%

% flow1 = readFlowFile('sintel_out.flo');
% flow2 = readFlowFile('sintel_outm.flo');
% 
% img1 = flowToColor(flow1);
% img2 = flowToColor(flow2);
% 
% figure; imshow(img1);
% figure; imshow(img2);

%

