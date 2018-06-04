addpath('flow-code-matlab');

%% DB path
db_path = './Test';
db_list = dir(db_path);
db_list = db_list(3:end);

%% Result path
result_path = './optical_flow';

%% Color path
color_path = './color_map';

%% Main
% For each sequence
for db_id = 1:length(db_list)
    % Make result directories
    result_dir = fullfile(result_path,db_list(db_id).name);
    if ~exist(result_dir,'dir')
        continue;
    end
    color_dir = fullfile(color_path,db_list(db_id).name);
    if ~exist(color_dir,'dir')
        mkdir(color_dir);
    end

    % Make list of frames
    frame_list = dir(fullfile(db_path,db_list(db_id).name,'*.png'));

    for frame_id = 1:length(frame_list)-1
        disp(frame_id);
        src_path = fullfile(db_path,db_list(db_id).name,frame_list(frame_id).name);
        trg_path = fullfile(db_path,db_list(db_id).name,frame_list(frame_id+1).name);
        flow_path = fullfile(result_dir,[frame_list(frame_id).name, '_', frame_list(frame_id+1).name, '.flo']);
        fimg_path = fullfile(color_dir,[frame_list(frame_id).name, '_', frame_list(frame_id+1).name, '.png']);
        
        if ~exist(flow_path,'file')
            break;
        end
        
        flow_map = readFlowFile(flow_path);
        flow_img = flowToColor(flow_map);

        imwrite(flow_img,fimg_path);

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

