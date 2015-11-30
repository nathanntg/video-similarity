function build_database(directory, network, database, max_duration)

%% CONFIGURATION
% load network
[model, weights] = caffe_network(network);

% max duration
if ~exist('max_duration', 'var') || isempty(max_duration)
    max_duration = 60;
end

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

% second to last layer
second_to_last_layer = net.blob_names{end-1};

% get mean (prevent loading per frame)
im_mean = get_mean_image();
if network_dim ~= size(im_mean, 1)
    im_mean = imresize(im_mean, [network_dim network_dim]);
end
im_mean = repmat(im_mean, 1, 1, 1, batch_size);

%% EXECUTION

% get videos
videos = dir(fullfile(directory, '*.mp4'));
videos = {videos(:).name};

% data
data_video_ids = [];
data_frame_ids = [];
data_timestamps = [];
data_features = single([]);
data_distances = single([]);
data_features2 = single([]);
data_distances2 = single([]);

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
    all_scores2 = {};
    all_times = [];
    
    % process video in batches of frames
    while true
        % stop after a minute
        if max_duration > 0 && max_duration < vh.CurrentTime
            break
        end
        
        % load batch of frames
        batch = cell(1, batch_size);
        i = 1;
        while hasFrame(vh) && i <= batch_size
            % read frames
            tic;
            all_times(end + 1) = vh.CurrentTime; %#ok<AGROW>
            frame = readFrame(vh);
            tm_frame = tm_frame + toc;
            
            % add to batch
            batch{i} = imresize(frame, [network_dim network_dim]);
            i = i + 1;
        end
        
        % current batch size
        cur_batch_size = i - 1;
        
        % handle partial batches
        if 0 == cur_batch_size % no frames, done
            break
        elseif cur_batch_size < batch_size % smaller batch, pad with zeros
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
        
        % SCORES FROM LAST LAYER
        
        % scores
        scores = output{1};
        if cur_batch_size < batch_size
            scores = scores(:, 1:cur_batch_size);
        end
        
        % append to scores
        all_scores{end + 1} = scores; %#ok<AGROW>
        
        % SCORES FROM SECOND TO LAST LAYER (pre-softmax)
        
        % get second to last layer scores
        scores2 = net.blobs(second_to_last_layer).get_data();
        if cur_batch_size < batch_size
            scores2 = scores2(:, 1:cur_batch_size);
        end
        
        % append to scores
        all_scores2{end + 1} = scores2; %#ok<AGROW>
    end
    
    % concatenate all scores together
    all_scores = cat(2, all_scores{:});
    all_scores2 = cat(2, all_scores2{:});
    
    % get distances
    distances = sqrt(mean(diff(all_scores, 1, 2) .^ 2, 1));
    distances2 = sqrt(mean(diff(all_scores2, 1, 2) .^ 2, 1));
    
    % append video id
    data_video_ids = [data_video_ids (video_id * ones(size(all_times)))]; %#ok<AGROW>
    data_frame_ids = [data_frame_ids 1:length(all_times)]; %#ok<AGROW>
    data_timestamps = [data_timestamps all_times]; %#ok<AGROW>
    data_features = [data_features all_scores]; %#ok<AGROW>
    data_distances = [data_distances nan distances]; %#ok<AGROW>
    data_features2 = [data_features2 all_scores2]; %#ok<AGROW>
    data_distances2 = [data_distances2 nan distances2]; %#ok<AGROW>
end

% save
save(database, '-v7.3', 'videos', 'data_video_ids', 'data_frame_ids', 'data_timestamps', 'data_features', 'data_distances', 'data_features2', 'data_distances2');

%% CLEAN UP
caffe.reset_all();

end
