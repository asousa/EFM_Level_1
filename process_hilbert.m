
% Process raw EFM data using the Hilbert Transform method. 
% filter/downsample to the desired output cadence.
%
% inputs: 
% Data = raw data from the files (leaving the loading part external)
% ADC_SAMPLING_FREQ = 1000 hz
% OUTPUT_SAMPLE_RATE = the sampling rate we're downsampling to. 100Hz?
% phase_offset = number of samples to shift the phase data left or right
%      by. This is useful if the mechanical phase-encoder was misaligned.
%
% function E_field_calib = process_hilbert(data, ADC_SAMPLING_FREQ, ...
%     ADC_REF, EFM_local_gain, cal_data, OUTPUT_SAMPLE_RATE, phase_offset)

function E_field = process_hilbert(data, ADC_SAMPLING_FREQ, OUTPUT_SAMPLE_RATE, phase_offset, omit_polarity)
    ADC_REF = 1.8;                                        % It varies from mill to mill, but let's roll that into the total calibration
    adjacent_sample_mask = 50;                            % How many samples (in output) to mask off before and after a dropout
    nan_mask_width = 5;

    % Raw data is uniformly sampled at ADC_SAMPLING_FREQ
    time = ((1:length(data)) - 1)/ADC_SAMPLING_FREQ;
    time = transpose(time); 

    % Decode via Hilbert transform
    sig = data(:,1)/65535*ADC_REF;
    sig = bandpass(sig, [99,101], ADC_SAMPLING_FREQ);     % Bandpass around the carrier frequency +- 1 Hz
    hilbert_sig = hilbert(sig);
    mag = abs(hilbert_sig);

    phase = data(:,2);
    phase = 2.*phase - 1;                                 % normalize to plus/minus 1
    phase = circshift(phase,phase_offset);                % Roll the phase left or right, if needed
    phase = bandpass(phase, [99,101], ADC_SAMPLING_FREQ); % Bandpass around the carrier frequency +- 1 Hz
    pol = angle(hilbert(sig)) - angle(hilbert(phase));  
    % Compute the relative phase between the signal and the encoder
    pol = abs(mod(pol,2*pi) - pi);                        % Wrap any angles, scale down by pi
    pol = 2*(pol>pi/2) - 1;                               % Threshold it at pi/2

    % Apply Polarity and Calibration
    if omit_polarity
        E_field = mag;
    else
        E_field = mag.*(pol);
    end
    
    % Downsample to a more-appropriate frequency:
    [E_down, ~] = resample(E_field, time, OUTPUT_SAMPLE_RATE);
    
%     % Apply calibration
%     E_field_calib = interp1(cal_data.efmVolts, cal_data.E_field_calib, E_down, 'linear','extrap');
%    
    E_field = E_down;
    
    % deselect any NaN values (resample smooths them over):
%     nanmask = (data(1:end-1,1)==0 & data(2:end,1)==0);  % Allow for the possibility of a single zero sample
    
%     figure();
%     aa = [];
%     for nan_mask_width=1:5
%         ax = subplot(5,1,nan_mask_width);
%         aa = [aa; ax];
%     %     nan_mask_width = 1;
%         nanmask = true(length(data(nan_mask_width:end,1)),1);
%         for k=1:nan_mask_width
%            nanmask = data(k:end-(nan_mask_width - k),1)==0 & nanmask; 
%         end
%     plot(t,data(:,1),'b.-'); hold on; plot(t(nanmask),data(nanmask,1),'ro');
%     
%     end
%     linkaxes(aa,'xy');

    % Allow for up to 5 adjacent zeros before calling it a NaN:
    nanmask = true(length(data(nan_mask_width:end,1)),1);
    for k=1:nan_mask_width
       nanmask = data(k:end-(nan_mask_width - k),1)==0 & nanmask; 
    end


    tnan = time(nanmask); % Find NaN times
    tnan_q = round(OUTPUT_SAMPLE_RATE*tnan); % Quantize to indices on our new timescale
    
    % For each break in data, also eliminate a few points on either side
    % (we have weird spikes there sometimes once the signal comes back)
    for k=-adjacent_sample_mask:adjacent_sample_mask 
        tnan_q = unique([tnan_q; (tnan_q + k)]); 
    end
    tnan_q(tnan_q<=0) = 1;
    tnan_q(tnan_q>=length(E_field)) = length(E_field) - 1;
    
    E_field(tnan_q) = NaN;

    fprintf("length(E)=%d\n", length(E_field));
end
