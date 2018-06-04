addpath('flow-code-matlab');

%% DB path
db_path = '/media/HDD1/wdjang/VSB100/Test_half/';
db_list = dir(db_path);
db_list = db_list(3:end);

%% Result path
result_path = './temp_test';
deep_edge = 'deep_edge';

%% Main
% For each sequence
db_tlist = 1:60;
for db_id = db_tlist
    % Make result directories
    result_dir = fullfile(result_path,db_list(db_id).name,deep_edge);
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
        
%         if exist(flow_path,'file')
%             continue;
%         end

        tic;
        deepflow_cmd = ['./deepmatching_1.0.2_c++/deepmatching-static', ' ' src_path, ' ' trg_path, ' ', '|', ' ', ...
            './deepflow2-static', ' ', src_path, ' ' trg_path, ' ', flow_path, ' ', '-a', ' ', '0.5', ' ', '-match'];
        system(deepflow_cmd);
        toc;
        
        flow1 = readFlowFile(flow_path);
        
        img1 = flowToColor(flow1);

        figure; imshow(img1);
        
        flow1 = readFlowFile('/media/HDD1/wdjang/Optical_Flow/DeepFlow_release2.0/data_half/airplane/deep_edge/image063.png_image064.png.flo');

        img1 = flowToColor(flow1);

        figure; imshow(img1);
        
        flow1 = readFlowFile('/media/HDD1/wdjang/ECCV2016/data_half/airplane/optical_flow/image063.png_image064.png.flo');
        
        img1 = flowToColor(flow1);

        figure; imshow(img1);
        
        input('wait key...');
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


%% 

