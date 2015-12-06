%% SETUP EVALUATORS
if ~exist('evaluators', 'var')
    class = {'EvaluatorOrder' 'EvaluatorOrder' 'EvaluatorDistance' 'EvaluatorDistance' 'EvaluatorOrder' 'EvaluatorOrder' 'EvaluatorDistance' 'EvaluatorDistance' 'EvaluatorOrder' 'EvaluatorOrder' 'EvaluatorDistance' 'EvaluatorDistance'};
    networks = {'AlexNet' 'AlexNet' 'AlexNet' 'AlexNet' 'GoogleNet' 'GoogleNet' 'GoogleNet' 'GoogleNet' 'R-CNN' 'R-CNN' 'R-CNN' 'R-CNN'};
    databases = {'./database/order/youtube_alexnet.mat' './database/order/youtube_alexnet2.mat' './database/distance/youtube_alexnet.mat' './database/distance/youtube_alexnet2.mat' './database/order/youtube_googlenet.mat' './database/order/youtube_googlenet2.mat' './database/distance/youtube_googlenet.mat' './database/distance/youtube_googlenet2.mat' './database/order/youtube_rcnn.mat' './database/order/youtube_rcnn2.mat' './database/distance/youtube_rcnn.mat' './database/distance/youtube_rcnn2.mat'};
    layers = {1 2 1 2 1 2 1 2 1 2 1 2};

    % make evaluators
    evaluators = cell(1, length(class));
    for i = 1:length(class)
        evaluators{i} = feval(class{i}, networks{i}, databases{i}, layers{i});
    end
end

%% RUN TESTS
ground_truth = [];
matched = [];
results = [];

% reset random number generator
old_rng = rng;
rng('default');

% get 10 normal videos
num = 10;
directory = './library/youtube/';
ground_truth = [ground_truth true(1, num)];

video_files = find_videos(directory, [], num);

% iterate over video files
for j = 1:length(video_files)
    % load video
    video_file = video_files{j};
    [~, a, b] = fileparts(video_file);
    video_name = [a b];
		
    % process video with all evaluators
    row = zeros(1, length(evaluators));
    matched_row = false(1, length(evaluators));
    for k = 1:length(evaluators)
        [match, score] = evaluators{k}.matchVideoFile(video_file);
        if isempty(match)
            score = inf;
        else
            % accurately matched?
            if strcmp(video_name, match.video)
                matched_row(k) = true;
            end
        end
        row(k) = score;
    end

    % append to results
    results = [results; row]; %#ok<AGROW>
    matched = [matched; matched_row]; %#ok<AGROW>
end

% get 10 novel videos
num = 10;
directory = './library/novel/';
ground_truth = [ground_truth false(1, num)];
matched = [matched; false(num, length(evaluators))];

video_files = find_videos(directory, [], num);

% iterate over video files
for j = 1:length(video_files)
    % load video
    video_file = video_files{j};
    
    % process video with all evaluators
    row = zeros(1, length(evaluators));
    for k = 1:length(evaluators)
        [match, score] = evaluators{k}.matchVideoFile(video_file);
        if isempty(match)
            score = inf;
        end
        row(k) = score;
    end

    % append to results
    results = [results; row]; %#ok<AGROW>
end

% get 10 deformed videos
video_files = {find_videos([directory 'resize/'], '*-0.5.*', 2) find_videos([directory 'crop-horizontal/'], '*-0.15.*', 2) find_videos([directory 'crop-horizontal/'], '*-0.3.*', 2) find_videos([directory 'color/'], '*-0.1.*', 2) find_videos([directory 'encode/'], '*-1.*', 2) find_videos([directory 'encode/'], '*-2.*', 2)};
num = length(video_files);
ground_truth = [ground_truth true(1, num)];

% iterate over video files
for j = 1:length(video_files)
    % load video
    video_file = video_files{j};
    [~, a, b] = fileparts(video_file);
    video_name = [a b];
    
    % process video with all evaluators
    row = zeros(1, length(evaluators));
    matched_row = false(1, length(evaluators));
    for k = 1:length(evaluators)
        [match, score] = evaluators{k}.matchVideoFile(video_file);
        if isempty(match)
            score = inf;
        else
            % get match name
            [~, match_name, ~] = fileparts(match.video);
            
            % accurately matched?
            if strcmp(video_name(1:length(match_name)), match_name)
                matched_row(k) = true;
            end
        end
        row(k) = score;
    end

    % append to results
    results = [results; row]; %#ok<AGROW>
end

rng(old_rng);