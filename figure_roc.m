% always wrong, no matter how classified (wrong video file matched)
always_wrong = repmat(ground_truth', 1, size(matched, 2)) & ~matched;

% network names
l = {'AlexNet', 'AlexNet 2nd', 'GoogleNet', 'GoogleNet 2nd', 'R-CNN', 'R-CNN 2nd'};

for i = 1:length(l)
    cur_matched = matched(:, i);
    cur_always_wrong = always_wrong(:, i);
    cur_results = results(:, i);
    
    % sort threshold
    t = sort([-1; cur_results], 'descend');
    tpr = zeros(size(t));
    fpr = zeros(size(t));
    
    for j = 1:length(t)
        threshold = t(j);
        
        idx = threshold < cur_results;
        tp = sum(cur_matched(idx) & ~cur_always_wrong(idx));
        fp = sum(idx) - tp;
        tn = sum(~cur_matched(~idx) & ~cur_always_wrong(~idx));
        fn = sum(~idx) - tn;
        
        tpr(j) = tp / (tp + fn);
        fpr(j) = fp / (tn + fp);
    end
    
    % make plot
    plot(fpr, tpr, 'b', 'LineWidth', 2.);
    auc = trapz(fpr, tpr);
    legend(sprintf('ROC (AUC: %.3f)', auc), 'Location', 'SouthEast');
    title(l{i});
    hold on; plot([0; 1], [0; 1], '-', 'Color', [.8 .8 .8]); hold off;
    xlim([0 1]); ylim([0 1]);
    xlabel('FPR'); ylabel('TPR');
    
    % save
    print(gcf, sprintf('roc-%d.png', i), '-dpng', '-r300');
    
    pause;
end
