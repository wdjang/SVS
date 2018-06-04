load('./models/forest/modelBsds.mat');
addpath(genpath('./toolbox'));

%% DB path
db_path = '/media/HDD1/wdjang/VSB100/Test';
db_list = dir(db_path);
db_list = db_list(3:end);

%% Result path
result_path = './data';

%% Parameters
model.opts.multiscale=0;          % for top accuracy set multiscale=1
model.opts.sharpen=2;             % for top speed set sharpen=0
model.opts.nTreesEval=4;          % for top speed set nTreesEval=1
model.opts.nThreads=4;            % max number threads for evaluation
model.opts.nms=0;                 % set to true to enable nms

%% Main
% For each sequence
for db_id = 41:60
    % Make result directories
    result_dir = fullfile(result_path,db_list(db_id).name,'boundary');
    if ~exist(result_dir,'dir')
        mkdir(result_dir);
    end
    % Make list of frames
    frame_list = dir(fullfile(db_path,db_list(db_id).name,'*.png'));
    
    disp(db_list(db_id).name);
    for frame_id = 1:length(frame_list)
        disp(frame_id);
        tic;
        src_path = fullfile(db_path,db_list(db_id).name,frame_list(frame_id).name);
        boundary_path = fullfile(result_dir,[frame_list(frame_id).name, '.mat']);
        png_path = fullfile(result_dir,[frame_list(frame_id).name, '.png']);

        img = imread(src_path);
        E=edgesDetect(img,model);

        save(boundary_path,'E');
        imwrite(E,png_path);
        toc;
    end
end

