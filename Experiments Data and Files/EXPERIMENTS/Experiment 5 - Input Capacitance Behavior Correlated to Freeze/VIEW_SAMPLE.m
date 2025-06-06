clear all; clc;

FILE = 'C:\Users\nicol\Desktop\TFG\muntatge\MATLAB\Experiments\C\ANALISIS\24V_celulose_film_8_layers_Ac_4_1_cm_7';
load(FILE);

% Remove outliers from C4
for i = 2:length(C4)
    if C4(i) < 2 || C4(i) > 15.6
        C4(i) = C4(i-1);
    end
end

% Filter the capacitance data noise with a moving average filter:
windowSize = 29;
C4_filtered = movmean(C4, windowSize);

% PLOT:
figure(2);
    clf;
    hold on;
    
    yyaxis right
        plot(timeStamp_T, temperature, ...
            'Color', "#A2142F", ...
            "LineStyle","-.", ...
            'LineWidth',1.5, ...
            'DisplayName', 'Temperature')
        ylabel('Temperature (ºC)','FontSize',16);
        ax = gca;
        ax.YColor = "#000000";
        %ylim([-3, 8])
        

    
    % Plot the data, with noise and filtered
    yyaxis left
        % plot(evmTimestamps, C4, ...
        %     'Color', "#000000", ...
        %     'DisplayName', 'Capacitance')
        plot(evmTimestamps, C4_filtered, ...
            'Color', "magenta", ...
            'LineStyle',':', ...
            'LineWidth',1.5, ...
            'DisplayName', 'Filtered Capacitance');
        ylabel('Capacitance (pF)','FontSize',16);
        ax.YColor = "k";
    
    xlabel('Time (s)','FontSize',16);
    title('Complete Data Overview of sample 7','FontSize',24);
    legend("Location", "northeast", 'FontSize', 16, "NumColumns", 4);
    xlim([0 1000])
    grid on;
    hold off;