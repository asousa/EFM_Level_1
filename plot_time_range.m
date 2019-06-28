function [fig, axs] = plot_time_range(start_time, stop_time, file_dir, sites)
    SAMPLE_RATE = 100; % Put this in the files please jfc
    
    % one file per hour
    dates_to_do = start_time + hours(0:(hours(stop_time - start_time) - 1));
    
    % Load all data
    Edata = containers.Map;
    
    for s=1:length(sites)
        site = sites(s);
        fprintf("loading %s\n",site);
        Evec = nan((length(dates_to_do))*SAMPLE_RATE*60*60,1);
        tvec = (0:(length(dates_to_do))*60*60*SAMPLE_RATE - 1)/(60*60*SAMPLE_RATE);
        t_axis = start_time + hours(tvec);

        for i=1:length(dates_to_do)
            dvec = datevec(dates_to_do(i));
            name = sprintf("%02d.mat",dvec(4));
            odir = fullfile(file_dir,site,sprintf('%d',dvec(1)),sprintf('%d',dvec(2)), sprintf('%d',dvec(3)));
            if isfile(fullfile(odir,name))
                data = load(fullfile(odir,name));
                hr = hours(dates_to_do(i) - dates_to_do(1));
                t_start = hr*60*60*SAMPLE_RATE + 1;
                t_end = t_start + 60*60*SAMPLE_RATE - 1;

                Evec(t_start:t_end) = data.E_field_calib;
            end
        end
        Edata(site) = Evec;
    end
    %% Plot it
    
    set(groot,'defaultfigurecolor',[1 1 1])
    set(groot,'defaultAxesFontSize',16)
    set(groot,'defaultTextFontSize',18)
    set(groot,'defaultAxesFontWeight','bold');
    set(groot,'defaultTextFontWeight','bold');
    set(groot,'defaultAxesLineWidth',2);
    set(groot,'defaultUicontrolFontName','Arial');
    set(groot,'defaultUitableFontName','Arial');
    set(groot,'defaultAxesFontName','Arial');
    set(groot,'defaultTextFontName','Arial');
    set(groot,'defaultUipanelFontName','Arial');


%     fig = figure('units','inch','position',[0,0,10,8]);
    fig = figure('units','pixels','position',[0 0 1280 720]);
%     fig = figure();
    axs = tight_subplot(length(sites),1,0.03, 0.8/10, 0.8/8);
    
    for s=1:length(sites)
        hold(axs(s),'on');
        box(axs(s),'on');
        site = sites(s);
        plot(axs(s), t_axis, Edata(site)/1000,'LineWidth',2);
        yticklabels(axs(s),'auto');
        ylabel(axs(s),{site,"[kV/m]"});
%         E= Edata(site); E = E(~isnan(Edata(site)));
%         deadpoints = interp1(t_axis(~isnan(Edata(site))),E, t_axis(isnan(Edata(site))),'f');
        plot(axs(s),t_axis(isnan(Edata(site))),zeros(1,sum(isnan(Edata(site)))), 'rx');
        
        xlim(axs(s),[start_time, stop_time]);
    end
    linkaxes(axs,'x');
    
    xlabel('Time of Day (UTC)')
%     yl = ylabel('Post-Processed EFM Signal (kV/m)');
%     set(yl, 'Units', 'Normalized', 'Position', [-0.04 3]);
    
    for s=1:(length(sites)-1)
       set(axs(s),'xticklabels',[]); 
    end
end
