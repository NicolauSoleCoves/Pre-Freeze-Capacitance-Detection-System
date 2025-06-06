clear all;clc;close all

% Define the folder where your files are stored
folderPath = 'C:\Users\nicol\Desktop\TFG\muntatge\MATLAB\Experiments\Exp0_Exo_H2O_Sola';

% Voltage categories and colors
voltages = [22,24];
colors = {'--', '-'}; % Blue for 22V, Orange for 24V

% Create figure
figure;
hold on;
legendEntries = {};

for v = 1:length(voltages)
    V = voltages(v);
    color = colors{v};

    % Loop through possible file indices
    for i = 1:5
        fileName = sprintf('Aigua_Sola_%dV_%d.mat', V, i);
        filePath = fullfile(folderPath, fileName);
        
        if isfile(filePath)
            % Load the .mat file
            data = load(filePath);
            
            % Plot temperature vs. time
            plot(data.timeStamp_T, data.temperature, 'LineWidth', 1.2,'Color','k','LineStyle',color);

            % Add to legend
            legendEntries{end+1} = sprintf('%dV - Test %d', V/2, i);
        end
    end
end

% Labels and formatting
xlabel('Time (s)', 'FontSize', 14);
ylabel('Temperature (ºC)', 'FontSize', 14);
title('Temperature Curves for 11V and 12V Experiments', 'FontSize', 18);
legend(legendEntries, 'Location', 'northeast');
grid on;
hold off;
ylim([-12, 23])
