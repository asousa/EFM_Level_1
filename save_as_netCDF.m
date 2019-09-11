close all; clear all;
data_dir = "/Volumes/lairdata/EFM/RELAMPAGO Data/Level 1/Without Site Corrections v2";
out_dir = "/Volumes/lairdata/EFM/RELAMPAGO Data/Level 1/netCDF";

sites = ["Cordoba","Manfredi","Pilar", "Villa-del-Rosario","Villa-Carlos-Paz"];
% sites = ["Cordoba"];

% Site calibrations:
% site_gains = containers.Map;
% site_offsets = containers.Map;
% site_gains("Cordoba") = 0.0222;           site_offsets("Cordoba") = 25.3092;
% site_gains("Manfredi") = 0.0427;          site_offsets("Manfredi") = 0;
% site_gains("Pilar") = 0.0576;             site_offsets("Pilar") = 13.8439;
% site_gains("Villa-Carlos-Paz") = 0.0458;  site_offsets("Villa-Carlos-Paz") = 10.4258;
% site_gains("Villa-del-Rosario") = 0.0200; site_offsets("Villa-del-Rosario") = -1.9374;

% Site calibrations: July 19th, 2019:
% These site calibrations use a Campbell Csite correction of 0.233.
%  -- Cordoba, Pilar, and Villa Carlos Paz are computed using Campbell field data
%  -- Villa Del Rosario uses the site correction computed in Colorado
%  (backyard test), since the VDR in-field data is from a low-activity day
%  -- Manfredi's gain is the average of the site gains and backyard gains for
%  Pilar and Villa Carlos Paz, since the in-field data is from a
%  low-activity day, and lacks polarity information.
%  -- Manfredi's offset is the mean offset from Cordoba, Pilar, VCP, and VDR.
%  -- Cordoba is lower gain than the other sites; this is believable,
%  though, as the EFM was on the roof of a building, and the corresponding
%  Campbell on the ground.
site_gains = containers.Map;
site_offsets = containers.Map;
site_gains("Cordoba") = 0.0559;           site_offsets("Cordoba") = 50.5869;
site_gains("Manfredi") = 0.1177;          site_offsets("Manfredi") = 12.5;
site_gains("Pilar") = 0.1277;             site_offsets("Pilar") = 10.7203;
site_gains("Villa-Carlos-Paz") = 0.1207;  site_offsets("Villa-Carlos-Paz") = 14.2689;
site_gains("Villa-del-Rosario") = 0.0993; site_offsets("Villa-del-Rosario") = -24.2991;
% site_gains("Villa-del-Rosario") = 0.0446; site_offsets("Villa-del-Rosario") = -24.2991;
% Manfredi gain: ((backyard_gains(EFMs("Villa-Carlos-Paz")) + backyard_gains(EFMs("Pilar")))*Csite + site_gains("Villa-Carlos-Paz") + site_gains("Pilar"))/4

site_lats = containers.Map;
site_lons = containers.Map;
site_lats("Cordoba") = -31.43847455;            site_lons("Cordoba") = -64.19298165;
site_lats("Manfredi") = -31.85712639;           site_lons("Manfredi") = -63.74865947;
site_lats("Pilar") = -31.66715781;              site_lons("Pilar") = -63.8826809;
site_lats("Villa-Carlos-Paz") = -31.47527066;   site_lons("Villa-Carlos-Paz") = -64.52608896;
site_lats("Villa-del-Rosario") = -31.55880245;  site_lons("Villa-del-Rosario") = -63.5655458;

site_fw = containers.Map;
site_fw("Cordoba") = 1.2; % THIS ONE WORKS SO MUCH BETTER, IS IT ~1.3+?
site_fw("Manfredi") = 1.2;
site_fw("Pilar") = 1.1;
site_fw("Villa-Carlos-Paz") = 1.2;
site_fw("Villa-del-Rosario") = 1.2;


start_date = datetime(2018,10,28,0,0,0);
end_date   = datetime(2018,12,20,1,0,0);
% start_date = datetime(2018,11,28,0,0,0);
% end_date   = datetime(2018,12,5,0,0,0);

error_hists = containers.Map();
files_to_do = start_date +  hours(0:hours(end_date - start_date));

fprintf("doing %d sites\ndoing %d hours\n",length(sites), length(files_to_do));
for s=1:length(sites)
    site = sites(s);
    fprintf("Loading %s\n",site);
    error_hists(site) = [];
%     tmp_avg = nan(length(files_to_do),1);
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
            ncwriteatt(outfile,'/','site_name',site);
            ncwriteatt(outfile,'E_field','SAMPLE_RATE',data.SAMPLE_RATE);
            ncwriteatt(outfile,'E_field','start_time',filetime_iso);
            ncwriteatt(outfile,'E_field','E_saturation',clipping_val);
            ncwriteatt(outfile,'E_field','site_gain',site_gains(site));
            ncwriteatt(outfile,'E_field','site_offset',site_offsets(site));
            ncwriteatt(outfile,'E_field','units','V/m');
            
            % Put in: Geo coordinates (lat / lon)
            ncwriteatt(outfile,'/','latitude',site_lats(site));
            ncwriteatt(outfile,'/','longitude',site_lons(site));
            
            %         Firmware version?
            ncwriteatt(outfile,'/','firmware_version',site_fw(site));
            % ncdisp(outfile)
            
            % Timing error: Sum the NaNs, and divide by 2 (since we
            % recorrect ourselves every 30 minutes)
            total_nans = sum(isnan(data.E_field_calib));
            max_timing_error = total_nans/data.SAMPLE_RATE/2.0;
            fprintf('max timing error %g seconds\n',max_timing_error);
            ncwriteatt(outfile,'E_field','max_timing_error',max_timing_error);
            
%             figure;
%             plot(isnan(data.E_field_calib));
            
            error_hists(site) = [error_hists(site), max_timing_error];
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

