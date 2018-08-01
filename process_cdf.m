function process_cdf(year, month)
    addpath 'matlab_cdf364_patch-64';

    % Window size
    nfft = 1024;
    % Sampling frequency
    Fs = 35000;
    f = (0:nfft/2-1)*(Fs/nfft); %frequency range, slice in half
    f = f(1,2:end);

    % read data from cdf file
    filelist_days = dir(sprintf('/var/EMFISIS-SOC/OUT/RBSP-A/L2/%d/%02d', year, month));
    
    for folder_index = 1:numel(filelist_days)
        
        if string(filelist_days(folder_index).name) ~= '.' && string(filelist_days(folder_index).name) ~= '..'
            % get list of files in folder for current day
            filelist = dir(sprintf('%s/%s', filelist_days(folder_index).folder, filelist_days(folder_index).name));
        
            for file_index = 1:numel(filelist)
                if size(regexp(filelist(file_index).name, 'rbsp-[a,b]_WFR-waveform-continuous-burst_emfisis?'), 1) == 1
                    cdf_path = sprintf('%s/%s', filelist(file_index).folder, filelist(file_index).name);
                    cdf_name = filelist(file_index).name
                    
                    epoch = spdfcdfread(cdf_path, 'Variable', 'Epoch', 'CDFEpochtoString', true);
                    
                    s = strsplit(cdf_name, '_');
                    instrument = s{1};
                    datestr = s{4};
                    
                    BuSamples = spdfcdfread(cdf_path, 'Variable', 'BuSamples');

                    % location to store .mat files
                    mat_folder = sprintf('data/mat/%d/%02d/%s', year, month, filelist_days(folder_index).name);

                    % create folder if it does not exist
                    if exist(mat_folder, 'dir') == 0
                        mkdir(mat_folder)
                    end

                    % get data from each sample in file
                    for burst_index = 1:size(epoch)
                    timestamp = datetime(epoch{burst_index},'Format','yyyy-MM-dd''T''HH:mm:ss.SSSSSSSSS');

                    BuData = BuSamples(burst_index, 1:end);

                    % spectrograms of samples
                    [im, fspec, tspec, psd] = spectrogram(BuData, hanning(nfft), nfft/2, f, Fs, 'yaxis');

                    % save to mat file
                    mat_filename = sprintf('%s/%s_%03d_%s.mat', mat_folder, datestr, burst_index, instrument);
                    save(mat_filename, 'fspec', 'psd', 'timestamp', 'tspec');
                    end
                end
            end
        end
    end
end