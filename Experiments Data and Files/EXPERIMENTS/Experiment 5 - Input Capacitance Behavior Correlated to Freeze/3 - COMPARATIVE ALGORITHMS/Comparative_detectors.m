clear; clc; close all

%% Constants
sourceFolder = 'C:\Users\nicol\Desktop\TFG\muntatge\MATLAB\Experiments\C\ANALISIS\T_EXO_STATISTICS';
Windowsize = 23;
WindowSize_C = Windowsize; % Window size for averaging the C
WindowSize_G = Windowsize;
WindowSize_S = Windowsize;

thup = 0.017;
thdown = 0.0024;

ni = 3;

%% Detection algorithms

% Valley detection with gradient descention:
[DTs_Gradient, Dts_Gradient,~, ~] = valley_detect(sourceFolder, WindowSize_C,WindowSize_G, 2,1);

% Inflexion point detection with std() threshold:
[DTs_std, Dts_std, ~, ~] = freez_detect(sourceFolder, thup, thdown, WindowSize_C, WindowSize_S,3,1);

%% Temperature Exothermic Detction:
% Detect the Temperature peak and texothermic initial time:
[t_peak_exo, T_peak, t_C_at_freeze, C_at_freeze, T_ini_exo, t_exo_ini,sample_ids] = exopeaks(sourceFolder, 1, 1);
% Calculate DT_ini_exo and Dt_ini_exo
DTs_gold =  T_peak - T_ini_exo;
Dts_gold =  t_exo_ini - t_peak_exo;

%% COMPARE PLOTS
%% -------------------------- DTemp (detected - exothermic)-------------------
figure(4); clf; hold on
h_scatter = []; h_fill = []; h_mean = [];

methods = {'Gradient', 'Std', 'Gold Standard'};
colors = [0 0 0]; % black

% Prepare data
DTs_all = {DTs_Gradient, DTs_std, DTs_gold};
Dts_all = {Dts_Gradient, Dts_std, Dts_gold};



for i = 1:ni
    y = DTs_all{i};
    x = i * ones(size(y));
    
    % Scatter (Datapoints)
    h_scatter(i) = scatter(x, y, 50, 'filled', ...
        'MarkerFaceColor', colors, 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 0.6);

    % Mean & STD
    m = mean(y, 'omitnan');
    s = std(y, 'omitnan');
    n = length(DTs_all{i});
    z = 1.96; % for a 95% CI normally distributed
    ci_half = z * s / sqrt(n); % confidence interval 

    % CI and STD fill
    y_patch_std = [m-s, m-s, m+s, m+s];
    y_patch_ci  = [m - ci_half, m - ci_half, m + ci_half, m + ci_half];

    % Shaded std (±1σ)
    h_fill(i) = fill([i-0.2 i+0.2 i+0.2 i-0.2], y_patch_std, ...
        [0.8 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.4);
    % Shaded uncertainty 95% CI:
    u_fill(i) = fill([i-0.2 i+0.2 i+0.2 i-0.2], y_patch_ci,  [0.4 0.4 0.4], ...
        'EdgeColor', 'none', ...
        'FaceAlpha', 0.4, 'DisplayName','u(\DeltaT) 95% CI');
    % Mean line
    h_mean(i) = plot([i-0.2 i+0.2], [m m], 'k-', 'LineWidth', 2);

    % Label
    %text(i + 0.25, m, sprintf('%.3g °C', m), 'VerticalAlignment', 'middle', 'FontSize', 10)
    if m ~= 0
        unc_pct = 100 * ci_half / abs(m);
        label_str = sprintf('%.3g °C\n(±%.1f%%)', m, unc_pct);
    else
        label_str = sprintf('%.3g °C\n(±N/A)', m); % avoid division by zero
    end
    text(i + 0.25, m, label_str, 'VerticalAlignment', 'middle', 'FontSize', 10)

end

plot([0 4], [0 0], 'k:', 'LineWidth', 1)

xlim([0.5 ni+0.5])
xticks(1:ni)
xticklabels(methods)
ylabel('ΔT (°C)')
title('Temperature Detection Delay relative to T_{peak}')
n_points = sum(~isnan(DTs_all{1}));

legend([h_scatter(1), u_fill(1), h_fill(1), h_mean(1)], ...
    {sprintf('Experiments (n = %d)', n_points), ...
    'u(\DeltaT) 95% CI','Std (±1σ)', 'Mean'}, ...
    'Location', 'northoutside', 'Orientation', 'horizontal')
grid on
box on

%% -------------------------- Dtime (detected - exothermic)-------------------
figure(5); clf; hold on
h_scatter = []; h_fill = []; h_mean = [];



for i = 1:ni
    y = Dts_all{i};
    x = i * ones(size(y));
    
    % Scatter (Datapoints)
    h_scatter(i) = scatter(x, y, 50, 'filled', ...
        'MarkerFaceColor', colors, 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 0.6);

    % Mean & STD
    m = mean(y, 'omitnan');
    s = std(y, 'omitnan');
    n = length(DTs_all{i});
    z = 1.96; % for a 95% CI normally distributed
    ci_half = z * s / sqrt(n); % confidence interval 

    % CI and STD fill
    y_patch_std = [m-s, m-s, m+s, m+s];
    y_patch_ci  = [m - ci_half, m - ci_half, m + ci_half, m + ci_half];

    % Shaded std (±1σ)
    h_fill(i) = fill([i-0.2 i+0.2 i+0.2 i-0.2], y_patch_std, ...
        [0.8 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.4);
    % Shaded uncertainty 95% CI:
    u_fill = fill([i-0.2 i+0.2 i+0.2 i-0.2], y_patch_ci,  [0.4 0.4 0.4], 'EdgeColor', 'none', 'FaceAlpha', 0.4, 'DisplayName','95% CI');
    % Mean line
    h_mean(i) = plot([i-0.2 i+0.2], [m m], 'k-', 'LineWidth', 2);

    % Mean line
    h_mean(i) = plot([i-0.2 i+0.2], [m m], 'k-', 'LineWidth', 2);
   
    % Label
    %text(i + 0.25, m, sprintf('%.3g s', m), 'VerticalAlignment', 'middle', 'FontSize', 10)
    if m ~= 0
        unc_pct = 100 * ci_half / abs(m);
        label_str = sprintf('%.3g s\n(±%.1f%%)', m, unc_pct);
    else
        label_str = sprintf('%.3g s\n(±N/A)', m); % avoid division by zero
    end
    text(i + 0.25, m, label_str, 'VerticalAlignment', 'middle', 'FontSize', 10)

end

plot([0 4], [0 0], 'k:', 'LineWidth', 1)

xlim([0.5 ni+0.5])
xticks(1:ni)
xticklabels(methods)
ylabel('Δt (s)')
title('Time Detection Delay relative to t_{peak}')
n_points = sum(~isnan(Dts_all{1}));

legend([h_scatter(1), u_fill(1), h_fill(1), h_mean(1)], ...
    {sprintf('Experiments (n = %d)', n_points), 'u(\Deltat) 95% CI','Std (±1σ)', 'Mean'}, ...
    'Location', 'northoutside', 'Orientation', 'horizontal')
grid on
box on


%% -------------------------- RATIO (DT/Dt)-------------------
figure(6); clf; hold on
h_scatter = []; h_fill = []; h_mean = [];


ratio_all = cell(size(DTs_all));  % Initialize cell array to hold ratios for each method

for i = 1:ni
    n = length(DTs_all{i});
    ratio_all{i} = NaN(1, n);  % Initialize with NaNs
    
    for j = 1:n
        if Dts_all{i}(j) == 0
            if DTs_all{i}(j) == 0
                ratio_all{i}(j) = 0;    % 0 / 0 → define as 0
            else
                ratio_all{i}(j) = NaN;  % nonzero / 0 → undefined
            end
        else
            ratio_all{i}(j) = DTs_all{i}(j) / Dts_all{i}(j);  % standard division
        end
    end

    y = ratio_all{i};
    x = i * ones(size(y));
    
    % Scatter (Datapoints)
    h_scatter(i) = scatter(x, y, 50, 'filled', ...
        'MarkerFaceColor', colors, 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 0.6);

    % Mean & STD
    m = mean(y, 'omitnan');
    s = std(y, 'omitnan');
    n = length(DTs_all{i});
    z = 1.96; % for a 95% CI normally distributed
    ci_half = z * s / sqrt(n); % confidence interval 

    % CI and STD fill
    y_patch_std = [m-s, m-s, m+s, m+s];
    y_patch_ci  = [m - ci_half, m - ci_half, m + ci_half, m + ci_half];

    % Shaded std (±1σ)
    h_fill(i) = fill([i-0.2 i+0.2 i+0.2 i-0.2], y_patch_std, ...
        [0.8 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.4);
    % Shaded uncertainty 95% CI:
    u_fill = fill([i-0.2 i+0.2 i+0.2 i-0.2], y_patch_ci,  [0.4 0.4 0.4], 'EdgeColor', 'none', 'FaceAlpha', 0.4, 'DisplayName','95% CI');
    % Mean line
    h_mean(i) = plot([i-0.2 i+0.2], [m m], 'k-', 'LineWidth', 2);

    % Mean line
    h_mean(i) = plot([i-0.2 i+0.2], [m m], 'k-', 'LineWidth', 2);
   
    % Label
    %text(i + 0.25, m, sprintf('%.3g s', m), 'VerticalAlignment', 'middle', 'FontSize', 10)
    if m ~= 0
        unc_pct = 100 * ci_half / abs(m);
        label_str = sprintf('%.3g s\n(±%.1f%%)', m, unc_pct);
    else
        label_str = sprintf('%.3g s\n(±N/A)', m); % avoid division by zero
    end
    text(i + 0.25, m, label_str, 'VerticalAlignment', 'middle', 'FontSize', 10)

end

plot([0 4], [0 0], 'k:', 'LineWidth', 1)

xlim([0.5 ni+0.5])
xticks(1:ni)
xticklabels(methods)
ylabel('Δt (s)')
title('\DeltaT / \Deltat Ratio (°C/s) relative to t_{peak}')
n_points = sum(~isnan(Dts_all{1}));

legend([h_scatter(1), u_fill(1), h_fill(1), h_mean(1)], ...
    {sprintf('Experiments (n = %d)', n_points), 'u(\DeltaT/\Deltat) 95% CI','Std (±1σ)', 'Mean'}, ...
    'Location', 'northoutside', 'Orientation', 'horizontal')
grid on
box on

%%

figure(7); clf; 
subplot(2,1,1);
hold on
h_scatter = []; h_fill = []; h_mean = [];

methods = {'Gradient', 'Std', 'Gold Standard'};
colors = [0 0 0]; % black

% Prepare data
DTs_all = {DTs_Gradient, DTs_std, DTs_gold};
Dts_all = {Dts_Gradient, Dts_std, Dts_gold};



for i = 1:ni
    y = DTs_all{i};
    x = i * ones(size(y));
    
    % Scatter (Datapoints)
    h_scatter(i) = scatter(x, y, 50, 'filled', ...
        'MarkerFaceColor', colors, 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 0.6);

    % Mean & STD
    m = mean(y, 'omitnan');
    s = std(y, 'omitnan');
    n = length(DTs_all{i});
    z = 1.96; % for a 95% CI normally distributed
    ci_half = z * s / sqrt(n); % confidence interval 

    % CI and STD fill
    y_patch_std = [m-s, m-s, m+s, m+s];
    y_patch_ci  = [m - ci_half, m - ci_half, m + ci_half, m + ci_half];

    % Shaded std (±1σ)
    h_fill(i) = fill([i-0.2 i+0.2 i+0.2 i-0.2], y_patch_std, ...
        [0.8 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.4);
    % Shaded uncertainty 95% CI:
    u_fill(i) = fill([i-0.2 i+0.2 i+0.2 i-0.2], y_patch_ci,  [0.4 0.4 0.4], ...
        'EdgeColor', 'none', ...
        'FaceAlpha', 0.4, 'DisplayName','u(\DeltaT) 95% CI');
    % Mean line
    h_mean(i) = plot([i-0.2 i+0.2], [m m], 'k-', 'LineWidth', 2);

    % Label
    %text(i + 0.25, m, sprintf('%.3g °C', m), 'VerticalAlignment', 'middle', 'FontSize', 10)
    if m ~= 0
        unc_pct = 100 * ci_half / abs(m);
        label_str = sprintf('%.2g ± %.2g °C (95%%CI)\n(ε_r = %.1f%%)', m, ci_half, unc_pct);
    else
        label_str = sprintf('%.2g °C\n(±N/A)', m); % avoid division by zero
    end
    text(i + 0.25, m, label_str, 'VerticalAlignment', 'middle', 'FontSize', 10)

end

plot([0 4], [0 0], 'k:', 'LineWidth', 1)

xlim([0.5 ni+0.8])
xticks(1:ni)
xticklabels(methods)
ylabel('ΔT (°C)')
title('Temperature Detection Delay relative to T_{peak}')
n_points = sum(~isnan(DTs_all{1}));

legend([h_scatter(1),  h_fill(1),u_fill(1), h_mean(1)], ...
    {sprintf('Experiments (n = %d)', n_points), ...
    'u(\DeltaT) 95% CI','Std (±1σ)', 'Mean'}, ...
    'Location', 'northoutside', 'Orientation', 'horizontal')
grid on
box on

% -----------------------------------------------------------------------
subplot(2,1,2);
hold on

h_scatter = []; h_fill = []; h_mean = [];



for i = 1:ni
    y = Dts_all{i};
    x = i * ones(size(y));
    
    % Scatter (Datapoints)
    h_scatter(i) = scatter(x, y, 50, 'filled', ...
        'MarkerFaceColor', colors, 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 0.6);

    % Mean & STD
    m = mean(y, 'omitnan');
    s = std(y, 'omitnan');
    n = length(DTs_all{i});
    z = 1.96; % for a 95% CI normally distributed
    ci_half = z * s / sqrt(n); % confidence interval 

    % CI and STD fill
    y_patch_std = [m-s, m-s, m+s, m+s];
    y_patch_ci  = [m - ci_half, m - ci_half, m + ci_half, m + ci_half];

    % Shaded std (±1σ)
    h_fill(i) = fill([i-0.2 i+0.2 i+0.2 i-0.2], y_patch_std, ...
        [0.8 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.4);
    % Shaded uncertainty 95% CI:
    u_fill = fill([i-0.2 i+0.2 i+0.2 i-0.2], y_patch_ci,  [0.4 0.4 0.4], 'EdgeColor', 'none', 'FaceAlpha', 0.4, 'DisplayName','95% CI');
    % Mean line
    h_mean(i) = plot([i-0.2 i+0.2], [m m], 'k-', 'LineWidth', 2);

    % Mean line
    h_mean(i) = plot([i-0.2 i+0.2], [m m], 'k-', 'LineWidth', 2);
   
    % Label
    %text(i + 0.25, m, sprintf('%.3g s', m), 'VerticalAlignment', 'middle', 'FontSize', 10)
    if m ~= 0
        unc_pct = 100 * ci_half / abs(m);
        label_str = sprintf('%.3g ± %.2g s (95%%CI)\n(ε_r = %.1f%%)', m, ci_half, unc_pct);
    else
        label_str = sprintf('%.3g s \n(±N/A)', m); % avoid division by zero
    end
    text(i + 0.25, m, label_str, 'VerticalAlignment', 'middle', 'FontSize', 10)

end

plot([0 4], [0 0], 'k:', 'LineWidth', 1)

xlim([0.5 ni+0.8])
xticks(1:ni)
xticklabels(methods)
ylabel('Δt (s)')
title('Time Detection Delay relative to t_{peak}')
n_points = sum(~isnan(Dts_all{1}));

legend([h_scatter(1),  h_fill(1), u_fill(1), h_mean(1)], ...
    {sprintf('Experiments (n = %d)', n_points), 'u(\Deltat) 95% CI','Std (±1σ)', 'Mean'}, ...
    'Location', 'northoutside', 'Orientation', 'horizontal')
grid on
box on
sgtitle("Comparative of the two proposed algorithms")