clear; clc; close all;

sourceFolder = 'C:\Users\nicol\Desktop\TFG\muntatge\MATLAB\Experiments\C\ANALISIS\T_EXO_STATISTICS';

% Extract peak and initial values
[t_peak_exo_all, T_peak_all, t_C_at_freeze_all, C_at_freeze_all, ...
 T_ini_exo_all, t_exo_ini_all, file_ids] = exopeaks(sourceFolder, 3, 1);

% Extract valid values
validIdx = ~isnan(t_peak_exo_all);
T_ini = T_ini_exo_all(validIdx);
T_peak = T_peak_all(validIdx);
t_ini = t_exo_ini_all(validIdx);
t_peak = t_peak_exo_all(validIdx);
file_ids_valid = file_ids(validIdx);

% Derived values
DT_exo = T_peak - T_ini;
Dt_exo = t_peak - t_ini;
ratio_exo = NaN(size(DT_exo));  % Initialize

for i = 1:length(DT_exo)
    if Dt_exo(i) == 0
        if DT_exo(i) == 0
            ratio_exo(i) = 0;    % 0 / 0 → define as 0
        else
            ratio_exo(i) = NaN;  % nonzero / 0 → undefined
        end
    else
        ratio_exo(i) = DT_exo(i) / Dt_exo(i);  % standard division
    end
end

% Data and labels
data = {DT_exo, Dt_exo, ratio_exo};
labels = {'\DeltaT_{exo} (°C)', '\Deltat_{exo} (s)', '\DeltaT / \Deltat Ratio (°C/s)'};

% Convert file_ids to cell array of strings (labels)
xLabels = arrayfun(@num2str, file_ids_valid, 'UniformOutput', false);
x = 1:length(file_ids_valid);  % Numeric positions

% Plot first two in Figure 1
figure(1); clf;
for i = 1:2
    subplot(1, 2, i); hold on;

    y = data{i};
    m = mean(y, 'omitnan');
    s = std(y, 'omitnan');
    n = sum(~isnan(y));
    z = 1.96; % for a 95% CI normally distributed
    ci_half = z * s / sqrt(n); % confidence interval 

    % CI and STD fill
    x_patch = [0.5, length(y)+0.5, length(y)+0.5, 0.5];
    y_patch_std = [m-s, m-s, m+s, m+s];
    y_patch_ci  = [m - ci_half, m - ci_half, m + ci_half, m + ci_half];

    fill(x_patch, y_patch_std, [0.9 0.9 0.9], 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'DisplayName','\sigma');
    fill(x_patch, y_patch_ci,  [0.6 0.6 0.6], 'EdgeColor', 'none', 'FaceAlpha', 0.4, 'DisplayName','95% CI');

    scatter(x, y, 'filled', 'k');
    yline(m, 'k--', 'LineWidth', 1.5);

    xlabel('Sample ID');
    ylabel(labels{i});
    title(sprintf('%s vs. Sample ID', labels{i}), 'Interpreter', 'tex');

    % Stats text
    ax = gca;
    xlims = ax.XLim; ylims = ax.YLim;
    dx = xlims(2) - xlims(1);
    dy = ylims(2) - ylims(1);
    xText = xlims(2) - 0.13 * dx;
    yText = ylims(2) - 0.05 * dy;

    txt = sprintf(['Mean = %.2f ± %.2f\n' ...
               '95%% CI: [%.2f, %.2f]'], ...
               m, s, m - ci_half, m + ci_half);

    text(xText, yText, txt, 'FontSize', 10, 'FontWeight', 'bold', ...
        'BackgroundColor', 'w', 'EdgeColor', 'k', 'Margin', 5, ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'top');

    xlim([0.5, length(y) + 0.5]);
    xticks(x); xticklabels(xLabels); xtickangle(90);
    grid on;
end
sgtitle(sprintf('Exothermic Parameters (n = %d)', length(DT_exo)), ...
    'FontSize', 14, 'FontWeight', 'bold');

% Plot third one in Figure 2
figure(2); clf;
i = 3;
y = data{i};
m = mean(y, 'omitnan');
s = std(y, 'omitnan');
n = sum(~isnan(y));
z = 1.96;
ci_half = z * s / sqrt(n);
rel_uncertainty_95 = (ci_half / m) * 100; %relative uncertainty

x_patch = [0.5, length(y)+0.5, length(y)+0.5, 0.5];
y_patch_std = [m-s, m-s, m+s, m+s];
y_patch_ci  = [m - ci_half, m - ci_half, m + ci_half, m + ci_half];

fill(x_patch, y_patch_std, [0.9 0.9 0.9], 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'DisplayName','\sigma');
hold on;
fill(x_patch, y_patch_ci,  [0.6 0.6 0.6], 'EdgeColor', 'none', 'FaceAlpha', 0.4, 'DisplayName','95% CI');

scatter(x, y, 'filled', 'k');
yline(m, 'k--', 'LineWidth', 1.5);

xlabel('Sample ID');
ylabel(labels{i});
title(sprintf('Statistics of %s for n = %d samples', labels{i},length(DT_exo)), 'Interpreter', 'tex');

ax = gca;
xlims = ax.XLim; ylims = ax.YLim;
dx = xlims(2) - xlims(1);
dy = ylims(2) - ylims(1);
xText = xlims(2) - 0.15 * dx;
yText = ylims(2) - 0.05 * dy;

txt = sprintf(['Mean = %.2f ± %.2f\nCV = %.1f%%\n' ...
    '95%% CI: [%.2f, %.2f]\nRel. Uncertainty (95%% CI) = %.2f%%'], ...
    m, s, s/m*100, m - ci_half, m + ci_half, rel_uncertainty_95);

text(xText, yText, txt, 'FontSize', 10, 'FontWeight', 'bold', ...
    'BackgroundColor', 'w', 'EdgeColor', 'k', 'Margin', 5, ...
    'HorizontalAlignment', 'right', 'VerticalAlignment', 'top');

xlim([0.5, length(y) + 0.5]);
xticks(x); xticklabels(xLabels); xtickangle(90);
grid on;
