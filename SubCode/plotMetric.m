%% =========================================================
% LOCAL FUNCTION
% =========================================================
function plotMetric(x, data, algorithms, markers, ...
                     xlabelText, ylabelText, ...
                     titleText, filename, yLimits)

figure('Position',[200 150 900 570]);

hold on;

for i = 1:size(data,1)

    plot(x, data(i,:), ...
        'LineWidth',2, ...
        'Marker',markers{i}, ...
        'MarkerSize',7);

end

xlabel(xlabelText, ...
    'FontSize',12, ...
    'FontWeight','bold');

ylabel(ylabelText, ...
    'FontSize',12, ...
    'FontWeight','bold');

title(titleText, ...
    'FontSize',14, ...
    'FontWeight','bold');

legend(algorithms, ...
    'Location','best', ...
    'FontSize',9);

xlim([0 max(x)+50]);

if ~isempty(yLimits)
    ylim(yLimits);
end

set(gca, ...
    'FontSize',11, ...
    'LineWidth',1);

grid on;
box on;

end