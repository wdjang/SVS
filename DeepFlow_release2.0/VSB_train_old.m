addpath('flow-code-matlab');

%% DB path
db_path = '/media/HDD1/wdjang/VSB100/Train/';
db_list = dir(db_path);
db_list = db_list(3:end);

%% Result path
out_path = './train';
result_path = './optical_flow';

small_path = './small_image';

%% Main
% For each sequence
for db_id = 1:10
    % Make result directories
    result_dir = fullfile(out_path,db_list(db_id).name,result_path);
    if ~exist(result_dir,'dir')
        mkdir(result_dir);
    end
    % Make small image directories
    small_dir = fullfile(small_path,db_list(db_id).name);
    if ~exist(small_dir,'dir')
        mkdir(small_dir);
    end
    % Make list of frames
    frame_list = dir(fullfile(db_path,db_list(db_id).name,'*.png'));

    for frame_id = 1:1
        disp(frame_id);
        src_path = fullfile(db_path,db_list(db_id).name,frame_list(frame_id).name);
        trg_path = fullfile(db_path,db_list(db_id).name,frame_list(frame_id+1).name);
        src_img = imresize(imread(src_path),0.5);
        trg_img = imresize(imread(trg_path),0.5);
        src_path = fullfile(small_dir,frame_list(frame_id).name);
        trg_path = fullfile(small_dir,frame_list(frame_id+1).name);
        imwrite(src_img,src_path);
        imwrite(trg_img,trg_path);
        
        flow_path = fullfile(result_dir,[frame_list(frame_id).name, '_', frame_list(frame_id+1).name, '.flo']);
        
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

    for frame_id = length(frame_list):length(frame_list)
        disp(frame_id);
        src_path = fullfile(db_path,db_list(db_id).name,frame_list(frame_id).name);
        trg_path = fullfile(db_path,db_list(db_id).name,frame_list(frame_id-1).name);
        src_img = imresize(imread(src_path),0.5);
        trg_img = imresize(imread(trg_path),0.5);
        src_path = fullfile(small_dir,frame_list(frame_id).name);
        trg_path = fullfile(small_dir,frame_list(frame_id-1).name);
        imwrite(src_img,src_path);
        imwrite(trg_img,trg_path);
        
        flow_path = fullfile(result_dir,[frame_list(frame_id).name, '_', frame_list(frame_id-1).name, '.flo']);
        
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

