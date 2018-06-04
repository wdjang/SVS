function ac_label = agglomerative_function(dist_mat, param_threshold)
	num_sp = size(dist_mat,1);
    ac_label = 1:num_sp;
    while 1
        % Find a pair of clusters of the minimum distance
        [min_val, min_id] = min(dist_mat(:));
        if min_val > param_threshold
            break;
        end
        [i_id, j_id] = ind2sub(size(dist_mat),min_id);

        % Distance computation
        new_dist = min(dist_mat(i_id,:), dist_mat(j_id,:));

        new_dist(i_id) = Inf;
        new_dist(j_id) = Inf;
        
        % Distance update
        dist_mat(i_id,:) = new_dist;
        dist_mat(:,i_id) = new_dist';
        
        dist_mat(j_id,:) = Inf;
        dist_mat(:,j_id) = Inf;
        
        % Labeling update
        ac_label(ac_label==i_id) = i_id;
        ac_label(ac_label==j_id) = i_id;
        
    end
end