clear all; clc; close all

%% ---------------------------------CONSTANTS-------------------------------------------------------
folderPath = 'C:\Users\nicol\Desktop\TFG\muntatge\MATLAB\Experiments\C\ANALISIS';
fileName = '24V_celulose_film_8_layers_Ac_4_1_cm_1';
WindowSize_C = 25; % Window size for averaging C
WindowSize_dC = 25; % Window size for smoothing derivative

xlimit = [0 700];

%% ----------- Load data ------------------------------------------------
cd(folderPath);
load(fileName);  % loads: timeStamp_T, temperature, evmTimestamps, C4

% Clean C4 data from outliers
for i = 2:length(C4)
    if C4(i) < 2 || C4(i) > 15.6
        C4(i) = C4(i-1);
    end
end

t_C = evmTimestamps;
t_T = timeStamp_T;

%% ----------------------SIGNAL PROCESSING-------------------------------------------------------
% Moving average filter on C4
C4_filtered = movmean(C4, WindowSize_C);

% Derivative
dt = mean(diff(t_C));
dCdt = gradient(C4_filtered, dt);

% Smooth the derivative
dCdt_smoothed = movmean(dCdt, WindowSize_dC);

% Zero-crossing detection from smoothed derivative
sign_dCdt = sign(dCdt_smoothed);
zeroCrossings = diff(sign_dCdt);

% Peaks (from + to -): -2
peakIndices = find(zeroCrossings == -2) + 1;

% Valleys (from - to +): +2
valleyIndices = find(zeroCrossings == 2) + 1;

% Extract sample ID from filename
parts = regexp(fileName, '\d+', 'match');
if isempty(parts)
    sampleID = 'Unknown Sample';
else
    sampleID = sprintf('Sample %s', parts{end});
end

%% ----------------------PLOT-------------------------------------------------------
figure(1); clf

% First subplot: C(t) + T(t) + peaks/valleys
subplot(2,1,1);
hold on
yyaxis right
    plot(t_C, C4_filtered, ...
        'Color', "magenta", ...
        'LineStyle', ':', ...
        'LineWidth', 1.5, ...
        'DisplayName', 'Filtered Capacitance');
    plot(t_C(peakIndices), C4_filtered(peakIndices), 'r|', 'MarkerSize', 25, 'DisplayName', 'Peaks');
    plot(t_C(valleyIndices), C4_filtered(valleyIndices), 'g|', 'MarkerSize', 25, 'DisplayName', 'Valleys');
    ylabel('Capacitance (pF)', 'FontSize', 12);
    ax = gca; ax.YColor = "k";

yyaxis left
    plot(t_T, temperature, ...
        'Color', "#A2142F", ...
        'LineStyle', "-.", ...
        'LineWidth', 1.5, ...
        'DisplayName', 'Temperature');
    ylabel('Temperature (°C)', 'FontSize', 12);
    ax.YColor = "k";

xlim(xlimit);
xlabel('Time (s)');
title('Reference Data \it{C(t)} and \it{T(t)}');
legend('Location', 'best', 'NumColumns', 2,'FontSize',16);
grid on;
hold off

% Second subplot: Smoothed derivative and zero line
subplot(2,1,2);
hold on
plot(t_C, dCdt_smoothed, '-', 'Color', "k", 'LineWidth', 1.5, 'DisplayName', sprintf('Smoothed dC/dt, W = %d',WindowSize_dC));
yline(0, '--b', 'LineWidth', 1.5, 'DisplayName', 'x = 0');
ylabel('dC/dt (pF/s)', 'FontSize', 12);
xlabel('Time (s)');
xlim(xlimit);
title('Smoothed Derivative of Filtered C');
legend('Location', 'best','FontSize',16);
grid on;
hold off

% Super title
sgtitle(['Complete Data Overview of ' sampleID], 'FontSize', 20);
