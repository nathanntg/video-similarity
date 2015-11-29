function [labels, scores] = sample_image(image, network, txt_labels)

%% CONFIGURATION
% network
[model, weights] = caffe_network(network);

% default labels
if ~exist('txt_labels', 'var') || isempty(txt_labels)
    txt_labels = 'resources/labels.txt';
end

%% SETUP

% configure caffe
caffe.set_mode_cpu();
%caffe.set_device(0);

% create net and load weights
net = caffe.Net(model, weights, 'test');

% cropped image size
net_input_shape = net.blobs('data').shape;
cropped_dim = net_input_shape(1);

%% EXECUTION

% load image
im = imread(image);

% prepare input
input = {prepare_image(im, cropped_dim)};

% run network
output = net.forward(input);

% scores
scores = mean(output{1}, 2);

% load labels
labels = {};
fh = fopen(txt_labels);
while 1
    line = fgetl(fh);
    if ~ischar(line), break, end
    labels{end+1} = line; %#ok<AGROW>
end
fclose(fh);

% print if no output arguments
if 0 == nargout
    % sorted scores
    [sorted_scores, idx] = sort(scores, 'descend');

    % print top five labels
    for i = 1:5
        fprintf('%f\t%s\n', sorted_scores(i), labels{idx(i)});
    end
end

%% CLEAN UP
caffe.reset_all();

end
