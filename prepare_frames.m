function frames = prepare_frames(frames, frames_mean)
%PREPARE_FRAMES Converts image to expected network input.

% convert from RGB to BGR
frames = frames(:, :, [3 2 1], :);

% flip width and height
frames = permute(frames, [2 1 3 4]);

% use singles
frames = single(frames);

% subtract mean
frames = frames - frames_mean;

end
