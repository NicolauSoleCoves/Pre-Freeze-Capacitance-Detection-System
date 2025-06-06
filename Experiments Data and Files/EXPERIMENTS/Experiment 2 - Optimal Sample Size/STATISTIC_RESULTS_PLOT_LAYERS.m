clear all; clc; close all

% Number of layers
x_labels = {'1', '2', '4', '8', '16'};
x_pos = 1:5;

% Data: Δt_exo (s)
dt_exo = {
    [44.462, 7.365], ...
    [3.522, 10.088], ...
    [3.895, 3.521, 3.307], ...
    [3.097, 9.393, 6.671, 4.003, 3.415], ...
    [14.037, 8.967, 6.351, 3.201, 14.196]
};

% Data: ΔT_exo (°C)
dT_exo = {
    [0.37, 0.09], ...
    [0.05, 0.05], ...
    [0.7, 0.4, 0.21], ...
    [0.91, 0.8, 0.84, 0.05, 0.15], ...
    [1.55, 1.22, 0.62, 0.51, 0.83]
};

% Compute means and stds
mean_dt = cellfun(@mean, dt_exo);
std_dt  = cellfun(@std, dt_exo);

mean_dT = cellfun(@mean, dT_exo);
std_dT  = cellfun(@std, dT_exo);

% Create figure
figure;

% Subplot 2: Δt_exo (s)
subplot(1,2,2); hold on;
errorbar(x_pos, mean_dt, std_dt, 'ks', 'MarkerSize', 6, 'MarkerFaceColor','k', 'LineWidth', 1);
for i = 1:length(x_pos)
    scatter(repmat(x_pos(i),1,length(dt_exo{i})), dt_exo{i}, 'ko');
end
xlim([0.5 5.5]);
xticks(x_pos); xticklabels(x_labels);
xlabel('Number of layers', 'FontSize', 16)
ylabel('Δt_{exo} (s)', 'FontSize', 16);
title('Time Interval Δt_{exo}', 'FontSize', 16);
grid on;
set(gca, 'FontSize', 14)

% Subplot 1: ΔT_exo (°C)
subplot(1,2,1); hold on;
errorbar(x_pos, mean_dT, std_dT, 'ks', 'MarkerSize', 6, 'MarkerFaceColor','k', 'LineWidth', 1);
for i = 1:length(x_pos)
    scatter(repmat(x_pos(i),1,length(dT_exo{i})), dT_exo{i}, 'ko');
end
xlim([0.5 5.5]);
xticks(x_pos); xticklabels(x_labels);
xlabel('Number of layers', 'FontSize', 16)
ylabel('ΔT_{exo} (°C)', 'FontSize', 16);
title('Temperature Interval ΔT_{exo}', 'FontSize', 16);
grid on;
set(gca, 'FontSize', 14)

% Legend
lgd = legend(["Mean ± Standard deviation","Data points"]);
set(lgd, 'FontSize', 14);

% Super title
sgtitle('Exothermic Interval by Number of Layers', 'FontSize', 18);
