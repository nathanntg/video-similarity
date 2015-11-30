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
            
            % get mean (prevent loading per frame)
            EV.im_mean = get_mean_image();
            if EV.net_dim ~= size(EV.im_mean, 1)
                EV.im_mean = imresize(EV.im_mean, [EV.net_dim EV.net_dim]);
            end
            
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
            
            % make features
            features = zeros(blob_shape(1), video_shape(end), 'single');
            
            for t = 1:video_shape(end)
                % get frame
                frame = video(:, :, :, t);
                
                % resize frame
                frame = imresize(frame, [EV.net_dim EV.net_dim]);
                
                % prepare frame
                prepared = {prepare_frames(frame, EV.im_mean)};
                
                % process in network
                EV.net.forward(prepared);
                
                % store feature
                features(:, t) = EV.net.blobs(blob_name).get_data();
            end
        end
        
        function match = matchFeatures(EV, features)
            % load video
        end
    end
    
%    methods (Abstract)
%        createMovie(SM, image, eye_x, eye_y)
%    end
end

