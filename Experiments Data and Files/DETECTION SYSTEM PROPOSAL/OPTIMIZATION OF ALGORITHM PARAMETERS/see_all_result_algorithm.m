clear all; clc; close all

%% ------------------------ CONSTANTS ------------------------
folderPath = 'C:\Users\nicol\Desktop\TFG\muntatge\MATLAB\Experiments\C\ANALISIS\T_EXO_STATISTICS';
WindowSize_C = 25;
WindowSize_S = 25;
th1 = 0.017;
th2 = 0.0025;
xlimit = [0 1000];
saveFigures = true;

cd(folderPath);
fileList = dir('*.mat');

for f = 1:length(fileList)
    %% ------------------------ LOAD DATA ------------------------
    fileName = fileList(f).name;
    [~, nameOnly, ~] = fileparts(fileName);

    % Skip "_exopeak.mat" cache files
    if endsWith(fileName, '_exopeak.mat')
        continue;
    end

    load(fileName);  % Assumes C4, temperature, timeStamp_T, evmTimestamps

    % Clean up C4
    for i = 2:length(C4)
        if C4(i) < 2 || C4(i) > 15.6
            C4(i) = C4(i-1);
        end
    end

    t_C = evmTimestamps;
    t_T = timeStamp_T;

    % Sample ID
    parts = regexp(fileName, '\d+', 'match');
    sampleID = 'Unknown Sample';
    if ~isempty(parts)
        sampleID = sprintf('Sample %s', parts{end});
    end

    %% ------------------------ PROCESSING ------------------------
    C4_filtered = movmean(C4, WindowSize_C);
    std_C = movstd(C4_filtered, WindowSize_S);

    %% ----------- USE CACHED EXOPEAK VALUES IF AVAILABLE ----------
    cacheFile = fullfile(folderPath, [nameOnly '_exopeak.mat']);
    if exist(cacheFile, 'file')
        load(cacheFile, 't_peak_exo', 'T_peak', 't_C_at_freeze', 'C_at_freeze', 'T_ini_exo', 't_exo_ini');
        fprintf('Loaded exopeak cache for %s\n', fileName);
    else
        % Compute manually if cache doesn't exist
        [t_peak_exo, T_peak, ~, ~, T_ini_exo, t_exo_ini] = exopeak_choose(t_T, temperature, C4_filtered, t_C);
        [~, idx_C_nearest] = min(abs(t_C - t_peak_exo));
        t_C_at_freeze = t_C(idx_C_nearest);
        C_at_freeze = C4_filtered(idx_C_nearest);
        save(cacheFile, 't_peak_exo', 'T_peak', 't_C_at_freeze', 'C_at_freeze', 'T_ini_exo', 't_exo_ini');
        fprintf('Saved exopeak cache for %s\n', fileName);
    end

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
    T_change = interp1(t_T_unique, temperature(uniqueIdx), t_change);

    delta_t = t_change - t_exo_ini;
    delta_T = T_ini_exo - T_change;

    %% ------------------------ PLOTTING ------------------------
    figure(f); clf;

    subplot(2,1,1); hold on
        yyaxis right
            plot(t_C, C4_filtered, 'm:', 'LineWidth', 1.5);
            plot(t_change, C_change, 'k|', 'MarkerSize', 15, 'LineWidth', 1);
            ylabel('Capacitance (pF)');
            text(mean(xlimit), max(C4_filtered), ...
                sprintf('\\Delta t = %.2f s\\newlineT = %.2f °C', delta_t, T_change), ...
                'FontSize', 10, 'Color', 'b', 'HorizontalAlignment', 'center');
        ax = gca;
        ax.YColor="k";

        yyaxis left
            plot(t_T, temperature, '-.', 'Color', "#A2142F", 'LineWidth', 1.5);
            plot(t_change, T_change, 'k|', 'MarkerSize', 15, 'LineWidth', 1);
            plot(t_exo_ini, T_ini_exo, 'kx', 'MarkerSize', 15, 'LineWidth', 1);
            ylabel('Temperature (°C)');
        xlim(xlimit); xlabel('Time (s)');
        ax = gca;
        ax.YColor="k";
        legend('show', 'Location', 'best', 'NumColumns', 2);
        title('Filtered Capacitance and Temperature');
        grid on;
    hold off

    subplot(2,1,2); hold on
        plot(t_C, std_C, 'b-', 'DisplayName', '\sigma(C(t))');
        yline(th1, '--', 'Color', [0.5, 0.5, 0.5], 'LineWidth', 2);
        yline(th2, 'k--', 'LineWidth', 2);
        plot(t_change, std_C(i), 'k|', 'MarkerSize', 15, 'LineWidth', 1);
        ylabel('\sigma(C(t)) (pF)'); xlabel('Time (s)');
        xlim(xlimit); legend('Location', 'best');
        ax = gca;
        ax.YColor="k"; 
        title('Standard Deviation of C(t)');
        grid on;
    hold off

    sgtitle(['Complete Data Overview of ' sampleID], 'FontSize', 20);

    %% ------------------------ SAVE FIGURE ------------------------
    if saveFigures
        figName = fullfile(folderPath, [nameOnly '_plot.png']);
        saveas(gcf, figName);
        fprintf('Saved figure: %s\n', figName);
    end
end
