function prune_database_order(full_db, pruned_db, suffix)
%PRUNE_DATABASE_ORDER Summary of this function goes here
%   Detailed explanation goes here

% default to no suffix
if ~exist('suffix', 'var') || isempty(suffix)
    suffix = '';
end

% load database
db = load(full_db, 'videos', 'data_video_ids', 'data_timestamps', 'data_frame_ids', ['data_features' suffix]);

% extract values of interest
videos = db.videos; %#ok<NASGU>
data_video_ids = db.data_video_ids;
data_frame_ids = db.data_frame_ids;
data_timestamps = db.data_timestamps;
data_features = db.(['data_features' suffix]);
%clear db;

% create new data features that represents sorted list
data_features_order = zeros(size(data_features), 'uint16');
for i = 1:size(data_features, 2)
    [~, data_features_order(:, i)] = sort(data_features(:, i), 'descend');
end

% estimate frames per second
starts = (data_timestamps == 0);
ends = [starts(2:end) true];
total_duration = sum(data_timestamps(ends));
%frames_per_second = length(data_timestamps) / total_duration;

approx_features_per_second = 2 + 1; % one extra for safe keeping
approx_features = total_duration * approx_features_per_second;

% number of orders to preserve
for n = 3:size(data_features, 1)
    data_features_order_top = data_features_order(1:n, :);
    
    % frames unlike the rest
    unlike = any(data_features_order_top(:, 1:(end - 1)) ~= data_features_order_top(:, 2:end), 1);
    
    % enough?
    if sum(unlike) >= approx_features
        break
    end
end

% save those that are unlike the previous entries and those that are the
% starts of videos
to_save = [true unlike] | (data_timestamps == 0);

% make new data features
data_video_ids = data_video_ids(to_save); %#ok<NASGU>
data_frame_ids = data_frame_ids(to_save); %#ok<NASGU>
data_timestamps = data_timestamps(to_save); %#ok<NASGU>
data_features = data_features_order_top(:, to_save); %#ok<NASGU>

% save
save(pruned_db, '-v7.3', 'videos', 'data_video_ids', 'data_frame_ids', 'data_timestamps', 'data_features');

end

