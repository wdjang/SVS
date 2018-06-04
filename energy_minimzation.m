%% Label warping
bwarp_label = ilabel_img{end-1}(bwarp_list{incell_id});
fwarp_label = cagsp_img(fwarp_list{incell_id-1});

%% Matching between from short-term segments to resultant segments at the previous frame
% Short-term segments
st_list = unique(cagsp_label);
num_st = length(st_list);
% Resultant segments
rs_list = unique(ilabel_list{end-1});
num_rs = length(rs_list);
% Overlap computation
rs_ovlmat = zeros(num_rs,num_st);
for rs_id = 1:num_rs
    if length(st_list) == 1
        warp_hist = sum(fwarp_label(ilabel_img{end-1}==rs_list(rs_id)));
    else
        warp_hist = hist(fwarp_label(ilabel_img{end-1}==rs_list(rs_id)),st_list');
    end
    rs_ovlmat(rs_id,:) = warp_hist / max(warp_hist);
end
st_ovlmat = zeros(num_rs,num_st);
for st_id = 1:num_st
    if length(rs_list) == 1
        warp_hist = sum(bwarp_label(cagsp_img==st_list(st_id)));
    else
        warp_hist = hist(bwarp_label(cagsp_img==st_list(st_id)),rs_list');
    end
    st_ovlmat(:,st_id) = warp_hist / max(warp_hist);
end
strs_ovlmat = 0.5*st_ovlmat + 0.5*rs_ovlmat;
% Edge construction
strs_edgemat = strs_ovlmat > 0;
% Lab feature extraction
stlab_hist = zeros(num_st,60);  
for st_id = 1:num_st
    stlab_hist(st_id,1:20)  = hist(l_img{incell_id}(cagsp_img==st_list(st_id)),2.5:5:100);
    stlab_hist(st_id,21:40) = hist(a_img{incell_id}(cagsp_img==st_list(st_id)),-95:10:100);
    stlab_hist(st_id,41:60) = hist(b_img{incell_id}(cagsp_img==st_list(st_id)),-95:10:100);
    stlab_hist(st_id,:)     = stlab_hist(st_id,:)/sqrt(sum(stlab_hist(st_id,:).^2));
end
rslab_hist = zeros(num_rs,60);
for rs_id = 1:num_rs
    rslab_hist(rs_id,1:20)  = hist(l_img{incell_id-1}(ilabel_img{end-1}==rs_list(rs_id)),2.5:5:100);
    rslab_hist(rs_id,21:40) = hist(a_img{incell_id-1}(ilabel_img{end-1}==rs_list(rs_id)),-95:10:100);
    rslab_hist(rs_id,41:60) = hist(b_img{incell_id-1}(ilabel_img{end-1}==rs_list(rs_id)),-95:10:100);
    rslab_hist(rs_id,:)     = rslab_hist(rs_id,:)/sqrt(sum(rslab_hist(rs_id,:).^2));
end

% Histogram construction
stlabbw_hist = zeros(num_st,param.lab_numw);
strgbbw_hist = zeros(num_st,param.rgb_numw);
for st_id = 1:num_st
    stlabbw_hist(st_id,:) = hist(labenc_cell{incell_id}(cagsp_img==st_list(st_id)),1:param.lab_numw);
    stlabbw_hist(st_id,:) = stlabbw_hist(st_id,:)/sqrt(sum(stlabbw_hist(st_id,:).^2));
    strgbbw_hist(st_id,:) = hist(rgbenc_cell{incell_id}(cagsp_img==st_list(st_id)),1:param.rgb_numw);
    strgbbw_hist(st_id,:) = strgbbw_hist(st_id,:)/sqrt(sum(strgbbw_hist(st_id,:).^2));
end
% Histogram construction
rslabbw_hist = zeros(num_rs,param.lab_numw);
rsrgbbw_hist = zeros(num_rs,param.rgb_numw);
for rs_id = 1:num_rs
    rslabbw_hist(rs_id,:) = hist(labenc_cell{incell_id-1}(ilabel_img{end-1}==rs_list(rs_id)),1:param.lab_numw);
    rslabbw_hist(rs_id,:) = rslabbw_hist(rs_id,:)/sqrt(sum(rslabbw_hist(rs_id,:).^2));
    rsrgbbw_hist(rs_id,:) = hist(rgbenc_cell{incell_id-1}(ilabel_img{end-1}==rs_list(rs_id)),1:param.rgb_numw);
    rsrgbbw_hist(rs_id,:) = rsrgbbw_hist(rs_id,:)/sqrt(sum(rsrgbbw_hist(rs_id,:).^2));
end

st_feat = [stlab_hist, 0.75*stlabbw_hist, 0.75*strgbbw_hist];
for st_id = 1:num_st
    st_feat(st_id,:) = st_feat(st_id,:)/sqrt(sum(st_feat(st_id,:).^2));
end
rs_feat = [rslab_hist, 0.75*rslabbw_hist, 0.75*rsrgbbw_hist];
for rs_id = 1:num_rs
    rs_feat(rs_id,:) = rs_feat(rs_id,:)/sqrt(sum(rs_feat(rs_id,:).^2));
end

strs_labdist = vl_alldist2(rs_feat',st_feat','CHI2');
strs_labdist = strs_labdist / max(strs_labdist(strs_edgemat));
strs_labdist(logical(1-strs_edgemat)) = Inf;
% Lab affinity computation
strs_labaff = exp(-strs_labdist);
% Lab affinity and overlap combination
strs_aff = strs_labaff.*strs_ovlmat;
% Matching matrix
strs_matchmat = zeros(num_rs,num_st);
% Find matching
[max_v, max_i] = max(strs_aff,[],1);
for st_id = 1:num_st
    if max_v(st_id) > 0.5
        strs_matchmat(max_i(st_id),st_id) = 1;
    end
end
% Find occlusion short-term segments
occ_list = find(sum(strs_matchmat)==0);
stocc_list = st_list(occ_list);
% Superpixel occlusion annotation
occ_vector = ismember(cagsp_label,stocc_list);
% Number of labels
num_label = max_label + length(stocc_list);

% Resultant segment unary term
plab_hist = zeros(60,1);
% Backward warping error
bwarp_aff = zeros(num_sp(incell_id),1);
for sp_id = 1:num_sp(incell_id)
    plab_hist(1:20)    = hist(l_img{incell_id-1}(bwarp_list{incell_id}(sp_cell{incell_id}==sp_id)),2.5:5:100);
    plab_hist(21:40)   = hist(a_img{incell_id-1}(bwarp_list{incell_id}(sp_cell{incell_id}==sp_id)),-95:10:100);
    plab_hist(41:60)   = hist(b_img{incell_id-1}(bwarp_list{incell_id}(sp_cell{incell_id}==sp_id)),-95:10:100);
    plab_hist          = plab_hist/sqrt(sum(plab_hist.^2));
    blab_dist = vl_alldist2(labcon_hist{incell_id}(sp_id,:)',plab_hist,'CHI2');
    bwarp_aff(sp_id) = exp(-blab_dist);
end
rsunary_mat = zeros(num_label,num_sp(incell_id));
for sp_id = 1:num_sp(incell_id)
    warp_hist = hist(bwarp_label(sp_cell{incell_id} == sp_id),1:num_label);
    warp_hist = warp_hist/max(warp_hist);
    rsunary_mat(:,sp_id) = warp_hist*bwarp_aff(sp_id);
end
% Short-term unary term
stunary_mat = zeros(num_label,num_sp(incell_id));
for sp_id = 1:num_sp(incell_id)
    if occ_vector(sp_id)
        stunary_mat(max_label+find(stocc_list==cagsp_label(sp_id)),sp_id) = 1;%1
    else
        st_id = find(st_list==cagsp_label(sp_id));
        stunary_mat(rs_list,sp_id) = strs_aff(:,st_id);
    end
end
% unary term
unary_ratio = 0.5;
prob_mat = unary_ratio*stunary_mat+(1-unary_ratio)*rsunary_mat;
prob_mat = prob_mat*diag(1./sum(prob_mat));
unary_mat = -log(prob_mat);
unary_mat(unary_mat==Inf) = 10;

%% Initial labels (Nx1)
class_cost = zeros(num_sp(incell_id),1);

%% Pairwise matrix (NxN)
% Assign the same label for connected neighbors
spa_dist = vl_alldist2(sp_feat{incell_id}','CHI2');
spa_dist = spa_dist.*edge_mat{incell_id};
spa_dist(logical(1-edge_mat{incell_id})) = Inf;
spa_aff = exp(-spa_dist/1);
spa_aff = spa_aff*diag(1./(sum(edge_mat{incell_id})+eps));
% Mix two affinities
pw_mat = sparse(spa_aff);

%% Label cost (CxC)
label_cost = ones(num_label,num_label);
label_cost = label_cost - eye(num_label);

%% Energy minimization using Graph-cut
[labels, E, Eafter] = GCMex(class_cost, single(unary_mat), 10*double(pw_mat), single(label_cost), 0);
labels = labels + 1;
ilabel_list{end} = labels;






















