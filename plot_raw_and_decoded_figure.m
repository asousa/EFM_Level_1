% Plot raw and processed data simultaneously, for a sweet figure
close all; clear all; clc;

ADC_SAMPLING_FREQ = 1000;
SAMPLE_RATE = 100; % Hz, what we're decimating to

phase_offset = 2;
ADC_REF = 1.8;

raw_data_dir = "/Volumes/lairdata/EFM/RELAMPAGO Data/Campaign Data";
site_name = 'Pilar';
file_time = datetime(2018,11,14,16,0,0);

dvec = datevec(file_time);
cur_file = fullfile(raw_data_dir,site_name,'DATA',...
            sprintf('%d',dvec(1)),sprintf('%d',dvec(2)), sprintf('%d',dvec(3)),...
            sprintf('%02d.bin',dvec(4)));
        
        
disp("Loading current file");
fileID = fopen(cur_file, 'r');
data = fread(fileID,[1,3600*ADC_SAMPLING_FREQ],'uint16','n');
fclose(fileID);
data(2,:) = bitget(data(1,:),ones(1,length(data))*1,'uint16'); % Newer version injects bit for phase
data(1,:) = bitset(data(1,:),ones(1,length(data))*1,ones(1,length(data))*0,'uint16');
data = transpose(data);        

sig = data(:,1)/65535*ADC_REF;
sig = bandpass(sig, [99,101], ADC_SAMPLING_FREQ);     % Bandpass around the carrier frequency +- 1 Hz
E_field = process_hilbert(data, ADC_SAMPLING_FREQ, SAMPLE_RATE, phase_offset, false);


tvec_raw = 60*60*(0:length(data(:,1))-1)/length(data(:,1));
tvec_proc =60*60*(0:length(E_field)-1)/length(E_field);


[su, tu] = resample(sig, tvec_raw, 10*ADC_SAMPLING_FREQ);

%% Plot that shit
close all;
fig = figure();


set(groot,'defaultfigurecolor',[1 1 1])
set(groot,'defaultAxesFontSize',12)
set(groot,'defaultTextFontSize',12)
set(groot,'defaultAxesFontWeight','bold');
set(groot,'defaultTextFontWeight','bold');
set(groot,'defaultAxesLineWidth',2);
set(groot,'defaultUicontrolFontName','Arial');
set(groot,'defaultUitableFontName','Arial');
set(groot,'defaultAxesFontName','Arial');
set(groot,'defaultTextFontName','Arial');
set(groot,'defaultUipanelFontName','Arial');
% set(gcf, 'Position', [0 100 595*1 425*1.0]);

hold on; box on;

% Plotting the upsampled version here -- the 2.5x critical sampling of the
% raw signal is misleading, in that there's ambiguity between the sampled
% peaks and the true physical sinusoid. Check it out, yo.

% plot(tvec_raw, 1000*sig,'lineWidth',2);
plot(tu, 1000*su,'lineWidth',1);                

% Plot the decoded signal and the inverted version for symmetry
plot(tvec_proc, 1000*E_field,'lineWidth',1.3);
plot(tvec_proc, -1000.*E_field,'lineWidth',1.3);

% plot(tvec_proc - 0.01, -1000.*E_field,'lineWidth',2);
% xlim([60*60*0.20885, 60*60*0.209]);
xlim([752, 752.5]);

ax = get(fig,'CurrentAxes');
set(ax,'XTick',752:0.1:752.5);
set(ax,'XTickLabels',0:0.1:0.5);

ylabel('EFM Signal [mV]')
xlabel('Time [sec]');
title('Amplitude Extraction');
% Ditch whitespace in the saved PDF

fig.PaperUnits ='inches';
fig_width = 4.5 ;fig_height = 3.25;
fig.PaperPosition= [0 0 fig_width fig_height]; %
  
% f.PaperPositionMode = 'auto';
fig_pos = fig.PaperPosition;
fig.PaperSize = [fig_pos(3) fig_pos(4)];

saveas(fig, 'amp_extraction_hilbert.pdf');