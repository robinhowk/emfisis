paramfilename = setparam(tspec, fspec, 35, -100);
load(paramfilename);
fspec = fspec(1):8:fspec(end);
[~,fspec,tspec,spect] = spectrogram(BuData, 2048, 2048-256, fspec, 35000);
spect = 10 * log10(spect);
spect2 = spect;
spect2(spect < -100) = -100;
[ridges, bwRidges, snrMap, staggeredSnr] = find_ridges(paramfilename, spect2);
[ dist, peaks, peakLabels, numPeaks ] = findDstPeaks( bwRidges, ridges );





figure;
subplot(3,3,1);pcolor(tspec, fspec, spect);colormap jet;shading flat;
title('Original Spectrogram');
xlabel('Duration of event (in seconds)');ylabel('Frequency (Hz)');
colorbar
subplot(3,3,2);pcolor(spect2);shading flat;colormap jet;colorbar;
title('Spectrogram Min Psd -100');
xlabel('Duration of event (in seconds)');ylabel('Frequency (Hz)');
subplot(3,3,2);pcolor(tspec, fspec, spect2);shading flat;colormap jet;colorbar;
title('Spectrogram Min Psd -100');
xlabel('Duration of event (in seconds)');ylabel('Frequency (Hz)');
subplot(3,3,3);pcolor(tspec, fspec, snrMap);shading flat;colormap jet;colorbar;
title('SNR Map');
xlabel('Duration of event (in seconds)');ylabel('Frequency (Hz)');
subplot(3,3,4);pcolor(tspec, fspec, ridges);colormap jet;shading flat;colorbar;
title('Detected Features');
xlabel('Duration of event (in seconds)');ylabel('Frequency (Hz)');
subplot(3,3,5);pcolor(tspec, fspec, dist);colormap jet;shading flat;colorbar;
title('Distance Transform');
xlabel('Duration of event (in seconds)');ylabel('Frequency (Hz)');

tempPeaks = peaks;
tempPeaks(peaks == 0) = 2;
tempPeaks = tempPeaks- 1;
i1=subplot(3,3,6);pcolor(tspec, fspec, tempPeaks);colormap(i1, gray);shading flat;colorbar;
title('Distance Transform Peaks');
xlabel('Duration of event (in seconds)');ylabel('Frequency (Hz)');



% distribution of sweeprates
i9 = subplot(3,3,9);
histogram(sweeprates / 1000, 'BinWidth', 1);
title(i9, 'Distribution of Sweeprates');
xlabel('Sweeprate (KHz / sec)');
xlim([-15 15]);
  