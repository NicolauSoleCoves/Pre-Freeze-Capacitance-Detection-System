clear; clc; close all

% ---------------- Constants ----------------
sourceFolder = 'C:\Users\nicol\Desktop\TFG\muntatge\MATLAB\Experiments\C\ANALISIS\T_EXO_STATISTICS';

% Configuration vector: each row is [WindowSize, thdown]
configs = [
    23, 0.0021;    
    23, 0.0024;    
    25, 0.0021;
    25, 0.0024;
    25, 0.0025;
];

thup = 0.017;
z = 1.96; % for 95% confidence interval

% ---------------- Compute each config ----------------
DTs_all = {}; Dts_all = {}; methods = {};n_detected_all={};
for i = 1:size(configs, 1)
    WindowSize_C = configs(i, 1);
    WindowSize_S = configs(i, 1);

    thdown = configs(i, 2);
    
    % Detection with std
    [DTs_std, Dts_std, ~, ~, n_detected] = freez_detect(sourceFolder, thup, thdown, WindowSize_C, WindowSize_S, 3, 1);
    
    % Store results
    DTs_all{end+1} = DTs_std;
    Dts_all{end+1} = Dts_std;
    methods{end+1} = sprintf('Std (%d, %.4f)', WindowSize_C, thdown);
    n_detected_all{end+1} = n_detected;
end

% ---------------- Gold Standard ----------------
[t_peak_exo, T_peak, t_C_at_freeze, C_at_freeze, T_ini_exo, t_exo_ini, sample_ids] = exopeaks(sourceFolder, 1, 1);

DTs_gold = T_peak - T_ini_exo;
Dts_gold = t_exo_ini - t_peak_exo;

DTs_all{end+1} = DTs_gold;
Dts_all{end+1} = Dts_gold;
methods{end+1} = 'Gold Standard';
n_detected_all{end+1} = length(sample_ids);
ni = numel(methods);

% Use black color for all
colors = repmat([0 0 0], ni, 1);
%%
% ---------------- PLOT ----------------
figure(7); clf;
subplot(2,1,1); hold on
h_scatter = []; h_fill = []; h_mean = [];

for i = 1:ni
    y = DTs_all{i};
    x = i * ones(size(y));
    
    % Scatter
    h_scatter(i) = scatter(x, y, 50, 'filled', ...
        'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 0.6);
    
    % Mean, std, CI
    m = mean(y, 'omitnan');
    s = std(y, 'omitnan');
    n = length(y);
    ci_half = z * s / sqrt(n);
    
    % Fill patches
    y_patch_std = [m-s, m-s, m+s, m+s];
    y_patch_ci = [m - ci_half, m - ci_half, m + ci_half, m + ci_half];
    
    h_fill(i) = fill([i-0.2 i+0.2 i+0.2 i-0.2], y_patch_std, ...
        [0.8 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.4);
    u_fill(i) = fill([i-0.2 i+0.2 i+0.2 i-0.2], y_patch_ci, ...
        [0.4 0.4 0.4], 'EdgeColor', 'none', 'FaceAlpha', 0.4);
    
    h_mean(i) = plot([i-0.2 i+0.2], [m m], 'k-', 'LineWidth', 2);
    
    % Text label
    if m ~= 0
        unc_pct = 100 * ci_half / abs(m);
        label_str = sprintf('%.2g ± %.2g °C\n(95%%CI)\n(ε_r = %.1f%%)\nn_{detected} = %.1d', m, ci_half, unc_pct,n_detected_all{i});
    else
        label_str = sprintf('%.2g °C\n(±N/A)', m);
    end
    text(i + 0.25, m, label_str, 'VerticalAlignment', 'middle', 'FontSize', 10)
end

plot([0 ni+1], [0 0], 'k:', 'LineWidth', 1)
xlim([0.7 ni+0.9])
ylim([-2 10])
xticks(1:ni)
xticklabels(methods)
xtickangle(45)
ylabel('ΔT (°C)')
title('Temperature Detection Delay relative to T_{peak}')
n_points = sum(~isnan(DTs_all{1}));
legend([h_scatter(1), h_fill(1), u_fill(1), h_mean(1)], ...
    {sprintf('Experiments (n = %d)', n_points), 'u(ΔT) 95% CI', 'Std (±1σ)', 'Mean'}, ...
    'Location', 'northoutside', 'Orientation', 'horizontal')
grid on; box on

% ---------------- Time delay subplot ----------------
subplot(2,1,2); hold on
h_scatter = []; h_fill = []; h_mean = [];

for i = 1:ni
    y = Dts_all{i};
    x = i * ones(size(y));
    
    h_scatter(i) = scatter(x, y, 50, 'filled', ...
        'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 0.6);
    
    m = mean(y, 'omitnan');
    s = std(y, 'omitnan');
    n = length(y);
    ci_half = z * s / sqrt(n);
    
    y_patch_std = [m-s, m-s, m+s, m+s];
    y_patch_ci = [m - ci_half, m - ci_half, m + ci_half, m + ci_half];
    
    h_fill(i) = fill([i-0.2 i+0.2 i+0.2 i-0.2], y_patch_std, ...
        [0.8 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.4);
    u_fill(i) = fill([i-0.2 i+0.2 i+0.2 i-0.2], y_patch_ci, ...
        [0.4 0.4 0.4], 'EdgeColor', 'none', 'FaceAlpha', 0.4);
    
    h_mean(i) = plot([i-0.2 i+0.2], [m m], 'k-', 'LineWidth', 2);
    
    if m ~= 0
        unc_pct = 100 * ci_half / abs(m);
        label_str = sprintf('%.3g ± %.2g s\n(95%%CI)\n(ε_r = %.1f%%)\nn_{detected} = %.1d', m, ci_half, unc_pct,n_detected_all{i});
    else
        label_str = sprintf('%.3g s\n(±N/A)', m);
    end
    text(i + 0.25, m, label_str, 'VerticalAlignment', 'middle', 'FontSize', 10)
end

plot([0 ni+1], [0 0], 'k:', 'LineWidth', 1)
xlim([0.7 ni+0.9])
xticks(1:ni)
xticklabels(methods)
xtickangle(45)
ylabel('Δt (s)')
title('Time Detection Delay relative to t_{peak}')
n_points = sum(~isnan(Dts_all{1}));
legend([h_scatter(1), h_fill(1), u_fill(1), h_mean(1)], ...
    {sprintf('Experiments (n = %d)', n_points), 'u(Δt) 95% CI', 'Std (±1σ)', 'Mean'}, ...
    'Location', 'northoutside', 'Orientation', 'horizontal')
grid on; box on

sgtitle("Comparison of Freeze Detection Methods (Std vs. Gold Standard)")
