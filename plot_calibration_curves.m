% Plot calibration curves for the set of millz
close all; clear all;

cal_dir = "/Volumes/lairdata/EFM/EFM Level 1 Processing/EFM calibration maps 6-17-2019";

EFMs = containers.Map;
EFMs("Cordoba") = "EFM011";
EFMs("Manfredi") = "EFM004";
EFMs("Pilar") = "EFM006";
EFMs("Villa-del-Rosario") = "EFM002";
EFMs("Villa-Carlos-Paz") = "EFM008";

sites = ["Cordoba","Manfredi","Pilar", "Villa-del-Rosario","Villa-Carlos-Paz"];

%% Plot a nice figure, with new and old calibration curves, and linear fits:
f = figure();
set(groot,'defaultfigurecolor',[1 1 1])
set(groot,'defaultAxesFontSize',10)
set(groot,'defaultTextFontSize',10)
set(groot,'defaultAxesFontWeight','bold');
set(groot,'defaultTextFontWeight','bold');
set(groot,'defaultAxesLineWidth',2);
set(groot,'defaultUicontrolFontName','Arial');
set(groot,'defaultUitableFontName','Arial');
set(groot,'defaultAxesFontName','Arial');
set(groot,'defaultTextFontName','Arial');
set(groot,'defaultUipanelFontName','Arial');
% set(gcf, 'Position', [0 100 595*1 425*1.0]);


hold on;
box on;
for s_ind=1:length(sites)
    site_name = sites(s_ind);
    EFM = EFMs(site_name);

    % Load the calibration map for this mill:
    cal_filename = sprintf("%s_map_2019-06-17.mat",EFM);
    cal_file = fullfile(cal_dir,cal_filename);  
    disp(cal_file);
    cal_data = load(cal_file); % returns efmVolts, E_field_calib
    plot(cal_data.efmVolts, cal_data.E_field_calib/1000, 'lineWidth',2);
end

grid on;
leg = legend(sites);
set(leg, 'Location','southeast');
ylabel('Electric field [kV/m]');
xlabel('Raw EFM signal [-1 .. 1]');
title('EFM Level 1 Calibration Maps');




% Ditch whitespace in the saved PDF

f.PaperUnits ='inches';
fig_width = 4.5 ;fig_height = 3.25;
f.PaperPosition= [0 0 fig_width fig_height]; %
  
% f.PaperPositionMode = 'auto';
fig_pos = f.PaperPosition;
f.PaperSize = [fig_pos(3) fig_pos(4)];

saveas(f, 'EFM_Level_1_Calibration_Maps.pdf');
