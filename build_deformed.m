function build_deformed(video_files, directory, deformation, arguments)
%BUILD_DEFORMED Summary of this function goes here
%   Detailed explanation goes here

if ~exist('arguments', 'var')
    arguments = {0};
end

max_j = length(arguments);

for i = 1:length(video_files)
    % load video (first 60 seconds max)
    video = video_read(video_files{i}, 60);
    
    % out file name
    [~, nm, ext] = fileparts(video_files{i});
    
    if strcmp(deformation, 'encode')
        for j = 1:max_j
            % make name (use argument as extension)
            new_nm = fullfile(directory, deformation, [nm sprintf('-%d.', j) arguments{j}]);
            
            % write exact same video
            video_write(new_nm, video);
        end
    else
        % for each deformation
        for j = 1:max_j
            % deform video
            deformed_video = deform_video(video, deformation, arguments{j});
            
            % make name
            new_nm = fullfile(directory, deformation, [nm sprintf('-%g', arguments{j}) ext]);
            
            % write exact deformed video
            video_write(new_nm, deformed_video);
        end
    end
end

