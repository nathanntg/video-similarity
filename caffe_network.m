function [model, weights] = caffe_network(id)
%CAFFE_NETWORK Model and weights by ID (for easy reuse)

switch id
    case {1, 'AlexNet'}
        model = '/Users/nathan/Development/caffe-master/models/bvlc_alexnet/deploy.prototxt';
        weights = '/Users/nathan/Development/caffe-master/models/bvlc_alexnet/bvlc_alexnet.caffemodel';
    case {2, 'GoogleNet'}
        model = '/Users/nathan/Development/caffe-master/models/bvlc_googlenet/deploy.prototxt';
        weights = '/Users/nathan/Development/caffe-master/models/bvlc_googlenet/bvlc_googlenet.caffemodel';
    case {3, 'CaffeNet'}
        model = '/Users/nathan/Development/caffe-master/models/bvlc_reference_caffenet/deploy.prototxt';
        weights = '/Users/nathan/Development/caffe-master/models/bvlc_reference_caffenet/bvlc_reference_caffenet.caffemodel';
    case {4, 'R-CNN'}
        model = '/Users/nathan/Development/caffe-master/models/bvlc_reference_rcnn_ilsvrc13/deploy.prototxt';
        weights = '/Users/nathan/Development/caffe-master/models/bvlc_reference_rcnn_ilsvrc13/bvlc_reference_rcnn_ilsvrc13.caffemodel';
end

end

