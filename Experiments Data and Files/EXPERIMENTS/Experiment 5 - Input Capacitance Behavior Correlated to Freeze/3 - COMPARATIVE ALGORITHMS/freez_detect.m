function [DTs, Dts, DTps, Dtps] = freez_detect(sourceFolder, thup, thdown, WindowSize_C, WindowSize_S, numfigure,PRINT)



%% Constants
th1 = thup;
th2 = thdown;

% Store results
DTs = [];
Dts = [];
DTps = [];
Dtps = [];
file_ids = [];
files = dir(fullfile(sourceFolder, '*.mat'));

for k = 1:length(files)
    fileName = files(k).name;
    filePath = fullfile(sourceFolder, fileName);
    %fprintf('\nLoading %s ...\n', fileName);
    data = load(filePath);

    % Check required variables
    if ~all(isfield(data, {'C4', 'temperature', 'timeStamp_T', 'evmTimestamps'}))
        fprintf('Skipping %s (missing required variables)\n', fileName);
        continue;
    end

    % Extract
    C4 = data.C4;
    temperature = data.temperature;
    t_T = data.timeStamp_T;
    t_C = data.evmTimestamps;

    % Filter C4 data
    for i = 2:length(C4)
        if C4(i) < 2 || C4(i) > 15.6
            C4(i) = C4(i-1);
        end
    end

    % Smooth C
    C4_filtered = movmean(C4, WindowSize_C);
    std_C = movstd(C4_filtered, WindowSize_S);

    % Detection algorithm

    P1 = false;
    t_detect = NaN;
    for i=1:length(C4_filtered)
        if std_C(i) > th1
            P1 = true;
        end
        if P1 && std_C(i) < th2
            t_detect = t_C(i);
            break;
        end
    end

    % Skip if no change detected
    if isnan(t_detect)
        fprintf('No detect detected in file: %s\n', fileName);
        continue;
    end

    % Create a cache filename for storing exopeak results
    [~, nameOnly, ~] = fileparts(fileName);
    cacheFile = fullfile(sourceFolder, [nameOnly '_exopeak.mat']);
    
    if exist(cacheFile, 'file')
        % Load cached data
        load(cacheFile, 't_peak_exo', 'T_peak', 't_C_at_freeze', ...
            'C_at_freeze', 'T_ini_exo', 't_exo_ini');
        %fprintf('Loaded exopeak data from cache for %s\n', fileName);
    else
        % Compute and save
        [t_peak_exo, T_peak, t_C_at_freeze, C_at_freeze, T_ini_exo, t_exo_ini] = ...
            exopeak_choose(t_T, temperature, C4_filtered, t_C);
        
        save(cacheFile, 't_peak_exo', 'T_peak', 't_C_at_freeze', ...
            'C_at_freeze', 'T_ini_exo', 't_exo_ini');
        fprintf('Saved exopeak data to cache for %s\n', fileName);
    end


    % Interpolate T_detect at t_detect
    [t_T_unique, uniqueIdx] = unique(t_T, 'stable');
    temperature_unique = temperature(uniqueIdx);
    T_detect = interp1(t_T_unique, temperature_unique, t_detect);

    % Calculate deltas
    DT = T_detect - T_ini_exo;
    Dt = t_detect - t_exo_ini;
    DTp = T_detect - T_peak;
    Dtp = t_detect - t_peak_exo;

    % Store values
    DTs(end+1) = DT;
    Dts(end+1) = Dt;
    DTps(end+1) = DTp;
    Dtps(end+1) = Dtp;

    % Extract number from filename for plotting
    parts = regexp(fileName, '\d+', 'match');
    if ~isempty(parts)
        file_ids(end+1) = str2double(parts{end});
    else
        file_ids(end+1) = k;
    end
end

%% Calculate means and stds
means = [mean(DTs),  mean(DTps),mean(Dts), mean(Dtps)];
stds = [std(DTs),  std(DTps),std(Dts), std(Dtps)];
%% Skip plot if no data
if isempty(file_ids)
    warning('No valid experiments were processed. Skipping plot.');
    return;
end
%% Plot results: one x-tick per experiment

if PRINT
figure(numfigure);clf

deltaNames = {'ΔT',  'ΔT_p','Δt', 'Δt_p'};
allData = {DTs,  DTps, Dts, Dtps};

numExperiments = length(file_ids); % number of experiments analyzed
xVals = 1:numExperiments;          % x positions

Values = {"\it{ΔT} (°C)","\it{ΔT_p} (°C)","\it{Δt} (s)","\it{Δt_p} (s)"};

for i = 1:4
    subplot(2,2,i);
    hold on;

    % Define y range for shaded area (mean ± std)
    y_lower = means(i) - stds(i);
    y_upper = means(i) + stds(i);

    % X range covers all experiment indices
    x_patch = [0.5, numExperiments+0.5, numExperiments+0.5, 0.5];
    y_patch = [y_lower, y_lower, y_upper, y_upper];

    % Plot shaded background for mean ± std
    hFill = fill(x_patch, y_patch, [0.9 0.9 0.9], 'EdgeColor', 'none');
    set(hFill, 'FaceAlpha', 0.6);

    % Scatter plot of delta values per experiment, x = experiment index
    scatter(xVals, allData{i}, 'filled', 'k');
    
    % Plot mean as a horizontal dashed line
    yline(means(i), 'k--', 'LineWidth', 1.5);

    % Get current axes limits
    ax = gca;
    xlims = ax.XLim;
    ylims = ax.YLim;

    % Position text box near top right corner with padding
    xText = xlims(2) - 0.13 * (xlims(2)-xlims(1));  % 5% left from right edge
    yText = ylims(2) + 0.05 * (ylims(2)-ylims(1));  % 5% down from top edge

    % Format the text string with units
    if contains(Values{i}, '(°C)')
        txt = sprintf('Mean = %.2f °C\n± %.2f °C (%.2f %%)', means(i), stds(i),  means(i)/stds(i)*100);
    else
        txt = sprintf('Mean = %.2f s\n± %.2f s (%.2f %%)', means(i), stds(i), means(i)/stds(i)*100);
    end

    % Add the textbox
    text(xText, yText, txt, 'FontSize', 10, 'FontWeight', 'bold', ...
         'BackgroundColor', 'w', 'EdgeColor', 'k', 'Margin', 5, ...
         'HorizontalAlignment', 'right', 'VerticalAlignment', 'top');

    xlim([0.5 numExperiments+0.5]);
    xticks(xVals);
    xticklabels(arrayfun(@num2str, file_ids, 'UniformOutput', false));
    xlabel('\it{n}');
    ylabel(Values{i});
    title(sprintf('Delta: %s', deltaNames{i}));
    grid on;
    hold off;
end
sgtitle(sprintf('n = %d and threshold = %.4f', length(xVals), th2));


%% Print summary
fprintf('\n--- Summary ---\n');
for i=1:4
    fprintf('Mean %s: %.4f ± %.4f\n', deltaNames{i}, means(i), stds(i));
end

end
end

