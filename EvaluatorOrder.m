classdef EvaluatorOrder < Evaluator
    %EVALUATORORDER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        max_partials = 5;
    end
    
    methods
        function EV = EvaluatorOrder(network, database, layer)
            if ~exist('layer', 'var')
                layer = [];
            end
            
            EV@Evaluator(network, database, layer);
        end
        
        function pruned_features = pruneFeatures(EV, features)
            % get number of features
            num = size(EV.db.data_features, 1);
            
            % get feature order
            features_order = zeros(3, size(features, 2), 'uint16');
            for i = 1:size(features, 2)
                [~, ord] = sort(features(:, i), 'descend');
                features_order(1:num, i) = ord(1:num);
            end
            
            % prune features
            unlike = any(features_order(:, 1:(end - 1)) ~= features_order(:, 2:end), 1);
            pruned_features = features_order(:, [true unlike]);
        end
        
        function [match, score] = matchFeatures(EV, pruned_features)
            % get index
            idx = ismember(EV.db.data_features', pruned_features(:, 1)', 'rows');
            
            % no match
            if ~any(idx)
                if size(pruned_features, 2) > 1
                    % match remaining features
                    [match, score] = EV.matchFeatures(pruned_features(:, 2:end));
                    
                    % correctly normalize score by true number of features
                    % (to reflect partial match)
                    score = score * ((size(pruned_features, 2) - 1) / size(pruned_features, 2));
                else
                    match = [];
                    score = 0;
                end
                return
            end
            
            % start of all matching segments
            match_starts = find(idx);
            
            % matches
            matches_video_id = zeros(1, length(match_starts));
            matches_timestamp = zeros(1, length(match_starts));
            matches_scores = nan(1, length(match_starts));
            
            % list of matches
            for i = 1:length(match_starts)
                % score number of matching frames
                score = 1; % exact match
                
                % start
                match_start = match_starts(i);
                
                % get remaining video frames
                cur_video_id = EV.db.data_video_ids(match_start);
                
                % already processed
                if ismember(cur_video_id, matches_video_id)
                    continue;
                end
                
                % get remaining frames
                remaining_frames = sum(EV.db.data_video_ids((match_start+1):end) == cur_video_id);
                
                % score remaining frames
                if 0 < remaining_frames
                    remaining_features = EV.db.data_features(:, (match_start + 1):(match_start + remaining_frames));
                    score = score + EV.matchRemainingFeatures(pruned_features(:, 2:end), remaining_features, 1 + EV.max_partials);
                end
                
                % store match
                matches_video_id(i) = cur_video_id;
                matches_timestamp(i) = EV.db.data_timestamps(match_start);
                matches_scores(i) = score;
            end
            
            % get best match
            [score, idx] = max(matches_scores);
            
            % normalize best score
            score = score / size(pruned_features, 2);
            
            % make match structure
            match = struct('video', EV.db.videos(matches_video_id(idx)), 'video_id', matches_video_id(idx), 'timestamp', matches_timestamp(idx));
        end
    end
    
    methods (Access=protected)
        function score = matchRemainingFeatures(EV, remaining_pruned_features, remaining_video_features, remaining_partials)
            score = 0;
            
            % no more remaining
            if isempty(remaining_pruned_features) || isempty(remaining_video_features) || 0 == remaining_partials
                return;
            end
            
            % next feature
            f = remaining_pruned_features(:, 1);
            
            % remaining features
            remaining_pruned_features = remaining_pruned_features(:, 2:end);
            
            % scoring for feature correspondence
            num = size(EV.db.data_features, 1);
            f_match = (num:-1:1) ./ ((num * (num + 1)) / 2);
            
            % check each frame
            for i = 1:size(remaining_video_features, 2)
                % get current score
                cur_score = sum(f_match(remaining_video_features(:, i) == f));
                
                % exact match
                if 0.9999 <= cur_score
                    % match remaining frames
                    score = score + cur_score;
                    
                    % end of video?
                    if isempty(remaining_pruned_features)
                        return;
                    end
                    
                    % advance feature
                    f = remaining_pruned_features(:, 1);
                    remaining_pruned_features = remaining_pruned_features(:, 2:end);
                    
                    continue;
                end
                
                % no match
                if 0 == cur_score
                    continue;
                end
                
                % partial match
                if remaining_partials > 0
                    remaining_partials = remaining_partials - 1;
                else
                    break;
                end
                
                % match remaining frames
                cur_score = cur_score + EV.matchRemainingFeatures(remaining_pruned_features, remaining_video_features(:, (i+1):end), remaining_partials);
                
                score = max(score, cur_score);
            end
        end
    end
end

