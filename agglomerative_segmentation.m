%% Agglomerative segmentation within a frame
% Feature distance
sp_dist  = vl_alldist2(sp_feat{end}','CHI2');
sp_dist = sp_dist / max(sp_dist(edge_mat{end}));
sp_dist(logical(1-edge_mat{end})) = Inf;
% Distance mixture
clust_list = agglomerative_function(sp_dist, param.gamma);

label_list = unique(clust_list);
sqz_label = clust_list;
for l_id = 1:length(label_list)
    sqz_label(clust_list==label_list(l_id)) = l_id;
end
clust_list = sqz_label;

seg_sp{end} = clust_list;

num_seg(end) = max(seg_sp{end});

seg_cell = zeros(h_size,w_size);
for sp_id = 1:num_sp(end)
    seg_cell(sp_cell{end} == sp_id) = seg_sp{end}(sp_id);
end


%% Feature description
% Lab histogram of each dimension
labseg_hist = zeros(num_seg(end),60);
for seg_id = 1:num_seg(end)
    labseg_hist(seg_id,1:20)    = hist(l_img{end}(seg_cell==seg_id),2.5:5:100);
    labseg_hist(seg_id,21:40)   = hist(a_img{end}(seg_cell==seg_id),-95:10:100);
    labseg_hist(seg_id,41:60)   = hist(b_img{end}(seg_cell==seg_id),-95:10:100);
    labseg_hist(seg_id,:)       = labseg_hist(seg_id,:)/sqrt(sum(labseg_hist(seg_id,:).^2));
end

% Histogram construction
lab_seg = zeros(num_seg(end),param.lab_numw);
for seg_id = 1:num_seg(end)
    lab_seg(seg_id,:) = hist(labenc_cell{end}(seg_cell==seg_id),1:param.lab_numw);
    lab_seg(seg_id,:) = lab_seg(seg_id,:)/sqrt(sum(lab_seg(seg_id,:).^2));
end

% Histogram construction
rgb_seg = zeros(num_seg(end),param.rgb_numw);
for seg_id = 1:num_seg(end)
    rgb_seg(seg_id,:) = hist(rgbenc_cell{end}(seg_cell==seg_id),1:param.rgb_numw);
    rgb_seg(seg_id,:) = rgb_seg(seg_id,:)/sqrt(sum(rgb_seg(seg_id,:).^2));
end
 
% Feature mixing
seg_feat = [labseg_hist, 0.75*rgb_seg, 0.75*lab_seg];
for seg_id = 1:num_seg(end)
    seg_feat(seg_id,:) = seg_feat(seg_id,:)/sqrt(sum(seg_feat(seg_id,:).^2));
end


%% Inter distance matrix
if curr_id > 1

    inter_tdist = vl_alldist2(pseg_feat',seg_feat','CHI2');
    
    % Backward flow
    bwarp_seg = pseg_cell(bwarp_list{end});

    bfedge_mat = zeros(size(inter_tdist));
    for seg_id = 1:num_seg(end)
        conn_list = unique(bwarp_seg(seg_cell==seg_id));
        bfedge_mat(conn_list,seg_id) = 1;
    end
    
    binter_ovl = zeros(size(inter_tdist));
    for seg_id = 1:num_seg(end)
        warp_hist = hist(bwarp_seg(seg_cell == seg_id),1:num_seg(end-1));
        warp_hist = warp_hist/max(warp_hist);
        binter_ovl(:,seg_id) =  warp_hist;
    end
    
    % Forward flow
    fwarp_seg = seg_cell(fwarp_list{end-1});

    ffedge_mat = zeros(size(inter_tdist));
    for seg_id = 1:num_seg(end-1)
        conn_list = unique(fwarp_seg(pseg_cell==seg_id));
        ffedge_mat(seg_id,conn_list) = 1;
    end
    
    finter_ovl = zeros(size(inter_tdist));
    for seg_id = 1:num_seg(end-1)
        warp_hist = hist(fwarp_seg(pseg_cell == seg_id),1:num_seg(end));
        warp_hist = warp_hist/max(warp_hist);
        finter_ovl(seg_id,:) =  warp_hist;
    end
        
    tedge_mat = bfedge_mat | ffedge_mat;

    inter_tdist = inter_tdist / max(inter_tdist(logical(tedge_mat)));
    inter_tdist(logical(1-(tedge_mat))) = Inf;
    inter_tsim{end} = exp(-inter_tdist/1).*(0.5*finter_ovl + 0.5*binter_ovl);

end


















