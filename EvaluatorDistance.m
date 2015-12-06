classdef EvaluatorDistance < Evaluator
    %EVALUATORDISTANCE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        top_matches = 10;
    end
    
    methods
        function EV = EvaluatorDistance(network, database, layer)
            if ~exist('layer', 'var')
                layer = [];
            end
            
            EV@Evaluator(network, database, layer);
        end
        
        function pruned_features = pruneFeatures(EV, features)
            % slightly lower threshold
            threshold = 0.99 * EV.db.threshold;
            
            % calculate distances
            distances = sqrt(mean(diff(features, 1, 2) .^ 2, 1));
            
            % prune features
            to_save = distances > threshold;
            pruned_features = features(:, [true to_save]);
        end
        
        function [match, score] = matchFeatures(EV, pruned_features)
            % distances
            distances = sqrt(sum(bsxfun(@(a, b) (a - b) .^ 2, pruned_features(:, 1), EV.db.data_features), 1));
            
            % normalizing constant for scores
            norm = max(EV.db.data_distances); % sqrt(sum(pruned_features .^ 2));
            
            % TODO: potentially select one distance per video id
            
            % sort top distances
            [distances, idx] = sort(distances);
            
            % start of all matching segments
            match_starts = idx(1:EV.top_matches);
            
            % matches
            matches_video_id = zeros(1, length(match_starts));
            matches_timestamp = zeros(1, length(match_starts));
            matches_scores = nan(1, length(match_starts));
            
            % list of matches
            for i = 1:length(match_starts)
                % score number of matching frames
                score = max(norm - distances(i), 0) / norm;
                
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
                    score = score + EV.matchRemainingFeatures(pruned_features(:, 2:end), remaining_features, norm);
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
        function score = matchRemainingFeatures(EV, remaining_pruned_features, remaining_video_features, norm)
            score = 0;
            fn = @(a, b) (a - b) .^ 2;
            last = 0;
            
            for i = 1:min(size(remaining_pruned_features, 2), size(remaining_video_features, 2))
                % distances
                distances = sqrt(sum(bsxfun(fn, remaining_pruned_features(:, i), remaining_video_features), 1));
                
                % get lowest distance
                [cur_score, cur] = min(distances);
                cur_score = max(norm - cur_score, 0) / norm;
                
                % not sequential
                if cur < last
                    cur_score = cur_score * 0.5;
                end
                last = cur;
                
                score = score + cur_score;
            end
        end
    end
end

