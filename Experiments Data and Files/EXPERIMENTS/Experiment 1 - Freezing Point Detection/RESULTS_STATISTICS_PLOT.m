clear all; clc; close all

% Data
Tf_11 = [-9.47, -10.32, -10.00, -9.73, -10.17];
dt_exo_11 = [0.266, 0.268, 0.533, 0.532, 0.4];
dT_exo_11 = [0.04, 0.02, 0.04, 0.07, 0.06];

Tf_12 = [-9.41, -8.35, -9.03, -8.79, -9.35];
dt_exo_12 = [0.233, 0.135, 0.133, 0.8, 0.799];
dT_exo_12 = [0.04, 0.04, 0.02, 0.12, 0.06];

% Voltage labels
x_labels = {'11 V', '12 V'};
x_pos = [1, 2];

% Means and SDs
mean_Tf = [mean(Tf_11), mean(Tf_12)];
std_Tf  = [std(Tf_11), std(Tf_12)];

mean_dt = [mean(dt_exo_11), mean(dt_exo_12)];
std_dt  = [std(dt_exo_11), std(dt_exo_12)];

mean_dT = [mean(dT_exo_11), mean(dT_exo_12)];
std_dT  = [std(dT_exo_11), std(dT_exo_12)];

% Create figure
figure;

% Subplot 1: Tf (°C)
subplot(1,3,1); hold on;
errorbar(x_pos, mean_Tf, std_Tf, 'ks', 'MarkerSize', 6, 'MarkerFaceColor','k', 'LineWidth', 1);
scatter(repmat(x_pos(1),1,5), Tf_11, 'ko');
scatter(repmat(x_pos(2),1,5), Tf_12, 'ko');
xlim([0.5 2.5]);
xticks(x_pos); xticklabels(x_labels);
set(gca, 'FontSize', 14)
ylabel('T_f (°C)', 'FontSize', 16);
title('Final Temperature T_f', 'FontSize', 16);
grid on;

% Subplot 3: Δt_exo (s)
subplot(1,3,3); hold on;
errorbar(x_pos, mean_dt, std_dt, 'ks', 'MarkerSize', 6, 'MarkerFaceColor','k', 'LineWidth', 1);
scatter(repmat(x_pos(1),1,5), dt_exo_11, 'ko');
scatter(repmat(x_pos(2),1,5), dt_exo_12, 'ko');
xlim([0.5 2.5]);
xticks(x_pos); xticklabels(x_labels);
set(gca, 'FontSize', 14)
ylabel('Δt_{exo} (s)', 'FontSize', 16);
title('Time Interval Δt_{exo}', 'FontSize', 16);
grid on;

% Subplot 2: ΔT_exo (°C)
subplot(1,3,2); hold on;
errorbar(x_pos, mean_dT, std_dT, 'ks', 'MarkerSize', 6, 'MarkerFaceColor','k', 'LineWidth', 1);
scatter(repmat(x_pos(1),1,5), dT_exo_11, 'ko');
scatter(repmat(x_pos(2),1,5), dT_exo_12, 'ko');
xlim([0.5 2.5]);
xticks(x_pos); xticklabels(x_labels);
set(gca, 'FontSize', 14)
ylabel('ΔT_{exo} (°C)', 'FontSize', 16);
title('Temperature Interval ΔT_{exo}', 'FontSize', 16);
grid on;

% Legend
lgd = legend(["Mean ± Standard deviation with CI = 96%","Data points"]);
set(lgd, 'FontSize', 14);

% Improve layout
sgtitle('Exothermic Phase Comparison: 11 V vs 12 V', 'FontSize', 18);
