%% RUN TESTS
class = {'EvaluatorOrder' 'EvaluatorOrder' 'EvaluatorDistance' 'EvaluatorDistance' 'EvaluatorOrder' 'EvaluatorOrder' 'EvaluatorDistance' 'EvaluatorDistance' 'EvaluatorOrder' 'EvaluatorOrder' 'EvaluatorDistance' 'EvaluatorDistance'};
networks = {'AlexNet' 'AlexNet' 'AlexNet' 'AlexNet' 'GoogleNet' 'GoogleNet' 'GoogleNet' 'GoogleNet' 'R-CNN' 'R-CNN' 'R-CNN' 'R-CNN'};
databases = {'./database/order/youtube_alexnet.mat' './database/order/youtube_alexnet2.mat' './database/distance/youtube_alexnet.mat' './database/distance/youtube_alexnet2.mat' './database/order/youtube_googlenet.mat' './database/order/youtube_googlenet2.mat' './database/distance/youtube_googlenet.mat' './database/distance/youtube_googlenet2.mat' './database/order/youtube_rcnn.mat' './database/order/youtube_rcnn2.mat' './database/distance/youtube_rcnn.mat' './database/distance/youtube_rcnn2.mat'};
layers = {1 2 1 2 1 2 1 2 1 2 1 2};

% make evaluators
evaluators = cell(1, length(class));
for i = 1:length(class)
    evaluators{i} = feval(class{i}, networks{i}, databases{i}, layers{i});
end

% make list of videos
result_videos = {};
results = [];
deformations = {'bw'}; % 'resize' 'rotate' 'crop-horizontal' 'color' 'bw'};
directory_videos = './library/youtube/';
directory_deformed = './library/deformed/';
for i = 1:length(deformations)
    % deformation
    deformation = deformations{i};
    
    % get all videos
    video_files = dir(fullfile(directory_deformed, deformation, '*-*.*'));
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
            done{end + 1} = video_nm;
            
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
            result_videos{end + 1} = video_nm;
            results = [results; row];
        end
            
        % load video
        video_file = fullfile(directory_deformed, deformation, video_files{j});
            
        % process video with all evaluators
        row = zeros(1, length(evaluators));
        for k = 1:length(evaluators)
            [match, score] = evaluators{k}.matchVideoFile(video_file);
            if ~strcmp(matched.video, match.video)
                score = nan;
            end
            row(k) = score;
        end

        % append to results
        result_videos{end + 1} = video_nm;
        results = [results; row];
    end
end
