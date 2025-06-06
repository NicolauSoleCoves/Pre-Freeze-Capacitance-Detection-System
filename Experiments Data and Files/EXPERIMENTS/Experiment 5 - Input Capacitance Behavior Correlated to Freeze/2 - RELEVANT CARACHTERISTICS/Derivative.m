clear all; clc; close all

%% ---------------------------------CONSTANTS-------------------------------------------------------
folderPath = 'C:\Users\nicol\Desktop\TFG\muntatge\MATLAB\Experiments\C\ANALISIS';
fileName = '24V_celulose_film_8_layers_Ac_4_1_cm_1';
WindowSize_C = 25; % Window size for averaging the C

xlimit = [0 500];

%% ----------- Load data ------------------------------------------------
cd(folderPath);
load(fileName);  % loads: timeStamp_T, temperature, evmTimestamps, C4

% Clean up C4 data from outliers
for i = 2:length(C4)
    if C4(i) < 2 || C4(i) > 15.6
        C4(i) = C4(i-1);
    end
end

t_C = evmTimestamps;
t_T = timeStamp_T;

%% ----------------------SIGNAL PROCESSING-------------------------------------------------------
% Moving average filter on C4:
C4_filtered = movmean(C4, WindowSize_C);

% Calculate time step dt:
dt = mean(diff(t_C));

% Derivative of filtered C4 (no smoothing):
dCdt = gradient(C4_filtered, dt);

% Detect zero crossings in the derivative (sign changes)
sign_dCdt = sign(dCdt);
zeroCrossings = diff(sign_dCdt);

% Peak indices (from + to -): zeroCrossings == -2
peakIndices = find(zeroCrossings == -2) + 1;

% Valley indices (from - to +): zeroCrossings == +2
valleyIndices = find(zeroCrossings == 2) + 1;

% Extract sample ID from filename
    parts = regexp(fileName, '\d+', 'match');
    if isempty(parts)
        sampleID = sprintf('File_%d', k);
    else
        sampleID = sprintf('Sample_%s', parts{end});
    end

%% ----------------------PLOT-------------------------------------------------------
figure(1); clf

% First subplot: Temperature, filtered Capacitance and zero crossing bars
subplot(2,1,1);
hold on
yyaxis right
    plot(evmTimestamps, C4_filtered, ...
        'Color', "magenta", ...
        'LineStyle', ':', ...
        'LineWidth', 1.5, ...
        'DisplayName', 'Filtered Capacitance');
    % Plot zero crossing peaks and valleys as vertical bars
    plot(t_C(peakIndices), C4_filtered(peakIndices), 'r|', 'MarkerSize', 25, 'DisplayName', 'Peaks');
    plot(t_C(valleyIndices), C4_filtered(valleyIndices), 'g|', 'MarkerSize', 25, 'DisplayName', 'Valleys');
    ylabel('Capacitance (pF)', 'FontSize', 12);
    ax = gca;
    ax.YColor = "k";

yyaxis left
    plot(timeStamp_T, temperature, ...
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

% Second subplot: Derivative on left axis and zero horizontal line
subplot(2,1,2);
hold on
plot(t_C, dCdt, '-', 'Color', "k", 'LineWidth', 1.5, 'DisplayName', 'dC/dt');
ylabel('dC/dt (pF/s)', 'FontSize', 12);
yline(0, '--b', 'LineWidth', 1.5, 'DisplayName', 'x = 0');  % Horizontal line at y=0


xlim(xlimit);
xlabel('Time (s)');
title('Derivative of Filtered C');
legend('Location', 'best','FontSize',16);
grid on;
hold off

sgtitle(['Complete Data Overview of ' strrep(sampleID, '_', ' ')], 'FontSize', 20)