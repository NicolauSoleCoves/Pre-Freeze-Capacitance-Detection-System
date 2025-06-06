clear all; clc; close all;

%% ------------------------ CONSTANTS ------------------------
folderPath = 'C:\Users\nicol\Desktop\TFG\muntatge\MATLAB\Experiments\FINAL_DETECTION_ALGORITHM\DATA_CLASSIFIED';
WindowSize_C = 25;
WindowSize_S = 25;
th1 = 0.017;
th2 = 0.0025;
xlimit = [0 600];

%% ------------------------ GET FILES ------------------------
cd(folderPath);
files = dir('*.mat');

% Initialize results table
results = [];
labels = [];
%% ------------------------ PROCESS EACH FILE ------------------------
for k = 1:length(files)
    fileName = files(k).name;
    load(fileName);  % Loads: timeStamp_T, temperature, evmTimestamps, C4
    
    % Skip cache files
    if startsWith(fileName, 'exo_cache')
        continue;
    end

    % Parse classification metadata from filename
    tokens = regexp(fileName, '_(AP|AN)_(PP|PN)_(\d+).mat$', 'tokens');
    
    if ~isempty(tokens)
        actualClass = tokens{1}{1};   % 'AP' or 'AN'
        predictedClass = tokens{1}{2}; % 'PP' or 'PN'
        sampleNumber = tokens{1}{3};   %
        overviewTitle = sprintf('Overview: Actual %s - Predicted %s - Sample %s', ...
                                actualClass, predictedClass, sampleNumber);
    else
        overviewTitle = 'Overview: Unknown Classification';
    end

    % Clean up C4 from outliers
    for i = 2:length(C4)
        if C4(i) < 2 || C4(i) > 15.6
            C4(i) = C4(i-1);
        end
    end

    % Rename variables
    t_C = evmTimestamps;
    t_T = timeStamp_T;

    % Parse file name
    isAP = contains(fileName, '_AP');
    isAN = contains(fileName, '_AN');
    isPP = contains(fileName, '_PP');
    isPN = contains(fileName, '_PN');

    % Sample name
    sampleID = fileName;

    % Moving average and std
    C4_filtered = movmean(C4, WindowSize_C);
    std_C = movstd(C4_filtered, WindowSize_S);

    % Initialize values
    detected = false;
    t_change = NaN; C_change = NaN; T_change = NaN;
    T_ini_exo = NaN; t_ini_exo = NaN; T_peak_exo = NaN; t_peak_exo = NaN;
    DT = NaN; Dt = NaN;

    % Only call exopeak_choose if AP
    if isAP
        [t_peak_exo, T_peak_exo, ~, ~, T_ini_exo, t_ini_exo] = ...
            exopeak_choose(t_T, temperature, C4_filtered, t_C, fileName);
    end

    % Detection via std(C)
    idx_th1 = 0;
    for i = 1:length(std_C)
        if std_C(i) > th1
            idx_th1 = i;
            for j = i+1:length(std_C)
                if std_C(j) < th2
                    idx_th2 = j;
                    t_change = t_C(j);
                    C_change = C4_filtered(j);
                    detected = true;
                    break;
                end
            end
            break;
        end
    end

    % Interpolate temperature at t_change
    if detected
        [t_T_unique, uniqueIdx] = unique(t_T, 'stable');
        temperature_unique = temperature(uniqueIdx);
        T_change = interp1(t_T_unique, temperature_unique, t_change);
    end

    % Compute DT, Dt
    if isAP && detected && ~isnan(T_ini_exo)
        DT = T_ini_exo - T_change;
        Dt = t_ini_exo - t_change;       
    end

    %% ------------------------ PLOT ------------------------
    figure(k); clf

    % Subplot 1: C(t) and T(t)
    subplot(2,1,1); hold on
    yyaxis left
        plot(t_C, C4_filtered, 'Color', "magenta", 'LineStyle', ':', 'LineWidth', 1.5);
        if detected
            plot(t_change, C_change, 'k|', 'MarkerSize', 15, 'LineWidth', 1);
        end
        ylabel('Capacitance (pF)', 'FontSize', 14);
        ax = gca; ax.YColor = 'k';

    yyaxis right
        plot(t_T, temperature, 'Color', "#A2142F", 'LineStyle', "-.", 'LineWidth', 1.5);
        if detected
            plot(t_change, T_change, 'k|', 'MarkerSize', 15, 'LineWidth', 1);
        end
        if isAP && ~isnan(T_peak_exo)
            plot(t_peak_exo, T_peak_exo, 'bx', 'MarkerSize', 15, 'LineWidth', 1);
        end
        ylabel('Temperature (°C)', 'FontSize', 14);
        ax = gca; ax.YColor = 'k';

        if isAP && detected
            text(mean(xlim()), max(C4_filtered), ...
                sprintf(['Detection Delay: \\Delta t = %.2f s\nT = %.2f °C'], Dt, T_change), ...
                'FontSize', 12, 'Color', 'k', 'HorizontalAlignment', 'center');
        end
    xlim(xlimit);
    xlabel('Time (s)', 'FontSize', 14);
    title('Filtered Capacitance and Temperature', 'FontSize', 16);
    grid on;
    legend({'filtered C_{in}(t)',  'C_{detected}', 'T(t)',  'T_{detected}',  'T_{peak}'},'Location', 'northeast', 'FontSize', 10)

    % Subplot 2: std(C)
    subplot(2,1,2); hold on
    plot(t_C, std_C, 'b-', 'DisplayName', '\sigma(C(t))');
    yline(th1, "Color", [0.5, 0.5, 0.5], "LineWidth", 2, 'Label', 'th_1');
    yline(th2, 'k', "LineWidth", 2, 'Label', 'th_2');
    if detected
        plot(t_change, std_C(idx_th2), 'k|', 'MarkerSize', 15, 'LineWidth', 1);
    end
    ylabel('\sigma(C(t)) (pF)', 'FontSize', 14);
    xlabel('Time (s)', 'FontSize', 14);
    xlim(xlimit);
    title('Standard Deviation of C(t)', 'FontSize', 16);
    grid on;
    legend({'\sigma(C_{in}(t))',  'th_1', 'th_2',  '\sigma_{detected}'},'Location', 'northeast', 'FontSize', 10)

    sgtitle(overviewTitle, 'FontSize', 20);


    g = gcf;
    g.WindowState = 'maximized';

    pngFile = fullfile(folderPath, sprintf('%s.png', fileName)); % Optional: Save as PNG
    saveas(k, pngFile); 
    %% ------------------------ SAVE RESULTS ------------------------
    results = [results; {
        fileName, isAP, isAN, isPP, isPN, detected, ...
        T_ini_exo, t_ini_exo, T_change, t_change, DT, Dt
    }];

        % Map actual and predicted labels to binary classes
        % Actual: AP=1, AN=0
        % Predicted: PP=1, PN=0
        actual = double(strcmp(actualClass, 'AP'));
        predicted = double(strcmp(predictedClass, 'PP'));
      
        % Append to label matrix
        labels = [labels; actual, predicted];

end

%% ------------------------ DISPLAY TABLE ------------------------
T = cell2table(results, 'VariableNames', ...
    {'FileName', 'AP', 'AN','PP','PN', 'Detected', ...
     'T_ini_exo', 't_ini_exo', 'T_change', 't_change', 'DT', 'Dt'});

disp(T);

%%
% CONFUSION MATRIX:
% Extract actual and predicted labels
actualLabels = labels(:,1);
predictedLabels = labels(:,2);

% True Positive (TP): actual 1, predicted 1
TP = sum(actualLabels == 1 & predictedLabels == 1);

% True Negative (TN): actual 0, predicted 0
TN = sum(actualLabels == 0 & predictedLabels == 0);

% False Positive (FP): actual 0, predicted 1
FP = sum(actualLabels == 0 & predictedLabels == 1);

% False Negative (FN): actual 1, predicted 0
FN = sum(actualLabels == 1 & predictedLabels == 0);

% Manual confusion matrix
confMat = [TP, FN; FP, TN];  % [row1 = actual 1; row2 = actual 0]

disp('Confusion Matrix (manual):');
disp(array2table(confMat, ...
    'VariableNames', {'Pred_Pos', 'Pred_Neg'}, ...
    'RowNames', {'Actual_Pos', 'Actual_Neg'}));

% Accuracy
accuracy = (TP + TN) / (TP + TN + FP + FN);

% Precision (Positive Predictive Value)
precision = TP / (TP + FP);

% Recall / Sensitivity / True Positive Rate
recall = TP / (TP + FN);

% Specificity (True Negative Rate)
specificity = TN / (TN + FP);

% F1 Score
f1 = 2 * (precision * recall) / (precision + recall);

% Display
fprintf('Accuracy    : %.2f %%\n', accuracy * 100);
fprintf('Precision   : %.2f %%\n', precision * 100);
fprintf('Recall      : %.2f %%\n', recall * 100);
fprintf('Specificity : %.2f %%\n', specificity * 100);
fprintf('F1 Score    : %.2f %%\n', f1 * 100);



%%
% Save table in excel for future formatting
writetable(T, 'results_table.xlsx');

%% ------------------------ SCATTER PLOTS FOR AP-PP: DT and Dt ------------------------
isAPPP = T.AP & T.PP;
DTs_APPP = T.DT(isAPPP);
Dts_APPP = T.Dt(isAPPP);
Tchanges_APPP = T.T_change(isAPPP);
tchanges_APPP = T.t_change(isAPPP);

groupLabels = {'TP'}; % GS can be later added if needed
colors = [0.2 0.2 0.2];  % Consistent color for both plots

figure;
sgtitle('True Positives Overview: \DeltaT and \Deltat', 'FontSize', 16);

for subplot_idx = 1:4
    subplot(2,2,subplot_idx); hold on; grid on;


    xticks(1:numel(groupLabels));
    xticklabels(groupLabels);
    xlim([0.5, numel(groupLabels) + 0.5]);
    
    % Choose variable to plot
    if subplot_idx == 1
        y = DTs_APPP;
        ylabel('\DeltaT (°C)', 'FontSize', 14);
    end
    if subplot_idx == 2
        y = Dts_APPP;
        ylabel('\Deltat (s)', 'FontSize', 14);
    end
    if subplot_idx == 3
        y = Tchanges_APPP;
        ylabel('T (°C)', 'FontSize', 14);
    end
    if subplot_idx == 4
        ylabel('t (s)', 'FontSize', 14);
        y = tchanges_APPP;
    end
    x = ones(size(y)); % only one group
    
    % Scatter (Datapoints)
    scatter(x, y, 50, 'filled', ...
        'MarkerFaceColor', colors, 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 0.6);

    % Mean & STD
    m = mean(y, 'omitnan');
    s = std(y, 'omitnan');
    n = sum(~isnan(y));
    z = 1.96; % for 95% CI
    ci_half = z * s / sqrt(n); % confidence interval

    % Shaded std (±1σ)
    y_patch_std = [m-s, m-s, m+s, m+s];
    fill([1-0.2 1+0.2 1+0.2 1-0.2], y_patch_std, ...
        [0.8 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.4);

    % Shaded CI
    y_patch_ci  = [m - ci_half, m - ci_half, m + ci_half, m + ci_half];
    fill([1-0.2 1+0.2 1+0.2 1-0.2], y_patch_ci, [0.4 0.4 0.4], ...
        'EdgeColor', 'none', 'FaceAlpha', 0.4);

    % Mean line
    plot([1-0.2 1+0.2], [m m], 'k-', 'LineWidth', 2);

    
    % Legend
    if subplot_idx == 2  % Only add legend once (on right subplot)
        legend({'Samples',  '95% CI', '±1σ', 'Mean'}, ...
            'Location', 'northeast', 'FontSize', 10);
    end

    % Label
    if m ~= 0
        unc_pct = 100 * ci_half / abs(m);
        label_str = sprintf('%.3g\n(u = ±%.1f%%)', m, unc_pct);
    else
        label_str = sprintf('%.3g\n(u = ±N/A)', m);
    end
    text(1 + 0.25, m, label_str, 'VerticalAlignment', 'middle', 'FontSize', 10);
end

