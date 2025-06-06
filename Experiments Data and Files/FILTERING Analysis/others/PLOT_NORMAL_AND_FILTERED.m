clear all; clc; close all;
% === Load latest saved file from your folder ===
folderPath = 'C:\Users\nicol\Desktop\TFG\muntatge\MATLAB\Experiments\C\ANALISIS\T_EXO_STATISTICS';
baseName = '24V_celulose_film_8_layers_Ac_4_1_cm_26';

% Get list of all .mat files matching the pattern
files = dir(fullfile(folderPath, [baseName, '_*.mat']));

if isempty(files)
    error('No files found in folder matching base name.');
end

[~, idx] = max([files.datenum]);
latestFile = fullfile(folderPath, baseName);
load(latestFile);  % Should load: timeStamp_T, temperature, evmTimestamps, C4

%% ------------------------------ FINAL PLOT ------------------------------
figure(2);
clf;
hold on;

yyaxis right
plot(timeStamp_T, temperature, 'Color', "#A2142F",'DisplayName', 'Temperature')
ylabel('Temperature (ºC)','FontSize',16);
ax = gca;
ax.YColor = "#000000";
%ylim([-3, 8])

% === Filter (moving average) the capacitance data ===
windowSize = 15;
C4_filtered = movmean(C4, windowSize);

yyaxis left
plot(evmTimestamps, C4, 'Color', "#000000", 'DisplayName', 'Capacitance')
%plot(evmTimestamps, C4_filtered, 'Color', "#EDB120",'LineStyle','-', 'DisplayName', 'Filtered Capacitance');
ylabel('Capacitance (pF)','FontSize',16);
ax.YColor = "k";
%ylim([11.9, 13.2])

xlabel('Time (s)','FontSize',16);
title('Complete Data Overview','FontSize',24);
legend("Location", "northeast", 'FontSize', 12, "NumColumns", 4);
grid on;
hold off;