spect2 = spect;
spect2(spect < -100) = -100;
fspec = fspec(1:size(spect, 1));
paramfilename = setparam(tspec, fspec, 15, -100);
[ridges, bw_ridges, snrMap, staggeredSnr] = find_ridges(paramfilename, spect2);
[skel, dist, skelLabels, spines, sweeprates, chorusAngles ] = findSpines(ridges, mu1, tspec, fspec);
% [chorusElements, numChorus] = getSpinesInfo(spineLabels, numSpines, spect, mu1);

imagerows = 4;
imagecols = 3;

burstimage = figure('visible', 'off');
i = 1;
i1=subplot(imagerows, imagecols, i);imagesc(tspec, fspec, spect);colormap jet;set(i1,'ydir','normal');c=colorbar;caxis([-160, -30]);
title(i1, sprintf('(%d) Original Spectrogram Starting at\n%s', i, datestr(timestamp)));
xlabel(i1, 'Duration of event in seconds');
ylabel(i1, 'Frequency (Hz)');
title(c, '10*log10(psd)');

i = i+1;
i2=subplot(imagerows, imagecols, i);imagesc(tspec, fspec, spect2);colormap jet;set(i2, 'ydir', 'normal');c=colorbar;caxis([-100, -30]);
title(i2, sprintf('(%d) Spectrogram with minimum\nPSD threshold at -100', i));
xlabel(i2, 'Duration of event in seconds');
ylabel(i2, 'Frequency (Hz)');
title(c, '10*log10(psd)');

i = i+1;
i3=subplot(imagerows, imagecols, i);pcolor(tspec, fspec, snrMap);shading flat;colormap jet;c=colorbar;
title(i3, sprintf('(%d) SNR Map', i));
xlabel(i3, 'Duration of event in seconds');
ylabel(i3, 'Frequency (Hz)');
title(c, 'SNR');

i = i+1;
i4 = subplot(imagerows, imagecols, i);
tempSnr = snrMap(:);
tempSnr(tempSnr == 0) = [];
histogram(tempSnr, 100)
title(i4, sprintf('(%d) Histogram of SNR Values > 0', i));
xlabel(i4, 'SNR');

i = i+1;
i13 = subplot(imagerows, imagecols, i);pcolor(medfilt2(spect2));shading flat;colormap(i13, jet);c = colorbar;caxis([-100, -30]);
title(i13, sprintf('(%d) Median PSD Value in 3x3 Window', i));
xlabel(i13, 'Duration of event in seconds');
ylabel(i13, 'Frequency (Hz)');
title(c, '10*log10(psd)');

i = i+1;
i12 = subplot(imagerows, imagecols, i);
pcolor(tspec, fspec, staggeredSnr);shading flat;colormap jet;c=colorbar;
title(i12, sprintf('(%d) Staggered SNR Map', i));
xlabel(i12, 'Duration of event in seconds');
ylabel(i12, 'Frequency (Hz)');
title(c, 'SNR');

i = i+1;
i5=subplot(imagerows, imagecols, i);pcolor(tspec, fspec, ridges);colormap jet;set(i5, 'ydir', 'normal');c=colorbar;caxis([-100 -30]);shading flat;
title(c, '10*log10(psd)');
s = sprintf('(%d) Identified Features', i);
title(i5, s);
xlabel(i5, 'Duration of event (in seconds)');
ylabel(i5, 'Frequency (Hz)');

i = i+1;
i6 = subplot(imagerows, imagecols, i); pcolor(tspec, fspec, dist);shading(i6, 'flat');colormap(i6, jet);c = colorbar;set(i6, 'ydir', 'normal');
title(i6, sprintf('(%d) Distance Transform of Ridge Features', i));
xlabel(i6, 'Duration of event (in seconds)');
ylabel(i6, 'Frequency (Hz)');

% i = i+1;
% i7 = subplot(imagerows, imagecols,i);pcolor(tspec, fspec, dist2);colormap(i7, jet);shading(i7, 'flat');c = colorbar;
% title(i7, '(8) Distance Transform Threshold at 1.25');
% xlabel(i7, 'Duration of event (in seconds)');
% ylabel(i7, 'Frequency (Hz)');

i = i+1;
i8 = subplot(imagerows, imagecols,i);
imagesc(tspec, fspec, skel);colormap(i8, gray);c = colorbar;set(i8, 'ydir', 'normal');
title(i8, sprintf('(%d) Skeleton (Open, Close, Thin, Clean)', i));
xlabel(i8, 'Duration of event (in seconds)');
ylabel(i8, 'Frequency (Hz)');

% i = i+1;
% temp = peaks;
% temp(~isnan(peaks)) = 1;
% temp(isnan(peaks)) = 0;
% i9 = subplot(imagerows, imagecols,i);imagesc(tspec, fspec, temp);colormap(i9, gray);colorbar;set(i9,'ydir','normal');
% title(i9, sprintf('(%d) Peaks Along Skeleton\n(Distance Transform)', i));
% xlabel(i9, 'Duration of event in seconds');
% ylabel(i9, 'Frequency (Hz)');

i = i+1;
temp = skelLabels;
temp(temp == 0) = nan;
i10 = subplot(imagerows, imagecols,i);pcolor(tspec, fspec, temp);colormap(i10, lines);colorbar;shading flat;
title(i10, sprintf('(%d) Identified Spines', i));
xlabel(i10, 'Duration of event in seconds');
ylabel(i10, 'Frequency (Hz)');

i = i+1;
i11 = subplot(imagerows, imagecols,i);imagesc(tspec, fspec, spect);colormap(i11, jet);c = colorbar;caxis([-100, -30]);set(i11, 'YDir', 'normal');
title(c, '10*log10(psd)');
title(i11, sprintf('(%d) Spectrogram with Identified Spines', i));
title(c, '10*log10(psd)');
xlabel(i11, 'Duration of event in seconds');
ylabel(i11, 'Frequency (Hz)');
hold on;
[f, t] = find(spines == 1);
plot(tspec(t), fspec(f), 'k*', 'markersize', 2);
hold off;

i = i+1;
i15=subplot(imagerows, imagecols, i);
edges = -90:5:90;
histogram(chorusAngles, 'BinEdges', edges);
axis tight;
title(i15, sprintf('(%d) Histogram of Chorus Angles', i));
xlabel(i15, 'Chorus Angle');

% render image maximized to screen
set(gcf, 'Position', get(0, 'Screensize'));

% save fig
% change this to the local folder path on your device
figname = sprintf('C:\\Users\\robin\\Desktop\\emfisis\\images\\gold\\%s.jpg', burstname);
saveas(burstimage, figname);