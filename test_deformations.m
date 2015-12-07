%% SETUP EVALUATORS
if ~exist('evaluators', 'var')
    class = {'EvaluatorIntersection' 'EvaluatorIntersection' 'EvaluatorIntersection' 'EvaluatorIntersection' 'EvaluatorIntersection' 'EvaluatorIntersection'};
    networks = {'AlexNet' 'AlexNet' 'GoogleNet' 'GoogleNet' 'R-CNN' 'R-CNN'};
    databases = {'./database/order/youtube_alexnet.mat' './database/order/youtube_alexnet2.mat' './database/order/youtube_googlenet.mat' './database/order/youtube_googlenet2.mat' './database/order/youtube_rcnn.mat' './database/order/youtube_rcnn2.mat'};
    layers = {1 2 1 2 1 2};

    % make evaluators
    evaluators = cell(1, length(class));
    for i = 1:length(class)
        evaluators{i} = feval(class{i}, networks{i}, databases{i}, layers{i});
    end
end

%% RUN TESTS
% make list of videos
result_videos = {};
result_deformations = {};
results = [];
deformations = {'bw' 'resize' 'rotate' 'crop-horizontal' 'color' 'encode'};
directory_videos = './library/youtube/';
directory_deformed = './library/deformed/';
for i = 1:length(deformations)
    % deformation
    deformation = deformations{i};
    
    % get all videos
    video_files = dir(fullfile(directory_deformed, deformation, '*.*'));
    video_files = video_files(cellfun(@(x) ~x, {video_files.isdir})); % files only
    video_files = video_files(cellfun(@(x) isempty(regexp(x, '^\.', 'once')), {video_files.name}));
    video_files = video_files(cellfun(@(x) isempty(regexp(x, '\.mat$', 'once')), {video_files.name})); % exclude cache files
    video_files = {video_files(:).name};
    
    % done
    done = {};
    
    % iterate over video files
    for j = 1:length(video_files)
        % remove deformation
        video_nm = regexprep(video_files{j}, '-[^\-]+\.[a-z0-9]+$', '');
        
        if ~ismember(video_nm, done)
            % process 5 videos
            if 5 <= length(done)
                break
            end
            
            % append to video done list
            done{end + 1} = video_nm; %#ok<SAGROW>
            
            % projess non-deformed
            disp(video_nm);
            
            % load video
            video_file = fullfile(directory_videos, [video_nm '.mp4']);
            
            % process video with all evaluators
            row = zeros(1, length(evaluators));
            for k = 1:length(evaluators)
                [match, score] = evaluators{k}.matchVideoFile(video_file);
                matched = match;
                row(k) = score;
            end
            
            % append to results
            result_videos{end + 1} = video_nm; %#ok<SAGROW>
            result_deformations{end + 1} = deformation; %#ok<SAGROW>
            results = [results; row]; %#ok<AGROW>
        end
            
        % load video
        video_file = fullfile(directory_deformed, deformation, video_files{j});
            
        % process video with all evaluators
        row = zeros(1, length(evaluators));
        for k = 1:length(evaluators)
            [match, score] = evaluators{k}.matchVideoFile(video_file);
            if ~isempty(match) && ~strcmp(matched.video, match.video)
                score = nan;
            end
            row(k) = score;
        end

        % append to results
        result_videos{end + 1} = [deformation filesep video_files{j}]; %#ok<SAGROW>
        result_deformations{end + 1} = deformation; %#ok<SAGROW>
        results = [results; row]; %#ok<AGROW>
    end
end
