function deformed_video = deform_video(video, deformation, argument)
%DEFORM_VIDEO Summary of this function goes here
%   Detailed explanation goes here

% empty argument
if ~exist('argument', 'var')
    argument = [];
end

% apply deformation
switch deformation
    case 'crop-horizontal'
        % default
        if isempty(argument)
            argument = 0.15;
        end
        
        % pixel value
        if argument <= 1
            argument = round(argument * size(video, 2) / 2);
        else
            argument = round(argument / 2);
        end
        
        % crop video
        deformed_video = video(:, (1 + argument):(end - argument), :, :);
        
    case 'crop-vertical'
        % default
        if isempty(argument)
            argument = 0.15;
        end
        
        % pixel value
        if argument <= 1
            argument = round(argument * size(video, 1) / 2);
        else
            argument = round(argument / 2);
        end
        
        % crop video
        deformed_video = video((1 + argument):(end - argument), :, :, :);
        
    case 'resize'
        % default
        if isempty(argument)
            argument = 0.75;
        end
        
        % get dimensions
        tmp = imresize(video(:, :, :, 1), argument);
        
        % create deformed video
        deformed_video = zeros(size(tmp, 1), size(tmp, 2), size(video, 3), size(video, 4), 'like', video);
        for t = 1:size(video, 4)
            deformed_video(:, :, :, t) = imresize(video(:, :, :, t), argument);
        end
        
    case 'rotate'
        % default
        if isempty(argument)
            argument = 5;
        end
        
        % create deformed video
        deformed_video = zeros(size(video), 'like', video);
        for t = 1:size(video, 4)
            deformed_video(:, :, :, t) = imrotate(video(:, :, :, t), argument, 'bilinear', 'crop');
        end
        
    case 'color'
        % default
        if isempty(argument)
            argument = 0.05;
        end
        if isscalar(argument)
            argument = [0 + argument 1 - argument];
        end
        
        % create deformed video
        deformed_video = zeros(size(video), 'like', video);
        for t = 1:size(video, 4)
            deformed_video(:, :, :, t) = imadjust(video(:, :, :, t), argument, []);
        end
        
    case 'bw'
        % create output
        deformed_video = zeros(size(video), 'like', video);
        
        for t = 1:size(video, 4)
            deformed_video(:, :, :, t) = repmat(rgb2gray(video(:, :, :, t)), 1, 1, 3);
        end
        
    otherwise
        error('Unrecognized deformation "%s".', deformation);
end

end

