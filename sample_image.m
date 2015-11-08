%% CONFIGURATION
% network
[model, weights] = caffe_network('GoogleNet');

% videos
directory = '';

%% SETUP

% configure caffe
caffe.set_mode_cpu();

% create net and load weights
net = caffe.Net(model, weights, 'test');

% cropped image size
net_input_shape = net.blobs('data').shape;
cropped_dim = net_input_shape(1);

%% EXECUTION

% load image
im = imread('library/elephant.jpg');

% prepare input
input = {prepare_image(im, cropped_dim)};

% run network
output = net.forward(input);

% scores
scores = mean(output{1}, 2);

% sorted scores
[sorted_scores, idx] = sort(scores, 'descend');

% load labels
labels = {};
fh = fopen('resources/labels.txt');
while 1
    line = fgetl(fh);
    if ~ischar(line), break, end
    labels{end+1} = line; %#ok<SAGROW>
end
fclose(fh);

% print top five labels
for i = 1:5
    fprintf('%f\t%s\n', sorted_scores(i), labels{idx(i)});
end

%% CLEAN UP
caffe.reset_all();