%% Build graph
graph_size = sum(num_seg(left_id:right_id));
inter_graph = sparse(graph_size,graph_size);
fward_graph = sparse(graph_size,graph_size);

for frame_id = left_id+1:right_id
    fward_graph(sum(num_seg(left_id:frame_id-1))+1:sum(num_seg(left_id:frame_id)),...
        sum(num_seg(left_id:frame_id-2))+1:sum(num_seg(left_id:frame_id-1))) = 1;
    
    inter_graph(sum(num_seg(left_id:frame_id-2))+1:sum(num_seg(left_id:frame_id-1)),...
        sum(num_seg(left_id:frame_id-1))+1:sum(num_seg(left_id:frame_id))) = sparse(inter_tsim{frame_id});
end

mix_graph = inter_graph;
affinity_mat = mix_graph' + mix_graph;

matching_mat = sparse(graph_size,graph_size);

fward_score = affinity_mat.*fward_graph.*(affinity_mat>0.3);
[max_v, max_i] = max(fward_score,[],1);
for seg_id = 1:graph_size
    if max_v(seg_id) > 0.0
        matching_mat(max_i(seg_id),seg_id) = 1;
    end
end

[m_row, m_col] = find(matching_mat);
ac_label = 1:size(matching_mat,1);
for m_id = 1:length(m_row)
    ac_label(ac_label==ac_label(m_col(m_id))) = ac_label(m_row(m_id));
end

label_list = unique(ac_label);
sqz_label = ac_label;
for l_id = 1:length(label_list)
    sqz_label(ac_label==label_list(l_id)) = l_id;
end
ac_label = sqz_label;

tsp_label = cell(right_id-left_id+1,1);
for frame_id = left_id:right_id
    tsp_label{frame_id-left_id+1} = ac_label(sum(num_seg(left_id:frame_id-1))+1:sum(num_seg(left_id:frame_id)));
end

spac_label = cell(right_id-left_id+1,1);
for frame_id = left_id:right_id
    spac_label{frame_id-left_id+1} = zeros(num_sp(frame_id),1);
    for seg_id = 1:num_seg(frame_id)
        spac_label{frame_id-left_id+1}(seg_sp{frame_id}==seg_id) = tsp_label{frame_id-left_id+1}(seg_id);
    end
end

temp_id = incell_id - left_id + 1;

new_labels = setdiff(spac_label{temp_id},spac_label{max(temp_id-1,1)});
nlabel_splist = ismember(spac_label{temp_id},new_labels);

cagsp_label = spac_label{temp_id};
pagsp_label = spac_label{max(temp_id-1,1)};

cagsp_img = zeros(h_size,w_size);
for sp_id = 1:num_sp(incell_id)
    cagsp_img(sp_cell{incell_id}==sp_id) = spac_label{temp_id}(sp_id);
end














