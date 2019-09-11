close all; clear all;
file_dir = "/Volumes/lairdata/EFM/RELAMPAGO Data/Level 1/netCDF";
sites = ["Cordoba","Manfredi","Pilar","Villa-Carlos-Paz", "Villa-del-Rosario"];

start_time = datetime(2018,10,28,0,0,0);
stop_time  = datetime(2018,12,15,0,0,0);

files_to_do = start_time +  hours(0:hours(stop_time - start_time));

error_hists = containers.Map();

for s=1:length(sites)
        site = sites(s);
        error_hists(site) = [];
        fprintf("loading %s\n",site);
% %         Evec = nan((length(dates_to_do))*SAMPLE_RATE*60*60,1);
% %         tvec = (0:(length(dates_to_do))*60*60*SAMPLE_RATE - 1)/(60*60*SAMPLE_RATE);
% %         t_axis = start_time + hours(tvec);
% 
        for i=1:length(files_to_do)
            dvec = datevec(files_to_do(i));
%             if netCDF
%                 % NetCDF files
                name = sprintf("%s_%04d-%02d-%02dT%02d.nc",site,dvec(1), dvec(2), dvec(3), dvec(4));
                odir = fullfile(file_dir,site,sprintf('%d',dvec(1)),sprintf('%d',dvec(2)), sprintf('%d',dvec(3))); 
                
%             else
%                 % Matlab files
%                 name = sprintf("%02d.mat",dvec(4));
%                 odir = fullfile(file_dir,site,sprintf('%d',dvec(1)),sprintf('%d',dvec(2)), sprintf('%d',dvec(3)));
%             end
            if isfile(fullfile(odir,name))
                cur_err = ncreadatt(fullfile(odir,name),"E_field","max_timing_error");
                error_hists(site) = [error_hists(site), cur_err];
            end
        end
% %         Edata(site) = Evec;
end

%%
figure(1);
axs = [];
for s=1:length(sites)
    site = sites(s);
    ax = subplot(length(sites),1,s);
    axs = [axs, ax];
    errs = error_hists(site);
    errs = errs(errs < 100);  % There are errors above 200 -- but these are probably whole-file dropouts and not timing errors (and this makes the histogram prettier)
    histogram(ax,errs, 24);%,'edgecolor','none');
%     xlim(ax,[0,100]);
%     set(ax,'yscale','log');
    ylabel([site,'counts']);
end

for x=1:(length(axs)-1)
    set(axs(x),'xticklabels',[]);
end
xlabel(axs(end),'Max error (seconds)');
sgtitle(['Timing error histograms',sprintf("%s -- %s",start_time, stop_time)]);
linkaxes(axs,'x');
