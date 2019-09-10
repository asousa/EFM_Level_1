% Compute local site corrections between Campbell and CU EFM measurements:
close all; clear all;
ADC_SAMPLING_FREQ = 1000;
EFM_SAMPLE_RATE = 100;      % Hz, what we're decimating to
CAMPBELL_SAMPLE_RATE = 4;   % Hz

raw_data_dir = "/Volumes/EFM External/EFM before office move/RELAMPAGO Data/Campaign Data";
campbell_data_dir = "/Volumes/EFM External/EFM before office move/RELAMPAGO Data/Campaign Data/Campbell Field Deployment";
cal_dir = "/Volumes/EFM External/EFM before office move/Field Mill Post-Campaign Calibration/EFM calibration maps 6-17-2019";
fig_dir = "/Volumes/EFM External/EFM before office move/EFM Level 1 Processing/Site Corrections";

Mplate = 89.79;  % Campbell's mill-specific collector area correction.
% Csite =  0.105;   % Campbell's reported site correction. Probably valid, but will vary with setup height
Csite = 0.233;  % Taken from Austin's backyard test data, 7/18/2019
C_offset = - 20; % ~ Taken from backyard tests. Probably drifts...

EFMs = containers.Map;
EFMs("Cordoba") = "EFM011";
EFMs("Manfredi") = "EFM004";
EFMs("Pilar") = "EFM006";
EFMs("Villa-del-Rosario") = "EFM002";
EFMs("Villa-Carlos-Paz") = "EFM008";

lags = containers.Map;
lags("Cordoba") = 20;
lags("Manfredi") = 1;
lags("Pilar") = -2;
lags("Villa-del-Rosario") = 0;
lags("Villa-Carlos-Paz") = 0;

site_correction_factor = 1; 
lag = 10;

sites = ["Cordoba","Manfredi","Pilar", "Villa-del-Rosario","Villa-Carlos-Paz"];
% sites = ["Manfredi"];

argentina_time_offset = hours(3); 
phase_offset = 3;
% omit_polarity = true;

gains = containers.Map;
offsets = containers.Map;

E_camp = containers.Map;
t_camp = containers.Map;
E_efm = containers.Map;
t_efm = containers.Map;

for s=1:length(sites)
    site_name = sites(s);
    EFM = EFMs(site_name);
    omit_polarity = (site_name=="Manfredi");  % Manfredi has garbage phase data at calibration time!
    
    % Load Campbell data:
    campbell_file = fullfile(campbell_data_dir,EFM,'CR1000_EFM.dat');
    Cfile = readtable(campbell_file);
    Cfile = Cfile(3:end,:);

    timec = regexprep(Cfile.TIMESTAMP, ':\d\d$', '$&.0', 'lineanchors');
    timec = datetime(timec, 'InputFormat', 'yyyy-MM-dd  HH:mm:ss.S');
    timec = timec + argentina_time_offset;
    EfieldC = str2double(Cfile.E_field);

    EfieldC = EfieldC*Csite*Mplate + C_offset;  % Apply site correction to Campbell
    % Calibration map
    cal_file = fullfile(cal_dir,sprintf("%s_map_2019-06-17.mat",EFM));  
    disp(cal_file);
    cal_data = load(cal_file); % returns efmVolts, E_field_calib



    %% Load corresponding EFM data:

    % next_file_time = file_time + hours(1);
    ndvec = datevec(timec(1) + hours(1));
    next_file = fullfile(raw_data_dir,site_name,'DATA',...
                sprintf('%d',ndvec(1)),sprintf('%d',ndvec(2)), sprintf('%d',ndvec(3)),...
                sprintf('%02d.bin',ndvec(4)));
    have_next   = isfile(next_file);

    dvec = datevec(timec(1));
    cur_file = fullfile(raw_data_dir,site_name,'DATA',...
                sprintf('%d',dvec(1)),sprintf('%d',dvec(2)), sprintf('%d',dvec(3)),...
                sprintf('%02d.bin',dvec(4)));

    % Load current file
    fprintf("Loading %s\n",cur_file);
    fileID = fopen(cur_file, 'r');
    data = fread(fileID,[1,3600*ADC_SAMPLING_FREQ],'uint16','n');
    fclose(fileID);
    data(2,:) = bitget(data(1,:),ones(1,length(data))*1,'uint16'); % Newer version injects bit for phase
    data(1,:) = bitset(data(1,:),ones(1,length(data))*1,ones(1,length(data))*0,'uint16');
    data = transpose(data);


    if have_next
        disp("loading next overlap");
        fileID = fopen(next_file, 'r');
        data_local = fread(fileID,[1,3600*ADC_SAMPLING_FREQ],'uint16','n');   
        fclose(fileID);
        data_local(2,:) = bitget(data_local(1,:),ones(1,length(data_local))*1,'uint16'); % Newer version injects bit for phase
        data_local(1,:) = bitset(data_local(1,:),ones(1,length(data_local))*1,ones(1,length(data_local))*0,'uint16');
        data = [data; transpose(data_local)];
    end

    OUTPUT_SAMPLE_RATE = 100;

    % Uncalibrated E_field from CU EFM:
    E_field = process_hilbert(data, ADC_SAMPLING_FREQ, OUTPUT_SAMPLE_RATE, phase_offset, omit_polarity);
    timeEFM = datetime(dvec(1),dvec(2),dvec(3),dvec(4),0,0) + seconds( ((0:length(E_field) - 1) )/OUTPUT_SAMPLE_RATE);


    %% Apply calibration curve:

    E_field_calib = interp1(cal_data.efmVolts, cal_data.E_field_calib, E_field,'linear','extrap');

    % figure();
    % plot(timeEFM, E_field);
    %% Downsample E_field to Campbell rate, for cross-corellation
    clf;
    fig = figure(2);
    hold on;
    lag = lags(site_name);
    
    E_down = resample(E_field_calib,CAMPBELL_SAMPLE_RATE,EFM_SAMPLE_RATE);
    t_down = (0:(length(E_down)-1))/CAMPBELL_SAMPLE_RATE;
    tv_down = timeEFM(1) + seconds(t_down) - seconds(lag);

    
    if site_name=="Villa-Carlos-Paz"
       % A band-aid: The VCP data has a strange DC offset halfway through.
       % Possibly charge deposition on the sense plate plastic? Either way,
       % let's see what the correction is like if we remove that offset
       % manually / by eye.
       
       t1 = datetime(2018,10,24,18,57,17);
       t2 = datetime(2018,10,24,18,58,55);
       inds = find((tv_down >=t1) & (tv_down < t2));
       E_down(inds)  = E_down(inds) - 100;
       
    end
    % ----- Least-squares fit for gain and offset -----


    % Indices of times where we have data for both instruments
    [C, ia, ib] = intersect(tv_down, timec);
    
    % Ignore any NaNs for the least-squares fit
    inan = find(~isnan(E_down(ia)));
    ia = ia(inan);
    ib = ib(inan);
    
    if omit_polarity
        A = [abs(E_down(ia))];%, ones(length(ia),1)];
        B = abs(EfieldC(ib));
        fit = A\B;
        gain = fit(1);
        offset =  0; %fit(2)*sign(mean(EfieldC)); %0;
    else
        A = [E_down(ia), ones(length(ia),1)];
        B = EfieldC(ib);
        fit = A\B;
        gain = fit(1);
        offset = fit(2);
    end

    
    gains(site_name) = gain;
    offsets(site_name) = offset;

    E_efm(site_name) = E_down(ia);
    t_efm(site_name) = tv_down(ia);
    E_camp(site_name) = EfieldC;
    t_camp(site_name) = timec;
%     
%     if omit_polarity
%         % only fit gain, since we can't really get the offset correct
%         fit = EFD_short\abs(EfieldC);
%         gain = fit(1);
%         offset = 0;
%         plot(timec, abs(EfieldC));
% 
%     else
%         A = [EFD_short, ones(length(EFD_short),1)];
%         size(A)
%         B = EfieldC;
%         size(B)
%         fit = A\B;
%         gain = fit(1);
%         offset = fit(2);
%         plot(timec, EfieldC);
%     end


    % hold on;
    plot(timec, EfieldC);
    if omit_polarity
        plot(tv_down(ia), gain*E_down(ia)*sign(mean(EfieldC)) + offset);
    else
        plot(tv_down(ia), gain*E_down(ia) + offset);
    end
    legend('Campbell',EFM);
    title(sprintf('Cross-calibration Fit at %s',site_name));
    ylabel({'Electric field [V/m]';sprintf('Campbell C_{site}=%g',Csite)});
    grid on;
    fprintf('Gain = %g, offset = %2g\n',gain,offset);

    xcoords = get(gca,'xlim');
    ycoords = get(gca,'ylim');
    xt = xcoords(1) + 0.7*(xcoords(2) - xcoords(1));
    yt = ycoords(1) + 0.1*(ycoords(2) - ycoords(1));

    text(xt,yt,sprintf('Gain = %2.3f\nOffset = %2.2f',gain,offset));
    saveas(gca, fullfile(fig_dir,sprintf('Calibration_curve_%s_%s.png',site_name, EFM)));
end
%% Plot everything side-by-side:

    set(groot,'defaultfigurecolor',[1 1 1])
    set(groot,'defaultAxesFontSize',14)
    set(groot,'defaultTextFontSize',12)
    set(groot,'defaultAxesFontWeight','bold');
    set(groot,'defaultTextFontWeight','bold');
    set(groot,'defaultAxesLineWidth',2);
    set(groot,'defaultUicontrolFontName','Arial');
    set(groot,'defaultUitableFontName','Arial');
    set(groot,'defaultAxesFontName','Arial');
    set(groot,'defaultTextFontName','Arial');
    set(groot,'defaultUipanelFontName','Arial');

    close all;
    fig = figure('units','inch','position',[0,0,14,8]);
    
    axs = tight_subplot(2,3,0.1, 0.1, 0.1);
    
    for s=1:length(sites)
        
        hold(axs(s),'on');
        box(axs(s),'on');
        

        site_name = sites(s);
        EFM = EFMs(site_name);
        
        plot(axs(s),t_camp(site_name), E_camp(site_name),'LineWidth',1.5);
        if site_name=='Manfredi'
            plot(axs(s),t_efm(site_name), ...
                gains(site_name)*E_efm(site_name)*sign(mean(E_camp(site_name))) ...
                + offsets(site_name),'LineWidth',1.5);
        else
            plot(axs(s),t_efm(site_name), gains(site_name)*E_efm(site_name) + offsets(site_name),'LineWidth',1.5);
        end
%         legend(axs(s),'Campbell',EFM);
        title(axs(s),sprintf('%s',site_name));
        ylabel(axs(s),'Electric field [V/m]');
        grid(axs(s),'on');
        yticks(axs(s),'auto');
        yticklabels(axs(s),'auto');
        TextLocation(axs(s),sprintf('%s\nGain = %2.3f\nOffset = %2.2f',EFM,gains(site_name),offsets(site_name)),'Location','best');
        
    end

    
%     box(axs(end),'off');
    delete(axs(end));
    
    l = legend(axs(5),'Campbell','CU EFM');
    lpos = get(l,'Position');
    lpos(1) = 0.75;
    lpos(2) = 0.3;
    set(l,'Position',lpos);
    
    sgtitle(sprintf('In-field Site Corrections -- Campbell C_{site}=%g',Csite));
    saveas(fig,'in_field_site_corrections.png');
