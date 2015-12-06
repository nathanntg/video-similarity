%% TEST NETWORKS
sample_image('library/elephant.jpg', 'AlexNet');
sample_image('library/guitar.jpg', 'AlexNet');
sample_image('library/lamp.jpg', 'AlexNet');
sample_image('library/crown.jpg', 'AlexNet');


%% BUILD DATABASE
build_database('./library/youtube/', 'AlexNet', './database/youtube_alexnet.mat');
build_database('./library/youtube/', 'GoogleNet', './database/youtube_googlenet.mat');
build_database('./library/youtube/', 'R-CNN', './database/youtube_rcnn.mat');

%% PRUNE DATABASE
% order
prune_database_order('./database/youtube_alexnet.mat', './database/order/youtube_alexnet.mat');
prune_database_order('./database/youtube_alexnet.mat', './database/order/youtube_alexnet2.mat', '2');
prune_database_order('./database/youtube_googlenet.mat', './database/order/youtube_googlenet.mat');
prune_database_order('./database/youtube_googlenet.mat', './database/order/youtube_googlenet2.mat', '2');
prune_database_order('./database/youtube_rcnn.mat', './database/order/youtube_rcnn.mat');
prune_database_order('./database/youtube_rcnn.mat', './database/order/youtube_rcnn2.mat', '2');

% order
prune_database_distance('./database/youtube_alexnet.mat', './database/distance/youtube_alexnet.mat');
prune_database_distance('./database/youtube_alexnet.mat', './database/distance/youtube_alexnet2.mat', '2');
prune_database_distance('./database/youtube_googlenet.mat', './database/distance/youtube_googlenet.mat');
prune_database_distance('./database/youtube_googlenet.mat', './database/distance/youtube_googlenet2.mat', '2');
prune_database_distance('./database/youtube_rcnn.mat', './database/distance/youtube_rcnn.mat');
prune_database_distance('./database/youtube_rcnn.mat', './database/distance/youtube_rcnn2.mat', '2');

%% DISTRIBUTION OF DISTANCES
% save distances figure
d = load('./database/youtube_rcnn.mat', 'data_distances');
d = d.data_distances;
hist(d, linspace(0, quantile(d, 0.999), 100));
xlim([0 quantile(d, 0.998)]);
xlabel('Distance between feature vectors');
saveTightFigure('./database/distance/youtube_rcnn.png');

% save distances figure
d = load('./database/youtube_rcnn.mat', 'data_distances2');
d = d.data_distances2;
hist(d, linspace(0, quantile(d, 0.999), 100));
xlim([0 quantile(d, 0.998)]);
xlabel('Distance between feature vectors');
saveTightFigure('./database/distance/youtube_rcnn2.png');

%% DEBUG EVALUATOR
video = video_read('./library/youtube/0ch-eJoT9IM.mp4', 60);

e = EvaluatorOrder('GoogleNet', './database/order/youtube_googlenet.mat');
features = e.processVideo(video);
pruned_features = e.pruneFeatures(features);
[match, score] = e.matchFeatures(pruned_features);
disp(match);
disp(score);

e = EvaluatorDistance('GoogleNet', './database/distance/youtube_googlenet.mat');
features = e.processVideo(video);
pruned_features = e.pruneFeatures(features);
[match, score] = e.matchFeatures(pruned_features);
disp(match);
disp(score);

%% BUILD DEFORMED COLLECTION
directory_videos = './library/youtube/';
directory_deformed = './library/deformed/';
build_deformed_many(directory_videos, directory_deformed, 'crop-horizontal', {0.15 0.3 0.45 0.6});
build_deformed_many(directory_videos, directory_deformed, 'resize', {0.5 0.25 0.125});
build_deformed_many(directory_videos, directory_deformed, 'rotate', {15 30 45 60 75 90});
build_deformed_many(directory_videos, directory_deformed, 'color', {0.1 0.2 0.3});
build_deformed_many(directory_videos, directory_deformed, 'encode', {'mj2' 'avi'});
build_deformed_many(directory_videos, directory_deformed, 'bw');

