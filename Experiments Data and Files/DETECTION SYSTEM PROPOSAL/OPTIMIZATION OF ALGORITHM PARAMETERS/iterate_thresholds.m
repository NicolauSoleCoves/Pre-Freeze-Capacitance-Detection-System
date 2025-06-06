clc; clear; close all;

% Parameters
sourceFolder = 'C:\Users\nicol\Desktop\TFG\muntatge\MATLAB\Experiments\C\ANALISIS\T_EXO_STATISTICS';
thup = 0.017;
Windowsize = 23;
WindowSize_C = Windowsize;
WindowSize_S = Windowsize;
thresholds = 0.0001:0.00002:0.0027;
z = 2.05;  % t-score for 95% confidence interval

% Store results
all_DT_means = [];
all_DT_ci = [];
all_Dt_means = [];
all_Dt_ci = [];

% Store all individual DTs and Dts per threshold
all_DTs = cell(1, length(thresholds));
all_Dts = cell(1, length(thresholds));

% Loop over thresholds
for i = 1:length(thresholds)
    thdown = thresholds(i);
    numfigure = i;

    % Get deltas
    [DTs, Dts, ~, ~] = freez_detect(sourceFolder, thup, thdown, WindowSize_C, WindowSize_S, numfigure, 0);

    % Save all individual DTs and Dts for scatter plot
    all_DTs{i} = DTs;
    all_Dts{i} = Dts;

    n_DT = length(DTs);
    n_Dt = length(Dts);

    m_DT = mean(DTs);
    s_DT = std(DTs);
    m_Dt = mean(Dts);
    s_Dt = std(Dts);

    ci_DT = z * s_DT / sqrt(n_DT);
    ci_Dt = z * s_Dt / sqrt(n_Dt);

    all_DT_means(end+1) = m_DT;
    all_DT_ci(end+1) = ci_DT;

    all_Dt_means(end+1) = m_Dt;
    all_Dt_ci(end+1) = ci_Dt;
end

% % Find ideal threshold
% ideal_index = find((all_DT_means - all_DT_ci > 0) & ...
%                    (all_Dt_means + all_Dt_ci < 0), 1, 'first');
% 
% if ~isempty(ideal_index)
%     ideal_threshold = thresholds(ideal_index);
%     ideal_DT = all_DT_means(ideal_index);
%     ideal_Dt = all_Dt_means(ideal_index);
% else
%     warning('No threshold found that satisfies the conditions.');
%     ideal_threshold = NaN;
% end

% Compute total number of samples for each threshold
all_total_samples = cellfun(@length, all_DTs) + cellfun(@length, all_Dts);

% Find index of maximum total samples
[~, ideal_index] = max(all_total_samples);

% Get ideal threshold and corresponding values
ideal_threshold = thresholds(ideal_index);
ideal_DT = all_DT_means(ideal_index);
ideal_Dt = all_Dt_means(ideal_index);


%% PLOT
figure(100); clf
color_main = [0 0 0];         % Black
color_ci = [0.5 0.5 0.5];     % Gray
color_scatter = [0.6 0.6 0.6];  % Light gray for individual points

% --- Subplot 1: ΔT ---
subplot(2,1,1); hold on;

% Plot CI bounds
h_ci1 = plot(thresholds, all_DT_means - all_DT_ci, '.-', 'Color', color_ci, 'DisplayName', '95% CI lower');
plot(thresholds, all_DT_means + all_DT_ci, '.-', 'Color', color_ci, 'HandleVisibility','off');

% Plot means
h_mean = scatter(thresholds, all_DT_means, 40, color_main, 'filled', ...
    'MarkerFaceAlpha', 0.7, 'MarkerEdgeColor', 'k', 'DisplayName', 'Mean ΔT');

% Plot all individual DT points (jittered horizontally for visibility)
for i = 1:length(thresholds)
    x_jitter = thresholds(i) + (rand(size(all_DTs{i})) - 0.5)*0.4*(thresholds(2)-thresholds(1)); % jitter scaled to threshold step
    h_indiv = scatter(x_jitter, all_DTs{i}, 20, color_scatter, 'filled', 'MarkerFaceAlpha', 0.4, 'MarkerEdgeColor', 'none', 'DisplayName', 'ΔT');
end

% Zero line
h_zero = yline(0, 'k', 'LineWidth', 1, 'HandleVisibility', 'off');

% Plot ideal threshold
if ~isnan(ideal_threshold)
    h_ideal = plot(ideal_threshold, ideal_DT, 'k|', 'MarkerSize', 30, 'LineWidth', 1.5, 'DisplayName', sprintf('Ideal Threshold = %.4f', ideal_threshold));
end

ylabel('ΔT (°C)', 'FontSize', 14);
title('Mean ± 95% CI of ΔT vs Threshold', 'FontSize', 16);
grid on; box on;
set(gca, 'FontSize', 12, 'LineWidth', 1);
xlim([thresholds(1) thresholds(end)]);

legendEntries1 = [h_mean, h_indiv, h_ci1];
if ~isnan(ideal_threshold)
    legendEntries1(end+1) = h_ideal;
end
legend(legendEntries1, {'Mean ΔT','ΔT', '95% CI', sprintf('Ideal Threshold = %.4f', ideal_threshold)}, 'Location', 'southeast');

% --- Subplot 2: Δt ---
subplot(2,1,2); hold on;

% CI bounds
h_ci1_2 = plot(thresholds, all_Dt_means - all_Dt_ci, '.-', 'Color', color_ci, 'DisplayName', '95% CI lower');
plot(thresholds, all_Dt_means + all_Dt_ci, '.-', 'Color', color_ci, 'HandleVisibility','off');

% Means
h_mean_2 = scatter(thresholds, all_Dt_means, 40, color_main, 'filled', ...
    'MarkerFaceAlpha', 0.7, 'MarkerEdgeColor', 'k', 'DisplayName', 'Mean Δt');

% Plot all individual Dt points (jittered horizontally for visibility)
for i = 1:length(thresholds)
    x_jitter = thresholds(i) + (rand(size(all_Dts{i})) - 0.5)*0.4*(thresholds(2)-thresholds(1));
    h_indiv = scatter(x_jitter, all_Dts{i}, 20, color_scatter, 'filled', 'MarkerFaceAlpha', 0.4, 'MarkerEdgeColor', 'none', 'DisplayName', 'Δt');
end

% Zero line
h_zero_2 = yline(0, 'k', 'LineWidth', 1, 'HandleVisibility', 'off');

% Ideal threshold
if ~isnan(ideal_threshold)
    h_ideal_2 = plot(ideal_threshold, ideal_Dt, 'k|', 'MarkerSize', 30, 'LineWidth', 1.5, 'DisplayName', sprintf('Ideal Threshold = %.4f', ideal_threshold));
end

xlabel('Threshold (pF)', 'FontSize', 14);
ylabel('Δt (s)', 'FontSize', 14);
title('Mean ± 95% CI of Δt vs Threshold', 'FontSize', 16);
grid on; box on;
set(gca, 'FontSize', 12, 'LineWidth', 1);
xlim([thresholds(1) thresholds(end)]);

legendEntries2 = [h_mean_2, h_indiv, h_ci1_2];
if ~isnan(ideal_threshold)
    legendEntries2(end+1) = h_ideal_2;
end
legend(legendEntries2, {'Mean Δt','Δt', '95% CI', sprintf('Ideal Threshold = %.4f', ideal_threshold)}, 'Location', 'northeast');
