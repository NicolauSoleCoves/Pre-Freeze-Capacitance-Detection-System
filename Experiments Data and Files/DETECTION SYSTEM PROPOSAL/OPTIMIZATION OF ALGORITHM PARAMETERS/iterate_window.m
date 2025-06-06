clc; clear; close all;

% Parameters
sourceFolder = 'C:\Users\nicol\Desktop\TFG\muntatge\MATLAB\Experiments\C\ANALISIS\T_EXO_STATISTICS';
thup = 0.017;
threshold = 0.0021;  % fixed threshold for this test (or you can also loop over thresholds)
WindowSizes = 5:2:100;  % example range of window sizes to iterate over
z = 2.05;  % t-score for 95% confidence interval

% Store results
all_DT_means = [];
all_DT_ci = [];
all_DT_ns = [];

all_Dt_means = [];
all_Dt_ci = [];
all_Dt_ns = [];

% Store all individual DTs and Dts per WindowSize
all_DTs = cell(1, length(WindowSizes));
all_Dts = cell(1, length(WindowSizes));

% Loop over WindowSizes
for i = 1:length(WindowSizes)
    WindowSize_C = WindowSizes(i);
    WindowSize_S = WindowSizes(i);
    numfigure = i;

    % Call your freeze detection function
    [DTs, Dts, ~, ~] = freez_detect(sourceFolder, thup, threshold, WindowSize_C, WindowSize_S, numfigure, 0);

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

    % Store statistics and sample counts
    all_DT_means(end+1) = m_DT;
    all_DT_ci(end+1) = ci_DT;
    all_DT_ns(end+1) = n_DT;

    all_Dt_means(end+1) = m_Dt;
    all_Dt_ci(end+1) = ci_Dt;
    all_Dt_ns(end+1) = n_Dt;
end

% Find ideal WindowSize based on maximum total number of samples detected
total_samples = all_DT_ns + all_Dt_ns;  % total samples for each window size

% Find the index of maximum total samples
[~, ideal_index] = max(total_samples);

ideal_window = WindowSizes(ideal_index);
ideal_DT = all_DT_means(ideal_index);
ideal_Dt = all_Dt_means(ideal_index);


%% PLOT
figure(101); clf
color_main = [0 0 0];         % Black
color_ci = [0.5 0.5 0.5];     % Gray
color_scatter = [0.6 0.6 0.6];  % Light blue for individual points

% --- Subplot 1: ΔT ---
subplot(2,1,1); hold on;

% Plot CI bounds
h_ci1 = plot(WindowSizes, all_DT_means - all_DT_ci, '.-', 'Color', color_ci, 'DisplayName', '95% CI lower');
plot(WindowSizes, all_DT_means + all_DT_ci, '.-', 'Color', color_ci, 'HandleVisibility','off');

% Plot means
h_mean1 = scatter(WindowSizes, all_DT_means, 40, color_main, 'filled', ...
    'MarkerFaceAlpha', 0.7, 'MarkerEdgeColor', 'k', 'DisplayName', 'Mean ΔT');

% Plot all individual DT points (jittered horizontally for visibility)
for i = 1:length(WindowSizes)
    x_jitter = WindowSizes(i) + (rand(size(all_DTs{i})) - 0.5)*0.4; % jitter in ±0.2 range
    h_indiv = scatter(x_jitter, all_DTs{i}, 20, color_scatter, 'filled', 'MarkerFaceAlpha', 0.4, 'MarkerEdgeColor', 'none', 'DisplayName', 'ΔT');
end

% Zero line
yline(0, 'k', 'LineWidth', 1, 'HandleVisibility', 'off');

% Ideal window marker
if ~isnan(ideal_window)
    h_ideal1 = plot(ideal_window, ideal_DT, 'k|', 'MarkerSize', 30, 'LineWidth', 1.5, 'DisplayName', sprintf('  Ideal Window = %d', ideal_window));
end

ylabel('ΔT (°C)', 'FontSize', 14);
title('Mean ± 95% CI of ΔT vs Window Size', 'FontSize', 16);
grid on; box on;
set(gca, 'FontSize', 12, 'LineWidth', 1);
xlim([WindowSizes(1)-1 WindowSizes(end)+1]);
legend([h_mean1,h_indiv, h_ci1, h_ideal1], 'Location', 'best');

% --- Subplot 2: Δt ---
subplot(2,1,2); hold on;

h_ci2 = plot(WindowSizes, all_Dt_means - all_Dt_ci, '.-', 'Color', color_ci, 'DisplayName', '95% CI lower');
plot(WindowSizes, all_Dt_means + all_Dt_ci, '.-', 'Color', color_ci, 'HandleVisibility','off');

h_mean2 = scatter(WindowSizes, all_Dt_means, 40, color_main, 'filled', ...
    'MarkerFaceAlpha', 0.7, 'MarkerEdgeColor', 'k', 'DisplayName', 'Mean Δt');

% Plot all individual Dt points (jittered horizontally for visibility)
for i = 1:length(WindowSizes)
    x_jitter = WindowSizes(i) + (rand(size(all_Dts{i})) - 0.5)*0.4;
    h_indiv = scatter(x_jitter, all_Dts{i}, 20, color_scatter, 'filled', 'MarkerFaceAlpha', 0.4, 'MarkerEdgeColor', 'none', 'DisplayName', 'Δt');
end

yline(0, 'k', 'LineWidth', 1, 'HandleVisibility', 'off');

if ~isnan(ideal_window)
    h_ideal2 = plot(ideal_window, ideal_Dt, 'k|', 'MarkerSize', 30, 'LineWidth', 1.5, 'DisplayName', sprintf('  Ideal Window = %d', ideal_window));
end

xlabel('Window Size (samples)', 'FontSize', 14);
ylabel('Δt (s)', 'FontSize', 14);
title('Mean ± 95% CI of Δt vs Window Size', 'FontSize', 16);
grid on; box on;
set(gca, 'FontSize', 12, 'LineWidth', 1);
xlim([WindowSizes(1)-1 WindowSizes(end)+1]);
legend([h_mean2,h_indiv, h_ci2, h_ideal2], 'Location', 'best');
