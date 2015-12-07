% load results
load('./results/deformation.mat');

t = {'Distortion: B&W', 'Distortion: Resize', 'Distortion: Rotate', 'Distortion: Crop', 'Distortion: Adjust Color', 'Distortion: Re-encode'};
l = {'AlexNet', 'AlexNet 2nd', 'GoogleNet', 'GoogleNet 2nd', 'R-CNN', 'R-CNN 2nd'};

for i = 1:length(deformations)
    % display deformation
    disp(deformations{i});
    
    % indices
    idx = strcmp(result_deformations, deformations{i});
    
    % results
    cur_results = results(idx, :);
    cur_videos = result_videos(idx);
    
    % clear mismatched
    cur_results(isnan(cur_results)) = 0;
    
    % sanity check
    if mod(size(cur_results, 1), 5)
        error('Unexpected results.');
    end
    
    % get number of modes
    modes = size(cur_results, 1) / 5;
    
    cur_mode_results = zeros(modes, size(cur_results, 2));
    
    % calculate mean
    groups = {'Original'};
    for j = 1:modes
        cur_mode_results(j, :) = mean(cur_results(j:modes:size(cur_results, 1), :));
        if 1 < j
            g = regexp(cur_videos{j}, '-([^-]+)\.', 'match');
            g = g{1};
            g = g(2:(end - 1));
            groups{end + 1} = g;
        end
    end
    
    switch deformations{i}
        case 'bw'
            groups = {'Color' 'B&W'};
        case 'encode'
            groups = {'H.264' 'MJ2000' 'MPEG'};
        case 'resize'
            ord = [1 size(cur_mode_results, 1):-1:2];
            cur_mode_results = cur_mode_results(ord, :);
            groups = groups(ord);
    end
    
    bar(cur_mode_results);
    title(t{i});
    legend(l, 'Location', 'EastOutside');
    ylabel('Score');
    set(gca, 'XTickLabel', groups);
    
    print(gcf, sprintf('deform-%s.png', deformations{i}), '-dpng', '-r300');
end
