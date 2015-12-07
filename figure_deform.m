example_files = {'./library/youtube/2c3afzjuCps.mp4' './library/deformed/bw/2c3afzjuCps-0.mp4' './library/youtube/0ch-eJoT9IM.mp4' './library/deformed/color/0ch-eJoT9IM-0.3.mp4' './library/youtube/2ayOA63bdiY.mp4' './library/deformed/crop-horizontal/2ayOA63bdiY-0.6.mp4' './library/youtube/n7gYx6x99tw.mp4' './library/deformed/resize/n7gYx6x99tw-0.125.mp4' './library/youtube/KJt_s3a8FqA.mp4' './library/deformed/rotate/KJt_s3a8FqA-75.mp4'};

for i = 1:length(example_files)
	n = ceil(i / 2);
	example = video_read(example_files{i}, 1);
    frame = example(:, :, :, 1);
    if mod(i, 2)
        imwrite(frame, sprintf('deform-%do.jpg', n));
    else
        imwrite(frame, sprintf('deform-%dd.jpg', n));
    end
end
