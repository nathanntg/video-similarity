function video_files = find_videos(directory, flt, shuff)

if ~exist('flt', 'var') || isempty(flt)
	flt = '*.*';
end

if ~exist('shuff', 'var')
	shuff = false;
end

% find videos
video_files = dir(fullfile(directory, flt));

% exclude: directories, hidden files and cache files
video_files = video_files(cellfun(@(x) ~x, {video_files.isdir})); % files only
video_files = video_files(cellfun(@(x) isempty(regexp(x, '^\.', 'once')) && isempty(regexp(x, '\.mat$', 'once')), {video_files.name})); % exclude hidden and cache files

% filter for videos
video_files = video_files(cellfun(@isvideo, {video_files.name}));

% turn into full paths
video_files = cellfun(@(x) fullfile(directory, x), {video_files.name}, 'UniformOutput', false);

% shuffle?
if shuff
	idx = randperm(length(video_files));
	if isscalar(shuff)
		idx = idx(1:shuff);
	end
	video_files = video_files(idx);
end

% file type filter
function b = isvideo(video_file)
    switch video_file((end-2):end)
        case 'mp4'
        	b = true;
        case 'm4v'
        	b = true;
        case 'mj2'
        	b = true;
        case 'avi'
        	b = true;
        otherwise
        	b = false;
    end
end

end