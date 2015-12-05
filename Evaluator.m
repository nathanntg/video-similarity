classdef Evaluator
    %EVALUATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=protected)
        % network information
        net
        net_dim
        
        % mean
        im_mean
        
        % layer
        layer
        
        % database
        db
        
        % max duration
        max_duration = 60;
        
        % batch size
        batch_size = 30;
    end
    
    methods
        function EV = Evaluator(network, database, layer)
            % network
            [model, weights] = caffe_network(network);

            % configure caffe
            caffe.set_mode_cpu();

            % create net and load weights
            EV.net = caffe.Net(model, weights, 'test');

            % cropped image size
            net_input_shape = EV.net.blobs('data').shape;
            EV.net_dim = net_input_shape(1);
            EV.net.blobs('data').reshape([net_input_shape(1:(end - 1)) EV.batch_size]);
            
            % get mean (prevent loading per frame)
            EV.im_mean = get_mean_image();
            if EV.net_dim ~= size(EV.im_mean, 1)
                EV.im_mean = imresize(EV.im_mean, [EV.net_dim EV.net_dim]);
            end
            EV.im_mean = repmat(EV.im_mean, 1, 1, 1, EV.batch_size);
            
            % database
            EV.db = load(database);
            
            % check layer
            if ~exist('layer', 'var') || isempty(layer)
                EV.layer = 0;
            else
                EV.layer = layer - 1;
            end
        end
        
        function delete(EV)
            caffe.reset_all();
        end
        
        function video = loadVideo(EV, video_file)
            % open video reader
            vh = VideoReader(video_file);
            
            % store frames
            frames = {};
            
            % had frame
            while hasFrame(vh)
                % too long
                if EV.max_duration > 0 && vh.CurrentTime > EV.max_duration
                    break
                end
                
                % read frame
                frame = readFrame(vh);
                
                % add frame
                frames{end + 1} = frame; %#ok<AGROW>
            end
            
            % turn into a video
            video = cat(1 + ndims(frames{1}), frames{:});
        end
        
        function features = processVideo(EV, video)
            % layer name
            blob_name = EV.net.blob_names{end - EV.layer};
            
            % shape
            blob_shape = EV.net.blobs(blob_name).shape;
            
            % video shape
            video_shape = size(video);
            
            % make batch
            batch = zeros(EV.net_dim, EV.net_dim, 3, EV.batch_size);
            
            % make features
            features = zeros(blob_shape(1), video_shape(end), 'single');
            
            for t_start = 1:EV.batch_size:video_shape(end)
                t_end = t_start + EV.batch_size - 1;
                for i = 1:EV.batch_size
                    t = t_start + i - 1;
                    if t > video_shape(end)
                        % zero (batch longer than end of video)
                        batch(:, :, :, i) = zeros(EV.net_dim, EV.net_dim, 3);
                    else
                        % resize frame
                        batch(:, :, :, i) = imresize(video(:, :, :, t), [EV.net_dim EV.net_dim]);
                    end
                end
                
                % prepare input
                input = {prepare_frames(batch, EV.im_mean)};
                
                % process in network
                EV.net.forward(input);
                
                % store feature
                output = EV.net.blobs(blob_name).get_data();
                features(:, t_start:min(t_end, video_shape(end))) = output(:, 1:(1 + min(t_end, video_shape(end)) - t_start));
            end
        end
    end
    
   methods (Abstract)
       pruned_features = pruneFeatures(SM, features)
       [match, score] = matchFeatures(SM, features)
   end
end

