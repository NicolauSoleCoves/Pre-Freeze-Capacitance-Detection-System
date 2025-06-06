%% Load Data
folderPath = 'C:\Users\nicol\Desktop\TFG\muntatge\MATLAB\Experiments\C\ICE_WATER_SAMPLES\Ac_4_4';
FileName = 'V24V_d1.5cm_Ac16cm2_Parar_Congelat_V_27';
load(fullfile(folderPath, FileName), 'C4', 'evmTimestamps');
t_C = evmTimestamps;
%% Parameters
W = [11, 15, 19, 25];  % Window sizes
colors = {'k', [0.6 0 1], [1 0 0]};  % Raw, Moving Avg, Polyfit

%% Figure setup
figure(100); clf;
sgtitle('Comparation of algorithms and window sample sizes (\it{W})','Interpreter','tex','FontSize',20)

for i = 1:length(W)
    w = W(i);
    half_w = floor(w/2);

    % === Moving average filter ===
    C_avg = movmean(C4, w);

    % === Polyfit (linear, local fit) ===
    C_polyfit = NaN(size(C4));  % preallocate
    for j = 1+half_w : length(C4)-half_w
        idx = j-half_w : j+half_w;
        p = polyfit(t_C(idx), C4(idx), 1);
        C_polyfit(j) = polyval(p, t_C(j));
    end

    % === Plot ===
    subplot(ceil(length(W)/2),ceil(length(W)/2),i)
    hold on
    scatter(t_C, C4, 'k','Marker','.','MarkerFaceAlpha',0.7)
    plot(t_C, C_polyfit, '-', 'Color', colors{3}, 'LineWidth', 1.2)
    plot(t_C, C_avg, 'k-', 'Color', colors{2}, 'LineWidth', 1.2)
    title(sprintf('W = %d', w))
    xlabel('Time (s)','FontSize',10)
    ylabel('Capacitance (pF)','FontSize',10)
    if i == 2
        legend({'Raw C_4', 'Moving Avg.', 'Local Polyfit'}, 'Location','best','FontSize',12)
    end
    xlim([70, 140])
    ylim([12.6, 13.1])
    grid on
    hold off
end
