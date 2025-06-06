clear; clc; close all;

% Folder containing the data files
folderPath = 'C:\Users\nicol\Desktop\TFG\muntatge\MATLAB\Experiments\C\Ideal Distance\Try3_IN_OUT\Ac_4_4';

% Distance mapping
distanceLabels = {'1cm', '2cm', '3cm', '4cm', '5cm'};
numDistances = length(distanceLabels);
numTrials = 5;

% Create one figure for all subplots
figure('Name', 'Capacitance Curves - All Distances and Trials', 'NumberTitle', 'off');
tiledlayout(numDistances, numTrials, 'Padding', 'compact', 'TileSpacing', 'compact');

% Loop through all distances and trials
for d = 1:numDistances
    for trial = 1:numTrials
        % Construct file name
        fileName = sprintf('24V_celulose_film_8_layers_Ac_4_%d_cm_%d.mat', d, trial);
        filePath = fullfile(folderPath, fileName);

        % Move to next tile
        nexttile;
        hold on;

        if exist(filePath, 'file')
            data = load(filePath);
            if isfield(data, 'evmTimestamps') && isfield(data, 'C4')
                plot(data.evmTimestamps, data.C4, 'k', 'LineWidth', 1.2);
                title(sprintf('Trial %d', trial), 'FontSize', 8);
            else
                text(0.5, 0.5, 'Missing vars', 'HorizontalAlignment', 'center');
            end
        else
            text(0.5, 0.5, 'Missing file', 'HorizontalAlignment', 'center');
        end

        % Axis labels
        if d == numDistances
            xlabel('Time (s)', 'FontSize', 12);
        end
        if trial == 1
            ylabel(sprintf('d = %s\nCin (pF)', distanceLabels{d}), 'FontSize', 12);  % Distance + Y-axis label
        end

        % Axis limits and formatting
        xlim([0, 30]);
        ylim([3.1, 7.2]);
        set(gca, 'FontSize',10);
        grid on;
    end
end

% Add a shared title
sgtitle('Capacitance Curves for each 5 distances ({\itd}) with an {\itA_c}= 16 cm^2', 'FontSize', 20);
