% Read frame
in_img = imread(fullfile(db_path, seq_name, frame_names(curr_id).name));
[h_size, w_size, ~] = size(in_img);

lab_img = vl_xyz2lab(vl_rgb2xyz(in_img));
l_img{end} = lab_img(:,:,1); a_img{end} = lab_img(:,:,2); b_img{end} = lab_img(:,:,3);

lab_list = reshape(lab_img,h_size*w_size,3);
dist_mat = vl_alldist2(lab_list',dic_list.lab_dic);
[~, min_list] = min(dist_mat,[],2);
lab_enc = reshape(min_list,h_size,w_size);
labenc_cell{end} = lab_enc;

rgb_list = reshape(double(in_img),h_size*w_size,3);
dist_mat = vl_alldist2(rgb_list',dic_list.rgb_dic);
[~, min_list] = min(dist_mat,[],2);
rgb_enc = reshape(min_list,h_size,w_size);
rgbenc_cell{end} = rgb_enc;

% Optical flow
fflow_enc = [];
bflow_enc = [];
fwarp_list{end} = [];
bwarp_list{end} = [];
y_list = repmat(1:h_size,w_size,1)';
x_list = repmat(1:w_size,h_size,1);
if curr_id ~= num_frame
    src_path = fullfile(db_path,seq_name,frame_names(curr_id).name);
    trg_path = fullfile(db_path,seq_name,frame_names(curr_id+1).name);
    out_path = fullfile(flow_path,seq_name,...
        [frame_names(curr_id).name, '_', frame_names(curr_id+1).name, '.flo']);
    deepflow_cmd = ['./DeepFlow_release2.0/deepflow2-static', ' ', src_path, ' ', trg_path, ' ', out_path];
    system(deepflow_cmd);
    
    fflow_map = readFlowFile(fullfile(flow_path,seq_name,...
        [frame_names(curr_id).name, '_', frame_names(curr_id+1).name, '.flo']));
    warp_xlist = min(max(round(x_list+fflow_map(:,:,1)),1),w_size);
    warp_ylist = min(max(round(y_list+fflow_map(:,:,2)),1),h_size);
    fwarp_list{end} = sub2ind([h_size,w_size], warp_ylist, warp_xlist);

    fflow_list = reshape(fflow_map,h_size*w_size,2);
    dist_mat = vl_alldist2(fflow_list',dic_list.flow_dic);
    [~, min_list] = min(dist_mat,[],2);
    fflow_enc = reshape(min_list,h_size,w_size);
end
if curr_id ~= 1
    src_path = fullfile(db_path,seq_name,frame_names(curr_id).name);
    trg_path = fullfile(db_path,seq_name,frame_names(curr_id-1).name);
    out_path = fullfile(flow_path,seq_name,...
        [frame_names(curr_id).name, '_', frame_names(curr_id-1).name, '.flo']);
    deepflow_cmd = ['./DeepFlow_release2.0/deepflow2-static', ' ', src_path, ' ', trg_path, ' ', out_path];
    system(deepflow_cmd);
    
    bflow_map = readFlowFile(fullfile(flow_path,seq_name,...
        [frame_names(curr_id).name, '_', frame_names(curr_id-1).name, '.flo']));
    warp_xlist = min(max(round(x_list+bflow_map(:,:,1)),1),w_size);
    warp_ylist = min(max(round(y_list+bflow_map(:,:,2)),1),h_size);
    bwarp_list{end} = sub2ind([h_size,w_size], warp_ylist, warp_xlist);

    fflow_list = reshape(bflow_map,h_size*w_size,2);
    dist_mat = vl_alldist2(fflow_list',dic_list.flow_dic);
    [~, min_list] = min(dist_mat,[],2);
    bflow_enc = reshape(min_list,h_size,w_size);
end


% Mean-shift
min_size = round(h_size*w_size*0.001);
rg_width = 5;
sp_width = 9;
[ms_img, ms_map, ~, ~, ~, ~] = edison_wrapper(in_img,@RGB2Luv,...
    'SpatialBandWidth',sp_width,'RangeBandWidth',rg_width,'MinimumRegionArea',min_size);
ms_map = ms_map + 1;
sp_cell{end} = ms_map;
num_sp(end) = max(sp_cell{end}(:));

postsp_cell{end} = sp_cell{end};
postnum_sp(end) = num_sp(end);

edge_mat{end} = k_Ring_Graph_Construction(sp_cell{end}, 1);
edge_mat{end} = logical(edge_mat{end});

postedge_mat{end} = edge_mat{end};


% UCM feature extraction
gPb_orient = edgesDetect(in_img,model);
gPb_orient = gPb_orient / max(gPb_orient(:));
ucm = contours2ucm(gPb_orient, 'imageSize');

ucmb_map = uint16(bwlabel(ucm<=0.1));
ucm_seg = ucmb_map;
[y_list, x_list] = find(ucm_seg==0);
for p_id = 1:length(y_list)
    ucm_seg(y_list(p_id),x_list(p_id)) = max([...
        ucmb_map(min(y_list(p_id)+1,h_size/2),x_list(p_id)),...
        ucmb_map(y_list(p_id),min(x_list(p_id)+1,w_size/2)),...
        ucmb_map(max(y_list(p_id)-1,1),x_list(p_id)),...
        ucmb_map(y_list(p_id),max(x_list(p_id)-1,1))...
        ucmb_map(max(y_list(p_id)-1,1),max(x_list(p_id)-1,1)),...
        ucmb_map(min(y_list(p_id)+1,h_size/2),max(x_list(p_id)-1,1))...
        ucmb_map(max(y_list(p_id)-1,1),min(x_list(p_id)+1,w_size/2)),...
        ucmb_map(min(y_list(p_id)+1,h_size/2),min(x_list(p_id)+1,w_size/2))]); 
end
ucm_numw = double(max(ucm_seg(:)));
ucm_hist1 = zeros(num_sp(end),ucm_numw);
for sp_id = 1:num_sp(end)
    ucm_hist1(sp_id,:) = hist(double(ucm_seg(sp_cell{end}==sp_id)),1:ucm_numw);
    ucm_hist1(sp_id,:) = ucm_hist1(sp_id,:)/sqrt(sum(ucm_hist1(sp_id,:).^2));
end

ucmb_map = uint16(bwlabel(ucm<=0.3));
ucm_seg = ucmb_map;
[y_list, x_list] = find(ucm_seg==0);
for p_id = 1:length(y_list)
    ucm_seg(y_list(p_id),x_list(p_id)) = max([...
        ucmb_map(min(y_list(p_id)+1,h_size/2),x_list(p_id)),...
        ucmb_map(y_list(p_id),min(x_list(p_id)+1,w_size/2)),...
        ucmb_map(max(y_list(p_id)-1,1),x_list(p_id)),...
        ucmb_map(y_list(p_id),max(x_list(p_id)-1,1))...
        ucmb_map(max(y_list(p_id)-1,1),max(x_list(p_id)-1,1)),...
        ucmb_map(min(y_list(p_id)+1,h_size/2),max(x_list(p_id)-1,1))...
        ucmb_map(max(y_list(p_id)-1,1),min(x_list(p_id)+1,w_size/2)),...
        ucmb_map(min(y_list(p_id)+1,h_size/2),min(x_list(p_id)+1,w_size/2))]); 
end
ucm_numw = double(max(ucm_seg(:)));
ucm_hist2 = zeros(num_sp(end),ucm_numw);
for sp_id = 1:num_sp(end)
    ucm_hist2(sp_id,:) = hist(double(ucm_seg(sp_cell{end}==sp_id)),1:ucm_numw);
    ucm_hist2(sp_id,:) = ucm_hist2(sp_id,:)/sqrt(sum(ucm_hist2(sp_id,:).^2));
end

ucmb_map = uint16(bwlabel(ucm<=0.5));
ucm_seg = ucmb_map;
[y_list, x_list] = find(ucm_seg==0);
for p_id = 1:length(y_list)
    ucm_seg(y_list(p_id),x_list(p_id)) = max([...
        ucmb_map(min(y_list(p_id)+1,h_size/2),x_list(p_id)),...
        ucmb_map(y_list(p_id),min(x_list(p_id)+1,w_size/2)),...
        ucmb_map(max(y_list(p_id)-1,1),x_list(p_id)),...
        ucmb_map(y_list(p_id),max(x_list(p_id)-1,1))...
        ucmb_map(max(y_list(p_id)-1,1),max(x_list(p_id)-1,1)),...
        ucmb_map(min(y_list(p_id)+1,h_size/2),max(x_list(p_id)-1,1))...
        ucmb_map(max(y_list(p_id)-1,1),min(x_list(p_id)+1,w_size/2)),...
        ucmb_map(min(y_list(p_id)+1,h_size/2),min(x_list(p_id)+1,w_size/2))]); 
end
ucm_numw = double(max(ucm_seg(:)));
ucm_hist3 = zeros(num_sp(end),ucm_numw);
for sp_id = 1:num_sp(end)
    ucm_hist3(sp_id,:) = hist(double(ucm_seg(sp_cell{end}==sp_id)),1:ucm_numw);
    ucm_hist3(sp_id,:) = ucm_hist3(sp_id,:)/sqrt(sum(ucm_hist3(sp_id,:).^2));
end


% LAB histogram construction
lab_hist = zeros(num_sp(end),param.lab_numw);
for sp_id = 1:num_sp(end)
    lab_hist(sp_id,:) = hist(labenc_cell{end}(sp_cell{end}==sp_id),1:param.lab_numw);
    lab_hist(sp_id,:) = lab_hist(sp_id,:)/sqrt(sum(lab_hist(sp_id,:).^2));
end

% Compute nearest RGB word for each pixel
rgb_hist = zeros(num_sp(end),param.rgb_numw);
for sp_id = 1:num_sp(end)
    rgb_hist(sp_id,:) = hist(rgbenc_cell{end}(sp_cell{end}==sp_id),1:param.rgb_numw);
    rgb_hist(sp_id,:) = rgb_hist(sp_id,:)/sqrt(sum(rgb_hist(sp_id,:).^2));
end

% Histogram construction
if ~isempty(fflow_enc)
    ff_hist = zeros(num_sp(end),param.flow_numw);
    for sp_id = 1:num_sp(end)
        ff_hist(sp_id,:) = hist(fflow_enc(sp_cell{end}==sp_id),1:param.flow_numw);
        ff_hist(sp_id,:) = ff_hist(sp_id,:)/sqrt(sum(ff_hist(sp_id,:).^2));
    end
else
    ff_hist = [];
end
if ~isempty(bflow_enc)
    bf_hist = zeros(num_sp(end),param.flow_numw);
    for sp_id = 1:num_sp(end)
        bf_hist(sp_id,:) = hist(bflow_enc(sp_cell{end}==sp_id),1:param.flow_numw);
        bf_hist(sp_id,:) = bf_hist(sp_id,:)/sqrt(sum(bf_hist(sp_id,:).^2));
    end
else
    bf_hist = [];
end

if isempty(fflow_enc)
    ff_hist = bf_hist;
end

if isempty(bflow_enc)
    bf_hist = ff_hist;
end

% Lab histogram of each dimension
labcon_hist{end} = zeros(num_sp(end),60);
for sp_id = 1:num_sp(end)
    labcon_hist{end}(sp_id,1:20)    = hist(l_img{end}(sp_cell{end}==sp_id),2.5:5:100);
    labcon_hist{end}(sp_id,21:40)   = hist(a_img{end}(sp_cell{end}==sp_id),-95:10:100);
    labcon_hist{end}(sp_id,41:60)   = hist(b_img{end}(sp_cell{end}==sp_id),-95:10:100);
    labcon_hist{end}(sp_id,:)       = labcon_hist{end}(sp_id,:)/sqrt(sum(labcon_hist{end}(sp_id,:).^2));
end

% Concatenate features
sp_feat{end} = [labcon_hist{end}, 0.75*rgb_hist, 0.75*lab_hist, ...
    0.5*ff_hist, 0.5*bf_hist, 0.8*ucm_hist1, 0.65*ucm_hist2, 0.5*ucm_hist3];
% labcon 1~60, rgb hist 61~360, lab hist 361~660, forward flow 661~760, backward flow 761~860, ucm hist 861~end
for sp_id = 1:num_sp(end)
    sp_feat{end}(sp_id,:) = sp_feat{end}(sp_id,:)/sqrt(sum(sp_feat{end}(sp_id,:).^2));
end
postsp_feat{end} = sp_feat{end};














