close all; clear all;

ADC_SAMPLING_FREQ = 1000;
SAMPLE_RATE = 100; % Hz, what we're decimating to

% Fiddle with this if we're having issues with large spikes from equal positive to negative values
phase_offset = 0; 
raw_data_dir = "/Volumes/lairdata/EFM/RELAMPAGO Data/Campaign Data";
out_data_dir = "/Volumes/lairdata/EFM/RELAMPAGO Data/Level 1/Without Site Corrections v2";
cal_dir = "/Volumes/lairdata/EFM/EFM Level 1 Processing/EFM calibration maps 6-17-2019";

% EFMs  = ["EFM011" ,"EFM004",  "EFM006",    "EFM002",         "EFM008"];
EFMs = containers.Map;
EFMs("Cordoba") = "EFM011";
EFMs("Manfredi") = "EFM004";
EFMs("Pilar") = "EFM006";
EFMs("Villa-del-Rosario") = "EFM002";
EFMs("Villa-Carlos-Paz") = "EFM008";

site_correction_factor = 1; 

sites = ["Cordoba","Manfredi","Pilar", "Villa-del-Rosario","Villa-Carlos-Paz"];
% sites = ["Cordoba"];
%%
% The whole campaign!

start_date = datetime(2018,10,28,0,0,0);
end_date   = datetime(2018,12,20,0,0,0);
% start_date = datetime(2018,12,4,19,0,0);
% end_date   = datetime(2018,12,4,19,0,0);

for s_ind=1:length(sites)
    site_name = sites(s_ind);
    EFM = EFMs(site_name);

    % Load the calibration map for this mill:
    cal_filename = sprintf("%s_map_2019-06-17.mat",EFM);
    cal_file = fullfile(cal_dir,cal_filename);  
    disp(cal_file);
    cal_data = load(cal_file); % returns efmVolts, E_field_calib

    % one file per hour
    dates_to_do = start_date + hours(0:hours(end_date - start_date));
    overlap_samples = 5*ADC_SAMPLING_FREQ; % How many samples to overlap from the adjacent files

    for i=1:length(dates_to_do)
        % Load the main file, with some overlap at the beginning and end from
        % the adjacent files (Hilbert transform takes a bit to settle)
        file_time = dates_to_do(i);
        prev_file_time = file_time - hours(1);
        next_file_time = file_time + hours(1);

        dvec = datevec(prev_file_time);
        prev_file = fullfile(raw_data_dir,site_name,'DATA',...
                    sprintf('%d',dvec(1)),sprintf('%d',dvec(2)), sprintf('%d',dvec(3)),...
                    sprintf('%02d.bin',dvec(4)));
        dvec = datevec(next_file_time);
        next_file = fullfile(raw_data_dir,site_name,'DATA',...
                    sprintf('%d',dvec(1)),sprintf('%d',dvec(2)), sprintf('%d',dvec(3)),...
                    sprintf('%02d.bin',dvec(4)));
        dvec = datevec(file_time);
        cur_file = fullfile(raw_data_dir,site_name,'DATA',...
                    sprintf('%d',dvec(1)),sprintf('%d',dvec(2)), sprintf('%d',dvec(3)),...
                    sprintf('%02d.bin',dvec(4)));
        
        if ~isfile(cur_file)
            fprintf("No data available for %s at %s\n",site_name, file_time);
            continue;
        end
        have_prev   = isfile(prev_file);
        have_next   = isfile(next_file);

        % Load current file
        disp("Loading current file");
        fileID = fopen(cur_file, 'r');
        data = fread(fileID,[1,3600*ADC_SAMPLING_FREQ],'uint16','n');
        fclose(fileID);
        data(2,:) = bitget(data(1,:),ones(1,length(data))*1,'uint16'); % Newer version injects bit for phase
        data(1,:) = bitset(data(1,:),ones(1,length(data))*1,ones(1,length(data))*0,'uint16');
        data = transpose(data);

        % Load previous overlap
        if have_prev
            disp("loading previous overlap");
            fileID = fopen(prev_file, 'r');
            fseek(fileID, overlap_samples, 1);
            data_local = fread(fileID,[1,overlap_samples],'uint16','n');
            fclose(fileID);
            data_local(2,:) = bitget(data_local(1,:),ones(1,length(data_local))*1,'uint16'); % Newer version injects bit for phase
            data_local(1,:) = bitset(data_local(1,:),ones(1,length(data_local))*1,ones(1,length(data_local))*0,'uint16');
            data = [transpose(data_local); data];
        end

        % Load next overlap
        if have_next
            disp("loading next overlap");
            fileID = fopen(next_file, 'r');
            data_local = fread(fileID,[1,overlap_samples],'uint16','n');
            fclose(fileID);
            data_local(2,:) = bitget(data_local(1,:),ones(1,length(data_local))*1,'uint16'); % Newer version injects bit for phase
            data_local(1,:) = bitset(data_local(1,:),ones(1,length(data_local))*1,ones(1,length(data_local))*0,'uint16');
            data = [data; transpose(data_local)];
        end


        E_field_raw = process_hilbert(data, ADC_SAMPLING_FREQ, SAMPLE_RATE, phase_offset, false);

        % Trim off any extra from the overlap:
        trim_length = (overlap_samples*SAMPLE_RATE/ADC_SAMPLING_FREQ);
        if have_prev
            disp("trimming prev");
            E_field_raw = E_field_raw(trim_length + 1:end);
        end
        if have_next
            disp("trimming next");
           E_field_raw = E_field_raw(1:end - trim_length); 
        end

        % Chat about it
        fprintf("File %s: \n",cur_file);
        fprintf("Length(output)=%d\n",length(E_field_raw));
        fprintf("NaNs in input: %d, NaNs in output: %d \n",sum(data(:,1)==0),sum(isnan(E_field_raw)))
        fprintf("Total dropouts: %3.2g seconds \n",(sum(isnan(E_field_raw))/SAMPLE_RATE))


        odir = fullfile(out_data_dir,site_name,sprintf('%d',dvec(1)),sprintf('%d',dvec(2)), sprintf('%d',dvec(3)));
        if ~isfolder(odir)
            sprintf("Making directory %s\n",odir);
            mkdir(odir);
        end

        % Calibrate data using the table map (post-campaign)
        E_field_calib = interp1(cal_data.efmVolts, cal_data.E_field_calib, E_field_raw,'linear','extrap');
        
        % Site correction factor (if we had it here):
%         E_field_calib = E_field_calib*site_correction_factor;

        % Compute clipping threshold, for reference
        % (efmVolts ~ 1 when clipping; Hilbert algorithm will get a little
        % bit beyond that, since we're filtering the signal to get a
        % fundamental wave at 100 Hz)
        E_clip = site_correction_factor*interp1(cal_data.efmVolts, cal_data.E_field_calib, 1.0,'linear','extrap');
        
        outfile = fullfile(odir, sprintf("%02d.mat",dvec(4)));
        save(outfile,'E_field_calib','SAMPLE_RATE','file_time','EFM','cal_filename','site_correction_factor','E_clip');
    end
end

plot_EFM_data;
