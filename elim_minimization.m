%% Initial labels (Nx1)
class_cost = zeros(postnum_sp(1),1);

%% Unary matrix (CxN)
unary_mat = zeros(num_label,postnum_sp(1));
for sp_id = 1:postnum_sp(1)
    if ~ismember(ilabel_list{1}(sp_id),elim_list)
        unary_mat(ilabel_list{1}(sp_id),sp_id) = 1;
    end
end
unary_mat = -log(unary_mat);
unary_mat(unary_mat==Inf) = 10;

%% Pairwise matrix (NxN)
% Assign the same label for connected neighbors
spa_dist = vl_alldist2(postsp_feat{1}','CHI2');
spa_dist(logical(1-postedge_mat{1})) = Inf;
spa_aff = exp(-spa_dist/1);
spa_aff = spa_aff*diag(1./(sum(postedge_mat{1})+eps));

% Mix two affinities
pw_mat = sparse(spa_aff);

%% Label cost (CxC)
label_cost = ones(num_label,num_label);
label_cost = label_cost - eye(num_label);

%% Energy minimization using Graph-cut
[labels, E, Eafter] = GCMex(class_cost, single(unary_mat), 10*double(pw_mat), single(label_cost), 0);

ilabel_list{1} = labels+1;





