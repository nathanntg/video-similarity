function prune_database_distance(full_db, pruned_db, suffix)
%PRUNE_DATABASE_DISTANCE Summary of this function goes here
%   This is the first of two pruned database formats used by the video
%   similarity project. This database format preserves features based on
%   distance from the prior last feature identified in the video.

% default to no suffix
if ~exist('suffix', 'var') || isempty(suffix)
    suffix = '';
end

% load database
db = load(full_db, 'videos', 'data_video_ids', 'data_timestamps', 'data_frame_ids', ['data_features' suffix], ['data_distances' suffix]);

% extract values of interest
videos = db.videos; %#ok<NASGU>
data_video_ids = db.data_video_ids;
data_frame_ids = db.data_frame_ids;
data_timestamps = db.data_timestamps;
data_features = db.(['data_features' suffix]);
data_distances = db.(['data_distances' suffix]);
%clear db;

% estimate frames per second
starts = (data_timestamps == 0);
ends = [starts(2:end) true];
total_duration = sum(data_timestamps(ends));
%frames_per_second = length(data_timestamps) / total_duration;

approx_features_per_second = 2 + 0.5; % half extra for safe keeping
approx_features = total_duration * approx_features_per_second;

% get sorted
sorted = sort(data_distances, 'descend');
threshold = sorted(round(approx_features));

% save those that have a distance above the threshold and those that are 
% the starts of videos
to_save = data_distances > threshold | data_timestamps == 0;

% make new data features
data_video_ids = data_video_ids(to_save); %#ok<NASGU>
data_frame_ids = data_frame_ids(to_save); %#ok<NASGU>
data_timestamps = data_timestamps(to_save); %#ok<NASGU>
data_features = data_features(:, to_save); %#ok<NASGU>
data_distances = data_distances(to_save); %#ok<NASGU>

% save
save(pruned_db, '-v7.3', 'videos', 'data_video_ids', 'data_frame_ids', 'data_timestamps', 'data_features', 'data_distances', 'threshold');

end

