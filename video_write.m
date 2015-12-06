function video_write(video_file, video, format)
%VIDEO_WRITE Write a video file

% infer format from name
if ~exist('format', 'var') || isempty(format)
    switch video_file((end-2):end)
        case 'mp4'
            format = 'MPEG-4';
        case 'm4v'
            format = 'MPEG-4';
        case 'mj2'
            format = 'Motion JPEG 2000';
        case 'avi'
            format = 'Motion JPEG AVI';
        otherwise
            error('Unknown format.');
    end
end

% open writer
vh = VideoWriter(video_file, format);
open(vh);

% write frames
for i = 1:size(video, 4)
    f = im2frame(video(:, :, :, i));
    writeVideo(vh, f);
end

% close
close(vh);

end
