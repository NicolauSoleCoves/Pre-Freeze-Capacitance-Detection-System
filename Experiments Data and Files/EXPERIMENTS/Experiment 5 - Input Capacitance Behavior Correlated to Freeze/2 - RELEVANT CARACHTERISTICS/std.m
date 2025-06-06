clear all; clc; close all

%% ------------------------ CONSTANTS ------------------------
folderPath = 'C:\Users\nicol\Desktop\TFG\muntatge\MATLAB\Experiments\FINAL_DETECTION_ALGORITHM\DATA';
fileName = '24V_celulose_film_8_layers_Ac_4_1_cm_AP_TP_GEL_COMPROVAT_INII_GEL_1';

WindowSize_C = 25;   % Window size for moving average on C
WindowSize_S = 25;   % Window size for std(C)

th1 = 0.017;          % Upper threshold
th2 = 0.0025;        % Lower threshold

xlimit = [0 500];

%% ------------------------ LOAD DATA ------------------------
cd(folderPath);
load(fileName);  % Loads: timeStamp_T, temperature, evmTimestamps, C4

% Clean up C4 from outliers
for i = 2:length(C4)
    if C4(i) < 2 || C4(i) > 15.6
        C4(i) = C4(i-1);
    end
end

t_C = evmTimestamps;
t_T = timeStamp_T;

% Extract sample ID from filename
parts = regexp(fileName, '\d+', 'match');
if isempty(parts)
    sampleID = 'Unknown Sample';
else
    sampleID = sprintf('Sample %s', parts{end});
end

%% ------------------------ PROCESSING ------------------------
% Moving average filter
C4_filtered = movmean(C4, WindowSize_C);

% Moving standard deviation
std_C = movstd(C4_filtered, WindowSize_S);

%% ------------------------ DETECTION BASED ON std(C) ------------------------
P1 = false;
for i = 1:length(std_C)
    if std_C(i) > th1
        P1 = true;
    end
    if P1 && std_C(i) < th2
        t_change = t_C(i);
        C_change = C4_filtered(i);
        break;
    end
end

% Interpolate temperature at t_change
[t_T_unique, uniqueIdx] = unique(t_T, 'stable');
temperature_unique = temperature(uniqueIdx);
T_change = interp1(t_T_unique, temperature_unique, t_change);

%% ------------------------ PLOTTING ------------------------
figure(1); clf

% Subplot 1: C(t) and T(t)
subplot(2,1,1); hold on
yyaxis right
    % plot(t_C, C4, 'k.', 'DisplayName', 'Raw C_in', 'MarkerSize', 1);
    plot(t_C, C4_filtered, ...
        'Color', "magenta", ...
        'LineStyle', ':', ...
        'LineWidth', 1.5, ...
        'DisplayName', 'Filtered Capacitance');
    plot(t_change, C_change, 'k|', 'DisplayName', 'C_{change}', 'MarkerSize', 15, 'LineWidth', 1);
    ylabel('Capacitance (pF)');
    ax = gca; ax.YColor = 'k';

yyaxis left
    plot(t_T, temperature, ...
        'Color', "#A2142F", ...
        'LineStyle', "-.", ...
        'LineWidth', 1.5, ...
        'DisplayName', 'Temperature');
    plot(t_change, T_change, 'k|', 'DisplayName', 'T_{change}', 'MarkerSize', 15, 'LineWidth', 1);
    ylabel('Temperature (°C)');
    ax.YColor = 'k';

xlim(xlimit);
xlabel('Time (s)', 'FontSize', 12);
legend('Location', 'best', 'NumColumns', 2);
title('Filtered Capacitance and Temperature');
grid on;
hold off

subplot(2,1,2); hold on
plot(t_C, std_C, 'b-', 'DisplayName', '\sigma(C(t))');
yline(th1,"Color",[0.5, 0.5, 0.5],"LineWidth",2, "DisplayName", 'th_1', 'LabelHorizontalAlignment', 'left');
yline(th2, 'k',"LineWidth",2, "DisplayName", 'th_2', 'LabelHorizontalAlignment', 'left');
plot(t_change, std_C(i), 'k|', 'DisplayName', 'std Change Point', 'MarkerSize', 15, 'LineWidth', 1);
ylabel('\sigma(C(t)) (pF)', 'FontSize', 12);
xlabel('Time (s)', 'FontSize', 12);
xlim(xlimit);
legend('Location', 'best');
title('Standard Deviation of C(t)');
grid on;
hold off


sgtitle(['Complete Data Overview of ' sampleID], 'FontSize', 20);

%% ------------------------ PRINT DETECTION RESULTS ------------------------
fprintf('\n--- STD-based Detection Summary ---\n');
fprintf('t_change = %.2f s\n', t_change);
fprintf('C_change = %.4f pF\n', C_change);
fprintf('T_change = %.2f °C\n', T_change);
