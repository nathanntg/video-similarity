function input = prepare_image(im, cropped_dim, image_dim, im_mean)
%PREPARE_IMAGE Converts image to expected network input.

% get mean data
if ~exist('im_mean', 'var') || isempty(im_mean)
    d = load('~/Development/caffe-master/matlab/+caffe/imagenet/ilsvrc_2012_mean.mat');
    im_mean = d.mean_data;
end

% parameters
if ~exist('cropped_dim', 'var') || isempty(cropped_dim)
    cropped_dim = 227;
end
if ~exist('image_dim', 'var') || isempty(image_dim)
    image_dim = 256;
end

% crop image to square
% TODO: potentially try oversampling rectangular image below
if size(im, 1) > size(im, 2)
    start = round((size(im, 1) - size(im, 2)) / 2);
    im = im(start:(start + size(im, 2) - 1), :, :);
elseif size(im, 2) > size(im, 1)
    start = round((size(im, 2) - size(im, 1)) / 2);
    im = im(:, start:(start + size(im, 1) - 1), :);
end

% convert from RGB to BGR
im = im(:, :, [3 2 1]);

% flip width and height
im = permute(im, [2 1 3]);

% use singles
im = single(im);

% resize
if size(im, 1) > size(im, 2)
    im = imresize(im, [nan image_dim]);
else
    im = imresize(im, [image_dim nan]);
end

% subtract mean
im = im - im_mean;

% build input by oversampling image at corners and center, including
% flipped versions (horizontally)

% make input
input = zeros(cropped_dim, cropped_dim, 3, 10, 'single');

% first: top-left corner, top-right corner, bottom-left corner,
% bottom-right corner

% make indices
i_idx = [1 size(im, 1) - cropped_dim + 1];
j_idx = [1 size(im, 2) - cropped_dim + 1];
k = 1;
for i = i_idx
    for j = j_idx
        % get corner
        input(:, :, :, k) = im(i:(i + cropped_dim - 1), j:(j + cropped_dim - 1), :);
        
        % horizontally flipped
        input(:, :, :, k + 5) = input(end:-1:1, :, :, k);
        
        k = k + 1;
    end
end

% second: center
center_x = round((size(im, 1) - cropped_dim) / 2);
center_y = round((size(im, 2) - cropped_dim) / 2);
input(:, :, :, 5) = im(center_x:(center_x + cropped_dim - 1), center_y:(center_y + cropped_dim - 1), :);
input(:, :, :, 10) = input(end:-1:1, :, :, 5);

end
