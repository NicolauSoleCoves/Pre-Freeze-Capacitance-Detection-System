function [t_peak_exo_all, T_peak_all, t_C_at_freeze_all, C_at_freeze_all, T_ini_exo_all, t_exo_ini_all, file_ids] = exopeaks(sourceFolder, FIGURE_NUMBER, PLOT)

% Initialize outputs
t_peak_exo_all     = [];
T_peak_all         = [];
t_C_at_freeze_all  = [];
C_at_freeze_all    = [];
T_ini_exo_all      = [];
t_exo_ini_all      = [];
file_ids           = [];

% Get all .mat files
files = dir(fullfile(sourceFolder, '*.mat'));

for k = 1:length(files)
    fileName = files(k).name;
    filePath = fullfile(sourceFolder, fileName);
    fprintf('\n=== Processing %s ===\n', fileName);
    data = load(filePath);

    % Skip file if required fields are missing
    if ~all(isfield(data, {'C4', 'temperature', 'timeStamp_T', 'evmTimestamps'}))
        fprintf('Missing required variables. Skipping.\n');
        continue;
    end

    % Extract variables
    C4 = data.C4;
    temperature = data.temperature;
    t_T = data.timeStamp_T;
    t_C = data.evmTimestamps;

    % Remove outliers from C4
    for i = 2:length(C4)
        if C4(i) < 2 || C4(i) > 15.6
            C4(i) = C4(i-1);
        end
    end
    C4_filtered = movmean(C4, 15);

    % Cache filename
    [~, nameOnly, ~] = fileparts(fileName);
    cacheFile = fullfile(sourceFolder, [nameOnly '_exopeak.mat']);

    % Load or compute exothermic peak
    if exist(cacheFile, 'file')
        load(cacheFile, 't_peak_exo', 'T_peak', 't_C_at_freeze', 'C_at_freeze', 'T_ini_exo', 't_exo_ini');
        fprintf('Loaded cached results.\n');
    else
        % Peak detection (can be replaced by your own logic)
        [~, idx_peak] = max(temperature);
        idx_window = max(1, idx_peak-20):min(length(temperature), idx_peak+20);
        [~, rel_idx_peak] = max(temperature(idx_window));
        idx_f_exo_T = idx_window(rel_idx_peak);
        t_peak_exo = t_T(idx_f_exo_T);
        T_peak = temperature(idx_f_exo_T);

        % Initial minimum before peak
        idx_ini = idx_window(1):idx_f_exo_T;
        [~, idx_min_rel] = min(temperature(idx_ini));
        idx_min_T = idx_ini(idx_min_rel);
        t_exo_ini = t_T(idx_min_T);
        T_ini_exo = temperature(idx_min_T);

        % Map to closest time in C4
        [~, idx_C_nearest] = min(abs(t_C - t_peak_exo));
        t_C_at_freeze = t_C(idx_C_nearest);
        C_at_freeze = C4_filtered(idx_C_nearest);

        save(cacheFile, 't_peak_exo', 'T_peak', 't_C_at_freeze', 'C_at_freeze', 'T_ini_exo', 't_exo_ini');
        fprintf('Saved results to cache.\n');
    end

    % Store results
    t_peak_exo_all(end+1) = t_peak_exo;
    T_peak_all(end+1) = T_peak;
    t_C_at_freeze_all(end+1) = t_C_at_freeze;
    C_at_freeze_all(end+1) = C_at_freeze;
    T_ini_exo_all(end+1) = T_ini_exo;
    t_exo_ini_all(end+1) = t_exo_ini;

    % Store file ID (last number in filename)
    parts = regexp(fileName, '\d+', 'match');
    if ~isempty(parts)
        file_ids(end+1) = str2double(parts{end});
    else
        file_ids(end+1) = k;
    end
end

%% Optional plotting
if PLOT
    validIdx = ~isnan(t_peak_exo_all);
    if sum(validIdx) == 0
        warning('No valid data found for plotting.');
        return;
    end

    % Extract valid values
    T_ini = T_ini_exo_all(validIdx);
    T_peak = T_peak_all(validIdx);
    t_ini = t_exo_ini_all(validIdx);
    t_peak = t_peak_exo_all(validIdx);
    sample_ids = file_ids(validIdx);
    x = 1:length(sample_ids);  % strictly increasing for xticks

    data = {T_ini, T_peak, t_ini, t_peak};
    labels = {'T_{ini,exo} (°C)', 'T_{peak,exo} (°C)', ...
              't_{ini,exo} (s)', 't_{peak,exo} (s)'};

    figure(FIGURE_NUMBER); clf;

    for i = 1:4
        subplot(2,2,i); hold on;
        y = data{i};

        % Mean and std
        m = mean(y);
        s = std(y);
        
        % Shaded area
        x_patch = [0.5, length(y)+0.5, length(y)+0.5, 0.5];
        y_patch = [m-s, m-s, m+s, m+s];
        fill(x_patch, y_patch, [0.9 0.9 0.9], 'EdgeColor', 'none', 'FaceAlpha', 0.6);

        scatter(x, y, 'k', 'filled');
        yline(m, 'k--', 'LineWidth', 1.5);

        xlabel('Sample ID');
        ylabel(labels{i});
        title(sprintf('%s vs. sample', labels{i}));

        % Stats box
        ax = gca;
        xlims = ax.XLim;
        ylims = ax.YLim;
        dx = xlims(2) - xlims(1);
        dy = ylims(2) - ylims(1);
        xText = xlims(2) - 0.13 * dx;
        yText = ylims(2) - 0.05 * dy;

        if i == 1
            xText = xlims(2) - 0.13 * dx;
            yText = ylims(1) + 0.25 * dy;
            ylim([-2 4])
        end

        if i == 2
            xText = xlims(2) - 0.13 * dx;
            yText = ylims(1) + 0.05 * dy;
            ylim([-2 4])
        end
        txt = sprintf('Mean = %.2f\n± %.2f (%.1f%%)', m, s, s/m*100);
        text(xText, yText, txt, 'FontSize', 10, 'FontWeight', 'bold', ...
            'BackgroundColor', 'w', 'EdgeColor', 'k', 'Margin', 5, ...
            'HorizontalAlignment', 'right', 'VerticalAlignment', 'top');

        
        xticks(x);
        xticklabels(arrayfun(@num2str, sample_ids, 'UniformOutput', false));
        xlim([0.5, length(y)+0.5]);
         xtickangle(90);
        grid on;
        hold off;
    end

    sgtitle(sprintf('Exothermic Freezing Parameters (n = %d)', length(x)));
end

end
