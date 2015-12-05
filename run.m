%% TEST NETWORKS
sample_image('library/elephant.jpg', 'GoogleNet');


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
e = EvaluatorOrder('GoogleNet', './database/order/youtube_googlenet.mat');
video = e.loadVideo('./library/youtube/0ch-eJoT9IM.mp4');
features = e.processVideo(video);
pruned_features = e.pruneFeatures(features);
[match, score] = e.matchFeatures(pruned_features);