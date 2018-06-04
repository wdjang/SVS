clear all

%% Third-party setting
run('/media/HDD2/wdjang/vlfeat-0.9.20/toolbox/vl_setup'); % Set vlfeat path
addpath('DeepFlow_release2.0'); % Set DeepFlow path
addpath('flow-code-matlab'); % Load optical flow functions
addpath(genpath('./edges-master')); % Set contour detector path
addpath('lib'); % Set UCM path
addpath('GCMex'); % Set GraphCut path
addpath('msseg'); % Set mean-shift path

load('./edges-master/models/forest/modelBsds.mat'); % Load pre-computed model
model.opts.multiscale=0; % Set contour option
model.opts.sharpen=2;    % Set contour option
model.opts.nTreesEval=4; % Set contour option
model.opts.nThreads=4;   % Set contour option
model.opts.nms=0;        % Set contour option

dic_path = './dictionary'; % Set dictionary path
load(fullfile(dic_path,'lab_dic.mat')); % Load Lab dictionary
load(fullfile(dic_path,'rgb_dic.mat')); % Load RGB dictionary
load(fullfile(dic_path,'flow_dic.mat')); % Load optical flow dictionary
dic_list.lab_dic = lab_dic;
dic_list.rgb_dic = rgb_dic;
dic_list.flow_dic = flow_dic;

%% Set target data
db_path = './data'; % Database path
seq_name = 'LongJump'; % Sequence name
result_path = './results'; % Result directory

%% Set parameters
param = param_setting(0.4);

%% Video segmentation
video_segmentation(db_path,seq_name,result_path,param,dic_list,model);
