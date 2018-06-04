addpath('flow-code-matlab');

%% DB path
db_path = '/media/HDD1/wdjang/VSB100/Train_half/';
db_list = dir(db_path);
db_list = db_list(3:end);

%% Result path
result_path = './optical_flow';

%% Main
% For each sequence
for db_id = 31:40
    % Make result directories
    result_dir = fullfile('./data_train_half',db_list(db_id).name,result_path);
    if ~exist(result_dir,'dir')
        mkdir(result_dir);
    end
    % Make list of frames
    frame_list = dir(fullfile(db_path,db_list(db_id).name,'*.png'));

    for frame_id = 1:length(frame_list)-1
        disp(frame_id);
        src_path = fullfile(db_path,db_list(db_id).name,frame_list(frame_id).name);
        trg_path = fullfile(db_path,db_list(db_id).name,frame_list(frame_id+1).name);
        flow_path = fullfile(result_dir,[frame_list(frame_id).name, '_', frame_list(frame_id+1).name, '.flo']);
        
        if exist(flow_path,'file')
            continue;
        end
        
%         tic;
%         deepflow_cmd = ['./deepflow2-static', ' ', src_path, ' ', trg_path, ' ', flow_path];
%         system(deepflow_cmd);
%         toc;

        tic;
        deepflow_cmd = ['./deepmatching_1.0.2_c++/deepmatching-static', ' ' src_path, ' ' trg_path, ' ', '|', ' ', ...
            './deepflow2-static', ' ', src_path, ' ' trg_path, ' ', flow_path, ' ', '-match'];
        system(deepflow_cmd);
        toc;
    end

    for frame_id = 2:length(frame_list)
        disp(frame_id);
        src_path = fullfile(db_path,db_list(db_id).name,frame_list(frame_id).name);
        trg_path = fullfile(db_path,db_list(db_id).name,frame_list(frame_id-1).name);
        flow_path = fullfile(result_dir,[frame_list(frame_id).name, '_', frame_list(frame_id-1).name, '.flo']);
        
        if exist(flow_path,'file')
            continue;
        end
        
%         tic;
%         deepflow_cmd = ['./deepflow2-static', ' ', src_path, ' ', trg_path, ' ', flow_path];
%         system(deepflow_cmd);
%         toc;

        tic;
        deepflow_cmd = ['./deepmatching_1.0.2_c++/deepmatching-static', ' ' src_path, ' ' trg_path, ' ', '|', ' ', ...
            './deepflow2-static', ' ', src_path, ' ' trg_path, ' ', flow_path, ' ', '-match'];
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

