clear; clc; close all

% Source folder containing .mat files
sourceFolder = 'C:\Users\nicol\Desktop\TFG\muntatge\MATLAB\Experiments\C\ANALISIS';

% Destination folder for figures
outputFolder = fullfile(sourceFolder, 'EXPERIMENT 5');

% Create output folder if it doesn't exist
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Load all .mat files in the folder
files = dir(fullfile(sourceFolder, '*.mat'));
windowSize = 25;

% Iterate over all files
for k = 1:length(files)
    fileName = files(k).name;
    filePath = fullfile(sourceFolder, fileName);
    data = load(filePath);

    % Skip if required fields are missing
    if ~all(isfield(data, {'C4', 'temperature', 'timeStamp_T', 'evmTimestamps'}))
        fprintf('Skipping file: %s (missing required data)\n', fileName);
        continue;
    end

    % Extract sample ID from filename
    parts = regexp(fileName, '\d+', 'match');
    if isempty(parts)
        sampleID = sprintf('File_%d', k);
    else
        sampleID = sprintf('Sample_%s', parts{end});
    end

    % Remove outliers from C4
    for i = 2:length(data.C4)
        if data.C4(i) < 2 || data.C4(i) > 15.6
            data.C4(i) = data.C4(i-1);
        end
    end

    % Filter C4
    C4_filtered = movmean(data.C4, windowSize);

    % Create full-screen visible figure BEFORE plotting
    fig = figure('Visible', 'on', 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
    clf; hold on;

    % Plot temperature (yyaxis right)
    yyaxis right
    plot(data.timeStamp_T, data.temperature, ...
        'Color', "#A2142F", ...
        'LineStyle', "-.", ...
        'LineWidth', 1.5, ...
        'DisplayName', 'Temperature');
    ylabel('Temperature (ºC)', 'FontSize', 16);
    ax = gca;
    ax.YColor = "#000000";

    % Plot capacitance (yyaxis left)
    yyaxis left
    plot(data.evmTimestamps, C4_filtered, ...
        'Color', "magenta", ...
        'LineStyle', ':', ...
        'LineWidth', 1.5, ...
        'DisplayName', 'Filtered Capacitance');
    ylabel('Capacitance (pF)', 'FontSize', 16);
    ax.YColor = "k";

    % Common settings
    xlabel('Time (s)', 'FontSize', 16);
    title(['Complete Data Overview of ' strrep(sampleID, '_', ' ')], 'FontSize', 20);
    legend("Location", "northeast", 'FontSize', 10, "NumColumns", 2);
    xlim([0 1000]);
    grid on;

    % Force layout update
    drawnow;

    % Save figure as .png
    savePath = fullfile(outputFolder, [sampleID '.png']);
    exportgraphics(fig, savePath, 'Resolution', 300);  % High resolution
    close(fig);  % Close to free memory

    fprintf('Saved figure: %s\n', savePath);
end
