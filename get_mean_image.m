function im_mean = get_mean_image()
%GET_MEAN_IMAGE

d = load('~/Development/caffe-master/matlab/+caffe/imagenet/ilsvrc_2012_mean.mat');
im_mean = d.mean_data;

end
