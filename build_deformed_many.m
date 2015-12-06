function build_deformed_many(directory_videos, directory_output, deformation, arguments, num)
%BUILD_DEFORMED_MANY 

if ~exist('num', 'var') || isempty(num)
    num = 10;
end
if ~exist('arguments', 'var')
    arguments = {0};
end

% get all videos
video_files = dir(fullfile(directory_videos, '*.mp4'));
video_files = {video_files(:).name};
video_files = cellfun(@(x) fullfile(directory_videos, x), video_files, 'UniformOutput', false);

% get random num
idx = randperm(length(video_files));
video_files = video_files(idx(1:num));

% do it
build_deformed(video_files, directory_output, deformation, arguments);

end

