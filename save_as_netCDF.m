close all; clear all;
data_dir = "/Volumes/Untitled/EFM before office move/RELAMPAGO Data/Level 1/Without Site Corrections v2";
out_dir = "/Volumes/Untitled/EFM before office move/RELAMPAGO Data/Level 1/netCDF";

sites = ["Cordoba","Manfredi","Pilar", "Villa-del-Rosario","Villa-Carlos-Paz"];
% sites = ["Cordoba"];

% Site calibrations:
site_gains = containers.Map;
site_offsets = containers.Map;
site_gains("Cordoba") = 0.0222;           site_offsets("Cordoba") = 25.3092;
site_gains("Manfredi") = 0.0427;          site_offsets("Manfredi") = 0;
site_gains("Pilar") = 0.0576;             site_offsets("Pilar") = 13.8439;
site_gains("Villa-Carlos-Paz") = 0.0458;  site_offsets("Villa-Carlos-Paz") = 10.4258;
site_gains("Villa-del-Rosario") = 0.0200; site_offsets("Villa-del-Rosario") = -1.9374;

start_date = datetime(2018,10,28,0,0,0);
end_date   = datetime(2018,12,20,1,0,0);

files_to_do = start_date +  hours(0:hours(end_date - start_date));

fprintf("doing %d sites\ndoing %d hours\n",length(sites), length(files_to_do));
for s=1:length(sites)
    site = sites(s);
    fprintf("Loading %s\n",site);
    tmp_avg = nan(length(files_to_do),1);
    for ft=1:length(files_to_do)
        dvec = datevec(files_to_do(ft));
        indir = fullfile(data_dir,site,sprintf('%d',dvec(1)),sprintf('%d',dvec(2)), sprintf('%d',dvec(3)));
        infile = fullfile(indir, sprintf("%02d.mat",dvec(4)));
        
        if isfile(infile)
            % Load the decoded and table-calibrated data
            fprintf("\tLoading %s\n",infile);
            data = load(infile);
            
            % Prepare output directory
            odir = fullfile(out_dir,site,sprintf('%d',dvec(1)),sprintf('%d',dvec(2)), sprintf('%d',dvec(3)));
            outfile= fullfile(odir, sprintf("%s_%04d-%02d-%02dT%02d.nc",site,dvec(1), dvec(2), dvec(3), dvec(4)));

            if ~isfolder(odir)
                mkdir(odir)
            end
            
            % Clear previous file
            if isfile(outfile)
                delete(outfile)
            end
           
            % Apply site corrections
            clipping_val = site_gains(site)*data.E_clip + site_offsets(site);
            E_field = site_gains(site)*data.E_field_calib + site_offsets(site);
            
            % Create netCDF file, write E field
            nccreate(outfile,'E_field','Dimensions',{'t',length(E_field)});
            ncwrite(outfile,'E_field',E_field);
            
            % Write metadata
            filetime_iso = sprintf("%04d-%02d-%02dT%02d:%02d:%02d+000",dvec(1),dvec(2),dvec(3),dvec(4),dvec(5),dvec(6));
            ncwriteatt(outfile,'/','creation_date',datestr(now));
            ncwriteatt(outfile,'/','calibration_file',data.cal_filename);
            ncwriteatt(outfile,'E_field','SAMPLE_RATE',data.SAMPLE_RATE);
            ncwriteatt(outfile,'E_field','start_time',filetime_iso);
            ncwriteatt(outfile,'E_field','E_saturation',clipping_val);
            ncwriteatt(outfile,'E_field','site_gain',site_gains(site));
            ncwriteatt(outfile,'E_field','site_offset',site_offsets(site));
            ncwriteatt(outfile,'E_field','units','V/m');
            % ncdisp(outfile)

        end
    end
    
end

%% Prepare netCDF
% odir = fullfile(out_dir,site,sprintf('%d',dvec(1)),sprintf('%d',dvec(2)), sprintf('%d',dvec(3)));
% outfile= fullfile(odir, sprintf("%s_%04d-%02d-%02dT%02d.nc",site,dvec(1), dvec(2), dvec(3), dvec(4)));
% 
% if ~isfolder(odir)
%     mkdir(odir)
% end
% 
% if isfile(outfile)
%     delete(outfile)
% end
% 
% filetime_iso = sprintf("%04d-%02d-%02dT%02d:%02d:%02d+000",dvec(1),dvec(2),dvec(3),dvec(4),dvec(5),dvec(6));
% clipping_val = site_gains(site)*data.E_clip + site_offsets(site);
% E_field = site_gains(site)*data.E_field_calib + site_offsets(site);
% 
% nccreate(outfile,'E_field','Dimensions',{'t',length(E_field)});
% ncwrite(outfile,'E_field',E_field);
% 
% ncwriteatt(outfile,'/','creation_date',datestr(now));
% ncwriteatt(outfile,'/','calibration_file',data.cal_filename);
% ncwriteatt(outfile,'E_field','SAMPLE_RATE',data.SAMPLE_RATE);
% ncwriteatt(outfile,'E_field','start_time',filetime_iso);
% ncwriteatt(outfile,'E_field','E_saturation',clipping_val);
% ncwriteatt(outfile,'E_field','site_gain',site_gains(site));
% ncwriteatt(outfile,'E_field','site_offset',site_offsets(site));
% ncwriteatt(outfile,'E_field','units','V/m');
% % ncdisp(outfile)

