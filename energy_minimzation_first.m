%% Preliminaries
temp_list = cagsp_label;
label_list = unique(temp_list);
sqz_label = temp_list;
for l_id = 1:length(label_list)
    sqz_label(temp_list==label_list(l_id)) = l_id;
end
cagsp_label = sqz_label;

num_label = max(cagsp_label);

%% Initial labels (Nx1)
class_cost = zeros(num_sp(incell_id),1);

%% Unary matrix (CxN)
unary_mat = zeros(num_label,num_sp(incell_id));
for sp_id = 1:num_sp(incell_id)
    unary_mat(cagsp_label(sp_id),sp_id) = 1;
end
unary_mat = -log(unary_mat);
unary_mat(unary_mat==Inf) = 10;

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

label_list = unique(labels);
sqz_label = labels;
for l_id = 1:length(label_list)
    sqz_label(labels==label_list(l_id)) = l_id;
end
ilabel_list{end} = sqz_label;

