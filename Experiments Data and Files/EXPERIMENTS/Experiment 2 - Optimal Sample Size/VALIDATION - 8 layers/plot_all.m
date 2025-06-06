% Define folder and base name
folderPath = 'C:\Users\nicol\Desktop\TFG\muntatge\MATLAB\Experiments\Exp1_Exotermic\8_LAYERS';
baseName = '24V_celulose_film_8_layers';
numTrials = 30;

% Create figure for subplots
figure('Name', 'All 30 Trials of Freezing Detection');
tiledlayout(6, 5, 'Padding', 'compact', 'TileSpacing', 'compact');

% Loop through files
for i = 1:numTrials
    % Construct file name
    fileName = sprintf('%s_%d.mat', baseName, i);
    filePath = fullfile(folderPath, fileName);
    
    if exist(filePath, 'file')
        % Load the data
        load(filePath, 'temperature', 'timeStamp_T');
        
        % Plot in subplot
        nexttile;
        plot(timeStamp_T, temperature, 'Color', "#A2142F");
        title(sprintf('Trial %d', i), 'FontSize', 12);
        xlabel('Time (s)','FontSize',10);
        ylabel('Temp (°C)','FontSize',10);
        xlim([100,450]);
        ylim([-4,7]);
        grid on;
    else
        warning('File not found: %s', filePath);
    end
end

% Add a shared title
sgtitle('Temperature Curves for Water-Saturated Absorbent Paper Samples with 8 layers', 'FontSize', 20);
