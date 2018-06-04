function video_segmentation(db_path, seq_name, result_path, param, dic_list, model)

flow_path = './optical_flow'; % Set path to save optical flow

%% Begin process
fprintf('=================================\n');
fprintf('%s\n',seq_name);
fprintf('=================================\n');

frame_names = dir( fullfile( db_path, seq_name, '*.png' ) ); % Load frames

rseq_path = fullfile(result_path,seq_name); % Make result directory
if ~exist(rseq_path,'dir')
    mkdir(rseq_path);
end

fout_path = fullfile(flow_path,seq_name); % Make optical flow directory
if ~exist(fout_path,'dir')
    mkdir(fout_path);
end

num_frame = length(frame_names); % Number of frames

%% Make variables
ilabel_list = cell(param.elim_len+1,1);
ilabel_img = cell(param.elim_len+1,1);

postnum_sp = zeros(param.elim_len+param.window_len+1,1);
postsp_cell = cell(param.elim_len+param.window_len+1,1);
postsp_feat = cell(param.elim_len+param.window_len+1,1);
postedge_mat = cell(param.elim_len+param.window_len+1,1);

num_sp = zeros(param.window_len*2+1,1);
num_seg = zeros(param.window_len*2+1,1);
labenc_cell = cell(param.window_len*2+1,1);
rgbenc_cell = cell(param.window_len*2+1,1);
fwarp_list = cell(param.window_len*2+1,1);
bwarp_list = cell(param.window_len*2+1,1);
sp_cell = cell(param.window_len*2+1,1);
edge_mat = cell(param.window_len*2+1,1);
seg_sp = cell(param.window_len*2+1,1);
labcon_hist = cell(param.window_len*2+1,1);
sp_feat = cell(param.window_len*2+1,1);
l_img = cell(param.window_len*2+1,1);
a_img = cell(param.window_len*2+1,1);
b_img = cell(param.window_len*2+1,1);
inter_tsim = cell(param.window_len*2+1,1);

cumlabel_hist = [];
max_label = 0;

%% Main process
for curr_id = 1:num_frame
    fprintf('Processing frames: %d\n',curr_id);
    
    left_id = max(1,(param.window_len*2+2)-curr_id);
    right_id = param.window_len*2+1;
    incell_id = param.window_len+1;
    
    fprintf('Feature extraction.. ');
    tic_time = tic;
    extract_features();
    toc(tic_time);
    
    fprintf('Hierarchical clustering.. ');
    tic_time = tic;
    agglomerative_segmentation(); 
    toc(tic_time);
    
    if curr_id > param.window_len
        fprintf('Segment matching.. ');
        tic_time = tic;
        match_segment_maxpath(); 
        toc(tic_time);
        
        % Energy minimization
        fprintf('Energy minimization.. ');
        tic_time = tic;
        if curr_id == param.window_len+1
            energy_minimzation_first();
        else
            energy_minimzation(); 
        end
        toc(tic_time);
        
        ilabel_img{end} = zeros(h_size, w_size);
        segs = cell(1,1);
        for sp_id = 1:num_sp(incell_id)
            ilabel_img{end}(sp_cell{incell_id}==sp_id) = ilabel_list{end}(sp_id);
        end
        
        if curr_id > param.window_len + param.elim_len
            unq_list = unique(ilabel_list{1});
            num_temporal = cumlabel_hist(unq_list);
            elim_list = unq_list(num_temporal < param.elim_len);
            if ~isempty(elim_list)
                fprintf('Short-label elimination.. ');
                tic_time = tic;
                elim_minimization();  
                toc(tic_time);
                ilabel_img{1} = zeros(h_size, w_size);
                segs = cell(1,1);
                for sp_id = 1:postnum_sp(1)
                    ilabel_img{1}(postsp_cell{1}==sp_id) = ilabel_list{1}(sp_id);
                end
                segs{1} = uint16(ilabel_img{1});
                save(fullfile(rseq_path,[frame_names(curr_id-param.window_len-param.elim_len).name(1:end-4) '.mat']),'segs');
            else
                segs{1} = uint16(ilabel_img{1});
                save(fullfile(rseq_path,[frame_names(curr_id-param.window_len-param.elim_len).name(1:end-4) '.mat']),'segs');
            end
        end

        prev_label = max_label;
        max_label = max(max_label,max(ilabel_list{end}));

        label_hist = hist(ilabel_list{end},1:max_label)>0;
        cumlabel_hist = [cumlabel_hist, zeros(1,max_label-prev_label)];
        cumlabel_hist = cumlabel_hist + label_hist;
    end
    
    % Previous features    
    pseg_feat = seg_feat;
    pseg_cell = seg_cell;
    
    for in_id = 1:length(inter_tsim)-1
        edge_mat{in_id} = edge_mat{in_id+1};
        seg_sp{in_id} = seg_sp{in_id+1};
        labcon_hist{in_id} = labcon_hist{in_id+1};
        sp_feat{in_id} = sp_feat{in_id+1};
        l_img{in_id} = l_img{in_id+1};
        a_img{in_id} = a_img{in_id+1};
        b_img{in_id} = b_img{in_id+1};
        inter_tsim{in_id} = inter_tsim{in_id+1};
        num_seg(in_id) = num_seg(in_id+1);
        sp_cell{in_id} = sp_cell{in_id+1};
        num_sp(in_id) = num_sp(in_id+1);
        fwarp_list{in_id} = fwarp_list{in_id+1};
        bwarp_list{in_id} = bwarp_list{in_id+1};
        labenc_cell{in_id} = labenc_cell{in_id+1};
        rgbenc_cell{in_id} = rgbenc_cell{in_id+1};
    end
    
    for in_id = 1:length(ilabel_list)-1
        ilabel_list{in_id} = ilabel_list{in_id+1};
        ilabel_img{in_id} = ilabel_img{in_id+1};    
    end
    
    for in_id = 1:length(postsp_cell)-1
        postsp_cell{in_id} = postsp_cell{in_id+1};
        postnum_sp(in_id) = postnum_sp(in_id+1);
        postsp_feat{in_id} = postsp_feat{in_id+1};
        postedge_mat{in_id} = postedge_mat{in_id+1};
    end
    
end


%%

for curr_id = num_frame+1:num_frame+param.window_len
    fprintf('Processing frames: %d\n',curr_id);
    
    left_id = 1;
    right_id = param.window_len*2 + (num_frame+1)-curr_id;
    incell_id = left_id+param.window_len;
    
    fprintf('Segment matching.. ');
    tic_time = tic;
    match_segment_maxpath(); 
    toc(tic_time);

    % Energy minimization
    fprintf('Energy minimization.. ');
    tic_time = tic;
    energy_minimzation(); 
    toc(tic_time);

    ilabel_img{end} = zeros(h_size, w_size);
    segs = cell(1,1);
    for sp_id = 1:num_sp(incell_id)
        ilabel_img{end}(sp_cell{incell_id}==sp_id) = ilabel_list{end}(sp_id);
    end

    unq_list = unique(ilabel_list{1});
    num_temporal = cumlabel_hist(unq_list);
    elim_list = unq_list(num_temporal < param.elim_len);
    if ~isempty(elim_list)
        fprintf('Short-label elimination.. ');
        tic_time = tic;
        elim_minimization();  
        toc(tic_time);
        ilabel_img{1} = zeros(h_size, w_size);
        segs = cell(1,1);
        for sp_id = 1:postnum_sp(1)
            ilabel_img{1}(postsp_cell{1}==sp_id) = ilabel_list{1}(sp_id);
        end
        segs{1} = uint16(ilabel_img{1});
        save(fullfile(rseq_path,[frame_names(curr_id-param.window_len-param.elim_len).name(1:end-4) '.mat']),'segs');
    else
        segs{1} = uint16(ilabel_img{1});
        save(fullfile(rseq_path,[frame_names(curr_id-param.window_len-param.elim_len).name(1:end-4) '.mat']),'segs');
    end

    prev_label = max_label;
    max_label = max(max_label,max(ilabel_list{end}));

    label_hist = hist(ilabel_list{end},1:max_label)>0;
    cumlabel_hist = [cumlabel_hist, zeros(1,max_label-prev_label)];
    cumlabel_hist = cumlabel_hist + label_hist;
    
    % Previous features
    for in_id = 1:length(inter_tsim)-1
        edge_mat{in_id} = edge_mat{in_id+1};
        seg_sp{in_id} = seg_sp{in_id+1};
        labcon_hist{in_id} = labcon_hist{in_id+1};
        sp_feat{in_id} = sp_feat{in_id+1};
        l_img{in_id} = l_img{in_id+1};
        a_img{in_id} = a_img{in_id+1};
        b_img{in_id} = b_img{in_id+1};
        inter_tsim{in_id} = inter_tsim{in_id+1};
        num_seg(in_id) = num_seg(in_id+1);
        sp_cell{in_id} = sp_cell{in_id+1};
        num_sp(in_id) = num_sp(in_id+1);
        fwarp_list{in_id} = fwarp_list{in_id+1};
        bwarp_list{in_id} = bwarp_list{in_id+1};
        labenc_cell{in_id} = labenc_cell{in_id+1};
        rgbenc_cell{in_id} = rgbenc_cell{in_id+1};
    end
    
    for in_id = 1:length(ilabel_list)-1
        ilabel_list{in_id} = ilabel_list{in_id+1};
        ilabel_img{in_id} = ilabel_img{in_id+1};    
    end
    
    for in_id = 1:length(postsp_cell)-1
        postsp_cell{in_id} = postsp_cell{in_id+1};
        postnum_sp(in_id) = postnum_sp(in_id+1);
        postsp_feat{in_id} = postsp_feat{in_id+1};
        postedge_mat{in_id} = postedge_mat{in_id+1};
    end
    
end

%%
for curr_id = 1 : param.elim_len
    unq_list = unique(ilabel_list{1});
    num_temporal = cumlabel_hist(unq_list);
    elim_list = unq_list(num_temporal < param.elim_len);
    if ~isempty(elim_list)
        fprintf('Short-label elimination.. ');
        tic_time = tic;
        elim_minimization();  
        toc(tic_time);
        ilabel_img{1} = zeros(h_size, w_size);
        segs = cell(1,1);
        for sp_id = 1:postnum_sp(1)
            ilabel_img{1}(postsp_cell{1}==sp_id) = ilabel_list{1}(sp_id);
        end
        segs{1} = uint16(ilabel_img{1});
        save(fullfile(rseq_path,[frame_names(curr_id+num_frame-param.elim_len).name(1:end-4) '.mat']),'segs');
    else
        segs{1} = uint16(ilabel_img{1});
        save(fullfile(rseq_path,[frame_names(curr_id+num_frame-param.elim_len).name(1:end-4) '.mat']),'segs');
    end
    
    for in_id = 1:length(postsp_cell)-1
        postsp_cell{in_id} = postsp_cell{in_id+1};
        postnum_sp(in_id) = postnum_sp(in_id+1);
        postsp_feat{in_id} = postsp_feat{in_id+1};
        postedge_mat{in_id} = postedge_mat{in_id+1};
    end
    
    for in_id = 1:length(ilabel_list)-1
        ilabel_list{in_id} = ilabel_list{in_id+1};
        ilabel_img{in_id} = ilabel_img{in_id+1};    
    end
end

end

