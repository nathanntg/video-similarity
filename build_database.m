%% CONFIGURATION
% network
[model, weights] = caffe_network('AlexNet');

% videos
directory = './library/explore/';

%% SETUP

% configure caffe
caffe.set_mode_cpu();

% create net and load weights
net = caffe.Net(model, weights, 'test');

% cropped image size
net_input_shape = net.blobs('data').shape;
cropped_dim = net_input_shape(1);

% get mean (prevent loading per frame)
d = load('~/Development/caffe-master/matlab/+caffe/imagenet/ilsvrc_2012_mean.mat');
im_mean = d.mean_data;

%% EXECUTION

% get videos
videos = dir(fullfile(directory, '*.mov'));
videos = {videos(:).name};

% data
video_ids = [];
timestamps = [];
features = [];
distances = [];

% profile
tm_frame = 0;
tm_prepare = 0;
tm_network = 0;

for video_id = 1:length(videos)
    % progress
    fprintf('Processing %d of %d...\n', video_id, length(videos));
    
    % file name
    fn = videos{video_id};
    
    last = [];
    
    vh = VideoReader(fullfile(directory, fn)); %#ok<TNMLP>
    while hasFrame(vh)
        tic;
        frame = readFrame(vh);
        tm_frame = tm_frame + toc;
        
        imshow(frame);
        
        % prepare input
        tic;
        input = {prepare_image(frame, cropped_dim, [], im_mean)};
        tm_prepare = tm_prepare + toc;
        
        % run network
        tic;
        output = net.forward(input);
        tm_network = tm_network + toc;
        
        % scores
        scores = mean(output{1}, 2);
        
        % should append feature?
        if isempty(last)
            append = true;
        else
            distance = sqrt(sum((last - scores) .^ 2));
            append = (distance > 0);
            distances(end + 1) = distance;
        end
        
        % should append
        if append
            video_ids(end + 1) = video_id; %#ok<SAGROW>
            timestamps(end + 1) = vh.CurrentTime; %#ok<SAGROW>
            features(end + 1, :) = scores; %#ok<SAGROW>
        end
        
        % rotate scores
        last = scores;
    end
    
    break
end

%% CLEAN UP
caffe.reset_all();
