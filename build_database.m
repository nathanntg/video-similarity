%% CONFIGURATION
% network
[model, weights] = caffe_network('AlexNet');

% videos
directory = './library/explore/';

%% SETUP

% batch size (frames are processed in batches)
batch_size = 30;

% configure caffe
caffe.set_mode_gpu();
caffe.set_device(0);

% create net and load weights
net = caffe.Net(model, weights, 'test');

% cropped image size
net_input_shape = net.blobs('data').shape;
network_dim = net_input_shape(1);
net.blobs('data').reshape([net_input_shape(1:(end - 1)) batch_size]);

% get mean (prevent loading per frame)
d = load('~/Development/caffe-master/matlab/+caffe/imagenet/ilsvrc_2012_mean.mat');
im_mean = d.mean_data;
if network_dim ~= size(im_mean, 1)
    im_mean = imresize(im_mean, [network_dim network_dim]);
end
im_mean = repmat(im_mean, 1, 1, 1, batch_size);

%% EXECUTION

% get videos
videos = dir(fullfile(directory, '*.mov'));
videos = {videos(:).name};

% data
video_ids = [];
frame_ids = [];
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
    
    vh = VideoReader(fullfile(directory, fn)); %#ok<TNMLP>
    
    % all scores (for all frames)
    all_scores = {};
    all_times = {};
    
    % process video in batches of frames
    while true
        % load batch of frames
        batch = cell(1, batch_size);
        i = 1;
        while hasFrame(vh) && i <= batch_size
            % read frames
            tic;
            all_times{end + 1} = vh.CurrentTime;  %#ok<SAGROW>
            frame = readFrame(vh);
            tm_frame = tm_frame + toc;
            
            % add to batch
            batch{i} = imresize(frame, [network_dim network_dim]);
            i = i + 1;
        end
        
        % current batch size
        cur_batch_size = i - 1;
        
        % handle partial batches
        if 1 == i % no frames, done
            break
        elseif i <= batch_size % smaller batch, pad with zeros
            while i <= batch_size
                batch{i} = zeros([network_dim network_dim 3], 'like', batch{1});
                i = i + 1;
            end
        end
        
        % prepare inputs
        tic;
        im = prepare_frames(cat(4, batch{:}), im_mean);
        input = {im};
        tm_prepare = tm_prepare + toc;
        
        % run network
        tic;
        output = net.forward(input);
        tm_network = tm_network + toc;
        
        % scores
        scores = output{1};
        if cur_batch_size < batch_size
            scores = scores(:, 1:cur_batch_size);
        end
        
        % append to scores
        all_scores{end + 1} = scores; %#ok<SAGROW>
    end
    
    % concatenate all scores together
    all_scores = cat(2, all_scores{:});
    
    break;
end

%% CLEAN UP
caffe.reset_all();
