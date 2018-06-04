addpath('flow-code-matlab');

%% DB path
db_path = '/media/HDD1/wdjang/Non-rigid_Tracking/SegTrackv2/JPEGImages/';
db_list = dir(db_path);
db_list = db_list(3:end);

%% Result path
result_path = './precomputed';
deep_edge = 'DeepFlow';

%% Main
% For each sequence
db_tlist = [6];
for db_id = db_tlist
    % Make result directories
    result_dir = fullfile(result_path,db_list(db_id).name,deep_edge);
    if ~exist(result_dir,'dir')
        mkdir(result_dir);
    end
    % Make list of frames
    frame_list = dir(fullfile(db_path,db_list(db_id).name,'*.png'));
    if isempty(frame_list)
        frame_list = dir(fullfile(db_path,db_list(db_id).name,'*.jpg'));
        if isempty(frame_list)
            bmp_list = dir(fullfile(db_path,db_list(db_id).name,'*.bmp'));
            for frame_id = 1:length(bmp_list)
                temp_img = imread(fullfile(db_path,db_list(db_id).name,bmp_list(frame_id).name));
                imwrite(temp_img,fullfile(db_path,db_list(db_id).name,[bmp_list(frame_id).name(1:end-4),'.png']));
            end
            frame_list = dir(fullfile(db_path,db_list(db_id).name,'*.png'));
        end
    end
    for frame_id = 2:length(frame_list)
        disp(frame_id);
        src_path = fullfile(db_path,db_list(db_id).name,frame_list(frame_id).name);
        trg_path = fullfile(db_path,db_list(db_id).name,frame_list(frame_id-1).name);
        flow_path = fullfile(result_dir,sprintf('flow_from_%04d_to_%04d.flo',frame_id,frame_id-1));
        
        if exist(flow_path,'file')
            continue;
        end
        
%         tic;
%         deepflow_cmd = ['./deepflow2-static', ' ', src_path, ' ', trg_path, ' ', flow_path];
%         system(deepflow_cmd);
%         toc;

        tic;
        deepflow_cmd = ['./deepmatching_1.0.2_c++/deepmatching-static', ' ' src_path, ' ' trg_path, ' ', '|', ' ', ...
            './deepflow2-static', ' ', src_path, ' ' trg_path, ' ', flow_path, ' ', '-a', ' ', '1.0', ' ', '-match'];
        system(deepflow_cmd);
        toc;
    end
end


% img_1 = imread('sintel1.png');
% img_2 = imread('sintel2.png');
% 
% deepflow2(img_1,img_2)

%%

% flow1 = readFlowFile('sintel_out.flo');
% flow2 = readFlowFile('sintel_outm.flo');
% 
% img1 = flowToColor(flow1);
% img2 = flowToColor(flow2);
% 
% figure; imshow(img1);
% figure; imshow(img2);

%% 

