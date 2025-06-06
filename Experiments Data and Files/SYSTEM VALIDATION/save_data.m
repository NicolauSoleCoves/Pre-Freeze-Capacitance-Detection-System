% === Saving without overwriting ===
folderPath = 'C:\Users\nicol\Desktop\TFG\muntatge\MATLAB\Experiments\FINAL_DETECTION_ALGORITHM\DATA';
baseName = '24V_celulose_film_8_layers_Ac_4_1_cm_AN_PFP';
i = 1;

% Generate a unique filename for .mat and .fig
while exist(fullfile(folderPath, sprintf('%s_%d.mat', baseName, i)), 'file') || ...
      exist(fullfile(folderPath, sprintf('%s_%d.fig', baseName, i)), 'file')
    i = i + 1;
end

% Construct final file paths
dataFile = fullfile(folderPath, sprintf('%s_%d.mat', baseName, i));
figFile = fullfile(folderPath, sprintf('%s_%d.fig', baseName, i));
pngFile = fullfile(folderPath, sprintf('%s_%d.png', baseName, i)); % Optional: Save as PNG too

% Save the data: temperature, timeStamp_T
save(dataFile, 'timeStamp_T', 'temperature','evmTimestamps','C4');

% Save the current figure (final one is figure(2))
savefig(2, figFile);
saveas(2, pngFile); % Optional: for external viewing

fprintf('Saved data to: %s\nSaved figure to: %s\n', dataFile, figFile);
