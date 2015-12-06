classdef Evaluator
    %EVALUATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=protected)
        % network information
        net
        net_nm
        net_dim
        
        % mean
        im_mean
        
        % layer
        layer
        
        % database
        db
        
        % batch size
        batch_size = 30;
    end
    
    methods
        function EV = Evaluator(network, database, layer)
            % store network name
            EV.net_nm = network;
            
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
        
        function features = cacheProcessVideoFile(EV, video_file)
            % file parts
            [d, f, ~] = fileparts(video_file);
                
            % field name
            fld_nm = sprintf('%s_%d', strrep(EV.net_nm, '-', ''), EV.layer);
            
            % cache file
            cache_file = fullfile(d, [f '.mat']);
            
            if exist(cache_file, 'file')
                % load cache file into structure
                s = load(cache_file);
                
                % found?
                if isfield(s, fld_nm)
                    features = s.(fld_nm);
                    return;
                end
            else
                s = struct();
            end
            
            % calculate features
            video = video_read(video_file);
            
            % extract features
            % layer name
            blob0_name = EV.net.blob_names{end};
            blob1_name = EV.net.blob_names{end - 1};
            
            % shape
            blob0_shape = EV.net.blobs(blob0_name).shape;
            blob1_shape = EV.net.blobs(blob1_name).shape;
            
            % video shape
            video_shape = size(video);
            
            % make batch
            batch = zeros(EV.net_dim, EV.net_dim, 3, EV.batch_size);
            
            % make features
            features0 = zeros(blob0_shape(1), video_shape(end), 'single');
            features1 = zeros(blob1_shape(1), video_shape(end), 'single');
            
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
                output = EV.net.blobs(blob0_name).get_data();
                features0(:, t_start:min(t_end, video_shape(end))) = output(:, 1:(1 + min(t_end, video_shape(end)) - t_start));
                
                output = EV.net.blobs(blob1_name).get_data();
                features1(:, t_start:min(t_end, video_shape(end))) = output(:, 1:(1 + min(t_end, video_shape(end)) - t_start));
            end
            
            % add to cache
            s.(sprintf('%s_%d', strrep(EV.net_nm, '-', ''), 0)) = features0;
            s.(sprintf('%s_%d', strrep(EV.net_nm, '-', ''), 1)) = features1;
            
            % update cache
            save(cache_file, '-v7.3', '-struct', 's');
            
            % features to return
            features = s.(fld_nm);
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
        
        function [match, score] = matchVideo(EV, video)
            features = EV.processVideo(video);
            features = EV.pruneFeatures(features);
            [match, score] = EV.matchFeatures(features);
        end
        
        function [match, score] = matchVideoFile(EV, video_file)
            features = EV.cacheProcessVideoFile(video_file);
            features = EV.pruneFeatures(features);
            [match, score] = EV.matchFeatures(features);
        end
    end
    
   methods (Abstract)
       pruned_features = pruneFeatures(EV, features)
       [match, score] = matchFeatures(EV, pruned_features)
   end
end

